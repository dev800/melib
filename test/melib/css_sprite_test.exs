defmodule Melib.CssSpriteTest do
  use ExUnit.Case

  @x1_src Path.join(__DIR__, "../fixtures/icons/x1") |> Path.expand
  @x2_src Path.join(__DIR__, "../fixtures/icons/x2") |> Path.expand

  @x1_css_to Path.join(__DIR__, "../tmp/css_sprite/x1.css") |> Path.expand
  @x2_css_to Path.join(__DIR__, "../tmp/css_sprite/x2.css") |> Path.expand

  @x1_img_to Path.join(__DIR__, "../tmp/css_sprite/x1.png") |> Path.expand
  @x2_img_to Path.join(__DIR__, "../tmp/css_sprite/x2.png") |> Path.expand

  test "generate x1" do
    Melib.CssSprite.generate(
      img_src_dir: @x1_src,
      img_to_path: @x1_img_to,
      css_img_url: "/css_sprite/x1.png",
      css_to_path: @x1_css_to,
      scope_name: "icon",
      css_class_shared: "icon",
      css_class_prefix: "icon-nm-",
      zoom: 1
    )
  end

  test "generate x2" do
    Melib.CssSprite.generate(
      img_src_dir: @x2_src,
      img_to_path: @x2_img_to,
      css_img_url: "/css_sprite/x2.png",
      css_to_path: @x2_css_to,
      scope_name: "icon",
      css_class_shared: "icon",
      css_class_prefix: "icon-nm-",
      zoom: 2
    )
  end

end
