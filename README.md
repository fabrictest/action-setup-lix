# action-setup-lix

This GitHub Action installs [Lix](https://lix.systems/) in single-user mode,
and adds almost no time at all to your workflow's running time.

The Lix installation is deterministic – for a given
release of this action the resulting Lix setup will always be identical, no
matter when you run the action.

- Supports all Linux and MacOS runners

- Single-user installation (no `nix-daemon`)

- Installs in ≈ 1 second on Linux, ≈ 5 seconds on MacOS

- Allows selecting Lix version via the `lix_version` input

- Allows specifying `nix.conf` contents via the `nix_conf` input

## Details

The main motivation behind this action is to install Lix as quickly as possible
in your GitHub workflow.

To make this action as quick as possible, the installation is minimal: no
nix-daemon, no nix channels and no `NIX_PATH`. The nix store (`/nix/store`) is
owned by the unprivileged runner user.

The action provides you with a fully working Lix setup, but since no `NIX_PATH`
or channels are setup you need to handle this on your own. Lix Flakes is great
for this, and works perfectly with this action (see below).

## Inputs

TODO: Generate inputs table.

## Usage

The following workflow installs Lix and then just runs
`nix-build --version`:

<!-- [$ examples-minimal.yaml](.github/workflows/examples-minimal.yaml) as yaml -->

```yaml
---
name: Examples / Minimal
on: workflow_dispatch
permissions: {}
jobs:
  example:
    runs-on: ubuntu-latest
    steps:
      - uses: fabrictest/action-setup-lix@d5d7d9aa579140ff7b9b64c02766ed55bb80c3f8 # v0.15.0
      - run: nix build --version
```

![examples-minimal](assets/img/examples-minimal.webp)

### Flakes

These settings are always set by default:

```conf
experimental-features = nix-command flakes
accept-flake-config = true
```

<!-- [$ examples-flakes.yaml](.github/workflows/examples-flakes.yaml) as yaml -->

```yaml
---
name: Examples / Flakes
on: workflow_dispatch
permissions: {}
jobs:
  example:
    runs-on: ubuntu-latest
    steps:
      - uses: fabrictest/action-setup-lix@d5d7d9aa579140ff7b9b64c02766ed55bb80c3f8 # v0.15.0
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
        with:
          repository: fabrictest/action-setup-lix
          persist-credentials: false
      - run: nix build ./examples/flakes
      - run: ./result/bin/hello
```

![examples-flakes](assets/img/examples-flakes.webp)

You can see the flake definition for the above example in
[examples/flakes/flake.nix](examples/flakes/flake.nix).

### Using specific Lix versions locally

Locally, you can use this repository's Lix flake to build or run any of the
versions of Lix that this action supports. This is very convenient if you
quickly need to compare the behavior between different Lix versions.

Build a specific version of Lix like this (requires you to use a version of Lix
that supports flakes):

<!-- renovate: datasource=github-tags depName=lix-project/lix -->

<!-- `! lix_version=2.91.1` -->

<!-- `! lix_version="${lix_version//./_}"` -->

<!--
```$
echo "nix build github:fabrictest/action-setup-lix#lix-$lix_version >/dev/null"
echo "./result/bin/nix --quiet --version"
``` -->

```
nix build github:fabrictest/action-setup-lix#lix-2_91_1 >/dev/null
./result/bin/nix --quiet --version
```

<!-- `$ nix build --no-write-lock-file .#lix-"$lix_version" >/dev/null && ./result/bin/nix --quiet --version` -->

```
nix (Lix, like Nix) 2.91.1
```

You can also directly run Lix with `nix shell -c`:

<!-- `$ echo "nix shell --no-write-lock-file github:fabrictest/action-setup-lix#lix-$lix_version -c nix --quiet --version"` -->

```
nix shell --no-write-lock-file github:fabrictest/action-setup-lix#lix-2_91_1 -c nix --quiet --version
```

List all available Lix versions with:

<!-- x-release-please-start-version -->

```
nix flake show --all-systems github:fabrictest/action-setup-lix/v0.15.0
```

<!-- x-release-please-end -->

<!-- `$ nix flake show --all-systems --no-write-lock-file github:fabrictest/action-setup-lix | sed -e '1 s|[^/]*$|…|'` -->

```
github:fabrictest/action-setup-lix/…
├───__functor: unknown
├───__std: unknown
├───aarch64-darwin: unknown
├───aarch64-linux: unknown
├───devShells
│   ├───aarch64-darwin
│   │   └───default: development environment 'action-setup-lix'
│   ├───aarch64-linux
│   │   └───default: development environment 'action-setup-lix'
│   ├───x86_64-darwin
│   │   └───default: development environment 'action-setup-lix'
│   └───x86_64-linux
│       └───default: development environment 'action-setup-lix'
├───overlays
│   └───lixPackages: Nixpkgs overlay
├───packages
│   ├───aarch64-darwin
│   │   ├───default: package 'lix-stores'
│   │   ├───lix-2_90_0: package 'lix-2.90.0' - 'Powerful package manager that makes package management reliable and reproducible'
│   │   ├───lix-2_91_1: package 'lix-2.91.1' - 'Powerful package manager that makes package management reliable and reproducible'
│   │   └───lix-stores: package 'lix-stores'
│   ├───aarch64-linux
│   │   ├───default: package 'lix-stores'
│   │   ├───lix-2_90_0: package 'lix-2.90.0' - 'Powerful package manager that makes package management reliable and reproducible'
│   │   ├───lix-2_91_1: package 'lix-2.91.1' - 'Powerful package manager that makes package management reliable and reproducible'
│   │   └───lix-stores: package 'lix-stores'
│   ├───x86_64-darwin
│   │   ├───default: package 'lix-stores'
│   │   ├───lix-2_90_0: package 'lix-2.90.0' - 'Powerful package manager that makes package management reliable and reproducible'
│   │   ├───lix-2_91_1: package 'lix-2.91.1' - 'Powerful package manager that makes package management reliable and reproducible'
│   │   └───lix-stores: package 'lix-stores'
│   └───x86_64-linux
│       ├───default: package 'lix-stores'
│       ├───lix-2_90_0: package 'lix-2.90.0' - 'Powerful package manager that makes package management reliable and reproducible'
│       ├───lix-2_91_1: package 'lix-2.91.1' - 'Powerful package manager that makes package management reliable and reproducible'
│       └───lix-stores: package 'lix-stores'
├───x86_64-darwin: unknown
└───x86_64-linux: unknown
```

If you want to make sure that the version of Lix you're trying to build hasn't
been removed in the latest revision of `action-setup-lix`, you can
specify a specific release of `action-setup-lix` like this:

<!-- x-release-please-start-version -->

<!-- `$ echo "nix build github:fabrictest/action-setup-lix/v0.15.0#lix-$lix_version"` -->

```
nix build github:fabrictest/action-setup-lix/v0.15.0#lix-2_91_1
```

Note that we've added `/v0.15.0` to the flake URL above.

<!-- x-release-please-end -->

# Credits

TODO
