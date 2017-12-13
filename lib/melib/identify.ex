defmodule Melib.Identify do
  alias Melib.Image

  @formats_by_mime_type %{
    "image/jpeg" => "jpeg",
    "image/png" => "png",
    "image/gif" => "gif",
    "image/bmp" => "bmp"
  }

  def verbose(file_path), do: verbose(file_path, [])
  def verbose(%Image{path: file_path}, opts) do
    verbose(file_path, opts)
  end
  def verbose(file_path, _opts) do
    case Melib.system_cmd("identify", ["-format", "%m:%w:%h", file_path <> "[0]"], stderr_to_stdout: true) do
      {rows_text, 0} ->
        data = rows_text |> String.split(":") |> Enum.map(fn(i) -> String.trim(i) end)
        width = data |> Enum.at(1) |> String.to_integer
        height = data |> Enum.at(2) |> String.to_integer

        %{
          width: width,
          height: height
        }

      {error_message, 1} ->
        raise Melib.VerboseError, message: "#{__MODULE__}.verbose -> #{error_message}"
    end
  end

  def mime_type(file_path), do: mime_type(file_path, [])
  def mime_type(%Image{path: file_path}, opts) do
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
    file_path
    |> verbose(opts)
    |> parse_verbose(file_path, opts)
  end

  def put_mime_type(nil), do: nil
  def put_mime_type(image) do
    image |> mime_type(image.path)
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
  def put_exif(image) do
    image = image |> put_file

    if image.format == "jpeg" do
      case Melib.Exif.exif_from_jpeg_buffer(image.file) do
        {:ok, exif} -> Map.put(image, :exif, exif)
        _ -> image
      end
    else
      image
    end
  end

  def parse_verbose(data, file_path), do: parse_verbose(data, file_path, [])
  def parse_verbose(data, file_path, _opts) do
    %{size: size} = File.stat! file_path
    mime_type = mime_type(file_path)
    filename = file_path |> Path.basename
    format = get_format_by_mime_type(mime_type)
    postfix = "." <> format
    animated = format == "gif"

    %{
      width: width,
      height: height
    } = data

    %Image{
      animated:    animated,
      filename:    filename,
      size:        size,
      path:        file_path,
      postfix:     postfix,
      ext:         file_path |> Path.extname |> String.downcase,
      format:      format,
      mime_type:   mime_type,
      width:       width,
      height:      height,
      operations:  [],
      dirty:       %{},
      exif:        %{}
    }
  end

  def get_format_by_mime_type(type) do
    Map.get(@formats_by_mime_type, type) || (type |> String.split("/") |> List.last)
  end

end
