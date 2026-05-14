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
  depends_on "wirelog"
  depends_on "libchronoid"
  depends_on "nanoarrow"
  depends_on "glib"
  depends_on "libsodium"
  depends_on "libsoup"
  depends_on "sqlite"

  uses_from_macos "zlib"

  on_macos do
    resource "duckdb-osx-universal" do
      url "https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-osx-universal.zip"
      sha256 "524f3537330a1b747556a0c98b62a46865a3f48c7ead2b2035c62f1ad3e5ca8b"
    end
  end

  on_linux do
    resource "duckdb-linux-amd64" do
      url "https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-linux-amd64.zip"
      sha256 "4711438f0fdb04f0441803409bec5430b763d4f2ac3482c1f97cfa6b5ecb4c15"
    end
  end

  def install
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath}" if OS.linux?
    ENV.append "LDFLAGS", "-Wl,-rpath,#{lib}" if OS.mac?

    if OS.mac?
      duckdb_dir = buildpath/"subprojects/duckdb-prebuilt-osx-universal"
      resource("duckdb-osx-universal").stage duckdb_dir
      cp buildpath/"subprojects/packagefiles/duckdb-prebuilt-osx/meson.build", duckdb_dir/"meson.build"
    elsif OS.linux?
      duckdb_dir = buildpath/"subprojects/duckdb-prebuilt-linux-amd64"
      resource("duckdb-linux-amd64").stage duckdb_dir
      cp buildpath/"subprojects/packagefiles/duckdb-prebuilt-linux/meson.build", duckdb_dir/"meson.build"
    end

    meson_args = std_meson_args.reject { |arg| arg.start_with?("--wrap-mode") }
    system "meson", "setup", "build", "--wrap-mode=default", *meson_args,
           "-Denable_client=enabled",
           "-Denable_audit=enabled",
           "-Denable_fact_store=enabled",
           "-Dduckdb_source=prebuilt",
           "-Denable_tpm=disabled",
           "-Drequire_tpm=false",
           "-Dwyrelog_log_max_level=warn"
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"

    # Remove files that conflict with wirelog/nanoarrow/libchronoid formulas
    # Use shell commands for more reliable removal
    system "bash", "-c", %{
      rm -f "#{lib}"/{libnanoarrow,libwirelog,libxxhash}*
      rm -f "#{bin}"/wirelog_cli "#{bin}"/xxhsum
      rm -rf "#{include}"/wirelog "#{include}"/nanoarrow
      rm -f "#{lib}/pkgconfig"/{wirelog,xxhash,nanoarrow}*.pc
      rm -f "#{share}/man/man1/xxhsum.1"
      rm -f "#{share}/glib-2.0/schemas/gschemas.compiled"
    }

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
