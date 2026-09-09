# ServerBox plugins

The official plugin repository for [ServerBox](https://github.com/lollipopkit/flutter_server_box).

Add it in the app under **Settings → Plugins → Plugin store**; it is there by
default:

```
https://github.com/lollipopkit/serverbox-plugins/releases/download/packages/index.json
```

## What is in here

`index.json` — the list of plugins, every version of each, and the SHA-256 of
each package. That is the whole of the repository's content; the `.sbp` packages
themselves are **release assets** under the `packages` tag, so every published
file keeps one URL forever and nothing here grows a binary in its history.

The plugins are built from
[`packages/plugins/`](https://github.com/lollipopkit/flutter_server_box/tree/main/packages/plugins)
in the app's own repository. They live there because that is where the SDK and
their tests are; they are released from here because a plugin's release cadence
is not the app's — the point of a repository is that fixing a plugin does not
mean shipping an app.

## What a checksum here does and does not buy

**There are no signatures.** The index is fetched over HTTPS and names, for each
version, the SHA-256 of the package; the app verifies the bytes it downloaded
against that. So:

- a mirror, a CDN, or anything between the index and a package can be swapped
  and the change is caught, because it did not write the index;
- **whoever controls this index controls what runs**, because they choose both
  the URL and the digest. TLS and this repository's owner are the trust anchor,
  and the checksum is not a substitute for either.

A version listed with no checksum is therefore not a small thing: it is the case
where none of the above holds. The app refuses one by default and installs it
only after telling the user what that means. **Every version published here has
a checksum**, computed from the bytes that were uploaded.

A checksum that does not *match* is never something the user is asked about. It
means one of the index and the file was changed after the other, and there is no
version of that worth proceeding through.

## What is accepted

Free and open-source plugins only, as the app's F-Droid build depends on
(`NonFreeAddons`). A plugin here has to say what it does in its manifest, ask
for the permissions it actually uses, and carry its own tests.

Anyone can serve their own repository — the app takes any `index.json` URL over
HTTPS — so nothing here is a gate on what can be written, only on what this
repository vouches for.

## How a release is made

The tooling is in the app's repository, in
[`packages/plugin-tools`](https://github.com/lollipopkit/flutter_server_box/tree/main/packages/plugin-tools).
From a checkout of it, with this repository cloned beside it:

```sh
scripts/publish-plugins.sh
```

That packs every plugin, merges them into this repository's `index.json`
computing each digest, commits and pushes it, uploads the packages and the
index, and then reads back what was served and checks it against the index.

**The order is the point, and it is why this is a script rather than three
commands.** Publishing is three things — the packages, the index as a release
asset, and the index in this repository's history — and the one worth designing
against going missing is the third: the next run merges into an `index.json`
that does not know about the version just published, and drops it. So the index
is committed first and the assets go up after. Getting stuck between the two
leaves an index naming a URL that 404s, which anyone can see and which running
it again fixes.

Two rules the generator enforces, both worth knowing:

- **an existing index is merged into, never replaced.** The reason it lists
  several versions of a plugin is that one index serves apps of different ages,
  and each installs the newest release its own ABI can run. Publishing only
  what is in `dist/` today would drop the older ones, and an older app would see
  the plugin vanish rather than see a version it can use.
- **republishing a version with different bytes is refused.** Nothing breaks the
  instant it happens — the app verifies at download time, against this file —
  but a version number that no longer identifies bytes makes every other check
  meaningless. Bump the version instead.

## License

The index and this README: MIT. Each plugin carries its own license, named in
its manifest.
