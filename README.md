# Train 🚂🚂🚂

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

## Examples

### Conversational agent
Designed to be used on conversational scenarios. It will use the given tools, and buffers the memory to remember previous conversations.
```elixir
{:ok, memory_pid} = Train.Memory.BufferAgent.start_link()
tools = [Train.Tools.BasicCalculator, Train.Tools.SerpApi]
chain = Train.LlmChain.new(%{memory_pid: memory_pid, tools: tools})

{:ok, response} = chain |> Train.Chains.ConversationChain.run("Who is Angela Merkel?")
# Angela Dorothea Merkel is a German former politician and scientist who served as Chancellor of Germany from November 2005 to December 2021. A member of the Christian Democratic Union, she previously served as Leader of the Opposition from 2002 to 2005 and as Leader of the Christian Democratic Union from 2000 to 2018.

{:ok, response} = chain |> Train.Chains.ConversationChain.run("Where was she born?")
# Angela Merkel was born in Hamburg, Germany.
```

### Vector ask agent
Allows asking questions to documents ingested on Pinecone.
Example: Given that cooking recipes were ingested on the `food` namespace, the following can be used to retrieve recipes.
```elixir
chain =
  Train.LlmChain.new(%{
    pinecone_config:
      Train.Clients.PineconeConfig.new(%{
        namespace: "food",
        topK: 5,
        index: "localtest",
        project: "1234567"
      })
  })
{:ok, history, response} =
  Train.Agents.VectorAgent.call(chain, "How to bake pão de queijo?", Train.Agents.VectorPrompt)
```

## Vector ingestion
Provides a way to ingest texts into the vector database (Pinecone) to be queried later.
The texts will be encoded in tokens using [ExTiktoken](https://github.com/ricardohsd/ex_tiktoken) and splitted in chunks.
```elixir
text = "Cascão da Silva Pereira Alves (born January 14, 1969) is an Brazilian musician. He is the founder of the rock band Casca Dura, for which he is the lead singer, guitarist, and principal songwriter. Prior to forming Casca Dura, he was the drummer of rock band Solitarios from 1990 to 1994."
chain =
  Train.LlmChain.new(%{
    pinecone_config:
      Train.Clients.PineconeConfig.new(%{
        namespace: "food",
        topK: 5,
        index: "localtest",
        project: "1234567"
      })
  })

Train.Agents.VectorIngestion.ingest(chain, text, %{about: "Langchain"}, 30)
{:ok, _history, response} =
  Train.Agents.VectorAgent.call(chain, "Who is Cascão Pereira?", Train.Agents.VectorPrompt)
# "Cascão Pereira, full name Cascão da Silva Pereira Alves, is a Brazilian musician born on January 14, 1969. He is the founder of the rock band Casca Dura, where he serves as the lead singer, guitarist, and principal songwriter. Before forming Casca Dura, he was the drummer for the rock band Solitarios from 1990 to 1994.\n\nReferences:\n- Context provided"
```

## Goals
- [] Implement other types of memory buffer like window and summary explained on this [post](https://www.pinecone.io/learn/langchain-conversational-memory/).
- [] Create other tools like: Wikipedia, Wolfram, PostgreSQL/MySQL.
- [] Implement a Zero Shot React agent.
- [] Implement a buffer memory backed by a SQL storage.