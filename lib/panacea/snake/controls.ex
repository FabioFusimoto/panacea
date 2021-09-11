defmodule Panacea.Snake.Controls do
  alias Panacea.Snake.Game, as: Game

  def up(), do: Game.set_next_direction("UP")

  def down(), do: Game.set_next_direction("DOWN")

  def left(), do: Game.set_next_direction("LEFT")

  def right(), do: Game.set_next_direction("RIGHT")

  def update(), do: Game.update()
end
