defmodule Train.Clients.OpenAITest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Clients.OpenAI
  alias Train.Clients.OpenAIConfig

  @prompt "what is the meaning of life?"

  setup_all do
    HTTPoison.start()
    %{config: OpenAIConfig.new(%{model: :"gpt-3.5-turbo"})}
  end

  test "single user chat completion", %{config: config} do
    use_cassette "open_ai/chat" do
      {:ok, _, response} = OpenAI.generate(:user, "What are continents?", config)

      assert response ==
               "Continents are large, continuous land masses on the Earth's surface that are separated by oceans or other bodies of water. There are seven continents on Earth: Africa, Antarctica, Asia, Australia, Europe, North America, and South America. Each continent has its own unique geography, climate, and natural resources."
    end
  end

  test "multiple chat completion messages", %{config: config} do
    use_cassette "open_ai/chat_messages" do
      messages = [
        %{"content" => "How many continents exist?", "role" => "user"}
      ]

      {:ok, _, response} = OpenAI.generate(:messages, messages, config)

      assert response ==
               "There are seven continents: Africa, Antarctica, Asia, Australia/Oceania, Europe, North America, and South America."
    end
  end

  test "chat completion timeout", %{config: config} do
    use_cassette "open_ai/chat_timeout" do
      {:error, %HTTPoison.Error{reason: reason, id: nil}} =
        OpenAI.generate(:user, "What are continents?", config)

      assert reason == "timeout"
    end
  end

  test "embedding", %{config: config} do
    use_cassette "open_ai/embedding" do
      {:ok, embeddings} = OpenAI.embedding(@prompt, config)

      assert length(embeddings) == 1536
      assert List.first(embeddings) == -0.0016817485
    end
  end

  test "empty embeddings", %{config: config} do
    use_cassette "open_ai/embedding_empty" do
      {:ok, embeddings} = OpenAI.embedding(@prompt, config)

      assert length(embeddings) == 0
      assert List.first(embeddings) == nil
    end
  end

  test "invalid embeddings payload", %{config: config} do
    use_cassette "open_ai/embedding_wrong_payload" do
      {:error, "invalid json"} = OpenAI.embedding(@prompt, config)
    end
  end

  test "invalid embedding's API key", %{config: config} do
    use_cassette "open_ai/embedding_invalid_key" do
      {:error, "http error 401"} = OpenAI.embedding(@prompt, config)
    end
  end

  test "timeout", %{config: config} do
    use_cassette "open_ai/embedding_timeout" do
      assert {:error, "timeout"} == OpenAI.embedding(@prompt, config)
    end
  end
end
