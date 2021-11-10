defmodule PanaceaWeb.SoundwaveLive do
  alias Phoenix.PubSub

  use Surface.LiveView
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.Submit

  alias Panacea.PythonGateway
  alias Panacea.Spectrum

  @topic "live_spectrum"

  ##################
  # Initialization #
  ##################
  def render(assigns) do
    ~F"""
    <section class="container">
      <h2>Sound Wave Displayer</h2>

      <Form for={:constant_spectrum} submit="toggle_live_spectrum">
        {#if !@live_update?}
          <div class="inline-element">
            <Field name="output_device">
              <Label>Device</Label>
              <Select name="output_device" options={@output_devices} />
            </Field>
          </div>

          <div class="inline-element">
            <Field name="update_rate">
              <Label>Update Rate (Hz)</Label>
              <Select name="update_rate" options={@update_rates} />
            </Field>
          </div>
          <Submit>Live Spectrum</Submit>
        {#else}
          <Submit>Stop</Submit>
        {/if}
      </Form>

      {#if @live_update?}
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
    |> Enum.filter(
      fn [_, {:value, index}] ->
        index == "7" or index == "8"
      end
    )

    update_rates = [5, 10, 20, 30, 60]

    PubSub.subscribe(Panacea.PubSub, @topic)

    {
      :ok,
      assign(
        socket,
        output_devices: output_devices,
        durations: 1..10,
        update_rates: update_rates,
        live_update?: false,
        table: []
      )
    }
  end

  ############
  # Handlers #
  ############

  def handle_event(
    "toggle_live_spectrum",
    %{"output_device" => device_index, "update_rate" => update_rate},
    socket
  ) do
    start? = !socket.assigns.live_update?

    if start? do
      Spectrum.start(
        String.to_integer(device_index),
        String.to_integer(update_rate)
      )
    else
      Spectrum.stop()
    end

    {:noreply, assign(socket, live_update?: start?)}
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
