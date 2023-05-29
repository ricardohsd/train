defmodule Train.Chains.ConversationChainTest do
  use ExUnit.Case, async: true

  alias Train.LlmChain
  alias Train.Chains.ConversationChain
  alias Train.Clients.OpenAIConfig

  test "tools must be present" do
    {:error, error} =
      %LlmChain{tools: []}
      |> ConversationChain.run("What is a continent?")

    assert "tools can't be empty" == error
  end

  test "memory agent's pid must be present" do
    {:error, error} =
      %LlmChain{tools: [Train.Tools.BasicCalculator], openai_config: OpenAIConfig.new()}
      |> ConversationChain.run("What is a continent?")

    assert "memory agent pid can't be null" == error
  end

  test "OpenAI config must be present" do
    {:error, error} =
      %LlmChain{tools: [Train.Tools.BasicCalculator], openai_config: nil, memory_pid: self()}
      |> ConversationChain.run("What is a continent?")

    assert "OpenAI config can't be null" == error
  end

  test "max_iterations mus be higher than 0" do
    {:error, error} =
      %LlmChain{
        tools: [Train.Tools.BasicCalculator],
        openai_config: OpenAIConfig.new(),
        memory_pid: self(),
        max_iterations: 0
      }
      |> ConversationChain.run("What is a continent?")

    assert "max_iterations must be higher than 0" == error
  end
end
