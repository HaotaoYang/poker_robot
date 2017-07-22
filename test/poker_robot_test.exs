defmodule PokerRobotTest do
  use ExUnit.Case
  doctest PokerRobot

  test "greets the world" do
    assert PokerRobot.hello() == :world
  end
end
