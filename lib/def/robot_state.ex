defmodule RobotState do

  defstruct [
    robot_index: 0,
    robot_id: 0,
    socket: 0,
    lobby_channel: 0,
    table_channel: 0,
    user_channel: 0,
    other_channel: 0
  ]

end
