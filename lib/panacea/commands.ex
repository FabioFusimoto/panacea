defmodule Panacea.Commands do
  alias Circuits.UART, as: Serial

  @timeout 20 # in milliseconds
  @commands_separator "|"
  @arguments_separator ";"
  @commands_per_chunk 3
  @ack_retry_count 10

  def build_command_string(command, args) do
    args
    |> List.insert_at(0, command)
    |> Enum.join(@arguments_separator)
    |> Kernel.<>(@commands_separator)
  end

  def write!(command, args \\ []) do
    connection = Panacea.Serial.retrieve_connection()
    command_string = build_command_string(command, args)
    Serial.write(connection, command_string)
    {:ok, response} = Serial.read(connection, @timeout)
    response
  end

  defp wait_for_acknowledges(connection, command_count, acc, attempts) do
    if String.length(acc) < command_count && attempts != @ack_retry_count do
      {:ok, serial_buffer} = Serial.read(connection, @timeout)
      wait_for_acknowledges(connection, command_count, acc <> serial_buffer, attempts + 1)
    else
      {acc, attempts}
    end
  end

  def write_multiple!(command_list, args_list) do
    connection = Panacea.Serial.retrieve_connection()
    command_strings = Enum.map(
      Enum.zip(command_list, args_list),
      fn {command, args} -> build_command_string(command, args) end
    )
    command_chunks = Enum.chunk_every(
      command_strings,
      @commands_per_chunk
    )

    Enum.each(
      command_chunks,
      fn chunk ->
        Enum.each(chunk, &(Serial.write(connection, &1)))
        wait_for_acknowledges(connection, length(chunk), "", 0)
      end
    )
  end

  def list() do
    %{
      "SHO" => [],
      "ONE" => ["X", "Y", "R", "G", "B"],
      "ALL" => ["R", "G", "B"],
      "BRI" => ["Brightness"],
    }
  end
end
