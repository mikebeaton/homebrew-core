class Netdata < Formula
  desc "Diagnose infrastructure problems with metrics, visualizations & alarms"
  homepage "https://netdata.cloud/"
  url "https://github.com/netdata/netdata/releases/download/v1.45.1/netdata-v1.45.1.tar.gz"
  sha256 "3c633bc7ffd4ae588684eb651ffcc03b276bba9d069ba3aa534d2c46a8370fef"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 arm64_sonoma:   "c8101e05d417e88592f1580f111f062ed2c64f7a107271ac9ecd50ac76f1b0eb"
    sha256 arm64_ventura:  "e0eadb2f33af018b9ba4435c6b53eb98e804170b980c1603c9487dae793002b7"
    sha256 arm64_monterey: "fa982cd46ddabb9a20302e6c2a059969d5a9b8361a2beac09583808ba33310d8"
    sha256 sonoma:         "bd24418a3bad424f6178bccbfd045f16bb0616d8b5b73b3dd397edff6a2c7da0"
    sha256 ventura:        "41d6ce9afd539e97dccecb5da9d7ac7cecf37e867db82708953cbddbbe4e2742"
    sha256 monterey:       "471ef2176b93e22b9b8fa12fda8e7de0e971bfd1fdc1e8d2890b74fd4c1688f8"
    sha256 x86_64_linux:   "eaf7d9f20de88f1e860c8f3709cb98d9d0cc37dc45f200d2d5e1df2fb6bdaf48"
  end

  depends_on "cmake" => :build
  depends_on "go" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "brotli"
  depends_on "freeipmi"
  depends_on "json-c"
  depends_on "libuv"
  depends_on "libyaml"
  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "pcre2"
  depends_on "zstd"

  uses_from_macos "zlib"

  on_linux do
    depends_on "util-linux"
  end

  def install
    # https://github.com/protocolbuffers/protobuf/issues/9947
    ENV.append_to_cflags "-DNDEBUG"

    args = %w[
      -DENABLE_PLUGIN_GO=On
      -DENABLE_BUNDLED_PROTOBUF=On
      -DENABLE_PLUGIN_SYSTEMD_JOURNAL=Off
      -DENABLE_PLUGIN_CUPS=On
      -DENABLE_PLUGIN_DEBUGFS=Off
      -DENABLE_PLUGIN_PERF=Off
      -DENABLE_PLUGIN_SLABINFO=Off
      -DENABLE_PLUGIN_CGROUP_NETWORK=Off
      -DENABLE_PLUGIN_LOCAL_LISTENERS=Off
      -DENABLE_PLUGIN_NETWORK_VIEWER=Off
      -DENABLE_PLUGIN_EBPF=Off
      -DENABLE_PLUGIN_LOGS_MANAGEMENT=Off
      -DENABLE_LOGS_MANAGEMENT_TESTS=Off
      -DENABLE_ACLK=On
      -DENABLE_CLOUD=On
      -DENABLE_BUNDLED_JSONC=Off
      -DENABLE_DBENGINE=On
      -DENABLE_H2O=On
      -DENABLE_ML=On
      -DENABLE_PLUGIN_APPS=On
      -DENABLE_EXPORTER_PROMETHEUS_REMOTE_WRITE=Off
      -DENABLE_EXPORTER_MONGODB=Off
      -DENABLE_PLUGIN_FREEIPMI=On
      -DENABLE_PLUGIN_NFACCT=Off
      -DENABLE_PLUGIN_XENSTAT=Off
    ]

    system "cmake", " -S", ".", "-B", "build", "-G", "Ninja", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    (etc/"netdata").install "system/netdata.conf"
  end

  def post_install
    (var/"cache/netdata/unittest-dbengine/dbengine").mkpath
    (var/"lib/netdata/registry").mkpath
    (var/"lib/netdata/lock").mkpath
    (var/"log/netdata").mkpath
    (var/"netdata").mkpath
  end

  service do
    run ["#{Formula["netdata"].opt_prefix}/usr/sbin/netdata", "-D"]
    working_dir var
  end

  test do
    system "#{Formula["netdata"].opt_prefix}/usr/sbin/netdata", "-W", "set", "registry", "netdata unique id file",
                              "#{testpath}/netdata.unittest.unique.id",
                              "-W", "set", "registry", "netdata management api key file",
                              "#{testpath}/netdata.api.key"
  end
end
