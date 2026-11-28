FROM docker.io/anaconda/miniconda:26.3.2@sha256:95b6476ce5d6ef79b7e1f2d109e827a1b9ad1cd0dfaf3fa0c03aea1ce40e1938

RUN <<'APT'
set -eu
if [ ! -s /etc/ssl/certs/ca-certificates.crt ]; then
    apt-get update --error-on=any
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates
fi

# Keep the inherited Debian security source and archive signing key.
sed -i -E 's|^(URIs:[[:blank:]]+)https?://deb\.debian\.org/debian/?[[:blank:]]*$|\1https://mirrors.tuna.tsinghua.edu.cn/debian|' \
    /etc/apt/sources.list.d/debian.sources
apt-get update --error-on=any
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl file git make perl ripgrep rsync sudo tmux unzip vim wget \
    cmake fortran-language-server g++-12 gcc-12 gdb gfortran-12 ninja-build pkgconf \
    openssh-client openssh-server \
    libblas-dev libbz2-dev libeccodes-dev libeccodes-tools liblapack-dev \
    libnetcdf-dev libnetcdff-dev netcdf-bin \
    libopenmpi-dev openmpi-bin libpnetcdf-dev pnetcdf-bin \
    libproj-dev proj-bin
for tool in cpp g++ gcc gcc-ar gcc-nm gcc-ranlib gfortran; do
    ln -s "/usr/bin/${tool}-12" "/usr/local/bin/$tool"
done
ln -s gcc /usr/local/bin/cc
ln -s g++ /usr/local/bin/c++
rm -rf /var/lib/apt/lists/* /var/cache/apt/*
rm -f /etc/ssh/ssh_host_*
APT

RUN <<'CONDA'
set -eu
umask 022
install -d -m 0755 /etc/conda /etc/conda/condarc.d
cat > /etc/conda/condarc.d/silam-mirrors.yaml <<'CONDA_MIRRORS'
channels: [defaults]
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
CONDA_MIRRORS
CONDA

RUN <<'INSTALL_FPM'
set -eu
fpm_version=0.14.0
fpm_sha256=8dbc48ce5491cb862cfc1ec8740dcb2da0ec1555db079ace31a01b3a6e6f3437
fpm_tmp_dir=$(mktemp -d)
trap 'rm -rf "$fpm_tmp_dir"' EXIT

curl --fail --silent --show-error --location --retry 3 --output "$fpm_tmp_dir/fpm" \
    "https://github.com/fortran-lang/fpm/releases/download/v${fpm_version}/fpm-${fpm_version}-linux-x86_64-gcc-14"
printf '%s  %s\n' "$fpm_sha256" "$fpm_tmp_dir/fpm" | sha256sum --check
install -m 0755 "$fpm_tmp_dir/fpm" /usr/local/bin/fpm
INSTALL_FPM

RUN <<'FORTRAN_MODULES'
set -eu
grib_api_module=$(dpkg-query -L libeccodes-dev | grep '/grib_api\.mod$')
pnetcdf_module=$(dpkg-query -L libpnetcdf-dev | grep '/pnetcdf\.mod$')
ln -s "$grib_api_module" "$pnetcdf_module" /usr/include/
FORTRAN_MODULES

RUN <<'SSH'
set -eu
conda_dir=/opt/miniconda3
cat > /etc/profile.d/conda-path.sh <<PROFILE
export PATH="${conda_dir}/bin:\$PATH"
PROFILE
cat > /etc/ssh/sshd_config.silam <<SSHD_CONFIG
HostKey /var/lib/sshd/ssh_host_rsa_key
HostKey /var/lib/sshd/ssh_host_ecdsa_key
HostKey /var/lib/sshd/ssh_host_ed25519_key
PidFile /run/sshd/sshd.pid
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
PermitRootLogin no
KbdInteractiveAuthentication no
UsePAM yes
SetEnv PATH=${conda_dir}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Subsystem sftp internal-sftp
SSHD_CONFIG
cat >> /etc/default/ssh <<'SSH_DEFAULTS'

# Generate missing host keys before the Debian SSH service starts.
case "${1:-}" in
    start|restart)
        /usr/bin/ssh-keygen -A || exit $?
        ;;
esac
SSH_DEFAULTS
SSH

COPY --chmod=0755 <<'START_SSHD' /usr/local/sbin/start-sshd
#!/bin/sh
set -eu

keygen_prefix=/run/sshd/keygen
install -d -m 0755 /run/sshd "$keygen_prefix/etc"
host_key_dir=/var/lib/sshd
install -d -m 0700 "$host_key_dir"
ln -sfT "$host_key_dir" "$keygen_prefix/etc/ssh"
flock "$host_key_dir" ssh-keygen -A -f "$keygen_prefix"

exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config.silam
START_SSHD

EXPOSE 22
CMD ["/usr/local/sbin/start-sshd"]
