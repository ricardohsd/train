defmodule Train.Tools.BasicCalculator do
  @moduledoc """
  Basic implementation of a calculator tool.
  Used for testing purposes.
  """

  alias Train.LlmChain

  @behaviour Train.Tools.Spec

  @name "calculator"

  @impl true
  def name() do
    @name
  end

  @impl true
  def to_func() do
    %{
      name: @name,
      description: "Calculate matematical questions, like age of a person, distance, etc",
      parameters: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "Mathematical equation as a string like: 10 + 2"
          }
        },
        required: ["query"]
      }
    }
  end

  @impl true
  @spec query(String.t(), LlmChain.t()) :: {:error, any} | {:ok, number}
  def query(text, _) do
    text
    |> String.replace(",", "")
    |> String.replace("**", "^")
    |> Abacus.eval()
  end
end
