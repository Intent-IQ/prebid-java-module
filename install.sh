#!/usr/bin/env bash
# Adds the IntentIQ Identity module to a Prebid Server Java checkout.
# Usage: install.sh <path-to-prebid-server-java>
# Safe to run again: it replaces the module and adds each pom entry only once.
set -euo pipefail

MODULE=intentiq-identity
MIN_VERSION=4.0.0

die() { echo "error: $*" >&2; exit 1; }

[ $# -eq 1 ] || die "usage: $0 <path-to-prebid-server-java>"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)/$MODULE"
PBS_DIR="$(cd "$1" 2>/dev/null && pwd)" || die "no such directory: $1"
MODULES_POM="$PBS_DIR/extra/modules/pom.xml"
BUNDLE_POM="$PBS_DIR/extra/bundle/pom.xml"

[ -d "$SRC_DIR" ] || die "module sources not found next to this script: $SRC_DIR"
[ -f "$MODULES_POM" ] && [ -f "$BUNDLE_POM" ] || die "$PBS_DIR is not a Prebid Server Java checkout (extra/modules/pom.xml or extra/bundle/pom.xml missing)"

# The PBS version is the parent version in extra/modules/pom.xml, e.g. 4.5.0 or 4.6.0-SNAPSHOT.
PBS_VERSION="$(awk '/<parent>/{p=1} p && /<version>/{gsub(/.*<version>|<\/version>.*/, ""); print; exit}' "$MODULES_POM")"
[ -n "$PBS_VERSION" ] || die "cannot read the Prebid Server version from $MODULES_POM"

version_core="${PBS_VERSION%%-*}"
lowest="$(printf '%s\n%s\n' "$MIN_VERSION" "$version_core" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)"
[ "$lowest" = "$MIN_VERSION" ] || die "Prebid Server $PBS_VERSION is not supported, $MIN_VERSION or later is required"

# 1. Module sources, with the parent version of this PBS.
rm -rf "$PBS_DIR/extra/modules/$MODULE"
mkdir -p "$PBS_DIR/extra/modules/$MODULE"
cp -R "$SRC_DIR/." "$PBS_DIR/extra/modules/$MODULE/"
rm -rf "$PBS_DIR/extra/modules/$MODULE/target"
awk -v v="$PBS_VERSION" '
    /<parent>/ {p=1}
    p && /<version>/ && !done {sub(/<version>[^<]*<\/version>/, "<version>" v "</version>"); done=1}
    /<\/parent>/ {p=0}
    {print}
' "$SRC_DIR/pom.xml" > "$PBS_DIR/extra/modules/$MODULE/pom.xml"

# 2. Register the module in extra/modules/pom.xml.
if ! grep -q "<module>$MODULE</module>" "$MODULES_POM"; then
    awk -v m="$MODULE" '
        /<\/modules>/ && !done {print "        <module>" m "</module>"; done=1}
        {print}
    ' "$MODULES_POM" > "$MODULES_POM.tmp" && mv "$MODULES_POM.tmp" "$MODULES_POM"
fi

# 3. Add the module to the bundle (the first <dependencies> block is the project's own).
if ! grep -q "<artifactId>$MODULE</artifactId>" "$BUNDLE_POM"; then
    awk -v m="$MODULE" '
        /<\/dependencies>/ && !done {
            print "        <dependency>"
            print "            <groupId>org.prebid.server.hooks.modules</groupId>"
            print "            <artifactId>" m "</artifactId>"
            print "            <version>${project.version}</version>"
            print "        </dependency>"
            done=1
        }
        {print}
    ' "$BUNDLE_POM" > "$BUNDLE_POM.tmp" && mv "$BUNDLE_POM.tmp" "$BUNDLE_POM"
fi

echo "IntentIQ Identity module added to Prebid Server $PBS_VERSION in $PBS_DIR"
echo "Build PBS with its modules: cd $PBS_DIR && mvn clean package --file extra/pom.xml"
