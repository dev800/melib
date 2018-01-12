defmodule Melib.Util do

  def to_i(nil), do: 0
  def to_i(x) when is_integer(x), do: x
  def to_i(x)  when is_float(x) do
    x |> :erlang.float_to_binary(decimals: 2) |> to_i
  end
  def to_i(x) when is_binary(x) or is_bitstring(x) do
    try do
      case x |> String.trim |> Integer.parse do
        {i, _} -> i
        :error -> 0
      end
    rescue
      ArgumentError -> 0
    end
  end
  def to_i(x) when is_atom(x) do
    try do
      x |> Atom.to_string |> to_i
    rescue
      ArgumentError -> 0
    end
  end

end
