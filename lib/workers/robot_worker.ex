defmodule RobotWorker do
  use GenServer
  require Logger

  def start_link({robot_id}) do
    GenServer.start_link(__MODULE__, robot_id, [name: where_is(robot_id)])
  end

  def where_is(robot_id) do
    {:via, Registry, {MyRegistry, "robot_#{robot_id}"}}
  end

  def init(robot_id) do
    robot_id
    {:ok, %{}}
  end

end
