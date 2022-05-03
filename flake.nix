{
  description = "LaTeX dev environment with hot-reloading support";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    flake-utils.url = github:numtide/flake-utils;
  };
  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib; eachSystem allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # tex = pkgs.texlive.combined.scheme-full;
        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-basic latexmk academicons moderncv fontawesome5
            luatexbase pgf multirow arydshln fontspec unicode-math
            lualatex-math;
        };
        document-file = "CV.tex";
      in
      rec {
        packages = rec {
          build-document =
            pkgs.writeShellScriptBin "build-document" ''
              export PATH="${pkgs.lib.makeBinPath [pkgs.coreutils tex]}"
              OUT_DIR=$(pwd)/out
              mkdir -p $OUT_DIR
              mkdir -p "$OUT_DIR/.texcache/texmf-var"
              env TEXMFHOME="$OUT_DIR/.texcache" \
                  OSFONTDIR=${pkgs.lmodern}/share/fonts \
                  TEXMFVAR="$OUT_DIR/.texcache/texmf-var" \
                latexmk -interaction=nonstopmode -pdf -lualatex \
                -output-directory="$OUT_DIR" \
                -usepretex ${document-file}
            '';
          watch-document =
            pkgs.writeShellScriptBin "watch-document" ''
              export PATH="${pkgs.lib.makeBinPath [pkgs.git pkgs.ripgrep pkgs.coreutils pkgs.inotify-tools build-document]}";

              inotifywait --event close_write --monitor --recursive . |
                while read -r directory events filename; do
                  if ! echo "$directory" | rg -q '^\./\.git/' &&
                     ! git check-ignore --non-matching --verbose "$directory/$filename" >/dev/null 2>&1
                  then
                    build-document
                  fi
                done              
            '';
          dev = pkgs.writeShellScriptBin "dev" ''
            export PATH="${pkgs.lib.makeBinPath [ pkgs.procps pkgs.coreutils pkgs.zathura build-document watch-document]}:$PATH";

            list_descendants ()
            {
              local children=$(ps -o pid= --ppid "$1")

              for pid in $children
              do
                list_descendants "$pid"
              done

              echo "$children"
            }

            cleanup()
            {
              kill $(list_descendants $$) >/dev/null 2>&1
            }

            trap 'cleanup' TERM INT
            build-document
            watch-document &
            DOCUMENT_FILE_BASENAME=$(basename -- "${document-file}")
            OUT_PDF_FILENAME=$(pwd)/out/''${DOCUMENT_FILE_BASENAME%.*}.pdf
            echo $OUT_PDF_FILENAME
            zathura $OUT_PDF_FILENAME
            cleanup
          '';
        };

        defaultPackage = packages.dev;
      });
}
