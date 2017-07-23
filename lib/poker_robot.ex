defmodule PokerRobot do
  
  def start(num) do
    for n <- 1..num do
      :timer.sleep 500
      Robot.Supervisor.start_child(n)
    end
  end

end
