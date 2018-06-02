# Melib

Media Lib: image, vedio and so on

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `melib` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:melib, "~> 0.1.1"}
  ]
end

## config.exs eg.

config :melib, :magick_path, "/usr/local/ImageMagick7/bin"
```

## Install ImageMagick-7

```
cd /usr/local/src && \
wget https://github.com/ImageMagick/ImageMagick/archive/7.0.7-35.tar.gz -O ImageMagick-7.0.7-35.tar.gz && \
tar xvzf ImageMagick-7.0.7-35.tar.gz && \
mv ImageMagick-7.0.7-35 ImageMagick7 && \
cd ImageMagick7 && \
./configure --prefix=/usr/local/ImageMagick7 --enable-shared  --enable-static --without-perl && \
make && \
make install && \
cd .. && \
rm -rf ImageMagick-7.0.7-35.tar.gz
```

## Install ImageMagick-6

```
cd /usr/local/src && \
wget https://github.com/ImageMagick/ImageMagick6/archive/6.9.9-47.tar.gz -O ImageMagick-6.9.9-47.tar.gz && \
tar xvzf ImageMagick-6.9.9-47.tar.gz && \
mv ImageMagick6-6.9.9-47 ImageMagick6 && \
cd ImageMagick6 && \
./configure --prefix=/usr/local/ImageMagick6 --enable-shared  --enable-static --without-perl && \
make && \
make install && \
cd .. && \
rm -rf ImageMagick-6.9.9-47.tar.gz
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/melib](https://hexdocs.pm/melib).

