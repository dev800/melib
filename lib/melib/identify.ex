defmodule Melib.Identify do
  alias Melib.Image
  alias Melib.Attachment

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
        rows_text = rows_text |> String.trim

        cond do
          String.starts_with?(rows_text, "cannot open") ->
            raise Melib.MimeTypeError, message: "#{__MODULE__}.mime_type -> No such file or directory"
          String.contains?(rows_text, " ") ->
            raise Melib.MimeTypeError, message: "#{__MODULE__}.mime_type -> #{rows_text}"
          true ->
            rows_text |> String.split(";") |> Enum.map(fn s -> String.trim(s) end) |> List.first
        end
      {error_message, 1} ->
        raise Melib.MimeTypeError, message: "#{__MODULE__}.mime_type -> #{error_message}"
    end
  end

  def identify(file_path), do: identify(file_path, [])
  def identify(file_path, opts) do
    data = %{path: file_path} |> put_mime_type

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
      image |> Map.put(:md5, Melib.md5(image.file))
    end
  end

  def put_sha256(nil), do: nil
  def put_sha256(image) do
    image = image |> put_file

    if image.sha256 do
      image
    else
      image |> Map.put(:sha256, Melib.sha256(image.file))
    end
  end

  def put_sha512(nil), do: nil
  def put_sha512(image) do
    image = image |> put_file

    if image.sha512 do
      image
    else
      image |> Map.put(:sha512, Melib.sha512(image.file))
    end
  end

  def put_exif(nil), do: nil
  def put_exif(%Image{} = image) do
    image = image |> put_file

    if image.format in ~w(jpg jpeg) do
      case Melib.Exif.exif_from_jpeg_buffer(image.file) do
        {:ok, exif} -> Map.put(image, :exif, exif)
        _ -> image
      end
    else
      image
    end
  end
  def put_exif(attachment), do: attachment

  def put_mime_type(nil), do: nil
  def put_mime_type(attachment) do
    mime_type = mime_type(attachment.path)
    format = MIME.extensions(mime_type) |> List.first
    postfix =
      if format && format != "" do
        "." <> format
      else
        ""
      end
    animated = format == "gif"

    attachment
    |> Map.put(:mime_type, mime_type)
    |> Map.put(:format, format)
    |> Map.put(:postfix, postfix)
    |> Map.put(:ext, Path.extname(attachment.path))
    |> Map.put(:animated, animated)
  end

  def parse_verbose(data, file_path, type), do: parse_verbose(data, file_path, type, [])
  def parse_verbose(data, file_path, :attachment, opts) do
    %{size: size} = File.stat! file_path
    filename = file_path |> Path.basename

    attachment =
      %Attachment{
        ext:         data[:ext],
        mime_type:   data[:mime_type],
        postfix:     data[:postfix],
        format:      data[:format],
        filename:    filename,
        size:        size,
        path:        file_path,
        operations:  [],
        dirty:       %{}
      }

    attachment = if opts[:md5], do: put_md5(attachment), else: attachment
    attachment = if opts[:sha256], do: put_sha256(attachment), else: attachment
    attachment = if opts[:sha512], do: put_sha512(attachment), else: attachment

    attachment
  end
  def parse_verbose(data, file_path, :image, opts) do

    %{width: width, height: height} =
      case Melib.system_cmd("identify", ["-format", "%m:%w:%h", file_path <> "[0]"], stderr_to_stdout: true) do
        {rows_text, 0} ->
          info = rows_text |> String.split(":") |> Enum.map(fn(i) -> String.trim(i) end)
          width = info |> Enum.at(1) |> String.to_integer
          height = info |> Enum.at(2) |> String.to_integer

          %{width: width, height: height}
        {error_message, 1} ->
          raise Melib.VerboseError, message: "#{__MODULE__}.verbose -> #{error_message}"
      end

    %{size: size} = File.stat! file_path
    filename = file_path |> Path.basename

    image =
      %Image{
        animated:    data[:animated],
        ext:         data[:ext],
        format:      data[:format],
        mime_type:   data[:mime_type],
        postfix:     data[:postfix],
        filename:    filename,
        size:        size,
        path:        file_path,
        width:       width,
        height:      height,
        operations:  [],
        dirty:       %{},
        exif:        %{}
      }

    image = if opts[:md5], do: put_md5(image), else: image
    image = if opts[:sha256], do: put_sha256(image), else: image
    image = if opts[:sha512], do: put_sha512(image), else: image

    image
  end

end
