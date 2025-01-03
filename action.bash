#!/usr/bin/env bash
set -euo pipefail

group() {
	printf "::group::%s\n" "$*"
}

endgroup() {
	printf "::endgroup::\n"
}

die() {
	printf "::error::%s\n" "$*"
	exit 1
}

group 'Preflight checks'
{
	test ! -e /nix -o -w /nix ||
		die "failed to set up Lix: /nix exists but isn't writable"

	: "${GITHUB_ACTION_REPOSITORY:="$GITHUB_REPOSITORY"}"
	: "${XDG_CONFIG_HOME:="$HOME/.config"}"
}
endgroup

group 'Mount /nix'
{
	test -e /nix || case "$RUNNER_OS" in
	Linux)
		sudo install -d -o "$USER" /nix
		$LIX_ON_DISK || sudo mount -t tmpfs -o "size=90%,mode=0755,uid=$UID,gid=$(id -g)" tmpfs /nix
		;;
	macOS)
		sudo tee -a /etc/synthetic.conf <<<$'nix\nrun\tprivate/var/run\n'
		sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t || :
		test -L /run || die "failed to set up Lix: apfs.util couldn't symlink /run"
		stat -f %Sd / |
			sed -e 's/s[0-9]*$//' |
			xargs -I{} -- sudo diskutil apfs addVolume {} APFS nix -mountpoint /nix
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
	pushd "$LIX_STORES_DIR"
	# x-release-please-start-version
	test -f "$LIX_STORE_FILE" ||
		gh release download "v0.3.0" \
			--output "$LIX_STORE_FILE" \
			--pattern "$LIX_STORE_FILE" \
			--repo "$GITHUB_ACTION_REPOSITORY"
	# x-release-please-end
	gh attestation verify "$LIX_STORE_FILE" --{,signer-}repo="$GITHUB_ACTION_REPOSITORY"
	rm -rf "/nix/var/gha"
	test "$RUNNER_OS" != macOS && tar=tar || tar=gtar
	$tar --auto-compress --extract --skip-old-files --directory /nix --strip-components 1 <"$LIX_STORE_FILE"
	popd
}
endgroup

group 'Synthesize nix.conf'
{
	mkdir -p "$XDG_CONFIG_HOME/nix"
	tee -a "$XDG_CONFIG_HOME/nix/nix.conf" <<EOF
accept-flake-config = true
access-tokens = ${GITHUB_SERVER_URL#*://}=$GITHUB_TOKEN
experimental-features = nix-command flakes
${NIX_CONF:+"include $XDG_CONFIG_HOME/nix/$GITHUB_REPOSITORY_ID.conf"}
EOF
	test -z "${NIX_CONF:-}" ||
		tee "$XDG_CONFIG_HOME/nix/$GITHUB_REPOSITORY_ID.conf" <<<"$NIX_CONF"
}
endgroup

group 'Install Lix'
{
	CDPATH='' cd "$(readlink /nix/var/gha/lix)"
	./bin/nix-store --load-db </nix/var/gha/registration
	# shellcheck source=/dev/null
	MANPATH='' . ./etc/profile.d/nix.sh
	test -n "${NIX_SSL_CERT_FILE:-}" -o ! -e /etc/ssl/cert.pem ||
		NIX_SSL_CERT_FILE=/etc/ssl/cert.pem
	./bin/nix-env --install "$PWD"
	tee -a "$GITHUB_PATH" <<<"$HOME/.nix-profile/bin"
	tee -a "$GITHUB_ENV" <<EOF
NIX_PROFILES=/nix/var/nix/profiles/default $HOME/.nix-profile
NIX_USER_PROFILE_DIR=/nix/var/nix/profiles/per-user/$USER
NIX_SSL_CERT_FILE=$NIX_SSL_CERT_FILE
EOF
}
endgroup
