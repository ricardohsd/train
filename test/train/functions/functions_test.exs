defmodule Train.FunctionsTest do
  use ExUnit.Case, async: true

  alias Train.Functions
  alias Train.Tools.SerpApi, as: Tool

  describe "format_function_call" do
    setup do
      %{tool: Tool}
    end

    test "adds the tool name when name not present", %{tool: tool} do
      assert  %{"arguments" => "foo", "name" => "google_search"} == Functions.format_function_call(tool, %{"arguments" => "foo"})
    end

    test "doesn't add the tool name when name is present", %{tool: tool} do
      assert  %{"arguments" => "foo", "name" => "calculator"} == Functions.format_function_call(tool, %{"arguments" => "foo", "name" => "calculator"})
    end
  end

  describe "get_tool" do
    setup do
      %{tools: [Tool]}
    end

    test "returns first tool when name is nil", %{tools: tools} do
      assert Tool == Functions.get_tool(tools, nil)
    end

    test "get tool by the name", %{tools: tools} do
      assert Tool == Functions.get_tool(tools, "google_search")
    end

    test "return nil when name doesn't match a tool", %{tools: tools} do
      assert nil == Functions.get_tool(tools, "sql")
    end
  end
end
