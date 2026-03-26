#!/usr/bin/env just --justfile
recipe := just_executable() + " --justfile=" + justfile()
ver dir='.':
    cd {{dir}} && echo $(if command -v yq >/dev/null; then yq -r '.version' {{dir}}/pubspec.yaml; else grep -E '^\s*version:' pubspec.yaml | head -n1 | sed -E 's/^\s*version:\s*"?([^"#]+)"?\s*(#.*)?$/\1/'; fi)
pg dir: # Pubget
    cd {{dir}} && fvm dart pub get
br dir: # Build runner
    cd {{dir}} && fvm dart pub get
    cd {{dir}} && fvm dart run build_runner build --delete-conflicting-outputs
cl_br dir: # Clean build runner
    cd {{dir}} && fvm dart run build_runner clean
cl dir: # Flutter clean
    cd {{dir}} && fvm flutter clean
license year +dirs:
    reuse annotate -c "Karim \"nogipx\" Mamatkazin <nogipx@gmail.com>" -l "MIT" -y {{year}} -r {{dirs}}

test:
    fvm dart test --concurrency=1

gen:
    {{recipe}} br .

get:
    {{recipe}} pg .

prepare:
    fvm dart fix --apply
    fvm dart format -l 80 .

dry:
    fvm dart pub publish --dry-run

publish:
    fvm dart pub publish
