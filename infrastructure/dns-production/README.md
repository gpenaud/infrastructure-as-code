# dns-production — les noms de production, dans Tofu

Importés le 7 novembre 2026 depuis les zones OVH, tels qu'external-dns les avait écrits
depuis infra01. Voir `main.tf` pour ce qui est géré et ce qui ne l'est pas, et
`~/work/migration-k8s-compose/docs/SPEC.md` § DNS pour la bascule.

```sh
tofu init -backend-config="access_key=…" -backend-config="secret_key=…"   # clés du bucket de state
tofu plan                                                                   # vide tant que rien ne bouge
```

Basculer une zone : changer `targets["<zone>"]` dans `terraform.tfvars`, `tofu plan`, lire,
`tofu apply`. external-dns doit être suspendu avant, sinon il réécrit l'apex.

Les identifiants d'import viennent de `migration-k8s-compose/dns/records-with-ids.tsv`
(`bin/import.sh` les rejoue).
