defmodule Train.Memory.BufferAgentTest do
  use ExUnit.Case, async: true

  alias Train.Memory.BufferAgent

  test "dedups messages" do
    {:ok, pid} = BufferAgent.start_link([%{role: "user", content: "abc"}])

    BufferAgent.put(pid, %{role: "user", content: "abc"})
    BufferAgent.put(pid, %{role: "user", content: "xyz"})
    BufferAgent.put(pid, %{role: "user", content: "abc"})

    assert ["Human: abc", "Human: xyz", "Human: abc"] == BufferAgent.get(pid)
  end

  test "puts many messages" do
    {:ok, pid} = BufferAgent.start_link([%{role: "user", content: "abc"}])

    BufferAgent.put_many(pid, [
      %{role: "user", content: "abc"},
      %{role: "user", content: "xyz"},
      %{role: "user", content: "abc"}
    ])

    assert ["Human: abc", "Human: xyz", "Human: abc"] == BufferAgent.get(pid)
  end

  test "filters out system messages" do
    {:ok, pid} = BufferAgent.start_link([%{role: "user", content: "abc"}])

    BufferAgent.put_many(pid, [
      %{role: "user", content: "abc"},
      %{role: "assistant", content: "xyz"},
      %{role: "system", content: "123"}
    ])

    assert ["Human: abc", "AI: xyz"] == BufferAgent.get(pid)
  end

  test "clears the agent state" do
    {:ok, pid} = BufferAgent.start_link([%{role: "user", content: "abc"}])

    BufferAgent.clear(pid)

    assert [] == BufferAgent.get(pid)
  end
end
