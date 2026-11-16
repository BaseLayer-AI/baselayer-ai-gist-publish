{
  description = "baselayer-ai-gist-publish";

  inputs = { nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*"; };

  outputs = { self, nixpkgs }:
    let
      aarch64-darwin = import nixpkgs { system = "aarch64-darwin"; };
      aarch64-linux = import nixpkgs { system = "aarch64-linux"; };
      x86_64-linux = import nixpkgs { system = "x86_64-linux"; };

      default = { pkgs } : pkgs.writeTextFile { name = "baselayer-ai-gist-publish"; executable = true; destination = "/bin/baselayer-ai-gist-publish";
        text = ''#!${pkgs.stdenv.shell}
[ -z "$GITHUB_TOKEN" ] && echo "Error: GITHUB_TOKEN environment variable is not set." && exit 1; [ $# -eq 0 ] && echo "Usage: $0 <file1> [file2 ...]" && exit 1; FILES_JSON="{}" && for f in "$@"; do [ -f "$f" ] || { echo "DEBUG: Error - $f is NOT visible to the shell"; exit 1; }; FILES_JSON=$(printf '%s' "$FILES_JSON" | ${pkgs.jq}/bin/jq --arg name "$f" --rawfile content "$f" '. + {($name): {content: $content}}'); done; ${pkgs.curl}/bin/curl -s -X POST -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2026-03-10" -d "$(${pkgs.jq}/bin/jq -n --arg desc "$(head -1 "$1")" --argjson files "$FILES_JSON" '{description: $desc, public: false, files: $files}')" https://api.github.com/gists | ${pkgs.jq}/bin/jq -r '.html_url' || { echo "DEBUG: Pipeline failed"; exit 1; }
        '';};
    in {
      packages.aarch64-darwin.default = default { pkgs = aarch64-darwin; };
      packages.aarch64-linux.default = default { pkgs = aarch64-linux; };
      packages.x86_64-linux.default = default { pkgs = x86_64-linux; };
    };
}
