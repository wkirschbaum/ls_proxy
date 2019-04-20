defmodule LsppWebWeb.MessagesController do
  use LsppWebWeb, :controller

  def create(conn, %{"message" => message, "direction" => direction_str}) do
    case parse_direction(direction_str) do
      :incoming -> :ok = LsProxy.ProxyState.record_incoming(message)
      :outgoing -> :ok = LsProxy.ProxyState.record_outgoing(message)
    end

    conn
    |> json(%{ok: true})
  end

  def create(conn, _params) do
    conn
    |> json(%{error: "Missing message param"})
  end

  defp parse_direction("incoming"), do: :incoming
  defp parse_direction("outgoing"), do: :outgoing
end
