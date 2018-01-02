defmodule Melib.Attachment do

  @type postfix     :: binary
  @type path        :: binary
  @type md5         :: binary
  @type md5_hash    :: binary
  @type sha512      :: binary
  @type sha512_hash :: binary
  @type sha256      :: binary
  @type sha256_hash :: binary
  @type size        :: integer
  @type ext         :: binary
  @type format      :: binary
  @type mime_type   :: mime_type
  @type operations  :: Keyword.t
  @type dirty       :: %{atom => any}
  @type filename    :: binary
  @type file        :: binary

  @type t :: %__MODULE__{
    size:        size,
    md5:         md5,
    md5_hash:    md5_hash,
    sha512:      sha512,
    sha512_hash: sha512_hash,
    sha256:      sha256,
    sha256_hash: sha256_hash,
    path:        path,
    ext:         ext,
    format:      format,
    postfix:     postfix,
    mime_type:   mime_type,
    operations:  operations,
    dirty:       dirty,
    filename:    filename,
    file:        file
  }

  defstruct path: nil,
            size:         nil,
            md5:          nil,
            md5_hash:     nil,
            sha512:       nil,
            sha512_hash:  nil,
            sha256:       nil,
            sha256_hash:  nil,
            ext:          nil,
            format:       nil,
            postfix:      nil,
            mime_type:    nil,
            operations:   [],
            dirty:        %{},
            filename:     nil,
            file:         nil

end
