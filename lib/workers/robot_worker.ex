defmodule RobotWorker do
  use GenServer
  require Logger
  import RobotState

  alias PhoenixChannelClient, as: Client

  def start_link(robot_index) do
    GenServer.start_link(__MODULE__, robot_index, [name: where_is(robot_index)])
  end

  def where_is(robot_index) do
    {:via, Registry, {MyRegistry, "robot_#{robot_index}"}}
  end

  def init(robot_index) do
    Process.flag :trap_exit, true
    Tools.gen_random_seed()
    {:ok, pid} = Client.start_link()
    {:ok, socket} = Client.connect(
	  pid,
      host: "192.168.10.244",
      port: 4396,
      path: "/socket/websocket",
      params: %{token: robot_index},
      secure: false
	)

    lobby_channel = Client.channel(socket, "lobby:channel", %{})
    {:ok, _} = join_channel(lobby_channel)
    start_heartbeat_timer()
    start_seats_info_timer()

    robot_state = %RobotState{
      robot_index: robot_index,
      socket: socket,
      lobby_channel: lobby_channel
    }

    Logger.debug("robot_index: #{robot_index} init successfully!!!")
    {:ok, robot_state}
  end

  def handle_call(msg, _from, state) do
    Logger.warn("robot_index: #{state.robot_index} receive an unknown call msg: #{inspect msg}")
    {:reply, :ok, state}
  end

  def handle_cast(msg, state) do
    Logger.warn("robot_index: #{state.robot_index} receive an unknown cast msg: #{inspect msg}")
    {:noreply, state}
  end

  def handle_info({"user_info", %{"user_id" => robot_id, "user_name" => robot_name, "chip" => chip}}, state) do
    {:noreply, %{state | robot_id: robot_id, robot_name: robot_name, chip: chip}}
  end
  def handle_info({"bet_time", _}, state) do
    bet_timer()
    {:noreply, state}
  end
  def handle_info({"result", %{"final_chip" => chip}}, state) do
    {:noreply, %{state | chip: chip}}
  end
  def handle_info(:send_heartbeat, %{lobby_channel: lobby_channel} = state) do
    push(lobby_channel, "ping", %{})
    start_heartbeat_timer()
    {:noreply, state}
  end
  def handle_info(:get_seats_info, %{lobby_channel: lobby_channel} = state) do
    push(lobby_channel, "get_seats_info", %{})
    start_seats_info_timer()
    {:noreply, state}
  end
  def handle_info(:bet, %{chip: chip, lobby_channel: lobby_channel} = state) do
    seat_id = Enum.random(1..4)
    count = case chip >= 500 * 4 * 8 do
      true -> 500 * Enum.random(1..4)
      _ -> 500
    end
    push(lobby_channel, "bet", %{"seat_id" => seat_id, "count" => count, "device" => 1})
    {:noreply, state}
  end
  def handle_info({"phx_reply", _}, state) do
    {:noreply, state}
  end
  def handle_info(_msg, state) do
    # Logger.warn("robot_index: #{state.robot_index} receive an unknown info msg: #{inspect msg}")
    {:noreply, state}
  end
  def terminate(reason, state) do
    Logger.warn("robot_index: #{state.robot_index} progress terminate, reason: #{inspect reason}")
    :ok
  end

  defp join_channel(channel) do
    Client.join(channel)
  end

  defp bet_timer() do
    time = Enum.random(1..13)
    Process.send_after(self(), :bet, time * 1000)
  end

  defp start_heartbeat_timer() do
    Process.send_after(self(), :send_heartbeat, 1000)
  end

  defp start_seats_info_timer() do
    Process.send_after(self(), :get_seats_info, 2000)
  end

  defp push(channel, proto, payload) do
    Client.push(channel, proto, payload)
  end

end
