defmodule LiveViewEvents.Notify do
  @moduledoc false

  @assign_name_for_event "__live_view_events__assign_event__"

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
  handled by `c:Phoenix.LiveView.handle_event/3` or by
  `c:Phoenix.LiveComponent.handle_event/3`. For messages sent from
  the server are currently being handled by `c:Phoenix.LiveView.handle_info/2`
  in live views, with not official way to do this but the hack this
  library is based on.

  The hack is basically send an update with `Phoenix.LiveView.send_update/3`
  and handle it in `c:Phoenix.LiveComponent.update/2`
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

  - `:self` to send to `self()`.
  - A PID.
  - A tuple of the form `{Module, "id"}` to send a message to a LiveView component.
  """
  def notify_to(:self, message), do: notify_to(self(), message)
  def notify_to(pid, message) when is_pid(pid), do: send(pid, message)

  def notify_to(target, message) when is_tuple(target) do
    {pid, module, id} = process_tuple(target)
    Phoenix.LiveView.send_update(pid, module, %{:id => id, @assign_name_for_event => message})
  end

  @doc """
  `notify_to/3` behaves like `notify_to/2` but accepting some extra parameters as the third arguments.
  In this case, the message sent would be a tuple with the `message` as first element and `params` as the
  second one.
  """
  def notify_to(:self, message, params), do: notify_to(self(), message, params)
  def notify_to(pid, message, params) when is_pid(pid), do: send(pid, {message, params})

  def notify_to(target, message, params) when is_tuple(target) do
    {pid, module, id} = process_tuple(target)

    Phoenix.LiveView.send_update(pid, module, %{
      :id => id,
      @assign_name_for_event => {message, params}
    })
  end

  defp process_tuple({module, id}), do: {self(), module, id}
  defp process_tuple({pid, _module, _id} = target) when is_pid(pid), do: target
end
