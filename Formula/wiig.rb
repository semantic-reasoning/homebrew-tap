class Wiig < Formula
  desc "Datalog (.dl) formatter and syntax highlighter for the wirelog dialect"
  homepage "https://github.com/semantic-reasoning/wiig"
  url "https://github.com/semantic-reasoning/wiig/archive/d4261367ba6651c428e0770c6252756407e89628.tar.gz"
  version "0.1.0"
  sha256 "cdd2dd64002b3d70b45ef7828df1892b83dc2320f7ac682e9766c79de25600f2"
  license "GPL-3.0-or-later"
  head "https://github.com/semantic-reasoning/wiig.git", branch: "main"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "glib"

  def install
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath}" if OS.linux?

    system "meson", "setup", "build", *std_meson_args, "-Dtests=false"
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wiig")
  end
end
