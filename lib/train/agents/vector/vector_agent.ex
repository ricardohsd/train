defmodule Train.Agents.VectorAgent do
  @moduledoc """
  The VectorAgent knows how to fetch and pass context from a Vector DB to the LLM.
  It is good for generating a response based on a document stored in the db.
  """
  import Train.LevelLogger

  alias Train.LlmChain
  alias Train.OpenAI
  alias Train.Clients.Pinecone
  alias Train.Agents.VectorPromptSpec
  alias Train.Utilities.VectorDocument
  alias Train.Tiktoken

  @spec call(LlmChain.t(), String.t(), VectorPromptSpec.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def call(
        %LlmChain{openai_config: openai_config, pinecone_config: pinecone_config} = chain,
        question,
        prompt
      ) do
    log("Started VectorAgent", chain)

    with :ok <- validate!(chain),
         {:ok, %{"database" => %{"dimension" => dimension}}} <-
           Pinecone.index(pinecone_config.index),
         {:ok, embeddings} <- OpenAI.embedding(question, openai_config),
         {:ok, vector} <- Pinecone.query(Enum.take(embeddings, dimension), pinecone_config),
         document <- VectorDocument.parse(vector),
         main_prompt <- prompt.with(question, document.text, document.metadata),
         {:ok, messages, result} <- OpenAI.chat(main_prompt, openai_config) do
      count_tokens(main_prompt, result, chain)
      {:ok, messages, result}
    else
      {:error, :timeout} -> {:error, "timeout"}
      {:error, err} -> {:error, err}
    end
  end

  defp count_tokens(prompt, result, chain) do
    prompt_tokens = Tiktoken.count_tokens(prompt)
    result_tokens = Tiktoken.count_tokens(result)

    log(
      "[VectorAgent Tokens][Prompt]#{prompt_tokens},[Result]#{result_tokens}",
      chain
    )

    :ok
  end

  defp validate!(%LlmChain{
         openai_config: openai_config,
         pinecone_config: pinecone_config
       }) do
    cond do
      openai_config == nil ->
        {:error, "OpenAI config can't be null"}

      pinecone_config == nil ->
        {:error, "Pinecone config can't be null"}

      true ->
        :ok
    end
  end
end
