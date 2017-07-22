defmodule Robot.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: :robot_sup)
  end

  def start_child(robot_index) do
    Supervisor.start_child(:robot_sup, [robot_index])
  end

  def init([]) do
    children = [worker(RobotWorker, [], restart: :temporary)]
    supervise children, strategy: :simple_one_for_one
  end
end
