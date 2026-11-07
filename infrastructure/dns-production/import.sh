#!/bin/sh
# Rejoue les imports des enregistrements existants (identifiants OVH releves le
# 7 novembre 2026). Idempotent : un enregistrement deja dans le state est saute.
set -eu
cd "$(dirname "$0")"
imp() { tofu state show "ovh_domain_zone_record.this[\"$1\"]" >/dev/null 2>&1 || tofu import "ovh_domain_zone_record.this[\"$1\"]" "$2"; }
imp "leportail.org/apex-A"          5416162603.leportail.org
imp "leportail.org/star-CNAME"      5428130721.leportail.org
imp "leportail.org/www-CNAME"       5416162633.leportail.org
imp "leportail.org/vault-CNAME"     5429022629.leportail.org
imp "fermedujointout.fr/apex-A"     5428225012.fermedujointout.fr
imp "fermedujointout.fr/star-CNAME" 5428225016.fermedujointout.fr
imp "fermedujointout.fr/vault-CNAME" 5429022628.fermedujointout.fr
imp "jardinsvedas.com/apex-A"       5428251853.jardinsvedas.com
imp "jardinsvedas.com/apex-AAAA"    5428251854.jardinsvedas.com
imp "jardinsvedas.com/star-CNAME"   5428251857.jardinsvedas.com
imp "labergeronnette.org/apex-A"    5415790083.labergeronnette.org
imp "labergeronnette.org/apex-AAAA" 5415790084.labergeronnette.org
imp "labergeronnette.org/star-CNAME" 5428131166.labergeronnette.org
imp "labergeronnette.org/www-CNAME" 5415790096.labergeronnette.org
imp "alter-it.eu/apex-A"            5416817289.alter-it.eu
imp "alter-it.eu/apex-AAAA"         5416817290.alter-it.eu
imp "alter-it.eu/star-CNAME"        5428136071.alter-it.eu
imp "alter-it.eu/vault-CNAME"       5429022631.alter-it.eu
imp "alter-it.eu/infra01-A"         5416817305.alter-it.eu
imp "alter-it.eu/infra01-AAAA"      5416817306.alter-it.eu
