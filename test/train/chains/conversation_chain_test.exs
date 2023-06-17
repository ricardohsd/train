defmodule Train.Chains.ConversationChainTest do
  use ExUnit.Case, async: true

  alias Train.LlmChain
  alias Train.Chains.ConversationChain
  alias Train.OpenAI.Config

  setup do
    tools = [
      %{
        name: "Calculator",
        description: "Calculate matematical questions, like age of a person, distance, etc",
        func: Train.Tools.BasicCalculator
      }
    ]

    %{tools: tools}
  end

  test "tools must be present" do
    {:error, error} =
      %LlmChain{memory: {self(), Train.Memory.BufferAgent}, tools: []}
      |> ConversationChain.run("What is a continent?")

    assert "tools can't be empty" == error
  end

  test "memory agent's pid must be present", %{tools: tools} do
    {:error, error} =
      %LlmChain{tools: tools, memory: {nil, nil}, openai_config: Config.new()}
      |> ConversationChain.run("What is a continent?")

    assert "memory agent pid can't be null" == error
  end

  test "OpenAI config must be present", %{tools: tools} do
    {:error, error} =
      %LlmChain{tools: tools, openai_config: nil, memory: {self(), Train.Memory.BufferAgent}}
      |> ConversationChain.run("What is a continent?")

    assert "OpenAI config can't be null" == error
  end

  test "max_iterations mus be higher than 0", %{tools: tools} do
    {:error, error} =
      %LlmChain{
        tools: tools,
        openai_config: Config.new(),
        memory: {self(), Train.Memory.BufferAgent},
        max_iterations: 0
      }
      |> ConversationChain.run("What is a continent?")

    assert "max_iterations must be higher than 0" == error
  end
end
