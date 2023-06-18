defmodule Train.Agents.VectorAgentTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.OpenAI
  alias Train.Agents.VectorPrompt
  alias Train.Agents.VectorAgent
  alias Train.Pinecone

  setup_all do
    HTTPoison.start()

    chain =
      Train.LlmChain.new(%{
        memory: nil,
        tools: [],
        openai_config: OpenAI.Config.new(%{model: :"gpt-4"}),
        pinecone_config:
          Pinecone.config(%{
            namespace: "food",
            topK: 5,
            index: "localtest",
            project: "1234567"
          })
      })

    %{chain: chain}
  end

  @question "Quem é Cascão Pereira Alves?"

  test "fetches context and metadata from Pinecone and uses OpenAI to generate a response", %{
    chain: chain
  } do
    use_cassette "agents/vector" do
      {:ok, [%{content: _, role: "user"} | _], response} =
        VectorAgent.call(chain, @question, VectorPrompt)

      expected =
        "Cascão Pereira Alves, full name Cascão da Silva Pereira Alves, is a Brazilian musician born on January 14, 1969. He is the founder of the rock band Casca Dura, serving as the lead singer, guitarist, and principal songwriter. Before forming Casca Dura, he was the drummer for the rock band Solitarios from 1990 to 1994.\n\nReferences:\n- Context"

      assert expected == response
    end
  end

  test "validates that Pinecone config is given", %{chain: chain} do
    chain = %{chain | pinecone_config: nil}
    {:error, error} = VectorAgent.call(chain, @question, VectorPrompt)

    assert error == "Pinecone config can't be null"
  end

  test "validates that OpenAI config is given", %{chain: chain} do
    chain = %{chain | openai_config: nil}
    {:error, error} = VectorAgent.call(chain, @question, VectorPrompt)

    assert error == "OpenAI config can't be null"
  end
end
