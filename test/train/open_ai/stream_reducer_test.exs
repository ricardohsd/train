defmodule Train.OpenAI.StreamReducerTest do
  use ExUnit.Case, async: true

  alias Train.OpenAI.StreamReducer

  test "reduce content response" do
    stream = [
      %{
        "choices" => [
          %{
            "delta" => %{"content" => "", "role" => "assistant"},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => "Ol"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => "af"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => " Sch"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => "ol"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => "z"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => " is"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"content" => " currently"},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => " "}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => "65"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => " years"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => " old"}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{"content" => "."}, "finish_reason" => nil, "index" => 0}
        ],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [%{"delta" => %{}, "finish_reason" => "stop", "index" => 0}],
        "created" => 1_687_011_337,
        "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      }
    ]

    assert StreamReducer.reduce(stream) == %{
             "choices" => [
               %{
                 "finish_reason" => "stop",
                 "index" => 0,
                 "message" => %{
                   "content" => "Olaf Scholz is currently 65 years old.",
                   "role" => "assistant"
                 }
               }
             ],
             "created" => 1_687_011_337,
             "id" => "chatcmpl-7SR0DzNdCVL2R7ETe0xiJq8HVbW2N",
             "model" => "gpt-3.5-turbo-16k-0613",
             "object" => "chat.completion.chunk"
           }
  end

  test "reduce function calling response" do
    stream = [
      %{
        "choices" => [
          %{
            "delta" => %{
              "content" => nil,
              "function_call" => %{"arguments" => "", "name" => "calculator"},
              "role" => "assistant"
            },
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "{\n"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => " "}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => " \""}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "query"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "\":"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => " \""}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "202"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "3"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => " -"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => " "}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "195"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "8"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "\"\n"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{
            "delta" => %{"function_call" => %{"arguments" => "}"}},
            "finish_reason" => nil,
            "index" => 0
          }
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      },
      %{
        "choices" => [
          %{"delta" => %{}, "finish_reason" => "function_call", "index" => 0}
        ],
        "created" => 1_687_010_190,
        "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
        "model" => "gpt-3.5-turbo-16k-0613",
        "object" => "chat.completion.chunk"
      }
    ]

    assert StreamReducer.reduce(stream) ==
             %{
               "choices" => [
                 %{
                   "finish_reason" => "function_call",
                   "index" => 0,
                   "message" => %{
                     "content" => nil,
                     "function_call" => %{
                       "arguments" => "{\n  \"query\": \"2023 - 1958\"\n}",
                       "name" => "calculator"
                     },
                     "role" => "assistant"
                   }
                 }
               ],
               "created" => 1_687_010_190,
               "id" => "chatcmpl-7SQhid2Fgj56otQrV1p1g1llroxHE",
               "model" => "gpt-3.5-turbo-16k-0613",
               "object" => "chat.completion.chunk"
             }
  end
end
