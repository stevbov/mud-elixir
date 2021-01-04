defmodule Mud.Direction do
  import Kernel, except: [to_string: 1]

  @directions [:north, :south, :east, :west, :up, :down]
  @type t :: :north | :south | :east | :west | :up | :down

  def directions(), do: @directions

  def reverse(direction) do
    case direction do
      :north -> :south
      :south -> :north
      :east -> :west
      :west -> :east
      :up -> :down
      :down -> :up
    end
  end

  def to_string(direction) do
    Kernel.to_string(direction)
  end

  def to_leave_string(direction) do
    case direction do
      :up -> "up"
      :down -> "down"
      _ -> "to the #{to_string(direction)}"
    end
  end

  def to_enter_string(direction) do
    case direction do
      :up -> "above"
      :down -> "below"
      _ -> "the #{to_string(direction)}"
    end
  end
end
