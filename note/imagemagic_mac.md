==> Installing dependencies for imagemagick: libtiff, freetype
==> Installing imagemagick dependency: libtiff
==> Downloading https://homebrew.bintray.com/bottles/libtiff-4.0.9.high_sierra.bottle.tar.gz
######################################################################## 100.0%
==> Pouring libtiff-4.0.9.high_sierra.bottle.tar.gz
🍺  /usr/local/Cellar/libtiff/4.0.9: 246 files, 3.5MB
==> Installing imagemagick dependency: freetype
==> Downloading https://homebrew.bintray.com/bottles/freetype-2.8.1.high_sierra.bottle.tar.gz
######################################################################## 100.0%
==> Pouring freetype-2.8.1.high_sierra.bottle.tar.gz
🍺  /usr/local/Cellar/freetype/2.8.1: 63 files, 2.6MB
==> Installing imagemagick
==> Downloading https://homebrew.bintray.com/bottles/imagemagick-7.0.7-14.high_sierra.bottle.tar.gz
######################################################################## 100.0%
==> Pouring imagemagick-7.0.7-14.high_sierra.bottle.tar.gz
Error: The `brew link` step did not complete successfully
The formula built, but is not symlinked into /usr/local
Could not symlink bin/Magick++-config
Target /usr/local/bin/Magick++-config
is a symlink belonging to imagemagick@6. You can unlink it:
  brew unlink imagemagick@6

To force the link and overwrite all conflicting files:
  brew link --overwrite imagemagick

To list all files that would be deleted:
  brew link --overwrite --dry-run imagemagick
