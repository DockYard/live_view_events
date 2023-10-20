defmodule TestAppWeb.SimpleTutorialLive do
  use TestAppWeb, :live_view

  alias TestAppWeb.Components.SimpleTutorial.Receiver
  alias TestAppWeb.Components.SimpleTutorial.Sender

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.live_component
        module={Sender}
        id="sender"
        notify_to={{Receiver, "receiver"}}
        />
      <.live_component module={Receiver} id="receiver" />
    </div>
    """
  end
end
