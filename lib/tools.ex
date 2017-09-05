defmodule Tools do

  require Logger

  ## 时间戳(秒)
  def time_stamp() do
    :erlang.system_time(:second)
  end

  ## 时间戳(毫秒)
  def millisecond() do
    :erlang.system_time(:millisecond)
  end

  ## 时间戳(微秒)
  def microsecond() do
    :erlang.system_time(:microsecond)
  end

  ## 生成随机种子
  def gen_random_seed() do
    :rand.seed(:exs1024, :erlang.timestamp())
  end

end
