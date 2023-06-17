defmodule Train.Clients.StreamReducer do
  def reduce(stream) do
    stream
    |> Enum.to_list()
    |> Enum.reduce(%{}, fn message, acc ->
      merge(acc, message)
    end)
  end

  # Stream chunks

  defp merge(
         map,
         %{
           "choices" => [
             %{
               "delta" => %{
                 "content" => nil,
                 "function_call" => %{"arguments" => _, "name" => _} = function_call,
                 "role" => role
               },
               "finish_reason" => finish_reason,
               "index" => index
             }
             | _
           ],
           "created" => created,
           "id" => id,
           "model" => model,
           "object" => object
         }
       )
       when map_size(map) == 0 do
    %{
      "choices" => [
        %{
          "finish_reason" => finish_reason,
          "index" => index,
          "message" => %{
            "content" => nil,
            "function_call" => function_call,
            "role" => role
          }
        }
      ],
      "created" => created,
      "id" => id,
      "model" => model,
      "object" => object
    }
  end

  defp merge(
         %{
           "choices" => [
             %{"message" => %{"function_call" => function_call} = message} | _
           ]
         },
         %{
           "choices" => [
             %{
               "delta" => %{
                 "function_call" => %{"arguments" => args}
               },
               "finish_reason" => finish_reason,
               "index" => index
             }
             | _
           ],
           "created" => created,
           "id" => id,
           "model" => model,
           "object" => object
         }
       ) do
    fcall = Map.put(function_call, "arguments", function_call["arguments"] <> args)

    %{
      "choices" => [
        %{
          "finish_reason" => finish_reason,
          "index" => index,
          "message" => Map.put(message, "function_call", fcall)
        }
      ],
      "created" => created,
      "id" => id,
      "model" => model,
      "object" => object
    }
  end

  defp merge(
         %{
           "choices" => [
             %{"message" => message}
             | _
           ]
         },
         %{
           "choices" => [
             %{"delta" => _, "finish_reason" => "function_call", "index" => index} | _
           ],
           "created" => created,
           "id" => id,
           "model" => model,
           "object" => object
         }
       ) do
    %{
      "choices" => [
        %{
          "finish_reason" => "function_call",
          "index" => index,
          "message" => message
        }
      ],
      "created" => created,
      "id" => id,
      "model" => model,
      "object" => object
    }
  end

  # Content chunks

  defp merge(
         map,
         %{
           "choices" => [
             %{"delta" => delta, "finish_reason" => finish_reason, "index" => index} | _
           ],
           "created" => created,
           "id" => id,
           "model" => model,
           "object" => object
         }
       )
       when map_size(map) == 0 do
    %{
      "choices" => [
        %{
          "finish_reason" => finish_reason,
          "index" => index,
          "message" => delta
        }
      ],
      "created" => created,
      "id" => id,
      "model" => model,
      "object" => object
    }
  end

  defp merge(
         %{"choices" => [%{"message" => %{"content" => content} = message} | _]},
         %{
           "choices" => [
             %{
               "delta" => %{"content" => chunk},
               "finish_reason" => finish_reason,
               "index" => index
             }
             | _
           ],
           "created" => created,
           "id" => id,
           "model" => model,
           "object" => object
         }
       ) do
    %{
      "choices" => [
        %{
          "finish_reason" => finish_reason,
          "index" => index,
          "message" => Map.put(message, "content", content <> chunk)
        }
      ],
      "created" => created,
      "id" => id,
      "model" => model,
      "object" => object
    }
  end

  defp merge(
         %{"choices" => [%{"message" => message} | _]},
         %{
           "choices" => [
             %{
               "delta" => %{},
               "finish_reason" => "stop",
               "index" => index
             }
             | _
           ],
           "created" => created,
           "id" => id,
           "model" => model,
           "object" => object
         }
       ) do
    %{
      "choices" => [
        %{
          "finish_reason" => "stop",
          "index" => index,
          "message" => message
        }
      ],
      "created" => created,
      "id" => id,
      "model" => model,
      "object" => object
    }
  end
end
