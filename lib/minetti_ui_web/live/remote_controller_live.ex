defmodule MinettiUiWeb.RemoteControllerLive do
  use MinettiUiWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    state = state_impl().state()
    if connected?(socket), do: Phoenix.PubSub.subscribe(MinettiUi.PubSub, "state")
    {:ok, assign(socket, state: state)}
  end

  @impl Phoenix.LiveView
  def handle_event("set_mode", %{"mode" => mode}, socket) do
    mode = String.to_atom(mode)
    state = state_impl().set_mode(mode)
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("temperature_up", _params, socket) do
    state = state_impl().temperature_up()
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("temperature_down", _params, socket) do
    state = state_impl().temperature_down()
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("cycle_fan_speed", _params, socket) do
    state = state_impl().cycle_fan_speed()
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("swing", _params, socket) do
    state_impl().swing()
    {:noreply, socket}
  end

  def handle_event("vertical_direction", _params, socket) do
    state_impl().vertical_direction()
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:state_changed, state}, socket) do
    {:noreply, assign(socket, state: state)}
  end

  defp state_impl, do: Application.get_env(:minetti_ui, :state_server, MinettiUi.FakeState)

  defp mode(%{mode: :cool}), do: "冷房"
  defp mode(%{mode: :dry}), do: "除湿"
  defp mode(%{mode: :heat}), do: "暖房"
  defp mode(%{mode: :fan_only}), do: "送風"
  defp mode(%{mode: :auto}), do: "自動"
  defp mode(%{mode: :off}), do: ""

  defp fan_speed(%{fan_speed: :auto}), do: "自動"
  defp fan_speed(%{fan_speed: :quiet}), do: "しずか"
  defp fan_speed(%{fan_speed: :low}), do: "微"
  defp fan_speed(%{fan_speed: :weak}), do: "弱"
  defp fan_speed(%{fan_speed: :strong}), do: "強"

  defp temperature(%{mode: mode}) when mode in [:fan_only, :auto, :off], do: ""
  defp temperature(%{temperature: temperature}), do: "#{temperature}°C"
end
