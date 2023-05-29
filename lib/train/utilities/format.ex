defmodule Train.Utilities.Format do
  @doc """
  Format the given string by replacing the {key} with the given value.
  """
  def format(text, key, value) do
    String.replace(text, "{#{key}}", value)
  end
end
