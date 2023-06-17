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
tools = [
  %{
    name: "Calculator",
    description: "Calculate matematical questions, like age of a person, distance, etc",
    func: Train.Tools.BasicCalculator
  },
  %{
    name: "Google search",
    description:
      "Useful for when you need to answer questions about current events. You should ask targeted questions",
    func: Train.Tools.SerpApi
  }
]
chain = Train.LlmChain.new(%{memory: {memory_pid, Train.Memory.BufferAgent}, tools: tools})

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

### Vector ingestion
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

### Zero Shot React Agent
Based on Langchain's `chat-zero-shot-react-description`. Doesn't use memory, for that check the `Train.Chains.ConversationChain` agent.
```elixir

tools = [
  %{
    name: "Calculator",
    description: "Calculate matematical questions, like age of a person, distance, etc",
    func: Train.Tools.BasicCalculator
  },
  %{
    name: "Google search",
    description:
      "Useful for when you need to answer questions about current events. You should ask targeted questions",
    func: Train.Tools.SerpApi
  }
]
chain =
      Train.LlmChain.new(%{
        tools: tools,
        openai_config:
          Train.OpenAI.Config.new(%{model: :"gpt-3.5-turbo", temperature: 0.0})
      })
chain |> Train.Agents.ZeroShotReact.Chat.call("Who is Leo DiCaprio's girlfriend? What is her current age raised to the 0.43 power?")
# 3.991298452658078
```

### Creating a tool from an agent
Agents can be combined in a chain as specialized tools. The example below creates an agent to query a vector database using the `VectorAgent`.
```elixir
defmodule Search do
  @behaviour Train.Tools.Spec

  def query(text, chain) do
    {:ok, _, response} =
      Train.Agents.VectorAgent.call(
        chain,
        text,
        Train.Agents.VectorPrompt
      )

    {:ok, response}
  end
end
```

## Function calling
Instead of having prompts that inform the AI how to think and ask for functions to be called we can use [OpenAI's function calling](https://openai.com/blog/function-calling-and-other-api-updates).

### Conversational agent
```elixir
{:ok, memory_pid} = Train.Memory.BufferTokenWindowAgent.start_link()
functions = [Train.Tools.SerpApi, Train.Tools.BasicCalculator]

chain =
  Train.LlmChain.new(%{
    memory: {memory_pid, Train.Memory.BufferTokenWindowAgent},
    functions: functions,
    openai_config:
      Train.OpenAI.Config.new(%{model: :"gpt-3.5-turbo-16k", temperature: 0.0})
  })
{:ok, response} =
  chain
  |> Train.Functions.Conversational.ChatAgent.run( "Who is currently the chanceller of Germany in 2023?")
# {:ok,
# "The current chancellor of Germany in 2023 is Olaf Scholz. He has been serving as the chancellor since December 8, 2021. Olaf Scholz is a member of the Social Democratic Party and previously served as the Vice Chancellor in the fourth Merkel cabinet and as the Federal Minister of Finance from 2018 to 2021."}
```

## Goals
- [] Implement other types of memory buffer like window and summary explained on this [post](https://www.pinecone.io/learn/langchain-conversational-memory/).
- [] Create other tools like: Wikipedia, Wolfram, PostgreSQL/MySQL.
- [] Implement a buffer memory backed by a SQL storage.