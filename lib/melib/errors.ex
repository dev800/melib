defmodule Melib.VerboseError do
  defexception [:message]
end

defmodule Melib.ConvertError do
  defexception [:message]
end

defmodule Melib.MimeTypeError do
  defexception [:message]
end

defmodule Melib.NotFoundError do
  defexception [:message]
end

defmodule Melib.ConfigError do
  defexception [:message]
end
