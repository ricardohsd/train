# Train

`Train` is an attempt of providing a set of tools for building applications with LLM. This project is heavily inspired on [LangChain](https://github.com/hwchase17/langchain).

This has been extracted from a personal project and it is still on its first steps.

## Installation

```elixir
def deps do
  [
    {:train, "~> 0.0.1-dev"}
  ]
end
```

## Example

```elixir
{:ok, memory_pid} = Train.Memory.BufferAgent.start_link()
tools = [Train.Tools.Calculator, Train.Tools.SerpApi]
chain = Train.LlmChain.new(%{memory_pid: memory_pid, tools: tools})

{:ok, messages, response} = chain |> Train.Chains.ConversationChain.run("Who is Angela Merkel?")
# Angela Dorothea Merkel is a German former politician and scientist who served as Chancellor of Germany from November 2005 to December 2021. A member of the Christian Democratic Union, she previously served as Leader of the Opposition from 2002 to 2005 and as Leader of the Christian Democratic Union from 2000 to 2018.

{:ok, messages, response} = chain |> Train.Chains.ConversationChain.run("Where was she born?")
# Angela Merkel was born in Hamburg, Germany.
```

## Goals
- [] Implement other types of memory buffer like window and summary explained on this [post](https://www.pinecone.io/learn/langchain-conversational-memory/).
- [] Create other tools like: Wikipedia, Wolfram, PostgreSQL/MySQL.
- [] Implement a Zero Shot React agent.
- [] Implement a buffer memory backed by a SQL storage.