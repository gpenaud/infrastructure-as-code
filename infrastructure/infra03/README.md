# infra03 — VPS Hetzner unique, docker-compose

Un serveur CX43 à Falkenstein, Ubuntu 24.04, qui porte trois instances de
[tenant-infra](../../../alter-it/tenant-infra) : le-portail, ferme-du-jointout
et jardins-vedas, derrière le gateway. Il remplace à terme infra01.

| Quoi | Où |
|---|---|
| serveur, DNS de staging, bucket S3 | cette racine (OpenTofu) |
| durcissement, Docker, outils, clé de déploiement | `~/work/ansible/playbooks/deploy-vps.yml` |
| instances, gateway, restauration | `~/work/ansible/playbooks/tenant-instances.yml` |
| sauvegardes | sur la machine, la pile `core/backup` de chaque tenant |

## Préalables, une fois

1. **Un projet Hetzner distinct du lab** et un jeton lecture/écriture dessus.
   Le projet 14748868 est vidé chaque nuit par `infra02-nightly-nuke` : rien de
   durable ne doit y vivre.
2. **Une clé API OVH qui porte la zone DNS** : celle de `s3-buckets` n a que
   `/cloud/*`. Le lien de création, avec les règles préremplies, est dans
   `terraform.tfvars.example`.
3. Le bucket de state, créé par la racine `infrastructure/s3-buckets` :
   ```sh
   cd ../s3-buckets && tofu apply -target='module.buckets.aws_s3_bucket.this["infra03-tofu-state"]'
   ```
   (cette racine a d autres changements en attente depuis août — l apply ciblé
   n y touche pas.)
4. `terraform.tfvars` à partir de l exemple.

## 1. La machine

```sh
tofu init -backend-config="access_key=$S3_KEY" -backend-config="secret_key=$S3_SECRET"
tofu plan
tofu apply
tofu output                          # ipv4, tenant_domains, backup_bucket
```

## 2. Le durcissement et Docker

Depuis `~/work/ansible`. La machine sort de Hetzner avec la clé SSH sur root ;
le rôle `gpenaud.secured-server` crée `operator`, ferme root et tout autre
compte, pose ufw, crowdsec, les mises à jour automatiques et les audits.

```sh
export BECOME_PASS_INFRA03='…'   # 16 caractères au moins : c est le mot de passe sudo d operator
ansible-playbook -i inventories/infra03/hosts.yml playbooks/deploy-vps.yml -u root   # première fois
ansible-playbook -i inventories/infra03/hosts.yml playbooks/deploy-vps.yml           # ensuite
```

Le dépôt `tenant-infra` est privé : le playbook fabrique une clé de déploiement
sur la machine et affiche la commande `gh repo deploy-key add …` à passer. Le
clone réussit à la passe suivante.

Ce que ufw laisse entrer : 22, 80, 443 (et 443/udp pour HTTP/3). Docker
contourne ufw pour les ports qu il publie ; la chaîne `DOCKER-USER` posée par
le playbook rend ces ports à ufw. Pas de pare-feu Hetzner : la cible finale est
un VPS Hostinger, la protection doit suivre la machine, pas l hébergeur.

## 3. Les instances

```sh
export RESTIC_PASSWORD=$(kubectl --context admin@infra01 -n le-portail-nextcloud get secret k8up-credentials -o jsonpath='{.data.RESTIC_PASSWORD}' | base64 -d)
# Les MÊMES identifiants S3 que k8up : chez OVH un bucket n est lisible que par
# l utilisateur qui l a créé, et celui-là possède les dépôts d infra01 comme
# alter-it-backups (voir s3.tf).
export BACKUP_ACCESS_KEY=$(kubectl --context admin@infra01 -n le-portail-nextcloud get secret k8up-credentials -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
export BACKUP_SECRET_KEY=$(kubectl --context admin@infra01 -n le-portail-nextcloud get secret k8up-credentials -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)

ansible-playbook -i inventories/infra03/hosts.yml playbooks/tenant-instances.yml --tags config   # .env, secrets, réseaux, inscription
ansible-playbook -i inventories/infra03/hosts.yml playbooks/tenant-instances.yml --tags up       # task up × 3, puis le gateway
```

Chaque tenant reçoit `BASE_DOMAIN=staging.<zone>`, quatre /24
distincts, sa liste d applications, et un `.env.restore` qui lit infra01 et
écrit `alter-it-backups/infra03/<tenant>-<application>`. Le même mot de passe
restic et les mêmes clés S3 qu en production, à dessein : un seul secret à
garder pour tout relire, et de toute façon le seul utilisateur OVH qui voie
ces buckets.

## 4. La restauration depuis infra01

Écrase les volumes et les bases des trois tenants par la dernière sauvegarde de
production. Longue (Nextcloud). Jamais implicite :

```sh
ansible-playbook -i inventories/infra03/hosts.yml playbooks/tenant-instances.yml --tags restore -e restore=yes
```

Ou tenant par tenant, sur la machine :

```sh
cd /srv/tenant-infra/tenant
INSTANCE=/srv/instances/le-portail task restore:all SOURCE=infra01 CONFIRM='oui je confirme'
```

## 5. Les sauvegardes

La pile `core/backup` de chaque tenant tourne dès `task up` : un snapshot par
application chaque nuit à 2 h, `check` le jeudi, purge simulée (sans
`AUTO_PURGE=yes`), test de restauration dans une base jetable le 1er du mois.

```sh
INSTANCE=/srv/instances/le-portail task backup:all      # tout de suite
INSTANCE=/srv/instances/le-portail task backup:verify   # se restaurent-elles ?
```

## Noms

Le staging de chaque tenant vit **dans sa zone** : `auth.staging.leportail.org`,
`www.staging.fermedujointout.fr`, `www.staging.jardinsvedas.com`. Chaque zone
porte `*.staging` en CNAME vers `staging.<zone>`, que Tofu fait pointer sur le
serveur. `infra03.alter-it.eu` n est que le nom de la machine.

Les enregistrements qui existaient avant cette racine ont été importés, pas
recréés. L identifiant d import est « <id>.<zone> » : le provider coupe au
PREMIER point, « zone.id » aurait donné la zone « com.5428251871 » :

```sh
tofu import 'ovh_domain_zone_record.this["le-portail-cname"]'        5417812177.leportail.org
tofu import 'ovh_domain_zone_record.this["ferme-du-jointout-cname"]' 5428225017.fermedujointout.fr
tofu import 'ovh_domain_zone_record.this["jardins-vedas-cname"]'     5428251858.jardinsvedas.com
tofu import 'ovh_domain_zone_record.this["jardins-vedas-A"]'         5428251871.jardinsvedas.com
```

Restent hors de ce state, à traiter à la main : `staging.alter-it.eu` et
`*.staging.labergeronnette.org`, qui pointent encore vers l ex-infra02.

## Ensuite : la bascule

Les noms de production restent sur infra01 jusqu à ce que les trois tenants
aient été éprouvés sous `staging.<zone>`. La bascule se fait zone par zone :
`BASE_DOMAIN` sans `staging.`, `task gateway:enrol`, puis les enregistrements
de production vers ce serveur, avec une dernière restauration juste avant pour
ne rien perdre entre les deux.

## Ce que `tofu destroy` refuse

Le serveur et le bucket portent `prevent_destroy`. C est délibéré : cette racine
n est pas un lab.
