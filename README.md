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

## Install ImageMagick7@Mac

```
brew install fftw fontconfig ghostscript libheif liblqr librsvg libwmf little-cms openexr pango perl webp
brew install imagemagick@7 --with-fftw --with-fontconfig --with-ghostscript --with-libheif --with-liblqr --with-librsvg --with-libwmf --with-little-cms --with-openexr --with-pango --with-perl
brew unlink imagemagick@6
brew link imagemagick@7
brew info imagemagick@7
```

## Install ImageMagick-7@centos

```
# use linuxbrew
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
# add -> export PATH="$HOME/.linuxbrew/bin:$PATH" -> to ~/.zshrc and ~/.bashrc
brew install fftw fontconfig ghostscript libheif liblqr librsvg libwmf little-cms openexr pango perl webp
brew install imagemagick@7 --with-fftw --with-fontconfig --with-ghostscript --with-libheif --with-liblqr --with-librsvg --with-libwmf --with-little-cms --with-openexr --with-pango --with-perl
```

```
cd /usr/local/src && \
git clone https://github.com/strukturag/libde265 && \
cd libde265 && \
./autogen.sh && \
./configure && \
make && \
make install

cd /usr/local/src && \
git clone https://github.com/strukturag/libheif && \
cd libheif && \
./autogen.sh && \
./configure && \
make && \
make install

cd /usr/local/src && \
rm -rf ImageMagick7 && \
wget https://github.com/ImageMagick/ImageMagick/archive/7.0.7-35.tar.gz -O ImageMagick-7.0.7-35.tar.gz && \
tar xvzf ImageMagick-7.0.7-35.tar.gz && \
mv ImageMagick-7.0.7-35 ImageMagick7 && \
cd ImageMagick7 && \
./configure --prefix=/usr/local/ImageMagick7 --with-openjp2=yes --with-gvc=yes --with-fftw=yes --with-heic=yes --with-rsvg=yes --with-wmf=yes --with-xml=yes --with-openexr=yes --with-webp=yes && \
make && \
make install && \
cd .. && \
rm -rf ImageMagick-7.0.7-35.tar.gz
```

## Install ImageMagick-6@centos

```
cd /usr/local/src && \
rm -rf ImageMagick6 && \
wget https://github.com/ImageMagick/ImageMagick6/archive/6.9.9-47.tar.gz -O ImageMagick-6.9.9-47.tar.gz && \
tar xvzf ImageMagick-6.9.9-47.tar.gz && \
mv ImageMagick6-6.9.9-47 ImageMagick6 && \
cd ImageMagick6 && \
./configure --prefix=/usr/local/ImageMagick6 --with-openjp2=yes --with-gvc=yes --with-fftw=yes --with-heic=yes --with-rsvg=yes --with-wmf=yes --with-xml=yes --with-openexr=yes --with-webp=yes && \
make && \
make install && \
cd .. && \
rm -rf ImageMagick-6.9.9-47.tar.gz
```

## Usage

### create gif from static images

```elixir
images = [
 "/Users/happy/tmp/a/1.jpg",
 "/Users/happy/tmp/a/2.jpg",
 "/Users/happy/tmp/a/3.jpg",
 "/Users/happy/tmp/a/4.jpg",
 "/Users/happy/tmp/a/5.jpg",
 "/Users/happy/tmp/a/6.jpg"
]
Melib.Mogrify.create_gif_from images, [
  path: "/Users/happy/tmp/b/1.gif",   # dist path
  speed: 2
]
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/melib](https://hexdocs.pm/melib).

