defmodule LsProxy.Protocol.MessageTest do
  use ExUnit.Case
  alias LsProxy.Protocol
  alias LsProxy.Protocol.Message
  alias LsProxyTest.Protocol.ParserHarness

  describe "Protocol.Parse behaviour" do
    test "parses a complete message" do
      text = """
      Content-Length: 131

      {"jsonrpc":"2.0","method":"window/logMessage","params":{"message":"Elixir version: \\"1.6.6 (compiled with OTP 20)\\"","type":4}}
      """

      expected_content = %{
        "jsonrpc" => "2.0",
        "method" => "window/logMessage",
        "params" => %{
          "message" => "Elixir version: \"1.6.6 (compiled with OTP 20)\"",
          "type" => 4
        }
      }

      assert ParserHarness.read_message(Message, text) ==
               {:ok,
                %Message{
                  header: %Protocol.Header{content_length: 131},
                  content: expected_content
                }}
    end

    test "parses a complete window/logMessage message" do
      text = """
      Content-Length: 99
      Content-Type: utf-8

      {"jsonrpc":"2.0","method":"window/logMessage","params":{"message":"Started ElixirLS","type":4}}
      """

      expected_content = %{
        "jsonrpc" => "2.0",
        "method" => "window/logMessage",
        "params" => %{"message" => "Started ElixirLS", "type" => 4}
      }

      assert ParserHarness.read_message(Message, text) ==
               {:ok,
                %Message{header: %Protocol.Header{content_length: 99}, content: expected_content}}
    end
  end
end