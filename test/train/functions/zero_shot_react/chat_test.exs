defmodule Train.Functions.ZeroShotReact.ChatTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Functions.ZeroShotReact.Chat

  setup do
    HTTPoison.start()

    tools = [Train.Tools.BasicCalculator, Train.Tools.SerpApi]

    chain =
      Train.LlmChain.new(%{
        functions: tools,
        openai_config: Train.OpenAI.Config.new(%{model: :"gpt-3.5-turbo-16k", temperature: 0.0})
      })

    %{chain: chain}
  end

  test "fetch age and calculate age raised to power", %{
    chain: chain
  } do
    use_cassette "functions/zero_shot_react", match_requests_on: [:request_body, :query] do
      prompt =
        "Who is Leo DiCaprio's girlfriend in 2023? What is her current age raised to the 0.43 power?"

      {:ok, _, response} = chain |> Chat.call(prompt)

      expected =
        "Leo DiCaprio's girlfriend in 2023 is Irina Shayk. Her current age raised to the power of 0.43 is approximately 4.25."

      assert expected == response
    end
  end

  test "fetch multiple times on Google", %{
    chain: chain
  } do
    use_cassette "functions/merkel", match_requests_on: [:request_body, :query] do
      prompt = "Who is Angela Merkel? Where was she born?"

      {:ok, _, response} = chain |> Chat.call(prompt)

      expected =
        "Angela Merkel is a German former politician and scientist who served as the chancellor of Germany from 2005 to 2021. She was born in Hamburg, Germany."

      assert expected == response
    end
  end
end
