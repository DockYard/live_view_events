defmodule TestAppWeb.Components.SimpleTutorial.Sender do
  use TestAppWeb, :live_component
  use LiveViewEvents

  def mount(socket) do
    socket = assign(socket, :notify_to, :self)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <button type="button" phx-click="clicked" phx-target={@myself}>
      Send event
    </button>
    """
  end

  def handle_event("clicked", _params, socket) do
    IO.inspect("clicked!!")
    notify_to(socket.assigns.notify_to, :sender_event, :rand.uniform(100))

    {:noreply, socket}
  end

  def handle_event(message, _params, socket) do
    IO.inspect(message, label: "Message received!")
    {:noreply, socket}
  end
end
