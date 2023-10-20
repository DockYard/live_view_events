# LiveViewEvents

![Elixir CI](https://github.com/DockYard/live_view_events/actions/workflows/elixir-ci.yml/badge.svg)

LiveViewEvents provides a set of tools to send events between components.

## Installation

Add `live_view_events` to your list of dependencies in `mix.exs` like:

```elixir
def deps do
  [
    {:live_view_events, "~> 0.1.0"}
  ]
end
```

## Usage

Add `use LiveViewEvents` whenever you want to use any of the features of the libraries.

### Sending events to LiveView components

You can send events to LiveView components by using `notify_to/2` or `notify_to/3` (the only
difference being that the latter sends some extra params). These functions accept a target as
first argument and a message name as second. Targets can be any of:

  - `:self` to send to `self()`.
  - A PID.
  - A tuple of the form `{Module, "id"}` to send a message to a `LiveView.Component` in the same process.
  - A tuple of the form `{pid, Module, "id"}` to send a message to a `LiveView.Component` in a different process.

You an handle these messages on the `handle_info/2` callback on
your LiveView components. For being able to do so, you need to
use the `handle_info_or_assign/2` macro on the `update/3` callback of your component. 

## Example


In our view, we are going to have two components. The first one is a `Sender`
that can send an event to whatever is being passed. Let's dig into the
implementation:

```elixir
defmodule MyAppWeb.Components.Sender do
  use MyAppWeb, :live_component
  use LiveViewEvents

  def mount(socket) do
    socket = assign(socket, :notify_to, :self)

    {:ok, socket}
  end

  def render(assigns) do
    ~H[<button type="button" phx-click="clicked" phx-target={@myself}>Send event</button>]
  end

  def handle_event("clicked", _params, socket) do
    notify_to(socket.assigns.notify_to, :sender_event, :rand.uniform(100))
    {:noreply, socket}
  end
end
```

This component will send a `:sender_event` message to whatever we pass to the `notify_to`
attribute. It sends a random number between 0 and up to 100 as parameter.

Let's dig into the receiver:

```elixir
defmodule MyAppWeb.Components.Receiver do
  use MyAppWeb, :live_component
  use LiveViewEvents

  def mount(socket) do
    socket = assign(socket, :messages, [])

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = handle_info_or_assign(socket, assigns)

    {:ok, socket}
  end

  def render(assigns),
    do: ~H[<ul><li :for={m <- @messages}><%= m %></li></ul>]

  def handle_info({:sender_event, num}, socket) do
    {:noreply, update(socket, :messages, &[num | &1])}
  end
end
```

This component will receive messages and handle them in `handle_info/2` because
it is using `handle_info_or_assign/2` in their `LiveComponent.update/2`.
It will add the received messages to `socket.assigns.messages` and display
them. As the reader can see, it is pattern matching against `:sender_event` messages.
When `notify_to/3` is used, the message sent is a tuple containing the event name
as first element, and the params as second the second element.

Finally, let's take a look at what the live view template would need to look like
for this to work:

```heex
<div class="contents">
  <.live_component
    module={MyAppWeb.Components.Sender}
    id="sender"
    notify_to={{MyAppWeb.Components.Receiver, "receiver"}}
  />
  <.live_component module={MyAppWeb.Components.Receiver} id="receiver" />
</div>
```

In this template, we set `notify_to` to the tuple `{MyAppWeb.Components.Receiver, "receiver"}`.
The first element of the tuple is the live component module and the second is the id.
Optionally, the tuple can contain an extra first element that needs to be a PID. Though
this might not be useful in the application code (there are way better ways to send events
between processes), it is quite useful when testing. When testing a `LiveView`
it creates a new process for it. Its PID can be accessed through `view.pid`.