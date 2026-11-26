FROM docker.io/anaconda/miniconda:26.3.2@sha256:95b6476ce5d6ef79b7e1f2d109e827a1b9ad1cd0dfaf3fa0c03aea1ce40e1938

RUN <<'APT'
set -eu
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates gcc-12 gfortran-12 git make perl sudo tmux vim \
    openssh-client openssh-server \
    libblas-dev libbz2-dev libeccodes-dev libeccodes-tools liblapack-dev \
    libnetcdf-dev libnetcdff-dev netcdf-bin \
    libopenmpi-dev openmpi-bin libpnetcdf-dev pnetcdf-bin \
    libproj-dev proj-bin
for tool in cpp gcc gcc-ar gcc-nm gcc-ranlib gfortran; do
    ln -s "/usr/bin/${tool}-12" "/usr/local/bin/$tool"
done
ln -s gcc /usr/local/bin/cc
rm -rf /var/lib/apt/lists/* /var/cache/apt/*
rm -f /etc/ssh/ssh_host_*
APT

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
