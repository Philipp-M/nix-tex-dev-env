# nix-tex-dev-env

This nix-flake based project offers a latex development environment with hot-reloading/preview support.

To build the document:

```bash
nix run .#build-document
```

To watch for changes and rebuild the project:

```bash
nix run .#watch-document
```

To start zathura as pdf-viewer and rebuild the pdf on changes:

```bash
nix run
```

This repo contains an example CV.tex file which serves as latex entrypoint file.

The file can be changed in the flake.nix in the variable `document-file`.