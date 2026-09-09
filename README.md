# ServerBox plugins

The official plugin repository for [ServerBox](https://github.com/lollipopkit/flutter_server_box).

It is in the app by default. To add it back, or to add it to another client, the
address is the repository itself:

```
https://github.com/lollipopkit/serverbox-plugins
```

## Layout

```
repo.toml                              schema, name
plugins/app/serverbox/diskusage.toml   one file per plugin
plugins/app/serverbox/ports.toml
plugins/app/serverbox/scheduled.toml
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

## How a client reads it

One request for a tarball of the latest tree —
`https://github.com/lollipopkit/serverbox-plugins/archive/HEAD.tar.gz`, which is
what the app builds from the address above. No git client. The package is then
fetched from the `url` its file named, which for these is a release of this same
repository.

`repo.toml` is what says a tarball is a plugin repository at all. It announces a
schema, and a client that reads an older one refuses the whole repository rather
than half of it — a field it does not know about may be the one that decides
something.

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

Free and open-source plugins only, as the app's F-Droid build depends on
(`NonFreeAddons`). A plugin has to say what it does in its manifest, ask for the
permissions it actually uses, and carry its own tests.

Anyone can serve their own repository — the app takes any repository address over
HTTPS — so nothing here is a gate on what can be written, only on what this
repository vouches for.

## Publishing

The tooling is in the app's repository, in
[`packages/plugin-tools`](https://github.com/lollipopkit/flutter_server_box/tree/main/packages/plugin-tools).
From a checkout of it, with this repository cloned beside it:

```sh
scripts/publish-plugins.sh
```

That packs every plugin, creates a release here for each new version, writes each
plugin's file with the digests it computed, commits and pushes, and then fetches
this repository the way a client does and checks every version in it against what
the files say.

**The releases go up before the files that name them.** A file pointing at an
address that 404s is broken for everybody who reads it; a release nothing lists
yet is invisible and harmless. An existing release is left alone rather than
re-uploaded — its tag already names that version.

Two rules the generator enforces:

- **a plugin's file is merged into, never replaced** — the reason is the several
  versions above;
- **republishing a version with different bytes is refused.** Nothing breaks the
  instant it happens, but a version number that no longer identifies bytes makes
  every other check meaningless. Bump the version instead.

## License

`repo.toml`, the plugin files and this README: MIT. Each plugin carries its own
license, named in its manifest and in its file here.
