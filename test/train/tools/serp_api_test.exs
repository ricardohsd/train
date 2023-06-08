defmodule Train.Tools.SerpApiTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Tools.SerpApi

  setup_all do
    HTTPoison.start()

    chain = Train.LlmChain.new(%{})

    %{chain: chain}
  end

  test "direct answer", %{chain: chain} do
    use_cassette "serpapi/google_search" do
      {:ok, "Luiz Inácio Lula da Silva"} = SerpApi.query("who is the president of Brazil?", chain)
    end
  end

  test "answer with instructions", %{chain: chain} do
    use_cassette "serpapi/answer_instructions" do
      instructions =
        [
          "Instructions:",
          "Place your eggs in a single layer on the bottom of your pot and cover with cold water. ... ;",
          "Over high heat, bring your eggs to a rolling boil.;",
          "Remove from heat and let stand in water for 10-12 minutes for large eggs. ... ;",
          "Drain water and immediately run cold water over eggs until cooled."
        ]
        |> Enum.join(" ")

      assert SerpApi.query("How to boil eggs", chain) == {:ok, instructions}
    end
  end

  test "answer with snippet", %{chain: chain} do
    use_cassette "serpapi/banana" do
      {:ok, "contain fiber, potassium, folate, and antioxidants, such as vitamin C"} =
        SerpApi.query("What is banana (fruit) known for?", chain)
    end
  end

  test "serialize sports result", %{chain: chain} do
    use_cassette "serpapi/sports" do
      resp =
        Jason.encode!(%{
          "arena" => "Fiserv Forum",
          "date" => "today, 9:30 PM",
          "league" => "NBA",
          "teams" => [
            %{"name" => "Miami Heat", "team_stats" => %{"losses" => 1, "wins" => 3}},
            %{
              "name" => "Milwaukee Bucks",
              "team_stats" => %{"losses" => 3, "wins" => 1}
            }
          ]
        })

      assert SerpApi.query("Milwaukee Bucks", chain) == {:ok, resp}
    end
  end

  test "knowledge graph", %{chain: chain} do
    use_cassette "serpapi/knowledge_graph" do
      resp =
        "Apple Inc. is an American multinational technology company headquartered in Cupertino, California. Apple is the world's largest technology company by revenue, with US$394.3 billion in 2022 revenue. As of March 2023, Apple is the world's biggest company by market capitalization."

      assert SerpApi.query("Apple", chain) == {:ok, resp}
    end
  end

  test "organic result", %{chain: chain} do
    use_cassette "serpapi/organic_result" do
      resp =
        "Coffee is a beverage prepared from roasted coffee beans. Darkly colored, bitter, and slightly acidic, coffee has a stimulating effect on humans, primarily due to its caffeine content. It has the highest sales in the world market for hot drinks."

      assert SerpApi.query("Coffee", chain) == {:ok, resp}
    end
  end

  test "population", %{chain: chain} do
    use_cassette "serpapi/population" do
      resp = "83.2 million, 2021"

      assert SerpApi.query("population of germany", chain) == {:ok, resp}
    end
  end

  test "timeout", %{chain: chain} do
    use_cassette "serpapi/timeout" do
      assert SerpApi.query("population of germany", chain) == {:error, "timeout"}
    end
  end
end
