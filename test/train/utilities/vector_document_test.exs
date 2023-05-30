defmodule Train.Utilities.VectorDocumentTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Clients.OpenAI
  alias Train.Clients.OpenAIConfig
  alias Train.Clients.Pinecone
  alias Train.Utilities.VectorDocument

  @prompt "o que é o divorcio?"

  setup_all do
    HTTPoison.start()
    %{config: OpenAIConfig.new(%{model: :"gpt-3.5-turbo"})}
  end

  describe "aggregate records into a single document" do
    test "when given multiple records", %{config: config} do
      {:ok, embeddings} =
        use_cassette "open_ai/divorce" do
          OpenAI.embedding(@prompt, config)
        end

      resp =
        use_cassette "pinecone/embedding" do
          Pinecone.query(embeddings, %Pinecone.Config{namespace: nil, topK: 2})
        end

      subject = VectorDocument.parse(resp)

      expected = %VectorDocument{
        text:
          "Art. 1.632. A separação judicial, o divórcio e a dissolução da união estável não alteram as relações entre pais e filhos senão quanto ao direito, que aos primeiros cabe, de terem em sua companhia os segundos.\n• Vide Lei n. 6.515, de 26-12-1977, art. 27 (Lei do Divórcio).Art. 1.576. A separação judicial põe termo aos deveres de coabitação e fidelidade recíproca e ao regime de bens.\n•• Vide Emenda Constitucional n. 66, de 13-7-2010, que instituiu o divórcio direto. Parágrafo único. O procedimento judicial da separação caberá somente aos cônjuges, e, no caso de incapacidade, serão representados pelo curador, pelo ascendente ou pelo irmão.",
        metadata:
          "{\"header\":\"TÍTULO I Do Direito Pessoal SUBTÍTULO I DO CASAMENTO\",\"chapter\":\"CAPÍTULO V DO PODER FAMILIAR\",\"book\":null}{\"header\":\"TÍTULO I Do Direito Pessoal SUBTÍTULO I DO CASAMENTO\",\"chapter\":\"CAPÍTULO X DA DISSOLUÇÃO DA SOCIEDADE E DO VÍNCULO CONJUGAL\",\"book\":null}"
      }

      assert subject == expected
    end

    test "when given empty pinecone response" do
      use_cassette "pinecone/nil" do
        assert Pinecone.query(nil, %Pinecone.Config{namespace: nil})
               |> VectorDocument.parse() == nil
      end
    end
  end
end
