class Uv < Formula
  desc "Extremely fast Python package installer and resolver, written in Rust"
  homepage "https://github.com/astral-sh/uv"
  url "https://github.com/astral-sh/uv/archive/refs/tags/0.1.33.tar.gz"
  sha256 "92d12bf283954c024c7672369985bf5baa5f08d1ddac0d2aa692679aba45b05e"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/astral-sh/uv.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "b9b59c45008cce15810594fc27c0d3b4d9ec52ae157cfc12d15985dce834c02d"
    sha256 cellar: :any,                 arm64_ventura:  "e41e05a207d6b8aaf13374fc371ca9178ec0f3f0cdf08f8ede7b8b021f34b62a"
    sha256 cellar: :any,                 arm64_monterey: "f81e41da0cf077cbc8fcd06db0ce0f3df70e4d9ef4ffb365470965044f79481c"
    sha256 cellar: :any,                 sonoma:         "d2f761e836a75e382bf8f37bcac226b4f9c89aee509329cdfca8c0f568495955"
    sha256 cellar: :any,                 ventura:        "c8e961f6983be8b0bb14c473e32c40a3a1d094b16b8925ddc92ca81bc6ec4440"
    sha256 cellar: :any,                 monterey:       "b47d8fdc06b10696e388c04ec64807eeab57b575978bf2a9786042384e5967f3"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "85022c878833d7eff8a9e7e26de66c042a44e4348b3adaa277261ce63d7d836e"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "openssl@3"

  uses_from_macos "python" => :test

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"

    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    system "cargo", "install", "--no-default-features", *std_cargo_args(path: "crates/uv")
    generate_completions_from_executable(bin/"uv", "generate-shell-completion")
  end

  def check_binary_linkage(binary, library)
    binary.dynamically_linked_libraries.any? do |dll|
      next false unless dll.start_with?(HOMEBREW_PREFIX.to_s)

      File.realpath(dll) == File.realpath(library)
    end
  end

  test do
    (testpath/"requirements.in").write <<~EOS
      requests
    EOS

    compiled = shell_output("#{bin}/uv pip compile -q requirements.in")
    assert_match "This file was autogenerated by uv", compiled
    assert_match "# via requests", compiled

    [
      Formula["libgit2"].opt_lib/shared_library("libgit2"),
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert check_binary_linkage(bin/"uv", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
