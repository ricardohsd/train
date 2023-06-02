defmodule Train.Memory.BufferWindowAgentTest do
  use ExUnit.Case, async: true

  alias Train.Memory.BufferWindowAgent

  test "dedups messages" do
    {:ok, pid} = BufferWindowAgent.start_link([%{role: "user", content: "abc"}], 2)

    BufferWindowAgent.put(pid, %{role: "user", content: "abc"})
    BufferWindowAgent.put(pid, %{role: "user", content: "xyz"})
    BufferWindowAgent.put(pid, %{role: "user", content: "abc"})

    assert ["Human: xyz", "Human: abc"] == BufferWindowAgent.get(pid)
  end

  test "keeps a window of 2 messages" do
    {:ok, pid} =
      BufferWindowAgent.start_link(
        [%{role: "user", content: "My goal is to relax at the beach."}],
        2
      )

    BufferWindowAgent.put_many(pid, [
      %{role: "assistant", content: "Ok. Your goal is to relax at the beach."},
      %{role: "user", content: "What is my goal?"},
      %{role: "assistant", content: "As you said before. Your goal is to relax at the beach."}
    ])

    assert [
             "Human: What is my goal?",
             "AI: As you said before. Your goal is to relax at the beach."
           ] == BufferWindowAgent.get(pid)
  end

  test "filters out system messages" do
    {:ok, pid} = BufferWindowAgent.start_link([%{role: "user", content: "abc"}])

    BufferWindowAgent.put_many(pid, [
      %{role: "user", content: "123"},
      %{role: "user", content: "cde"},
      %{role: "user", content: "abc"},
      %{role: "system", content: "xyz"},
      %{role: "assistant", content: "xyz"},
      %{role: "system", content: "123"}
    ])

    assert ["Human: abc", "AI: xyz"] == BufferWindowAgent.get(pid)
  end

  test "clears the agent state" do
    {:ok, pid} = BufferWindowAgent.start_link([%{role: "user", content: "abc"}])

    BufferWindowAgent.clear(pid)

    assert [] == BufferWindowAgent.get(pid)
  end
end
