defmodule TestAppWeb.Components.Receiver do
  use TestAppWeb, :live_component

  use LiveViewEvents

  def mount(socket) do
    socket = assign(socket, :messages, [])

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = socket |> handle_info_or_assign(assigns)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul id={@id}>
      <%= for message <- @messages do %>
        <li class="message">
          <span class="name"><%= message.name %></span>
          <span class="params"><%= display_params(message.params) %></span>
        </li>
      <% end %>
    </ul>
    """
  end

  def handle_info({message, params}, socket) do
    socket = update(socket, :messages, &[%{name: message, params: params} | &1])

    {:noreply, socket}
  end

  def handle_info(message, socket) do
    socket = update(socket, :messages, &[%{name: message, params: :empty} | &1])

    {:noreply, socket}
  end

  defp display_params(:empty), do: "empty"
  defp display_params(other), do: Jason.encode!(other)
end
