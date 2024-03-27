{ writeScriptBin, opentofu }:

writeScriptBin "opentofu-fmt" ''
  #!/usr/bin/env bash
  for arg in "$@"; do
    dirname "$arg"
  done \
    | sort \
    | uniq \
    | while read dir; do
        ${opentofu}/bin/tofu fmt "$dir"
      done
''
