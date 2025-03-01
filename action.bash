#!/usr/bin/env bash
set -euo pipefail

test "${RUNNER_DEBUG:-}" != '1' || set -x

function group {
	printf '::group::%s\n' "$*"
}

function endgroup {
	printf '::endgroup::\n'
}

function die {
	printf '::error::%s\n' "$*"
	exit 1
}

group 'Do preflight checks'
{
	test ! -e /nix -o -w /nix ||
		die "failed to set up Lix: /nix exists but isn't writable"

	: "${XDG_CONFIG_HOME:="$HOME/.config"}"
}
endgroup

group 'Mount /nix'
{
	test -e /nix || case "$RUNNER_OS" in
	Linux)
		sudo install -d -o "$USER" /nix
		! "$LIX_ON_TMPFS" ||
			sudo mount -t tmpfs -o "size=90%,mode=0755,uid=$UID,gid=$(id -g)" tmpfs /nix
		;;
	macOS)
		sudo tee -a /etc/synthetic.conf <<<$'nix\nrun\tprivate/var/run\n' >/dev/null
		sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t || :
		test -L /run || die "failed to set up Lix: apfs.util couldn't symlink /run"
		disk=$(stat -f %Sd / | sed -e 's/s[0-9]*$//')
		sudo diskutil apfs addVolume "$disk" APFS nix -mountpoint /nix
		sudo mdutil -i off /nix
		sudo chown "$USER" /nix
		;;
	*)
		die "failed to set up Lix: this action doesn't support $RUNNER_OS runners (yet? :)"
		;;
	esac
}
endgroup

group 'Install Lix store'
{
	test -f "$LIX_STORE_FILE" || {
		mkdir -p "${LIX_STORE_FILE%/*}"
		gh release download "v$(cat VERSION)" \
			-O "$LIX_STORE_FILE" \
			-R "$GH_ACTION_REPOSITORY" \
			-p "${LIX_STORE_FILE##*/}"
	}
	gh attestation verify "$LIX_STORE_FILE" \
		--{,signer-}repo="$GH_ACTION_REPOSITORY"
	rm -rf /nix/var/gha
	test "$RUNNER_OS" != 'macOS' && tar='tar' || tar='gtar'
	$tar -ax --skip-old-files -C /nix --strip-components 1 <"$LIX_STORE_FILE"
}
endgroup

group 'Synthesize nix.conf'
{
	install -d -o "$USER" "$XDG_CONFIG_HOME/nix"
	cat <<EOF >>"$XDG_CONFIG_HOME/nix/nix.conf"
accept-flake-config = true
access-tokens = ${GITHUB_SERVER_URL#*://}=$GITHUB_TOKEN
experimental-features = nix-command flakes
include $RUNNER_TEMP/nix.conf
EOF
	cat <<<"${NIX_CONF:-}" >"$RUNNER_TEMP/nix.conf"
}
endgroup

group 'Install Lix'
{
	lix_path=$(readlink /nix/var/gha/lix)
	"$lix_path/bin/nix-store" --load-db </nix/var/gha/registration
	# shellcheck source=/dev/null
	MANPATH='' source "$lix_path/etc/profile.d/nix.sh"
	! test -z "${NIX_SSL_CERT_FILE:-}" -a -e /etc/ssl/cert.pem ||
		NIX_SSL_CERT_FILE=/etc/ssl/cert.pem
	"$lix_path/bin/nix-env" --install "$lix_path"
}
endgroup

group 'Set up environment'
{
	cat <<EOF >>"$GITHUB_ENV"
NIX_PROFILES=/nix/var/nix/profiles/default $HOME/.nix-profile
NIX_USER_PROFILE_DIR=/nix/var/nix/profiles/per-user/$USER
NIX_SSL_CERT_FILE=$NIX_SSL_CERT_FILE
EOF
	cat <<EOF >>"$GITHUB_PATH"
$HOME/.nix-profile/bin
EOF
}
endgroup
