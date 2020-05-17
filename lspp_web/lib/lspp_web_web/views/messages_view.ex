defmodule LsppWeb.MessagesView do
  use LsppWebWeb, :view

  alias LsProxy.MessageRecord

  @doc """
  Render a detailed view of the message
  """
  def render_message(message_record, expanded, formatted)

  def render_message(%MessageRecord{} = message_record, true, formatted) do
    ~E"""
    <%= message_common(message_record, true, formatted) %>
    <div class="text-btn">
    <a phx-click="collapse:<%= message_record.id %>">collapse</a>
    </div>
    <%= render_full(message_record.message.content) %>
    """
  end

  def render_message(%MessageRecord{} = message_record, expanded, formatted) do
    ~E"""
    <%= message_common(message_record, expanded, formatted) %>
    <div class="text-btn">
      <a phx-click="expand:<%= message_record.id %>">show full</a>
      <%= if(has_formatting?(message_record.message.content)) do %>
        <%= if formatted do %>
          <a phx-click="collapse-formatted:<%= message_record.id %>">hide formatted message</a>
        <% else %>
          <a phx-click="expand-formatted:<%= message_record.id %>">show formatted message</a>
        <% end %>
      <% end %>
    </div>
    """
  end

  def message_common(%MessageRecord{} = message_record, expanded, formatted) do
    timestamp_format = if expanded, do: :full, else: :short
    method_name = MessageRecord.method(message_record)

    ~E"""
    <%= render_direction(message_record) %>
    <%= render_timestamp(message_record, timestamp_format) %>
    <div>
      <%= render_message_details(message_record, method_name, formatted: formatted) %>
    </div>
    """
  end

  def render_message_details(%MessageRecord{} = message_record, "textDocument/hover", opts)
      when is_list(opts) do
    content = message_record.message.content
    %{"id" => id} = content

    case content["params"] do
      %{
        "textDocument" => %{"uri" => uri_str},
        "position" => %{"line" => line, "character" => character}
      } ->
        # IO.inspect(message_record, label: "new message_record for hover")

        ~E"""
        textDocument/hover <code><%= uri_str %>:<%= line %></code>(char <%= character %>)
        <div class="code"><%= message_record.extra_info %></div>
        <%= render_id(id) %>
        """

      _ ->
        ~E"""
        textDocument/hover
        """
    end
  end

  def render_message_details(%MessageRecord{} = message_record, _method, opts)
      when is_list(opts) do
    formatted = Keyword.get(opts, :formatted)

    ~E"""
    <%= render_message_contents(message_record.message.content, formatted) %>
    """
  end

  def render_message_contents(%{"method" => "initialize"}, _formatted) do
    ~E"""
    initialize
    """
  end

  def render_message_contents(message, _formatted) when is_binary(message) do
    ~E"""
    <pre><code>
    <%= Phoenix.HTML.Format.text_to_html(message) %>
    </code></pre>
    """
  end

  def render_message_contents(%{"method" => "window/logMessage"} = message, true) do
    %{"params" => %{"message" => log_message}} = message

    ~E"""
    <div>Log: <%= Utils.truncate(log_message, 100) %></div>
    <pre>
      <%= log_message %>
    </pre>
    """
  end

  def render_message_contents(%{"method" => "window/logMessage"} = message, _formatted) do
    %{"params" => %{"message" => log_message}} = message

    ~E"""
    <div>Log: <%= Utils.truncate(log_message, 100) %></div>
    """
  end

  def render_message_contents(
        %{"method" => "textDocument/hover", "id" => id} = message_record,
        _formatted
      ) do
    case message_record["params"] do
      %{
        "textDocument" => %{"uri" => uri_str},
        "position" => %{"line" => line, "character" => character}
      } ->
        ~E"""
        textDocument/hover <code><%= uri_str %>:<%= line %></code>(char <%= character %>)
        <%= render_id(id) %>
        """

      _ ->
        ~E"""
        textDocument/hover
        """
    end
  end

  def render_message_contents(%{"method" => "$/cancelRequest", "params" => params}, _formatted) do
    %{"id" => id} = params

    ~E"""
    $/cancelRequest id: <%= id %>
    """
  end

  def render_message_contents(
        %{"method" => "textDocument/codeLens", "id" => id} = message_record,
        _formatted
      ) do
    uri_str = get_in(message_record, ["params", "textDocument", "uri"])

    ~E"""
    textDocument/codeLens: <code><%= uri_str %></code>
    <div>
      id: <b><%= id %></b>
    </div>
    """
  end

  def render_message_contents(%{"method" => "textDocument/didOpen"} = message_record, _formatted) do
    case message_record["params"]["textDocument"] do
      %{"text" => text, "uri" => uri_str} ->
        ~E"""
        textDocument/didOpen: <code><%= uri_str %></code>
        <div>
          <%= Utils.truncate(text, 80) %>
        </div>
        """

      _ ->
        "textDocument/didOpen"
    end
  end

  def render_message_contents(
        %{"method" => "textDocument/publishDiagnostics"} = message_record,
        _formatted
      ) do
    case message_record["params"]["uri"] do
      uri_str when not is_nil(uri_str) ->
        ~E"""
        textDocument/publishDiagnostics: <code><%= uri_str %></code>
        """

      _ ->
        "textDocument/publishDiagnostics"
    end
  end

  def render_message_contents(%{"id" => id, "result" => %{"contents" => []}}, _formatted) do
    ~E"""
    Result: empty
    <%= render_id(id) %>
    """
  end

  def render_message_contents(%{"id" => id, "result" => %{"contents" => contents}}, true)
      when is_binary(contents) do
    case Earmark.as_html(contents, %Earmark.Options{smartypants: false}) do
      {:ok, html, []} ->
        ~E"""
        Result: <%= Utils.truncate(contents, 100) %>
        <%= render_id(id) %>
        <%= Phoenix.HTML.raw html %>
        """

      {:error, html, error_messages} ->
        ~E"""
        Result: <%= Utils.truncate(contents, 100) %>
        <%= render_id(id) %>
        Unable to render full contents
        <%= html %>
        <div>
          <%= inspect(error_messages) %>
        </div>
        """
    end
  end

  def render_message_contents(%{"id" => id, "result" => %{"contents" => contents}}, _formatted)
      when is_binary(contents) do
    ~E"""
    Result: <%= Utils.truncate(contents, 100) %>
    <%= render_id(id) %>
    """
  end

  def render_message_contents(%{"id" => id, "result" => _result}, _formatted) do
    ~E"""
    Result
    <%= render_id(id) %>
    """
  end

  def render_message_contents(%{"error" => error} = message_contents, formatted) do
    %{"code" => error_code, "message" => error_message} = error

    error_name =
      case LsProxy.ErrorCodes.error_name(error_code) do
        {:ok, error_name} -> error_name
        _ -> "An Unknown Error"
      end

    ~E"""
    <div><%= error_name %>: <%= Utils.truncate(error_message, 100) %></div>
    <%= if formatted do %>
      <pre><%= error_message %></pre>
    <% end %>
    <%= if message_contents["id"] do %>
      <%= render_id(message_contents["id"]) %>
    <% end %>
    """
  end

  def render_message_contents(other, _formatted) do
    render_full(other)
  end

  def render_full(other) do
    ~E"""
    <pre><code>
    <%= inspect(other, pretty: true) %>
    </code></pre>
    """
  end

  def render_direction(%MessageRecord{} = message_record) do
    ~E"""
    <span class="direction-arrow" title="<%= direction_tooltip(message_record) %>">
      <%= direction_arrow(message_record) %>
    </span>
    """
  end

  def direction_arrow(message_record) do
    case message_record.direction do
      :incoming -> "➡"
      :outgoing -> "⬅"
    end
  end

  def direction_tooltip(message_record) do
    case message_record.direction do
      :incoming -> "Message sent TO server"
      :outgoing -> "Message received FROM server"
    end
  end

  def render_timestamp(%MessageRecord{timestamp: timestamp}, :short) do
    {{_year, _month, _day}, {hour, minute, second}} = NaiveDateTime.to_erl(timestamp)

    [zero_pad(hour), zero_pad(minute), zero_pad(second)]
    |> Enum.join(":")
  end

  def render_timestamp(%MessageRecord{timestamp: timestamp}, :full) do
    NaiveDateTime.to_string(timestamp)
  end

  defp has_formatting?(%{"method" => "window/logMessage"}), do: true

  defp has_formatting?(%{"error" => %{"message" => _message}}), do: true

  defp has_formatting?(%{"result" => %{"contents" => contents}}) when is_binary(contents) do
    true
  end

  defp has_formatting?(_), do: false

  defp zero_pad(number), do: String.pad_leading(to_string(number), 2, "0")

  def render_id(id), do: ~E"<div>id: <b><%= id %></b></div>"

  defdelegate plot_response_times(data), to: LsppWebWeb.MessagesLive
end
