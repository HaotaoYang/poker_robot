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
    {:ok, pid} = Client.start_link()
    {:ok, socket} = Client.connect(
	  pid,
      host: "192.168.10.244",
      port: 8888,
      path: "/socket/websocket",
      params: %{userToken: robot_index},
      secure: false
	)

    lobby_channel = Client.channel(socket, "lobby:channel", %{})
    {:ok, %{"id" => robot_id}} = join_channel(lobby_channel)

    user_channel = Client.channel(socket, "user:" <> "#{robot_id}", %{})
    _ = join_channel(user_channel)

    other_channel = Client.channel(socket, "other:heartbeat", %{})
    _ = join_channel(other_channel)
    start_heartbeat_timer()

    table_channel = case Client.push_and_receive(lobby_channel, "enterRoom", %{"room_id" => 1}) do
      {:ok, %{"table_id" => table_id}} ->
        table_channel = Client.channel(socket, "table:" <> table_id, %{})
        _ = join_channel(table_channel)
        Client.push(table_channel, "enter", %{re: 0})
        table_channel
      _ ->
        0
    end

    robot_state = %RobotState{
      robot_index: robot_index,
      robot_id: robot_id,
      socket: socket,
      lobby_channel: lobby_channel,
      user_channel: user_channel,
      other_channel: other_channel,
      table_channel: table_channel
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

  def handle_info(:send_heartbeat, %{other_channel: other_channel} = state) do
    Client.push(other_channel, "ping", %{})
    start_heartbeat_timer()
    {:noreply, state}
  end
  def handle_info({"merge_table", %{"table_id" => table_id}}, state) do
    state = merge_table(table_id, state)
    {:noreply, state}
  end
  def handle_info({"action", %{"id" => id}}, %{robot_id: robot_id, table_channel: table_channel} = state) do
    case table_channel do
      0 ->
        :ok
      _ ->
        case id == robot_id do
          true ->
            do_action(table_channel)
          _ ->
            random_act(table_channel)
        end
    end
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

  defp start_heartbeat_timer() do
    :erlang.send_after(1000, self(), :send_heartbeat)
  end

  defp merge_table(table_id, state) do
    case Client.push_and_receive(state.table_channel, "exit", %{}) do
      {:ok, %{}} ->
        Client.leave(state.table_channel)
        new_table_channel = Client.channel(state.socket, "table:" <> table_id, %{})
        case join_channel(new_table_channel) do
          {:ok, %{}} ->
            case Client.push_and_receive(new_table_channel, "enter", %{re: 0}) do
              {:ok, _} -> %{state | table_channel: new_table_channel}
              _ -> %{state | table_channel: 0}
            end
          _ -> %{state | table_channel: 0}
        end
      _ -> state
    end
  end

  defp do_action(table_channel) do
    n = Enum.random 1..4
    case n do
      1 -> push(table_channel, "fold", %{})
      2 -> push(table_channel, "bet", %{"amount" => 200})
      _ -> push(table_channel, "call", %{})
    end
  end

  defp random_act(table_channel) do
    n = Enum.random 1..3
    case n do
      1 -> push(table_channel, "chat", %{"msg" => "face:#{Enum.random(0..16)}"})
      2 -> push(table_channel, "chat", %{"msg" => "rapid:#{Enum.random(0..12)}"})
      _ -> push(table_channel, "tip", %{})
    end
  end

  defp push(channel, proto, payload) do
    Client.push(channel, proto, payload)
  end

end
