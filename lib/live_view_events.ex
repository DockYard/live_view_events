defmodule LiveViewEvents do
  @moduledoc """
  Documentation for `LiveViewEvents`.
  """

  defmacro __using__(_opts) do
    quote do
      import LiveViewEvents.Notify
    end
  end
end
