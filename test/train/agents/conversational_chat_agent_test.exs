defmodule Train.Agents.ConversationalChatAgentTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Agents.ConversationalChatAgent
  alias Train.Clients.OpenAIConfig

  setup_all do
    Logger.configure(level: :warning)
    HTTPoison.start()
    tools = [Train.Tools.BasicCalculator, Train.Tools.SerpApi]

    chain =
      Train.LlmChain.new(%{
        memory_pid: nil,
        tools: tools,
        openai_config: OpenAIConfig.new(%{model: :"gpt-3.5-turbo"})
      })

    %{chain: chain}
  end

  test "uses the search tool to get more context", %{chain: chain} do
    use_cassette "agents/conversational" do
      {:ok, _, response} =
        ConversationalChatAgent.call(
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
        "AI: Angela Dorothea Merkel is a German former politician and scientist who served as Chancellor of Germany from November 2005 to December 2021. A member of the Christian Democratic Union, she previously served as Leader of the Opposition from 2002 to 2005 and as Leader of the Christian Democratic Union from 2000 to 2018."
      ]

      {:ok, _, response} =
        ConversationalChatAgent.call(
          chain,
          "In which city was she born?",
          chat_history
        )

      assert response == "Hamburg, Germany"
    end
  end
end
