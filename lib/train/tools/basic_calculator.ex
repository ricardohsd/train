defmodule Train.Tools.BasicCalculator do
  @moduledoc """
  Basic implementation of a calculator tool.
  Used for testing purposes.
  """

  @behaviour Train.Tools.Spec

  @impl true
  @spec query(String.t()) :: {:error, any} | {:ok, number}
  def query(text) do
    text
    |> String.replace(",", "")
    |> String.replace("**", "^")
    |> Abacus.eval()
  end
end
