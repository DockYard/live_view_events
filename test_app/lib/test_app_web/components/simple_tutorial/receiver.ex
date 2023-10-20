defmodule TestAppWeb.Components.SimpleTutorial.Receiver do
  use TestAppWeb, :live_component
  use LiveViewEvents

  def mount(socket) do
    socket = assign(socket, :messages, [])

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = handle_info_or_assign(socket, assigns)

    {:ok, socket}
  end

  def render(assigns), do: ~H[<ul>
  <li :for={m <- @messages}><%= m %></li>
</ul>]

  def handle_info({:sender_event, num}, socket) do
    {:noreply, update(socket, :messages, &[num | &1])}
  end
end
