defmodule Train.Tools.BasicCalculator do
  @moduledoc """
  Basic implementation of a calculator tool.
  Used for testing purposes.
  """

  alias Train.LlmChain

  @behaviour Train.Tools.Spec

  @impl true
  @spec query(String.t(), LlmChain.t()) :: {:error, any} | {:ok, number}
  def query(text, _) do
    text
    |> String.replace(",", "")
    |> String.replace("**", "^")
    |> Abacus.eval()
  end
end
