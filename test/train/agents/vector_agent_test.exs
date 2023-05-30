defmodule Train.Agents.VectorAgentTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Clients.OpenAIConfig
  alias Train.Agents.VectorPrompt
  alias Train.Agents.VectorAgent
  alias Train.Clients.Pinecone

  setup_all do
    HTTPoison.start()

    chain =
      Train.LlmChain.new(%{
        memory_pid: nil,
        tools: [],
        openai_config: OpenAIConfig.new(%{model: :"gpt-3.5-turbo"}),
        pinecone_config: %Pinecone.Config{namespace: "foo", topK: 2}
      })

    %{chain: chain}
  end

  @question "o que é o divorcio?"

  test "fetches context and metadata from Pinecone and uses OpenAI to generate a response", %{
    chain: chain
  } do
    use_cassette "agents/vector" do
      {:ok, [%{content: _, role: "user"} | _], response} =
        VectorAgent.call(chain, @question, VectorPrompt)

      expected =
        "O divórcio é a dissolução legal do vínculo matrimonial entre duas pessoas, que implica na separação dos deveres de coabitação e fidelidade recíproca, bem como no fim do regime de bens. No entanto, não altera as relações entre pais e filhos, que continuam tendo direito à convivência com ambos os genitores. O procedimento judicial da separação cabe somente aos cônjuges, e, no caso de incapacidade, serão representados por um curador, ascendente ou irmão. (Fonte: Lei n. 6.515/77, art. 27 e Emenda Constitucional n. 66/2010, parágrafo único do art. 1.576 e art. 1.632 do Código Civil)"

      assert response == expected
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
