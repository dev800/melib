defmodule Melib.Identify do
  alias Melib.Image
  alias Melib.Attachment

  @new_image_formats ["heic", "heif", "webp"]

  def mime_type(file_path), do: mime_type(file_path, [])

  def mime_type(%Image{path: file_path}, opts) do
    mime_type(file_path, opts)
  end

  def mime_type(%Attachment{path: file_path}, opts) do
    mime_type(file_path, opts)
  end

  def mime_type(file_path, _opts) do
    case Melib.system_cmd("file", ["--mime-type", "-b", file_path], stderr_to_stdout: true) do
      {rows_text, 0} ->
        rows_text = rows_text |> String.trim()

        cond do
          String.starts_with?(rows_text, "cannot open") ->
            raise Melib.NotFoundError,
              message: "#{__MODULE__}.mime_type -> No such file or directory"

          String.contains?(rows_text, " ") ->
            raise Melib.MimeTypeError, message: "#{__MODULE__}.mime_type -> #{rows_text}"

          true ->
            rows_text |> String.split(";") |> Enum.map(fn s -> String.trim(s) end) |> List.first()
        end

      {error_message, 1} ->
        raise Melib.MimeTypeError, message: "#{__MODULE__}.mime_type -> #{error_message}"
    end
  end

  def identify(file_path), do: identify(file_path, [])

  def identify(file_path, opts) do
    data = %{path: file_path} |> verbose(true)

    case data[:mime_type] do
      "image/" <> _format ->
        data |> parse_verbose(file_path, :image, opts)

      _ ->
        data |> parse_verbose(file_path, :attachment, opts)
    end
  end

  def put_file(nil), do: nil

  def put_file(image) do
    if image.file do
      image
    else
      image |> Map.put(:file, File.read!(image.path))
    end
  end

  def put_md5(nil), do: nil

  def put_md5(image) do
    image = image |> put_file

    if image.md5 do
      image
    else
      md5_hash = Melib.md5_hash(image.file)

      image
      |> Map.put(:md5_hash, md5_hash)
      |> Map.put(:md5, md5_hash |> Base.encode16(case: :lower))
    end
  end

  def put_sha256(nil), do: nil

  def put_sha256(image) do
    image = image |> put_file

    if image.sha256 do
      image
    else
      image |> Map.put(:sha256, Melib.sha256(image.file))
      sha256_hash = Melib.sha256_hash(image.file)

      image
      |> Map.put(:sha256_hash, sha256_hash)
      |> Map.put(:sha256, sha256_hash |> Base.encode16(case: :lower))
    end
  end

  def put_sha512(nil), do: nil

  def put_sha512(image) do
    image = image |> put_file

    if image.sha512 do
      image
    else
      image |> Map.put(:sha512, Melib.sha512(image.file))
      sha512_hash = Melib.sha512_hash(image.file)

      image
      |> Map.put(:sha512_hash, sha512_hash)
      |> Map.put(:sha512, sha512_hash |> Base.encode16(case: :lower))
    end
  end

  def put_exif(nil), do: nil

  def put_exif(%Image{} = image) do
    if image.format in ~w(jpg jpeg) do
      image = image |> put_file

      case Melib.Exif.exif_from_jpeg_buffer(image.file) do
        {:ok, exif} -> Map.put(image, :exif, exif)
        _ -> image
      end
    else
      image
    end
  end

  def put_exif(attachment), do: attachment

  defp _generate_postfix(format) do
    if format && format != "" do
      "." <> format
    else
      ""
    end
  end

  def verbose(attachment, force \\ false)

  def verbose(attachment, _force) do
    mime_type = mime_type(attachment.path)
    format = MIME.extensions(mime_type) |> List.first()
    animated = format == "gif"

    attachment =
      attachment
      |> Map.put(:format, format)
      |> Map.put(:ext, Path.extname(attachment.path))
      |> Map.put(:animated, animated)

    attachment.path
    |> run_identify()
    |> case do
      %{image?: false} ->
        attachment
        |> Map.put(:mime_type, mime_type)
        |> Map.put(:postfix, _generate_postfix(format))

      %{image?: true, height: height, width: width, frame_count: frame_count, format: format} ->
        mime_type =
          if Enum.member?(@new_image_formats, format) do
            "image/#{format}"
          else
            mime_type
          end

        attachment
        |> Map.put(:format, format)
        |> Map.put(:height, height)
        |> Map.put(:width, width)
        |> Map.put(:frame_count, frame_count)
        |> Map.put(:mime_type, mime_type)
        |> Map.put(:postfix, _generate_postfix(format))
    end
  end

  defdelegate put_width_and_height(attachment, force \\ false), to: __MODULE__, as: :verbose

  def _parse_width_and_height(w, h, "Horizontal (normal)"), do: {w, h}
  def _parse_width_and_height(w, h, "Mirror horizontal"), do: {w, h}
  def _parse_width_and_height(w, h, "Rotate 180"), do: {w, h}
  def _parse_width_and_height(w, h, "Mirror vertical"), do: {w, h}
  def _parse_width_and_height(w, h, "Mirror horizontal and rotate 270 CW"), do: {h, w}
  def _parse_width_and_height(w, h, "Rotate 90 CW"), do: {h, w}
  def _parse_width_and_height(w, h, "Mirror horizontal and rotate 90 CW"), do: {h, w}
  def _parse_width_and_height(w, h, "Rotate 270 CW"), do: {h, w}
  def _parse_width_and_height(w, h, _), do: {w, h}

  def fix_sbit(media), do: media

  def parse_verbose(data, file_path, type), do: parse_verbose(data, file_path, type, [])

  def parse_verbose(data, file_path, :attachment, opts) do
    filename = file_path |> Path.basename()

    %Attachment{
      ext: data[:ext],
      mime_type: data[:mime_type],
      postfix: data[:postfix],
      format: data[:format],
      filename: filename,
      size: get_size(file_path),
      path: file_path,
      operations: [],
      dirty: %{}
    }
    |> Melib.if_call(opts[:md5], fn media ->
      put_md5(media)
    end)
    |> Melib.if_call(opts[:sha256], fn media ->
      put_sha256(media)
    end)
    |> Melib.if_call(opts[:sha512], fn media ->
      put_sha512(media)
    end)
  end

  def parse_verbose(data, file_path, :image, opts) do
    filename = file_path |> Path.basename()
    height = data[:height]
    width = data[:width]

    image =
      %Image{
        animated: data[:animated],
        ext: data[:ext],
        format: data[:format],
        mime_type: data[:mime_type],
        frame_count: data[:frame_count],
        postfix: data[:postfix],
        filename: filename,
        size: get_size(file_path),
        path: file_path,
        operations: [],
        dirty: %{},
        exif: %{}
      }
      |> Melib.if_call(opts[:md5], fn media ->
        put_md5(media)
      end)
      |> Melib.if_call(opts[:sha256], fn media ->
        put_sha256(media)
      end)
      |> Melib.if_call(opts[:sha512], fn media ->
        put_sha512(media)
      end)
      |> fix_sbit
      |> put_exif()

    orientation =
      image
      |> Map.get(:exif, %{})
      |> get_in([:tiff, :orientation])

    {width, height} = _parse_width_and_height(width, height, orientation)
    %Image{image | width: width, height: height}
  end

  def run_identify(file_path) do
    case Melib.ImageMagick.run(
           "identify",
           ["-format", "%m:%W:%H:%w:%h\n", file_path],
           stderr_to_stdout: true
         ) do
      {rows_text, 0} ->
        rows = rows_text |> String.split("\n", trim: true)
        filtered_rows = rows |> Enum.filter(fn row -> Regex.match?(~r/\w+:\d+:\d+/, row) end)

        if filtered_rows |> Enum.any?() do
          frame_count = filtered_rows |> length()

          [format, width, height | _] =
            filtered_rows
            |> List.last()
            |> String.split(":", trim: true)

          format = format |> String.downcase()
          width = width |> String.to_integer()
          height = height |> String.to_integer()

          %{
            width: width,
            height: height,
            frame_count: frame_count,
            format: format,
            image?: true
          }
        else
          raise Melib.VerboseError,
            message: "#{__MODULE__}._identify -> #{rows_text}"
        end

      {_error_message, 1} ->
        %{image?: false}
    end
  end

  def get_size(file_path) do
    file_path |> File.stat!() |> Melib.get(:size)
  end
end
