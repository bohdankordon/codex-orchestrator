# Release manifests

`v<version>.sha256` lists the SHA-256 of every file in the production source set
at that version: the skill entry point, its four references, the skill metadata
file, and the five worker role files.

Format is the standard `sha256sum` layout - lowercase hash, two spaces, path -
so it can be checked directly:

    sha256sum -c manifests/v1.2.0.sha256

Lines are sorted in ordinal path order, use forward slashes, and are written with
LF line endings and a trailing newline. The same source always produces the same
bytes, so a changed manifest means changed source.

`scripts\New-ReleaseManifest.ps1` writes these files and
`scripts\Test-Repository.ps1` checks them. The manifest covers what gets
installed, not only what is documented: a file that ships without a hash would be
a file nothing verifies.
