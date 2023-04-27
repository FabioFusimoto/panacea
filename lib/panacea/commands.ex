defmodule Panacea.Commands do
  alias Panacea.Serial

  @commands_separator " "
  @arguments_separator ";"
  @commands_end "\n"
  @commands_per_chunk 20

  defp build_command_string(command, args) do
    args
    |> List.insert_at(0, command)
    |> Enum.join(@arguments_separator)
    |> Kernel.<>(@commands_separator)
  end

  defp dispatch_command(command) do
    Serial.write(command)
  end

  def write!(command, args \\ []) do
    command_string = build_command_string(command, args) <> @commands_end
    dispatch_command(command_string)
  end

  def write_multiple!(command_list, args_list) do
    command_strings =
      Enum.map(
        Enum.zip(command_list, args_list),
        fn {command, args} -> build_command_string(command, args) end
      )

    command_chunks =
      Enum.chunk_every(
        command_strings,
        @commands_per_chunk
      )

    Enum.each(
      command_chunks,
      fn chunk ->
        chunk
        |> Enum.join()
        |> Kernel.<>(@commands_end)
        |> dispatch_command()
      end
    )
  end

  def list() do
    %{
      "SHO" => [],
      "ONE" => ["X", "Y", "R", "G", "B"],
      "ALL" => ["R", "G", "B"],
      "BRI" => ["Brightness"],
      "ONB" => ["Index", "R", "G", "B"],
      "ALB" => ["R", "G", "B"]
    }
  end
end
