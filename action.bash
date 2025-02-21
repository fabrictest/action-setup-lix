#!/usr/bin/env bash
set -euo pipefail

test -z "${RUNNER_DEBUG:-}" || set -x

function group {
	printf "::group::%s\n" "$*"
}

function endgroup {
	printf "::endgroup::\n"
}

function die {
	printf "::error::%s\n" "$*"
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
	test -f "$LIX_STORE_FILE" ||
		gh release download v"$(cat "$ACTION_PATH"/VERSION)" \
			--output "$LIX_STORE_FILE" \
			--pattern "${LIX_STORE_FILE##*/}" \
			--repo "$ACTION_REPOSITORY"
	gh attestation verify "$LIX_STORE_FILE" --{,signer-}repo="$ACTION_REPOSITORY"
	rm -rf /nix/var/gha
	test "$RUNNER_OS" != macOS && tar=tar || tar=gtar
	$tar --auto-compress --extract --skip-old-files --directory /nix --strip-components 1 <"$LIX_STORE_FILE"
	rm -f "$LIX_STORE_FILE"
}
endgroup

group 'Synthesize nix.conf'
{
	mkdir -p "$XDG_CONFIG_HOME"/nix
	pushd "$XDG_CONFIG_HOME"/nix
	cat <<EOF >>nix.conf
accept-flake-config = true
access-tokens = ${GITHUB_SERVER_URL#*://}=$GITHUB_TOKEN
experimental-features = nix-command flakes
include $PWD/${GITHUB_REPOSITORY//\//_}.conf
EOF
	cat <<<"$NIX_CONF" >"${GITHUB_REPOSITORY//\//_}".conf
	popd
}
endgroup

group 'Install Lix'
{
	pushd "$(readlink /nix/var/gha/lix)"
	./bin/nix-store --load-db </nix/var/gha/registration
	# shellcheck source=/dev/null
	MANPATH='' . ./etc/profile.d/nix.sh
	test -n "${NIX_SSL_CERT_FILE:-}" -o ! -e /etc/ssl/cert.pem ||
		NIX_SSL_CERT_FILE=/etc/ssl/cert.pem
	./bin/nix-env --install "$PWD"
	popd
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
