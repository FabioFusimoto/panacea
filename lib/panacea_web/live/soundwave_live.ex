defmodule PanaceaWeb.SoundwaveLive do
  alias Phoenix.PubSub

  use Surface.LiveView
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.Submit

  alias Panacea.PythonGateway
  alias Panacea.Spectrum.Analyzer

  alias PanaceaWeb.Monitor

  @topic "live_spectrum"

  ################################
  # Initialization / Termination #
  ################################
  def render(assigns) do
    ~F"""
    <section class="container">
      <h2>Sound Wave Displayer</h2>

      <Form for={:constant_spectrum} submit="toggle_live_spectrum">
        {#if !@live_update?}
          <div class="inline-element">
            <Field name="output_device">
              <Label>Device</Label>
              <Select name="output_device" options={@output_devices} selected={@selected_device_index} />
            </Field>
          </div>

          <div class="inline-element">
            <Field name="update_rate">
              <Label>Update Rate (Hz)</Label>
              <Select name="update_rate" options={@update_rates} selected={@selected_update_rate} />
            </Field>
          </div>
          <Submit>Live Spectrum</Submit>
        {#else}
          <Submit>Stop</Submit>
        {/if}
      </Form>

      {#if @live_update?}
        <div>
          <p>{@selected_device_description}</p>
        </div>
        <table id="spectrum-table" class="spectrum-table">
          <tr class="spectrum-tr"/>
          {#for row <- @table}
            <tr class="spectrum-tr">
              {#for cell <- row}
                {#case cell}
                  {#match "filled"}
                    <td class="spectrum-td-filled"/>
                  {#match "empty"}
                    <td class="spectrum-td-empty"/>
                {/case}
              {/for}
            </tr>
          {/for}
        </table>
      {/if}

    </section>
    """
  end

  def mount(_params, _assign, socket) do
    output_devices = :output
    |> PythonGateway.list_devices()
    |> Enum.map(&device_option/1)

    update_rates = [5, 10, 20, 30, 60]

    PubSub.subscribe(Panacea.PubSub, @topic)

    {
      :ok,
      assign(
        socket,
        output_devices: output_devices,
        selected_device_index: 0,
        selected_device_description: nil,
        durations: 1..10,
        update_rates: update_rates,
        selected_update_rate: Enum.at(update_rates, 0),
        live_update?: false,
        table: []
      )
    }
  end

  def unmount() do
    Analyzer.stop()
    :ok
  end

  ############
  # Handlers #
  ############
  def handle_event(
    "toggle_live_spectrum",
    params,
    socket
  ) do
    start? = !socket.assigns.live_update?

    if start? do
      Monitor.monitor(self(), __MODULE__)

      %{"output_device" => selected_device_index, "update_rate" => selected_update_rate} = params
      Analyzer.start(
        String.to_integer(selected_device_index),
        String.to_integer(selected_update_rate)
      )

      selected_device_description = socket.assigns.output_devices
      |> Enum.find(fn [_, value: index] -> index == selected_device_index end)
      |> Enum.at(0)
      |> elem(1)

      {
        :noreply,
        assign(
          socket,
          live_update?: true,
          selected_update_rate: selected_update_rate,
          selected_device_index: selected_device_index,
          selected_device_description: selected_device_description
        )
      }
    else
      Analyzer.stop()
      {:noreply, assign(socket, live_update?: false)}
    end
  end

  def handle_info(
    %{
      topic: @topic,
      payload: %{
        spectrum: spectrum
      }
    },
    socket
  ) do
    levels = Enum.map(spectrum, fn [_, p] -> p end)
    table = table_content(levels)
    {:noreply, assign(socket, table: table)}
  end

  ###########
  # Helpers #
  ###########
  defp device_option(device_description) do
    name = device_description['name']
    index = Integer.to_string(device_description['index'])

    key = "#{name} [#{index}]"
    [
      key: key,
      value: index
    ]
  end

  defp table_content(levels) do
    for y <- 17..0 do
      for l <- levels do
        if l > y do
          "filled"
        else
          "empty"
        end
      end
    end
  end
end
