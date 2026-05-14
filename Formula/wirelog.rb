class Wirelog < Formula
  desc "Embedded-to-Enterprise Datalog Engine in C11"
  homepage "https://github.com/semantic-reasoning/wirelog"
  url "https://github.com/semantic-reasoning/wirelog/archive/refs/tags/v0.40.0.tar.gz"
  version "0.40.0"
  sha256 "08ffccf85f2681e19bae733e70c6b1a2fa3659376ca6a1752a07156d996fe30c"
  license "LGPL-3.0-or-later"
  head "https://github.com/semantic-reasoning/wirelog.git", branch: "main"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "libchronoid"

  resource "nanoarrow" do
    url "https://github.com/apache/arrow-nanoarrow/archive/981775cad8542dee661aec0a9c0441bb2458f8be.tar.gz"
    sha256 "9af249f8b9bf4f77adea9504de5ca9bb3ceb63488bfbd07fa87040d0c7bc1fea"
  end

  resource "xxhash" do
    url "https://github.com/Cyan4973/xxHash/archive/v0.8.3.tar.gz"
    sha256 "aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80"
  end

  resource "xxhash-meson-wrapdb-patch" do
    url "https://wrapdb.mesonbuild.com/v2/xxhash_0.8.3-2/get_patch"
    sha256 "c7f78fc2d08ec21ff1bae928d7bdcddb42713a07d9d973a885c59ea7f8cf6bc8"
  end

  def install
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath}" if OS.linux?

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"
  end

  test do
    shell_output("#{bin}/wirelog_cli --help")
  end
end
