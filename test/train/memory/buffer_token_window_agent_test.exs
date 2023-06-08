defmodule Train.Memory.BufferTokenWindowAgentTest do
  use ExUnit.Case, async: true

  alias Train.Memory.BufferTokenWindowAgent

  test "dedups messages" do
    {:ok, pid} = BufferTokenWindowAgent.start_link()

    BufferTokenWindowAgent.put(pid, %{role: "system", content: "the system prompt"})
    BufferTokenWindowAgent.put(pid, %{content: "In which city was she born?", role: "user"})
    BufferTokenWindowAgent.put(pid, %{content: "In which city was she born?", role: "user"})
    BufferTokenWindowAgent.put(pid, %{content: "Hamburg, Germany", role: "assistant"})
    BufferTokenWindowAgent.put(pid, %{content: "Hamburg, Germany", role: "assistant"})

    assert [
             "Human: In which city was she born?",
             "AI: Hamburg, Germany"
           ] ==
             BufferTokenWindowAgent.get(pid)
  end

  test "keeps a window of messages not reaching max of 300 tokens" do
    {:ok, pid} = BufferTokenWindowAgent.start_link(300)

    BufferTokenWindowAgent.put(pid, %{role: "user", content: "Good morning AI!"})

    BufferTokenWindowAgent.put_many(pid, [
      %{
        role: "assistant",
        content: "Good morning! It's a beautiful day today, isn't it? How can I help you?"
      },
      %{
        role: "user",
        content:
          "My interest here is to explore the potential of integrating Large Language Models with external knowledge"
      }
    ])

    BufferTokenWindowAgent.put_many(pid, [
      %{
        role: "assistant",
        content:
          "Interesting! Large Language Models are a type of artificial intelligence that can process natural language and generate text. They can be used to generate text from a given context, or to answer questions about a given context. Integrating them with external knowledge can help them to better understand the context and generate more accurate results. Do you have any specific questions about this integration?"
      },
      %{
        role: "user",
        content: "I just want to analyze the different possibilities. What can you think of?"
      },
      %{
        role: "assistant",
        content:
          "There are many possibilities for integrating Large Language Models with external knowledge. For example, you could use external knowledge to provide additional context to the model, or to provide additional training data. You could also use external knowledge to help the model better understand the context of a given text, or to help it generate more accurate results."
      },
      %{
        role: "user",
        content: "Which data source types could be used to give context to the model?"
      },
      %{
        role: "assistant",
        content:
          "Data sources that could be used to give context to the model include text corpora, structured databases, and ontologies. Text corpora provide a large amount of text data that can be used to train the model and provide additional context. Structured databases provide structured data that can be used to provide additional context to the model. Ontologies provide a structured representation of knowledge that can be used to provide additional context to the model."
      }
    ])

    assert [
             "Human: My interest here is to explore the potential of integrating Large Language Models with external knowledge",
             "AI: Interesting! Large Language Models are a type of artificial intelligence that can process natural language and generate text. They can be used to generate text from a given context, or to answer questions about a given context. Integrating them with external knowledge can help them to better understand the context and generate more accurate results. Do you have any specific questions about this integration?",
             "Human: I just want to analyze the different possibilities. What can you think of?",
             "AI: There are many possibilities for integrating Large Language Models with external knowledge. For example, you could use external knowledge to provide additional context to the model, or to provide additional training data. You could also use external knowledge to help the model better understand the context of a given text, or to help it generate more accurate results.",
             "Human: Which data source types could be used to give context to the model?",
             "AI: Data sources that could be used to give context to the model include text corpora, structured databases, and ontologies. Text corpora provide a large amount of text data that can be used to train the model and provide additional context. Structured databases provide structured data that can be used to provide additional context to the model. Ontologies provide a structured representation of knowledge that can be used to provide additional context to the model."
           ] == BufferTokenWindowAgent.get(pid)
  end

  test "returns only messages that fit the max tokens" do
    {:ok, pid} = BufferTokenWindowAgent.start_link(100)

    BufferTokenWindowAgent.put(pid, %{role: "user", content: "Good morning AI!"})

    BufferTokenWindowAgent.put_many(pid, [
      %{
        role: "user",
        content: "Which data source types could be used to give context to the model?"
      },
      %{
        role: "assistant",
        content:
          "Data sources that could be used to give context to the model include text corpora, structured databases, and ontologies. Text corpora provide a large amount of text data that can be used to train the model and provide additional context. Structured databases provide structured data that can be used to provide additional context to the model. Ontologies provide a structured representation of knowledge that can be used to provide additional context to the model."
      }
    ])

    assert [
             "AI: Data sources that could be used to give context to the model include text corpora, structured databases, and ontologies. Text corpora provide a large amount of text data that can be used to train the model and provide additional context. Structured databases provide structured data that can be used to provide additional context to the model. Ontologies provide a structured representation of knowledge that can be used to provide additional context to the model."
           ] == BufferTokenWindowAgent.get(pid)
  end

  test "returns nothing if no messages fit max_tokens" do
    {:ok, pid} = BufferTokenWindowAgent.start_link(10)

    BufferTokenWindowAgent.put(pid, %{role: "user", content: "Good morning AI!"})

    BufferTokenWindowAgent.put_many(pid, [
      %{
        role: "user",
        content: "Which data source types could be used to give context to the model?"
      },
      %{
        role: "assistant",
        content:
          "Data sources that could be used to give context to the model include text corpora, structured databases, and ontologies. Text corpora provide a large amount of text data that can be used to train the model and provide additional context. Structured databases provide structured data that can be used to provide additional context to the model. Ontologies provide a structured representation of knowledge that can be used to provide additional context to the model."
      }
    ])

    assert [] == BufferTokenWindowAgent.get(pid)
  end

  test "clears the agent state" do
    {:ok, pid} = BufferTokenWindowAgent.start_link()

    BufferTokenWindowAgent.put_many(pid, [
      %{role: "user", content: "abc"}
    ])

    BufferTokenWindowAgent.clear(pid)

    assert [] == BufferTokenWindowAgent.get(pid)
  end
end
