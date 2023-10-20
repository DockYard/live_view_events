defmodule LiveViewEvents do
  @moduledoc """
  Add `use LiveViewEvents` to the module you want to use any
  of the features of `LiveViewEvents` in.

  For more info about sending and receiving events, see `LiveViewEvents.Notify`.
  """

  defmacro __using__(_opts) do
    quote do
      import LiveViewEvents.Notify
    end
  end
end
