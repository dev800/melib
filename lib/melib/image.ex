defmodule Melib.Image do

  @type postfix     :: binary
  @type path        :: binary
  @type md5         :: binary
  @type sha512      :: binary
  @type sha256      :: binary
  @type filename    :: binary
  @type size        :: integer
  @type ext         :: binary
  @type format      :: binary
  @type mime_type   :: mime_type
  @type width       :: integer
  @type height      :: integer
  @type animated    :: boolean
  @type frame_count :: integer
  @type operations  :: Keyword.t
  @type dirty       :: %{atom => any}
  @type file        :: binary

  @type t :: %__MODULE__{
    size:        size,
    md5:         md5,
    sha512:      sha512,
    sha256:      sha256,
    frame_count: frame_count,
    filename:    filename,
    path:        path,
    ext:         ext,
    postfix:     postfix,
    format:      format,
    mime_type:   mime_type,
    width:       width,
    height:      height,
    animated:    animated,
    operations:  operations,
    dirty:       dirty,
    file:        file
  }

  defstruct path: nil,
            size:         nil,
            md5:          nil,
            sha512:       nil,
            sha256:       nil,
            frame_count:  1,
            filename:     nil,
            ext:          nil,
            postfix:      nil,
            format:       nil,
            mime_type:    nil,
            width:        nil,
            height:       nil,
            animated:     false,
            operations:   [],
            dirty:        %{},
            file:         nil

end
