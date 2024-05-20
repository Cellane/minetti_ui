defmodule MinettiUi.FakeState do
  use GenServer

  @valid_modes [:cool, :heat, :dry, :fan_only, :auto, :off]

  # Client
  def start_link(_),
    do:
      GenServer.start_link(
        __MODULE__,
        %{mode: :off, temperature: 20.0, fan_speed: :auto, on_timer: nil, off_timer: nil},
        name: __MODULE__
      )

  def state, do: GenServer.call(__MODULE__, :state)

  def set_mode(mode) when mode in @valid_modes,
    do: GenServer.call(__MODULE__, {:set_mode, mode})

  def temperature_up, do: GenServer.call(__MODULE__, :temperature_up)
  def temperature_down, do: GenServer.call(__MODULE__, :temperature_down)
  def cycle_fan_speed, do: GenServer.call(__MODULE__, :cycle_fan_speed)

  def swing, do: GenServer.cast(__MODULE__, :swing)
  def vertical_direction, do: GenServer.cast(__MODULE__, :vertical_direction)

  # Server
  @impl GenServer
  def init(state), do: {:ok, state}

  @impl GenServer
  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call({:set_mode, mode}, _from, state) when mode in [:dry, :auto] do
    state = %{state | mode: mode, fan_speed: :auto}
    schedule_apply()
    {:reply, state, state}
  end

  def handle_call({:set_mode, mode}, _from, state) do
    state = %{state | mode: mode}
    schedule_apply()
    {:reply, state, state}
  end

  def handle_call(_command, _from, %{mode: :off} = state), do: {:reply, state, state}

  def handle_call(:temperature_up, _from, %{temperature: temperature} = state)
      when temperature >= 30,
      do: {:reply, state, state}

  def handle_call(:temperature_up, _from, %{temperature: temperature} = state) do
    state = %{state | temperature: temperature + 0.5}
    schedule_apply()
    {:reply, state, state}
  end

  def handle_call(:temperature_down, _from, %{temperature: temperature} = state)
      when temperature <= 16,
      do: {:reply, state, state}

  def handle_call(:temperature_down, _from, %{temperature: temperature} = state) do
    state = %{state | temperature: temperature - 0.5}
    schedule_apply()
    {:reply, state, state}
  end

  def handle_call(:cycle_fan_speed, _from, %{mode: mode} = state) when mode in [:dry, :auto],
    do: {:reply, state, state}

  def handle_call(:cycle_fan_speed, _from, %{fan_speed: fan_speed} = state) do
    state = %{state | fan_speed: next_fan_speed(fan_speed)}
    schedule_apply()
    {:reply, state, state}
  end

  @impl GenServer
  def handle_cast(:swing, state) do
    {:noreply, state}
  end

  def handle_cast(:vertical_direction, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:apply, state) do
    Phoenix.PubSub.broadcast(MinettiUi.PubSub, "state", {:state_changed, state})
    {:noreply, state}
  end

  defp fan_speed_order, do: [:auto, :quiet, :low, :weak, :strong, :super]

  defp next_fan_speed(current_speed),
    do:
      fan_speed_order()
      |> Stream.cycle()
      |> Stream.drop_while(&(&1 != current_speed))
      |> Enum.at(1)

  defp schedule_apply, do: send(self(), :apply)
end
