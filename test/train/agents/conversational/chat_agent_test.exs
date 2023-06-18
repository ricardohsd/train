defmodule Train.Agents.Conversational.ChatAgentTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.LlmChain
  alias Train.Agents.Conversational.ChatAgent
  alias Train.OpenAI.Config

  setup_all do
    Logger.configure(level: :warning)
    HTTPoison.start()

    tools = [
      %{
        name: "Calculator",
        description: "Calculate matematical questions, like age of a person, distance, etc",
        func: Train.Tools.BasicCalculator
      },
      %{
        name: "Google search",
        description: "Used to search on Google.",
        func: Train.Tools.SerpApi
      }
    ]

    chain =
      Train.LlmChain.new(%{
        memory: nil,
        tools: tools,
        openai_config: Config.new(%{model: :"gpt-3.5-turbo"})
      })

    %{chain: chain}
  end

  describe "call" do
    test "uses the search tool to get more context", %{chain: chain} do
      use_cassette "agents/conversational" do
        {:ok, _, response} =
          ChatAgent.call(
            chain,
            "Who is the creator of Elixir?",
            []
          )

        assert response == "José Valim"
      end
    end

    test "uses the chat history as context", %{chain: chain} do
      use_cassette "agents/conversational_multiple" do
        chat_history = [
          %{
            role: "assistant",
            content:
              "Angela Dorothea Merkel is a German former politician and scientist who served as Chancellor of Germany from November 2005 to December 2021. A member of the Christian Democratic Union, she previously served as Leader of the Opposition from 2002 to 2005 and as Leader of the Christian Democratic Union from 2000 to 2018."
          }
        ]

        {:ok, messages, response} =
          ChatAgent.call(
            chain,
            "In which city was she born?",
            chat_history
          )

        assert [
                %{content: "In which city was she born?", role: "user"},
                %{content: "Hamburg, Germany", role: "assistant"}
              ] == messages

        assert response == "Hamburg, Germany"
      end
    end
  end

  describe "run" do
    test "tools must be present" do
      {:error, error} =
        %LlmChain{memory: {self(), Train.Memory.BufferAgent}, tools: []}
        |> ChatAgent.run("What is a continent?")

      assert "tools can't be empty" == error
    end

    test "memory agent's pid must be present", %{chain: %LlmChain{tools: tools}} do
      {:error, error} =
        %LlmChain{tools: tools, memory: {nil, nil}, openai_config: Config.new()}
        |> ChatAgent.run("What is a continent?")

      assert "memory agent pid can't be null" == error
    end

    test "OpenAI config must be present", %{chain: %LlmChain{tools: tools}} do
      {:error, error} =
        %LlmChain{tools: tools, openai_config: nil, memory: {self(), Train.Memory.BufferAgent}}
        |> ChatAgent.run("What is a continent?")

      assert "OpenAI config can't be null" == error
    end

    test "max_iterations mus be higher than 0", %{chain: %LlmChain{tools: tools}} do
      {:error, error} =
        %LlmChain{
          tools: tools,
          openai_config: Config.new(),
          memory: {self(), Train.Memory.BufferAgent},
          max_iterations: 0
        }
        |> ChatAgent.run("What is a continent?")

      assert "max_iterations must be higher than 0" == error
    end
  end
end
