defmodule LiveViewEvents.Notify.ToComponentTest do
  use TestAppWeb.ConnCase

  import LiveIsolatedComponent
  import Phoenix.Component, only: [live_component: 1, sigil_H: 2]

  alias LiveViewEvents.Notify
  alias TestAppWeb.Components.Receiver
  alias TestAppWeb.Components.Sender

  @receiver_id "receiver"

  defp live_receiver(), do: live_isolated_component(Receiver, %{id: @receiver_id})

  defp text(el), do: el |> Floki.text() |> String.replace(~r/\s+/, " ")
  defp text(el, selector), do: el |> Floki.find(selector) |> text()

  defp parse_params("empty"), do: %{}

  defp parse_params(text) do
    Jason.decode!(text)
  end

  defp events(view) do
    view
    |> render()
    |> Floki.find(".message")
    |> Enum.map(fn el ->
      {text(el, ".name"), el |> text(".params") |> parse_params()}
    end)
  end

  defp last_event(view), do: view |> events() |> List.first()

  describe "with pid in tuple" do
    # In tests, we need to include the pid in the tuple as the live view is a different process.
    test "can send event to component without params" do
      {:ok, view, _html} = live_receiver()

      assert events(view) == []

      view |> target() |> Notify.notify_to(:a_message)

      assert last_event(view) == {"a_message", %{}}

      view |> target() |> Notify.notify_to(:another_message)

      assert last_event(view) == {"another_message", %{}}
    end

    test "can send events to component with params" do
      {:ok, view, _html} = live_receiver()

      assert events(view) == []

      view |> target() |> Notify.notify_to(:a_message, %{"hello" => "hello"})

      assert last_event(view) == {"a_message", %{"hello" => "hello"}}

      view |> target() |> Notify.notify_to(:another_message, 5)

      assert last_event(view) == {"another_message", 5}

      view |> target() |> Notify.notify_to(:yet_another_message, ["hola", 5, true])

      assert last_event(view) == {"yet_another_message", ["hola", 5, true]}
    end
  end

  describe "without pid in tuple" do
    # So we can send the message correctly, we need to use another component
    test "can send event without params" do
      {:ok, view, _html} =
        live_send_and_receiver(assigns: %{message_params: [target(), :message]})

      assert events(view) == []

      send_event(view)

      assert last_event(view) == {"message", %{}}
    end

    test "can send event with params" do
      {:ok, view, _html} =
        live_send_and_receiver(
          assigns: %{message_params: [target(), :message, %{"a" => "param"}]}
        )

      assert events(view) == []

      send_event(view)

      assert last_event(view) == {"message", %{"a" => "param"}}
    end
  end

  def send_event(view), do: view |> element(".sender") |> render_click()

  defp target(), do: {Receiver, @receiver_id}
  defp target(view), do: {view.pid, Receiver, @receiver_id}

  defp live_send_and_receiver(opts) do
    live_isolated_component(
      fn assigns ->
        assigns = Phoenix.Component.assign(assigns, :receiver_id, @receiver_id)

        ~H"""
        <.live_component module={Sender} id="sender" message_params={@message_params} />
        <.live_component module={Receiver} id={@receiver_id} />
        """
      end,
      opts
    )
  end
end
