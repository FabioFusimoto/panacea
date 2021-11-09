defmodule PanaceaWeb.SoundwaveLive do
  use Surface.LiveView
  alias Panacea.PythonGateway

  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.Submit

  ##################
  # Initialization #
  ##################
  def render(assigns) do
    ~F"""
    <section class="container">
      <h2>Sound Wave Displayer</h2>

      <Form for={:sound_spectrum} submit="display_spectrum">
        <div class="inline-element">
          <Field name="output_device">
            <Label>Device</Label>
            <Select name="output_device" options={@output_devices} />
          </Field>
        </div>

        <div class="inline-element">
          <Field name="record_duration">
            <Label>Seconds to record</Label>
            <Select name="record_duration" options={@record_durations} />
          </Field>
        </div>

        <Submit>Record</Submit>
      </Form>
    </section>
    """
  end

  def mount(_params, _assign, socket) do
    output_devices = :output
    |> PythonGateway.list_devices()
    |> Enum.map(&device_option/1)

    {:ok, assign(socket, output_devices: output_devices, record_durations: 1..10)}
  end

  ############
  # Handlers #
  ############
  def handle_event(
    "display_spectrum",
    %{"output_device" => device_index, "record_duration" => duration},
    socket
  ) do
    frames_recorded = PythonGateway.record(
      String.to_integer(device_index),
      String.to_integer(duration)
    )
    IO.inspect("#{frames_recorded} frame(s) recorded!")
    {:noreply, socket}
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
end
