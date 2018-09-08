defmodule Melib.Exif.Tag do
  @moduledoc """
  Parse the different tag type values (strings, unsigned shorts, etc...)
  """

  @max_signed_32_bit_int 2_147_483_647

  # unsigned byte, size = 1
  def value(1, count, value, context) do
    decode_numeric(value, count, 2, context)
  end

  # ascii string, size = 1
  def value(2, count, value, context) do
    {exif, _offset, ru} = context
    # ignore null-byte at end
    length = count - 1

    if count > 4 do
      offset = ru.(value)
      <<_::binary-size(offset), string::binary-size(length), _::binary>> = exif
      string
    else
      <<string::binary-size(length), _::binary>> = value
      string
    end
  end

  # unsigned short, size = 2
  def value(3, count, value, context) do
    decode_numeric(value, count, 2, context)
  end

  # unsigned long, size = 4
  def value(4, count, value, context) do
    decode_numeric(value, count, 4, context)
  end

  # unsigned rational, size = 8
  def value(5, count, value, context) do
    decode_ratio(value, count, 8, context)
  end

  #
  # def value(6, count, value, rest, ru) do  # signed byte, size = 1
  #   # size 1
  # end
  #
  # undefined, size = 1
  def value(7, count, value, context) do
    decode_numeric(value, count, 1, context)
  end

  #
  # def value(8, count, value, rest, ru) do  # signed short, size = 2
  #   # size 1
  # end
  #
  # def value(9, count, value, rest, ru) do  # signed long, size = 4
  #   # size 1
  # end
  #
  # signed rational, size = 8
  def value(10, count, value, context) do
    decode_ratio(value, count, 8, context, :signed)
  end

  #
  # def value(11, count, value, rest, ru) do  # single float, size = 4
  #   # size 1
  # end
  #
  # def value(12, count, value, rest, ru) do  # double float, size = 4
  #   # size 1
  # end

  # Handle malformed tags
  def value(_, _, _, _) do
    nil
  end

  def decode_numeric(value, count, size, {exif, _offset, ru}) do
    length = count * size

    values =
      if length > 4 do
        case exif do
          <<_::binary-size(value), data::binary-size(length), _::binary>> ->
            data

          # probably a maker_note or user_comment
          _ ->
            nil
        end
      else
        <<data::binary-size(length), _::binary>> = value
        data
      end

    if values do
      if count == 1 do
        ru.(values)
      else
        read_unsigned_many(values, size, ru)
      end
    end
  end

  def decode_ratio(value_offset, count, 8, {exif, _offset, ru}, signed \\ :unsigned) do
    offset = ru.(value_offset)
    result = decode_ratios(exif, count, offset, ru, signed)

    if count == 1 do
      hd(result)
    else
      result
    end
  end

  def decode_ratios(_data, 0, _offset, _ru, _signed) do
    []
  end

  def decode_ratios(data, count, offset, ru, signed) do
    <<_::binary-size(offset), numerator::binary-size(4), denominator::binary-size(4),
      rest::binary>> = data

    d = maybe_signed_int(ru.(denominator), signed)
    n = maybe_signed_int(ru.(numerator), signed)

    result =
      case {d, n} do
        {1, n} -> n
        {d, 1} -> "1/#{d}"
        {0, _} -> :infinity
        {d, n} -> round(n * 1000 / d) / 1000
      end

    [result | decode_ratios(rest, count - 1, 0, ru, signed)]
  end

  def read_unsigned_many(<<>>, _size, _ru) do
    []
  end

  def read_unsigned_many(data, size, ru) do
    <<number::binary-size(size), rest::binary>> = data
    [ru.(number) | read_unsigned_many(rest, size, ru)]
  end

  def maybe_signed_int(x, :signed) when x > @max_signed_32_bit_int do
    x - (@max_signed_32_bit_int + 1) * 2
  end

  # +ve or unsigned
  def maybe_signed_int(x, _), do: x
end
