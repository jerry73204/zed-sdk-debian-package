# Maintainer: Hsiang-Jui Lin <jerry73204@gmail.com>
pkgname=zed-sdk
pkgver=5.0.5
pkgrel=1
pkgdesc="StereoLabs ZED SDK"
arch=('amd64' 'arm64')
url="https://www.stereolabs.com/developers/release/"
license=('custom')

_arch="$(dpkg --print-architecture)"

_common_depends=(
  'libjpeg-turbo8'
  'libturbojpeg'
  'libusb-1.0-0'
  'libusb-1.0-0-dev'
  'libopenblas-dev'
  'libarchive-dev'
  'libv4l-0'
  'curl'
  'unzip'
  'zlib1g'
  'mesa-utils'
  # dev
  'libpng-dev'
  #
  'qtbase5-dev'
  'qtchooser'
  'qt5-qmake'
  'qtbase5-dev-tools'
  'libqt5opengl5'
  'libqt5svg5'
  # samples
  'libglew-dev'
  'freeglut3-dev'
  # python
  'python3-numpy'
  'python3-requests'
  'python3-pyqt5'
)
_jetson_depends=(
  'nvidia-l4t-camera'
)
depends_x86_64=(
  ${_common_depends[@]}
)
depends_aarch64=(
  x${_common_depends[@]}
  'nvidia-l4t-camera'
)

conflicts_x86_64=()
conflicts_aarch64=('libv4l-dev')

if [[ "$_arch" == "arm64" && -f /etc/nv_tegra_release ]]; then
  depends_aarch64+=(${_jetson_depends[@]})
fi

makedepends=(
  'zstd'
  'tar'
  # python
  'python3-dev'
  'python3-pip'
  'python3-setuptools'
)
options=('!strip')
postinst='postinst.sh'
prerm='prerm.sh'
postrm='postrm.sh'

CARCH=$(dpkg --print-architecture)

if [ "${CARCH}" = "amd64" ]; then
    run_file="ZED_SDK_Ubuntu22_cuda12.8_tensorrt10.9_v${pkgver}.zstd.run"
else
    run_file="ZED_SDK_Tegra_L4T36.4_v${pkgver}.zstd.run"
fi

source_amd64=(
    "${run_file}::https://download.stereolabs.com/zedsdk/5.0/cu12/ubuntu22"
    "python_shebang.patch"
    "zed_download_ai_models"
)
source_arm64=(
    "${run_file}::https://download.stereolabs.com/zedsdk/5.0/l4t36.4/jetsons"
    "python_shebang.patch"
    "zed_download_ai_models"
)

noextract=()

sha256sums_amd64=(
    '71836b2dc0d1b1f164554be9435c14f996cc279ac67be0cd2d5f16d8b12c0102'
    '1eed77b1cb24af3e58ecffde7a6bd1524215efeb9bafdc9364a2add2bc911fcd'
    'f4bff6ceb6de242615ddb2c305d70b35f7935adee4bbdda1d5d980a960efa09b'
)
sha256sums_arm64=(
    'SKIP'
    '1eed77b1cb24af3e58ecffde7a6bd1524215efeb9bafdc9364a2add2bc911fcd'
    'f4bff6ceb6de242615ddb2c305d70b35f7935adee4bbdda1d5d980a960efa09b'
)


prepare() {
  cd "${srcdir}"

  # Extract content from the self-extracting archive
  # The number 718 is the line where the binary data starts in the run file
  mkdir -p extract
  tail -n +718 "../${run_file}" | zstdcat -d | tar -xf - -C extract

  cd extract
  patch -Np1< "${srcdir}/python_shebang.patch"
}

package() {
  cd "${srcdir}/extract"

  # Create target directories
  mkdir -p "${pkgdir}/usr/local/zed"
  mkdir -p "${pkgdir}/usr/local/lib/python3.10/dist-packages"
  mkdir -p "${pkgdir}/etc/udev/rules.d"
  mkdir -p "${pkgdir}/etc/ld.so.conf.d"
  mkdir -p "${pkgdir}/usr/local/bin"
  mkdir -p "${pkgdir}/usr/share/licenses/${pkgname}"

  # Install license
  install -Dm644 "doc/license/LICENSE.txt" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"

  # Install ZED libraries and includes
  cp -a -t "${pkgdir}/usr/local/zed" lib
  cp -a -t "${pkgdir}/usr/local/zed" include

  # Install firmware and resources
  cp -a -t "${pkgdir}/usr/local/zed" firmware
  # cp -a -t "${pkgdir}/usr/local/zed" resources

  # Install cmake files
  install -Dm644 "zed-config.cmake" "${pkgdir}/usr/local/zed/zed-config.cmake"
  install -Dm644 "zed-config-version.cmake" "${pkgdir}/usr/local/zed/zed-config-version.cmake"

  # Install Python API script
  install -Dm755 "get_python_api.py" "${pkgdir}/usr/local/zed/get_python_api.py"

  # Install Python API script
  install -Dm755 "${srcdir}/zed_download_ai_models" "${pkgdir}/usr/local/bin/zed_download_ai_models"

  # Install tools
  cp -a -t "${pkgdir}/usr/local/zed" tools

  # Create symlinks for tools
  find "${pkgdir}/usr/local/zed/tools/" -type f -executable | while read tool_exe; do
      name="$(basename $tool_exe)"
      ln -s "/usr/local/zed/tools/$name" "${pkgdir}/usr/local/bin/$(basename $tool_exe)"
  done

  # Install samples if available (optional)
  cp -a -t "${pkgdir}/usr/local/zed" samples

  # Install udev rules
  install -Dm644 "99-slabs.rules" "${pkgdir}/etc/udev/rules.d/99-slabs.rules"

  # Create and install ld.so.conf.d file
  echo "/usr/local/zed/lib" > "${srcdir}/zed.conf"
  install -Dm644 "${srcdir}/zed.conf" "${pkgdir}/etc/ld.so.conf.d/zed.conf"

  # Install ZEDMediaServer service (if available)
  if [ "${CARCH}" = "arm64" ] && [ -f "zed_media_server_cli.service" ]; then
      install -Dm644 "zed_media_server_cli.service" "${pkgdir}/etc/systemd/system/zed_media_server_cli.service"
  fi

  # Create the doc directory
  cp -a -t "${pkgdir}/usr/local/zed" doc

  # Note: Python API installation will be handled by the get_python_api.py script
  # which users can run after installation
}
