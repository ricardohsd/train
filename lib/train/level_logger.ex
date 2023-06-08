defmodule Train.LevelLogger do
  require Logger

  alias Train.LlmChain

  def log(message, %LlmChain{log_level: log_level}) do
    Logger.log(log_level, message)
  end
end
