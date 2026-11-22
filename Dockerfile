FROM docker.io/anaconda/miniconda:26.3.2@sha256:95b6476ce5d6ef79b7e1f2d109e827a1b9ad1cd0dfaf3fa0c03aea1ce40e1938

# Build for linux/amd64 with no filesystem context: docker build --platform linux/amd64 - < Dockerfile
RUN <<'APT'
set -eu
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl gcc-12 gfortran-12 git make perl sudo tmux vim wget \
    openssh-client openssh-server \
    libblas-dev libbz2-dev libeccodes-dev libeccodes-tools liblapack-dev \
    libnetcdf-dev libnetcdff-dev netcdf-bin \
    libopenmpi-dev openmpi-bin libpnetcdf-dev pnetcdf-bin \
    libproj-dev proj-bin
# GCC 12 accepts the OpenMP loop bounds in SILAM's MPI build.
for tool in cpp gcc gcc-ar gcc-nm gcc-ranlib gfortran; do
    ln -s "/usr/bin/${tool}-12" "/usr/local/bin/$tool"
done
ln -s gcc /usr/local/bin/cc
rm -rf /var/lib/apt/lists/* /var/cache/apt/*
# openssh-server's post-install script generates host keys that must be per deployment.
rm -f /etc/ssh/ssh_host_*
APT

# SILAM's GNU builds look in /usr/include for Debian's versioned Fortran modules.
RUN <<'FORTRAN_MODULES'
set -eu
grib_api_module=$(dpkg-query -L libeccodes-dev | grep '/grib_api\.mod$')
pnetcdf_module=$(dpkg-query -L libpnetcdf-dev | grep '/pnetcdf\.mod$')
ln -s "$grib_api_module" "$pnetcdf_module" /usr/include/
FORTRAN_MODULES

RUN <<'SSH'
set -eu
conda_dir=/opt/miniconda3
# Debian login shells initialize PATH in /etc/profile.
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
SSH

COPY --chmod=0755 <<'START_SSHD' /usr/local/sbin/start-sshd
#!/bin/sh
set -eu

keygen_prefix=/run/sshd/keygen
install -d -m 0755 /run/sshd "$keygen_prefix/etc"
# Store host keys across container restarts while using ssh-keygen's default filenames.
host_key_dir=/var/lib/sshd
install -d -m 0700 "$host_key_dir"
ln -sfT "$host_key_dir" "$keygen_prefix/etc/ssh"
flock "$host_key_dir" ssh-keygen -A -f "$keygen_prefix"

exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config.silam
START_SSHD

EXPOSE 22
CMD ["/usr/local/sbin/start-sshd"]
