FROM docker.io/library/debian:bookworm-slim@sha256:c67e92c8099ba22853ab4cfda7cfb494d253d6012ca82dee98ba8976772af018

RUN <<'APT'
set -eu
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bzip2 ca-certificates curl gcc gfortran git make nano perl sudo tmux vim wget xz-utils \
    openssh-client openssh-server \
    libblas-dev libbz2-dev libeccodes-dev libeccodes-tools liblapack-dev \
    libnetcdf-dev libnetcdff-dev netcdf-bin \
    libopenmpi-dev openmpi-bin libpnetcdf-dev pnetcdf-bin \
    libproj-dev proj-bin
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/*
# openssh-server's post-install script generates host keys that must be per deployment.
rm -f /etc/ssh/ssh_host_*
APT

RUN <<'TOOLS'
set -eu
work=$(mktemp -d)
cd "$work"

uv_version=0.13.6
uv_package=uv-x86_64-unknown-linux-gnu
curl -fsSL --retry 3 -o uv.tar.gz "https://releases.astral.sh/github/uv/releases/download/${uv_version}/${uv_package}.tar.gz"
printf '%s  %s\n' 'f29c3e94ffabd7e6f3ba521dba169a9b7ec12100bf3257087f0f24f6123f3645' uv.tar.gz | sha256sum -c -
tar -xzf uv.tar.gz
install -m 0755 "${uv_package}/uv" "${uv_package}/uvx" /usr/local/bin/

# uv checks the SHA-256 stored in its 0.13.6 download metadata for the 20261026 build.
# CPython 3.12.16 x86_64 GNU: ce4f6d0a6cfdb3bed6e44c2f9affd85943c76a42e25ad3a259002f31d6fb8a20
export UV_PYTHON_INSTALL_DIR=/opt/uv/python
python_version=cpython-3.12.16-linux-x86_64-gnu
uv --no-cache python install "$python_version" --no-bin
interpreter=$(uv --no-cache python find --managed-python "$python_version")
# Keep the underlying interpreter discoverable when uv ignores the shared venv on PATH.
ln -s "$interpreter" /usr/local/bin/python3.12
uv --no-cache venv --python "$interpreter" /opt/silam-python
cat > requirements.txt <<'PYTHON_PACKAGES'
pip==26.2.2 --hash=sha256:fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70
ruff==0.17.6 --hash=sha256:aa3b08254a732acba246891089a152c47c5733dc36b8ecb76ce8602f8326e5e4
PYTHON_PACKAGES
uv --no-cache pip install --python /opt/silam-python/bin/python --only-binary :all: --require-hashes -r requirements.txt

node_version=24.22.3
curl -fsSL --retry 3 -o node.tar.xz "https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-x64.tar.xz"
printf '%s  %s\n' '4f2b175a6d53a5c617a80dba2676238a0688cef28c6da4eba35c7d844e66fcfb' node.tar.xz | sha256sum -c -
tar -xJf node.tar.xz -C /usr/local --strip-components=1 --no-same-owner
cd /
rm -rf "$work"
TOOLS

ENV PATH=/opt/silam-python/bin:${PATH}

RUN <<'SSH'
set -eu
useradd --create-home --user-group --uid 1000 --shell /bin/bash silam
install -d -m 0755 /run/silam
# Debian login shells initialize PATH in /etc/profile.
cat > /etc/profile.d/silam-python.sh <<'PROFILE'
export PATH="/opt/silam-python/bin:$PATH"
PROFILE
cat > /etc/ssh/sshd_config.silam <<'SSHD_CONFIG'
HostKey /var/lib/silam-sshd/ssh_host_ed25519_key
AuthorizedKeysFile /run/sshd/authorized_keys
PermitRootLogin no
AllowUsers silam
PubkeyAuthentication yes
AuthenticationMethods publickey
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
SetEnv PATH=/opt/silam-python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Subsystem sftp internal-sftp
SSHD_CONFIG
cat > /usr/local/sbin/start-sshd <<'START_SSHD'
#!/bin/sh
set -eu
install -d -m 0755 /run/sshd
install -d -m 0700 /var/lib/silam-sshd
install -m 0644 /run/silam/authorized_keys /run/sshd/authorized_keys
host_key=/var/lib/silam-sshd/ssh_host_ed25519_key
if [ ! -f "$host_key" ]; then
    ssh-keygen -q -t ed25519 -N '' -f "$host_key"
fi
exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config.silam
START_SSHD
chmod 0755 /usr/local/sbin/start-sshd
SSH

EXPOSE 22
USER silam
WORKDIR /home/silam
CMD ["bash"]
