# ServerBox plugins and themes

The official plugin and theme repository for
[ServerBox](https://github.com/lollipopkit/flutter_server_box).

It is in the app by default. To add it back, or to add it to another client, the
address is the repository itself:

```
https://github.com/lollipopkit/serverbox-plugins
```

**One repository serves both kinds.** A client reads the section it knows and
skips the rest, so `themes/` and `plugins/` sit in one tree, and a client that
has not been taught about themes reads this repository as it always did. That is
why the address is a repository rather than a kind: what it offers is whatever
its tree holds.

## Layout

```
repo.toml                              schema, name
plugins/app/serverbox/diskusage.toml   one file per plugin
plugins/app/serverbox/ports.toml
plugins/app/serverbox/scheduled.toml
themes/serverbox.aurora.toml           one file per theme
themes/serverbox.ember.toml
themes/serverbox.aurora/manifest.toml  the theme itself, packed on publish
themes/serverbox.ember/manifest.toml
```

**Shaped after a Homebrew tap.** A tap is a git repository with one file per
formula, each naming where the thing itself lives; a client fetches the tree and
reads what is in it. So there is no single document that every publish rewrites,
a pull request touches exactly the plugin it is about, and **nothing in the tree
is binary** — the packages are releases, one per plugin version.

**The path is the id.** A plugin id is reverse-DNS, so its first two parts are
the publisher and the rest is the plugin: `app.serverbox.diskusage` lives at
`plugins/app/serverbox/diskusage.toml`. That shards the directory the way
Homebrew's `Formula/a/…` does while keeping one publisher's plugins together,
which a first-letter shard would not. A file whose path and `id` disagree is
refused rather than read — that is what a copy into the wrong folder looks like.

A plugin file lists **every version still on offer**, newest first:

```toml
id = "app.serverbox.diskusage"
name = "Disk usage"
description = "Where the space went, one directory at a time."
license = "MIT"

[[version]]
version = "1.0.1"
abi = 2
url = "https://github.com/lollipopkit/serverbox-plugins/releases/download/app.serverbox.diskusage-1.0.1/app.serverbox.diskusage-1.0.1.sbp"
sha256 = "4e310109…"
size = 17643
```

More than one, because one repository serves apps of different ages: each
installs the newest release its own **ABI** can run, and dropping the older ones
would make a plugin vanish from an older app rather than offer it a version it
can use.

A version names either an absolute https `url` or a `path` inside the repository
— never both. These use `url`, pointing at **this repository's own releases: one
per plugin version**, tagged `<id>-<version>`. So a tag identifies exactly one
set of bytes and keeps its URL for as long as a file lists that version, a
version can be withdrawn by deleting one release without touching another, and
nothing here is ever replaced — different bytes mean a different version.

`path` is there for a repository that would rather carry its packages in its own
tree.

## Themes

A theme file sits at `themes/<id>.toml` and is the same shape as a plugin's:
identity, then every version still on offer.

```toml
id = "serverbox.aurora"
name = "Aurora"
description = "A purple palette, light and dark."
homepage = "https://github.com/lollipopkit/serverbox-plugins"
license = "MIT"

[[version]]
version = "1.0.0"
schema_min = 1
schema_max = 1
url = "https://github.com/lollipopkit/serverbox-plugins/releases/download/serverbox.aurora-1.0.0/serverbox.aurora-1.0.0.fsbt"
sha256 = "5df8066215fa6ca4b5567fe8395a45141e511d82782e8ce6ae2703f45f7fdc86"
size = 3661
```

The id is the one the theme's own manifest carries, so `serverbox.aurora` is
`themes/serverbox.aurora.toml` and its package says `id = "serverbox.aurora"` —
one spelling, checked on both sides. The folder beside it,
`themes/serverbox.aurora/`, is the theme itself, and it is not what a client
reads; it is what `scripts/publish-themes.sh` packs.

`schema_min` and `schema_max` are the manifest schema range the package carries,
in place of the plugin's `abi`. They are why a theme file also lists every
version: an app installs **the newest version it can read**, and dropping the
older ones would make a theme vanish from an older app rather than offer it a
version it can run. The app picks by version number, so the order in the file
means nothing — this repository appends.

`themes/serverbox.aurora` is the reference theme, listing every supported field
at what it defaults to. `themes/serverbox.ember` is the minimal one: identity,
schema and a seed.

## How a client reads it

One request for a tarball of the latest tree —
`https://github.com/lollipopkit/serverbox-plugins/archive/HEAD.tar.gz`, which is
what the app builds from the address above. No git client. The package is then
fetched from the `url` its file named, which for these is a release of this same
repository.

`repo.toml` is what says a tarball is a repository at all. It announces a
schema, and a client that reads an older one refuses the whole repository rather
than half of it — a field it does not know about may be the one that decides
something.

That one request carries both kinds, and each client reads its own section: a
plugin file is found under `plugins/`, a theme file under `themes/`, and a
section a client has no reader for is skipped. A theme names a `.fsbt` fetched
the same way a plugin's `.sbp` is, and this repository's own releases carry
both.

## What a checksum here does and does not buy

**There are no signatures.** Each version names the SHA-256 of its package and
the app verifies the bytes against it. The file and the package are fetched
separately — the tree in one request, the package from a release — so **that
digest is what binds an address to a particular set of bytes**, the same thing a
Homebrew formula's `sha256` does for the tarball it points at.

What it does not buy: **whoever controls this repository controls what runs**,
because they choose both the address and the digest. TLS and this repository's
owner are the trust anchor, and the checksum is not a substitute for either.

A version listed with no checksum is refused by the app unless the user is told
and says otherwise; every version here has one. A checksum that does not *match*
is never something the user is asked about: it means one of the file and the
package was changed after the other, and there is no version of that worth
proceeding through.

## What is accepted

Free and open-source plugins and themes only, as the app's F-Droid build depends
on (`NonFreeAddons`). A plugin has to say what it does in its manifest, ask for
the permissions it actually uses, and carry its own tests. A theme has to say
which modes it supports and stay within the package format's limits.

Anyone can serve their own repository — the app takes any repository address over
HTTPS — so nothing here is a gate on what can be written, only on what this
repository vouches for.

## Publishing

**A plugin's tooling is in the app's repository, in
[`packages/plugin-tools`](https://github.com/lollipopkit/flutter_server_box/tree/main/packages/plugin-tools)** —
`bin/repo.ts` packs a plugin, creates its release here, writes its file with the
digest, and `bin/verify.ts` fetches this repository the way a client does and
checks every version in it against what the files say.

**A theme's tooling is `scripts/publish-themes.sh` here**, because a theme shares
nothing with a plugin past this layout: a `.fsbt` is a ZIP of its folder and its
manifest is read by an app, where a `.sbp` is a bundled module that has to be
compiled first. So it needs `zip`, `shasum` and an authenticated `gh`, and no
checkout of anything else:

```sh
scripts/publish-themes.sh serverbox.aurora 1.0.1
```

That packs `themes/serverbox.aurora/` into `serverbox.aurora-1.0.1.fsbt`,
creates the release tagged `serverbox.aurora-1.0.1` here, and appends the version
to `themes/serverbox.aurora.toml` with the digest and size it computed.

**The releases go up before the files that name them.** A file pointing at an
address that 404s is broken for everybody who reads it; a release nothing lists
yet is invisible and harmless. An existing release is left alone rather than
re-uploaded — its tag already names that version.

Two rules the tooling enforces, on both kinds:

- **a file is merged into, never replaced** — the reason is the several versions
  above;
- **republishing a version with different bytes is refused.** Nothing breaks the
  instant it happens, but a version number that no longer identifies bytes makes
  every other check meaningless. Bump the version instead.

Nothing else reads what was actually served, so the app's own test does, opt-in
and over the network:

```sh
SBM_E2E_THEME_CATALOG=https://raw.githubusercontent.com/lollipopkit/flutter_server_box/main/assets/catalog/repos.toml \
flutter test test/unit/theme_repo_live_test.dart
```

## License

`repo.toml`, the plugin and theme files, `scripts/` and this README: MIT. Each
plugin and theme carries its own license, named in its manifest and in its file
here.
