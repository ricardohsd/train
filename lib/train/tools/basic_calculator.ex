defmodule Train.Tools.BasicCalculator do
  @moduledoc """
  Basic implementation of a calculator tool.
  Used for testing purposes.
  """

  @behaviour Train.ToolSpec

  @impl true
  def name() do
    "Calculator"
  end

  @impl true
  def description() do
    "Calculate matematical questions, like age of a person, distance, etc"
  end
  @impl true
  @spec query(String.t()) :: {:error, any} | {:ok, number}
  def query(text) do
    Abacus.eval(String.replace(text, ",", ""))
  end
end
