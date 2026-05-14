class Wyrelog < Formula
  desc "Datalog-backed authorization daemon and command-line client"
  homepage "https://github.com/semantic-reasoning/wyrelog"
  url "https://github.com/semantic-reasoning/wyrelog/archive/fe2a3bc8f77a0e4b44aff260511df30aa8f72100.tar.gz"
  version "0.1.0"
  sha256 "2e78389d4a1a3c2d77fc06c12bbac97bc1a006115f27f6eebb2c516b6cc6da30"
  license "GPL-3.0-or-later"
  head "https://github.com/semantic-reasoning/wyrelog.git", branch: "main"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "glib"
  depends_on "libsodium"
  depends_on "libsoup"
  depends_on "sqlite"

  uses_from_macos "zlib"

  resource "wirelog" do
    url "https://github.com/semantic-reasoning/wirelog/archive/d2d418344b0ae224944d6bd81a33a37575eaee4f.tar.gz"
    sha256 "176d06d815a438b21160340b4c95883af2fcb6ba80516cd88e2c7a4f134900c4"
  end

  resource "libchronoid" do
    url "https://github.com/semantic-reasoning/libchronoid/archive/refs/tags/v1.0.1.tar.gz"
    sha256 "82e3a7748a09898834425c812e5dffb78b7d8e8864118e67ca96e669aee721a9"
  end

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

  resource "duckdb-linux-amd64" do
    url "https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-linux-amd64.zip"
    sha256 "4711438f0fdb04f0441803409bec5430b763d4f2ac3482c1f97cfa6b5ecb4c15"
  end

  resource "duckdb-osx-universal" do
    url "https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-osx-universal.zip"
    sha256 "524f3537330a1b747556a0c98b62a46865a3f48c7ead2b2035c62f1ad3e5ca8b"
  end

  def install
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath}" if OS.linux?

    resource("wirelog").stage buildpath/"subprojects/wirelog"
    resource("libchronoid").stage buildpath/"subprojects/libchronoid"
    resource("nanoarrow").stage buildpath/"subprojects/wirelog/subprojects/nanoarrow"
    resource("xxhash").stage buildpath/"subprojects/wirelog/subprojects/xxHash-0.8.3"
    resource("xxhash-meson-wrapdb-patch").stage do
      cp_r Dir["xxHash-0.8.3/*"], buildpath/"subprojects/wirelog/subprojects/xxHash-0.8.3"
    end

    if OS.mac?
      duckdb_dir = buildpath/"subprojects/duckdb-prebuilt-osx-universal"
      resource("duckdb-osx-universal").stage duckdb_dir
      cp buildpath/"subprojects/packagefiles/duckdb-prebuilt-osx/meson.build", duckdb_dir/"meson.build"
    elsif OS.linux?
      duckdb_dir = buildpath/"subprojects/duckdb-prebuilt-linux-amd64"
      resource("duckdb-linux-amd64").stage duckdb_dir
      cp buildpath/"subprojects/packagefiles/duckdb-prebuilt-linux/meson.build", duckdb_dir/"meson.build"
    end

    system "meson", "setup", "build", *std_meson_args,
           "-Denable_client=enabled",
           "-Denable_audit=enabled",
           "-Denable_fact_store=enabled",
           "-Dduckdb_source=prebuilt",
           "-Denable_tpm=disabled",
           "-Drequire_tpm=false",
           "-Dwyrelog_log_max_level=warn"
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"

    if OS.mac?
      lib.install buildpath/"subprojects/duckdb-prebuilt-osx-universal/libduckdb.dylib"
    elsif OS.linux?
      lib.install buildpath/"subprojects/duckdb-prebuilt-linux-amd64/libduckdb.so"
    end

    (var/"lib/wyrelog").mkpath
    (var/"log/wyrelog").mkpath
  end

  def caveats
    <<~EOS
      wyrelog installs both the daemon and the client CLI:
        #{opt_bin}/wyrelogd
        #{opt_bin}/wyctl

      This formula builds the client, audit sink, and fact-store support. For a
      local development daemon, create a policy key and run wyrelogd with an
      explicit policy DB, audit DB, and fact root under #{var}.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wyrelogd --version")
    assert_match version.to_s, shell_output("#{bin}/wyctl --version")
    assert_path_exists share/"wyrelog/access/manifest.ini"
  end
end
