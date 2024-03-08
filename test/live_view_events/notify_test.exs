defmodule LiveViewEvents.NotifyTest do
  use ExUnit.Case

  alias LiveViewEvents.Notify

  test "notify_to/2 with `nil` target does not break" do
    Notify.notify_to(nil, "event")
  end

  test "notify_to/3 with `nil` target does not break" do
    Notify.notify_to(nil, "event", %{some: :params})
  end
end
