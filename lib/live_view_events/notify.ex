defmodule LiveViewEvents.Notify do
  @moduledoc """
  Functions to send messages in the server including to live components
  and handle them.

  ## Example

  In our view, we are going to have two components. The first one is a `Sender`
  that can send an event to whatever is being passed. Let's dig into the
  implementation:

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

  This component will send a `:sender_event` message to whatever we pass to the `notify_to`
  attribute. It sends a random number between 0 and up to 100 as parameter.

  Let's dig into the receiver:

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

        def render(assigns), do: ~H[<ul><li :for={m <- @messages}><%= m %></li></ul>]

        def handle_info({:sender_event, num}, socket) do
          {:noreply, update(socket, :messages, &[num | &1])}
        end
      end

  This component will receive messages and handle them in `handle_info/2` because
  it is using `handle_info_or_assign/2` in their [`LiveComponent.update/2`](`c:Phoenix.LiveComponent.update/2`).
  It will add the received messages to `socket.assigns.messages` and display
  them. As the reader can see, it is pattern matching against `:sender_event` messages.
  When `notify_to/3` is used, the message sent is a tuple containing the event name
  as first element, and the params as second the second element.

  Finally, let's take a look at what the live view template would need to look like
  for this to work:

      <div class="contents">
        <.live_component
          module={MyAppWeb.Components.Sender}
          id="sender"
          notify_to={{MyAppWeb.Components.Receiver, "receiver"}}
          />
        <.live_component module={MyAppWeb.Components.Receiver} id="receiver" />
      </div>

  In this template, we set `notify_to` to the tuple `{MyAppWeb.Components.Receiver, "receiver"}`.
  The first element of the tuple is the live component module and the second is the id.
  Optionally, the tuple can contain an extra first element that needs to be a PID. Though
  this might not be useful in the application code (there are way better ways to send events
  between processes), it is quite useful when testing. When testing a [`LiveView`](`Phoenix.LiveView`),
  it creates a new process for it. Its PID can be accessed through `view.pid`.
  """

  @assign_name_for_event :__live_view_events__assign_event__

  @doc """
  Use this macro instead of the default `assigns(socket, assign)` in
  `c:Phoenix.LiveComponent.update/2`.

  This will detect if `c:Phoenix.LiveComponent.update/2` is being called
  because of an event send with either `notify_to/2` or `notify_to/3`
  and handle it with `c:Phoenix.LiveView.handle_info/2`. Otherwise,
  it will assign the given `assigns` to `socket`.

  If there is no `c:Phoenix.LiveView.handle_info/2` defined in the
  component, sending an event won't raise an error but if there is one
  defined and it cannot handle the received message, it will.

  Furthermore, if the handler returns anything that is not a tuple
  `{:noreply, socket}`, it'll raise an exception too.

  ## Why using `c:Phoenix.LiveView.handle_info/2` in components?

  In one word: consistency. Messages coming from the client are
  handled by [LiveView.handle_event/3](`c:Phoenix.LiveView.handle_event/3`)
  in live views or by [`LiveComponent.handle_event/3`](`c:Phoenix.LiveComponent.handle_event/3`)
  in live components.
  Messages sent from the server are currently being handled by
  [`LiveView.handle_info/2`](`c:Phoenix.LiveView.handle_info/2`) in live views,
  with no official way to do this but the __hack__ this library is based on.

  The hack is basically send an update with [`LiveView.send_update/3`](`Phoenix.LiveView.send_update/3`)
  and handle it in [`LiveComponent.update/2`](`c:Phoenix.LiveComponent.update/2`).
  """
  defmacro handle_info_or_assign(socket, assigns) do
    quote do
      LiveViewEvents.Notify.handle_info_or_assign(__MODULE__, unquote(socket), unquote(assigns))
    end
  end

  @doc false
  def handle_info_or_assign(module, socket, assigns) do
    case Map.get(assigns, @assign_name_for_event) do
      nil ->
        Phoenix.Component.assign(socket, assigns)

      message ->
        handle_message(module, socket, message)
    end
  end

  defp handle_message(module, socket, message) do
    if function_exported?(module, :handle_info, 2) do
      case module.handle_info(message, socket) do
        {:noreply, socket} ->
          socket

        other ->
          raise "#{module}.handle_info/2 return an invalid value (#{inspect(other)}), needs to return `{:noreply, socket}`"
      end
    else
      socket
    end
  end

  @doc """
  `notify_to/2` accepts a target and a message name. The target can be any of:

  - `nil` would make it be a noop.
  - `:self` to send to `self()`.
  - A PID.
  - A tuple of the form `{Module, "id"}` to send a message to a [`LiveView.Component`](`Phoenix.LiveView.Component`) in the same process.
  - A tuple of the form `{pid, Module, "id"}` to send a message to a [`LiveView.Component`](`Phoenix.LiveView.Component`) in a different process.

  The event send will take the form of `{message, %{}}`.
  """
  def notify_to(nil, _message), do: nil
  def notify_to(:self, message), do: notify_to(self(), normalize_message(message))
  def notify_to(pid, message) when is_pid(pid), do: send(pid, normalize_message(message))

  def notify_to(target, message) when is_tuple(target) do
    {pid, module, id} = process_tuple(target)

    Phoenix.LiveView.send_update(pid, module, %{
      :id => id,
      @assign_name_for_event => normalize_message(message)
    })
  end

  @doc """
  `notify_to/3` behaves like `notify_to/2` but accepting some extra parameters as the third arguments.
  In this case, the message sent would be a tuple with the `message` as first element and `params` as the
  second one.
  """
  def notify_to(nil, _message, _params), do: nil
  def notify_to(:self, message, params), do: notify_to(self(), message, params)
  def notify_to(pid, message, params) when is_pid(pid), do: send(pid, {message, params})

  def notify_to(target, message, params) when is_tuple(target) do
    {pid, module, id} = process_tuple(target)

    Phoenix.LiveView.send_update(pid, module, %{
      :id => id,
      @assign_name_for_event => {message, params}
    })
  end

  defp normalize_message({_message_name, %{} = _params} = message), do: message
  defp normalize_message(message_name), do: {message_name, %{}}

  defp process_tuple({module, id}), do: {self(), module, id}
  defp process_tuple({pid, _module, _id} = target) when is_pid(pid), do: target
end
