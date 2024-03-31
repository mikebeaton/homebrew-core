class S2geometry < Formula
  desc "Computational geometry and spatial indexing on the sphere"
  homepage "https://github.com/google/s2geometry"
  url "https://github.com/google/s2geometry/archive/refs/tags/v0.11.1.tar.gz"
  sha256 "bdbeb8ebdb88fa934257caf81bb44b55711617a3ab4fdec2c3cfd6cc31b61734"
  license "Apache-2.0"

  livecheck do
    url :homepage
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "80e9962267439af1de9f48231bf5fd2843f09825c62498f50bbd66290f3d3f9e"
    sha256 cellar: :any,                 arm64_ventura:  "97ede51316899c6f4f34dfe092c3b8ccec4276bb3b637c53c92e8b5be0fe45df"
    sha256 cellar: :any,                 arm64_monterey: "839e1ee4dbbf7bac0eef6584f509f01d3a2e311c1311b6a3b0665060b931ce56"
    sha256 cellar: :any,                 arm64_big_sur:  "261c1a2494e5a665d7412774939f9de44b13ec1c383471ca19dc670c23ed331c"
    sha256 cellar: :any,                 sonoma:         "11af3c270a33a4e54c50686bee8a518eebcf2d1beff675a761ca66888d633c19"
    sha256 cellar: :any,                 ventura:        "41574127892178f975b9288302a173d95531aa1660d3603ea097a8447b331a67"
    sha256 cellar: :any,                 monterey:       "c32c79613a93dddf1c44c1453d670cded5fb9a046388e7627f637d5bf19adc00"
    sha256 cellar: :any,                 big_sur:        "a132c68316515afc343b9edd8047786d53260ffc98569aa334a532885c74ba5d"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "4bc799fb810424ce3052a520c01f7ac7245c343efef46becb68ea383b1328e3d"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "abseil"
  depends_on "glog"
  depends_on "openssl@3"

  fails_with gcc: "5" # C++17

  def install
    args = %W[
      -DOPENSSL_ROOT_DIR=#{Formula["openssl@3"].opt_prefix}
      -DBUILD_TESTS=OFF
      -DWITH_GFLAGS=1
      -DWITH_GLOG=1
      -DCMAKE_CXX_STANDARD=17
      -DCMAKE_CXX_STANDARD_REQUIRED=TRUE
    ]

    system "cmake", "-S", ".", "-B", "build/shared", *args, *std_cmake_args
    system "cmake", "--build", "build/shared"
    system "cmake", "--install", "build/shared"

    system "cmake", "-S", ".", "-B", "build/static", *args,
                    "-DBUILD_SHARED_LIBS=OFF",
                    "-DOPENSSL_USE_STATIC_LIBS=TRUE",
                    *std_cmake_args
    system "cmake", "--build", "build/static"
    lib.install "build/static/libs2.a"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include "s2/s2loop.h"
      #include "s2/s2polygon.h"
      #include "s2/s2latlng.h"

      #include <vector>
      #include <iostream>

      int main() {
          // Define the vertices of a polygon around a block near the Googleplex.
          std::vector<S2LatLng> lat_lngs = {
              S2LatLng::FromDegrees(37.422076, -122.084518),
              S2LatLng::FromDegrees(37.422003, -122.083984),
              S2LatLng::FromDegrees(37.421964, -122.084028),
              S2LatLng::FromDegrees(37.421847, -122.083171),
              S2LatLng::FromDegrees(37.422140, -122.083167),
              S2LatLng::FromDegrees(37.422076, -122.084518) // Last point equals the first one
          };

          std::vector<S2Point> points;
          for (const auto& ll : lat_lngs) {
              points.push_back(ll.ToPoint());
          }
          std::unique_ptr<S2Loop> loop = std::make_unique<S2Loop>(points);

          S2Polygon polygon(std::move(loop));

          S2LatLng test_point = S2LatLng::FromDegrees(37.422, -122.084);
          if (polygon.Contains(test_point.ToPoint())) {
              std::cout << "The point is inside the polygon." << std::endl;
          } else {
              std::cout << "The point is outside the polygon." << std::endl;
          }

          return 0;
      }
    EOS

    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test",
                    "-L#{lib}", "-ls2"
    system "./test"
  end
end
