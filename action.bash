#!/usr/bin/env bash
set -euo pipefail

group() {
	printf "::group::%s\n" "$*"
}

endgroup() {
	printf "::endgroup::\n"
}

error() {
	printf "::error::%s\n" "$*"
	exit 1
}

group 'Preflight checks'
	test ! -e /nix -o -w /nix ||
		error "failed to set up Lix: /nix exists but isn't writable"

	: "${GITHUB_ACTION_REPOSITORY:="$GITHUB_REPOSITORY"}"
	: "${XDG_CONFIG_HOME:="$HOME/.config"}"

	: "${OUR_VERSION:=$(head -n1 "$GITHUB_ACTION_PATH/VERSION")}"
	: "${LIX_VERSION:="$LIX_DEFAULT_VERSION"}"
	: "${LIX_SYSTEM:=$(uname -m | sed -e 's/^arm/aarch/g')-$(uname -s | tr '[:upper:]' '[:lower:]')}"
	: "${LIX_STORE_FILE:="${LIX_STORE_TAR_DIR:-"$RUNNER_TEMP"}/lix-$LIX_VERSION-$LIX_SYSTEM.tar.zstd"}"
endgroup

group 'Mount /nix'
	test -e /nix || case "$RUNNER_OS" in
		Linux)
			sudo install -d -o "$USER" /nix
			${LIX_ON_DISK:+:} sudo mount -t tmpfs -o "size=90%,mode=0755,uid=$UID,gid=$(id -g)" tmpfs /nix
			;;
		macOS)
			sudo tee -a /etc/synthetic.conf <<<$'nix\nrun\tprivate/var/run\n'
			sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t || :
			test -L /run ||
				error "failed to set up Lix: apfs.util couldn't symlink /run"
			stat -f %Sd / |
				sed -e 's/s[0-9]*$//' |
				xargs -I{} -- sudo diskutil apfs addVolume {} APFS nix -mountpoint /nix
			sudo mdutil -i off /nix
			sudo chown "$USER" /nix
			;;
		*)
			error "failed to set up Lix: this action doesn't support $RUNNER_OS runners (yet? :)"
			;;
	esac
endgroup

group 'Install Lix store'
	test -f "$LIX_STORE_FILE" ||
		gh release download "v$OUR_VERSION" \
			--output "$LIX_STORE_FILE" \
			--pattern "${LIX_STORE_FILE##*/}" \
			--repo "$GITHUB_ACTION_REPOSITORY"
	gh attestation verify "$LIX_STORE_FILE" --{,signer-}repo="$GITHUB_ACTION_REPOSITORY"
	rm -rf /nix/var/action-setup-lix
	test "$RUNNER_OS" != macOS && tar=tar || tar=gtar
	$tar --auto-compress --extract --skip-old-files --directory /nix --strip-components 1 <"$LIX_STORE_FILE"
endgroup

group 'Synthesize nix.conf'
	mkdir -p "$XDG_CONFIG_HOME/nix"
	tee -a "$XDG_CONFIG_HOME/nix/nix.conf" <<EOF
accept-flake-config = true
access-tokens = ${GITHUB_SERVER_URL#*://}=$GITHUB_TOKEN
experimental-features = nix-command flakes
${NIX_CONF:+"include $XDG_CONFIG_HOME/nix/$GITHUB_REPOSITORY_ID.conf"}
EOF
	test -z "${NIX_CONF:-}" ||
		tee "$XDG_CONFIG_HOME/nix/$GITHUB_REPOSITORY_ID.conf" <<<"$NIX_CONF"
endgroup

group 'Install Lix'
	CDPATH='' cd "$(readlink /nix/var/action-setup-lix/lix)"
	./bin/nix-store --load-db </nix/var/action-setup-lix/registration
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
endgroup
