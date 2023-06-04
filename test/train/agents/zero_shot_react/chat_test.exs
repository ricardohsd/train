defmodule Train.Agents.ZeroShotReact.ChatTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Agents.ZeroShotReact.Chat

  setup do
    HTTPoison.start()

    tools = [
      %{
        name: "Calculator",
        description: "Calculate matematical questions, like age of a person, distance, etc",
        func: Train.Tools.BasicCalculator
      },
      %{
        name: "Google search",
        description:
          "useful for when you need to answer questions about current events. You should ask targeted questions",
        func: Train.Tools.SerpApi
      }
    ]

    chain =
      Train.LlmChain.new(%{
        tools: tools,
        openai_config:
          Train.Clients.OpenAIConfig.new(%{model: :"gpt-3.5-turbo", temperature: 0.0})
      })

    %{chain: chain}
  end

  test "fetch age and calculate age raised to power", %{
    chain: chain
  } do
    use_cassette "agents/zero_shot_react", match_requests_on: [:request_body, :query] do
      prompt =
        "Who is Leo DiCaprio's girlfriend? What is her current age raised to the 0.43 power?"

      {:ok, _, response} = chain |> Chat.call(prompt)

      expected = "3.991298452658078"

      assert expected == response
    end
  end

  test "timeout", %{
    chain: chain
  } do
    use_cassette "agents/zero_shot_react_timeout" do
      prompt =
        "Who is Leo DiCaprio's girlfriend? What is her current age raised to the 0.43 power?"

      {:ok, _, response} = chain |> Chat.call(prompt)

      assert %HTTPoison.Error{reason: "timeout", id: nil} == response
    end
  end
end
