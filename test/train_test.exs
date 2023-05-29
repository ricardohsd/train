defmodule TrainTest do
  use ExUnit.Case
  doctest Train

  test "greets the world" do
    assert Train.hello() == :world
  end
end
