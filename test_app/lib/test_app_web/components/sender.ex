defmodule TestAppWeb.Components.Sender do
  use TestAppWeb, :live_component

  use LiveViewEvents

  def render(assigns) do
    ~H"""
    <button class="sender" phx-click="send" phx-target={@myself}>Send</button>
    """
  end

  def handle_event("send", _params, socket) do
    message_params = socket.assigns.message_params

    apply(LiveViewEvents.Notify, :notify_to, message_params)

    {:noreply, socket}
  end
end
