defmodule Train.Memory.BufferAgentTest do
  use ExUnit.Case, async: true

  alias Train.Memory.BufferAgent

  test "dedups messages" do
    {:ok, pid} = BufferAgent.start_link()

    BufferAgent.put(pid, %{role: "system", content: "the system prompt"})
    BufferAgent.put(pid, %{content: "In which city was she born?", role: "user"})
    BufferAgent.put(pid, %{content: "In which city was she born?", role: "user"})
    BufferAgent.put(pid, %{content: "Hamburg, Germany", role: "assistant"})
    BufferAgent.put(pid, %{content: "Hamburg, Germany", role: "assistant"})

    assert [
             %{role: "user", content: "In which city was she born?"},
             %{role: "assistant", content: "Hamburg, Germany"}
           ] == BufferAgent.get(pid)
  end

  test "puts many messages" do
    {:ok, pid} = BufferAgent.start_link()

    BufferAgent.put_many(pid, [
      %{role: "user", content: "abc"},
      %{role: "user", content: "abc"},
      %{role: "user", content: "xyz"},
      %{role: "user", content: "abc"}
    ])

    assert [
             %{role: "user", content: "abc"},
             %{role: "user", content: "xyz"},
             %{role: "user", content: "abc"}
           ] == BufferAgent.get(pid)
  end

  test "filters out system messages" do
    {:ok, pid} = BufferAgent.start_link()

    BufferAgent.put_many(pid, [
      %{role: "user", content: "abc"},
      %{role: "user", content: "abc"},
      %{role: "assistant", content: "xyz"},
      %{role: "system", content: "123"}
    ])

    assert [%{role: "user", content: "abc"}, %{role: "assistant", content: "xyz"}] ==
             BufferAgent.get(pid)
  end

  test "clears the agent state" do
    {:ok, pid} = BufferAgent.start_link()

    BufferAgent.put(pid, %{role: "user", content: "abc"})

    BufferAgent.clear(pid)

    assert [] == BufferAgent.get(pid)
  end
end
