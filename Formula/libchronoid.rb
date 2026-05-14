class Libchronoid < Formula
  desc "Fast hash-date library for Unix timestamps and durations"
  homepage "https://github.com/semantic-reasoning/libchronoid"
  url "https://github.com/semantic-reasoning/libchronoid/archive/refs/tags/v1.0.1.tar.gz"
  version "1.0.1"
  sha256 "82e3a7748a09898834425c812e5dffb78b7d8e8864118e67ca96e669aee721a9"
  license "LGPL-3.0-or-later AND MIT"
  head "https://github.com/semantic-reasoning/libchronoid.git", branch: "main"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  def install
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath}" if OS.linux?

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <chronoid.h>

      int main(void) {
        const char *version = chronoid_version();
        printf("libchronoid version: %s\\n", version);
        return 0;
      }
    C

    system ENV.cc, "-I#{include}", "test.c", "-L#{lib}", "-lchronoid", "-o", "test"
    system "./test"
  end
end
