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
    {:ok, pid} = Client.start_link()
    {:ok, socket} = Client.connect(
	  pid,
      host: "192.168.10.244",
      port: 8888,
      path: "/socket/websocket",
      params: %{userToken: robot_index},
      secure: false
	)
    lobbychannel = Client.channel(socket, "lobby:channel", %{})
    case Client.join_channel(lobbychannel) do
      {:ok
    end
    robot_state = %RobotState{
      robot_index: robot_index
      robot_id: robot_id,
      socket: socket
    }
    {:ok, robot_state}
  end

  defp join_channel(channel) do
    Client.join(channel)
  end

end
