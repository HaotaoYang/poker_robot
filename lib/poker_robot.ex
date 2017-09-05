defmodule PokerRobot do
  
  def start(start_index, end_index) do
    for n <- start_index..end_index do
      :timer.sleep 500
      Robot.Supervisor.start_child(n)
    end
  end

end
