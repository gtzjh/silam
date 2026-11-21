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
AuthorizedKeysFile /run/sshd/authorized_keys
PidFile /run/sshd/sshd.pid
PermitRootLogin no
KbdInteractiveAuthentication no
UsePAM yes
SetEnv PATH=${conda_dir}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Subsystem sftp internal-sftp
SSHD_CONFIG
# PAM compares account names literally and checks both password and public-key sessions.
printf '%s\n' 'account requisite pam_listfile.so item=user sense=allow file=/run/sshd/allowed-user onerr=fail' >> /etc/pam.d/sshd
SSH

COPY --chmod=0755 <<'START_SSHD' /usr/local/sbin/start-sshd
#!/bin/sh
set -eu
ssh_user=${SILAM_SSH_USER:?Set SILAM_SSH_USER to the SSH login name}

# Mount the password as one line and the public keys in authorized_keys format.
password_file=/run/secrets/ssh_password
public_keys_file=/run/secrets/ssh_authorized_keys
ssh_password=
if [ -f "$password_file" ]; then
    ssh_password=$(head -n 1 "$password_file")
fi
public_key_auth=no
if [ -f "$public_keys_file" ] && [ -s "$public_keys_file" ]; then
    public_key_auth=yes
fi
if [ -z "$ssh_password" ] && [ "$public_key_auth" = no ]; then
    printf '%s\n' 'Mount an SSH password at /run/secrets/ssh_password or public keys at /run/secrets/ssh_authorized_keys.' >&2
    exit 1
fi

lookup_account() {
    perl -e '
        my ($name, undef, $uid) = getpwnam($ARGV[0]);
        exit 1 unless defined $name;
        print "$name:$uid\n";
    ' -- "$1"
}
if ! account=$(lookup_account "$ssh_user"); then
    useradd --create-home --user-group --shell /bin/bash -- "$ssh_user"
    account=$(lookup_account "$ssh_user")
fi
ssh_user=${account%%:*}
uid=${account#*:}
uid_min=$(awk '$1 == "UID_MIN" { print $2; exit }' /etc/login.defs)
uid_max=$(awk '$1 == "UID_MAX" { print $2; exit }' /etc/login.defs)
if [ "$uid" -lt "$uid_min" ] || [ "$uid" -gt "$uid_max" ]; then
    printf '%s\n' 'SILAM_SSH_USER must be a regular account.' >&2
    exit 1
fi

password_auth=no
if [ -n "$ssh_password" ]; then
    printf '%s:%s\n' "$ssh_user" "$ssh_password" | chpasswd
    unset ssh_password
    password_auth=yes
fi

keygen_prefix=/run/sshd/keygen
install -d -m 0755 /run/sshd "$keygen_prefix/etc"
(umask 077; printf '%s\n' "$ssh_user" > /run/sshd/allowed-user)
if [ "$public_key_auth" = yes ]; then
    install -m 0644 "$public_keys_file" /run/sshd/authorized_keys
fi
# Keep the existing key filenames in the named volume while using ssh-keygen's defaults.
host_key_dir=/var/lib/sshd
install -d -m 0700 "$host_key_dir"
ln -sfT "$host_key_dir" "$keygen_prefix/etc/ssh"
flock "$host_key_dir" ssh-keygen -A -f "$keygen_prefix"

exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config.silam \
    -o "PasswordAuthentication=$password_auth" \
    -o "PubkeyAuthentication=$public_key_auth"
START_SSHD

EXPOSE 22
CMD ["/usr/local/sbin/start-sshd"]
