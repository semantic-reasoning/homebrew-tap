class Libchronoid < Formula
  desc "Fast hash-date library for Unix timestamps and durations"
  homepage "https://github.com/semantic-reasoning/libchronoid"
  url "https://github.com/semantic-reasoning/libchronoid/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "0f0e0e0aa87c5f42658b5ba1e23c83b1860657391cc1c4f60c9377012236e69a"
  license all_of: ["LGPL-3.0-or-later", "MIT"]
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
      #include <string.h>
      #include <chronoid/chronoid.h>

      int main(void) {
        chronoid_ksuid_t id;
        const unsigned char payload[CHRONOID_KSUID_PAYLOAD_LEN] = {0};
        char out[CHRONOID_KSUID_STRING_LEN + 1] = {0};
        if (strcmp(CHRONOID_VERSION_STRING, "#{version}") != 0) {
          return 1;
        }
        if (chronoid_ksuid_from_parts(&id, CHRONOID_KSUID_EPOCH_SECONDS,
                                      payload, sizeof(payload)) != CHRONOID_KSUID_OK) {
          return 1;
        }
        chronoid_ksuid_format(&id, out);
        printf("libchronoid version: %s %s\\n", CHRONOID_VERSION_STRING, out);
        return 0;
      }
    C

    system ENV.cc, "-I#{include}", "test.c", "-L#{lib}", "-lchronoid", "-o", "test"
    assert_match version.to_s, shell_output("./test")
  end
end
