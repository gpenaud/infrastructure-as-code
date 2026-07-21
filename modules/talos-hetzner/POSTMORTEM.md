# Post-mortem — Talos sur Hetzner Cloud bloqué au boot (27 mai 2026)

## Symptôme

`tofu apply` reste bloqué très longtemps sur les ressources
`talos_machine_configuration_apply.node[*]` (« Still creating... »).
Les trois nœuds refusent les connexions sur le port 50000 (apid) :

```
178.105.125.169 : refused
46.225.158.131  : refused
178.105.217.159 : refused
```

`refused` (et non `timed out`) = le paquet arrive bien à la machine (le firewall
ne bloque pas), mais **rien n'écoute** sur le port. Donc apid n'est pas démarré.

## Ce que montrait la console (VNC du nœud)

Le nœud bootait correctement, réseau OK (IP publique sur eth0, IP privée sur
eth1, routes présentes). Mais il bouclait sur :

```
[talos] fetching machine config from: "http://169.254.169.254/hetzner/v1/userdata"
[talos] retrying error: failed to download config ... status code 204, body ""
```

`204 No Content` = le user-data du serveur était **vide**.

## Cause racine

Erreur de modèle mental dans le module initial.

J'avais supposé que « Talos ignore le user-data cloud-init, donc on applique la
config séparément par le réseau via `talos_machine_configuration_apply` (qui se
connecte à apid sur le port 50000 en mode maintenance) ».

**C'est faux pour la plateforme `hcloud` de Talos.** L'image Talos buildée pour
hcloud est conçue pour récupérer sa config machine VIA le user-data du serveur
(le service metadata `169.254.169.254`). Tant qu'elle ne la trouve pas, elle
reste en boucle d'attente et **ne démarre pas apid en mode maintenance**.

D'où le blocage circulaire :
- Talos attend une config dans le user-data (qui était vide) → apid ne démarre pas
- `talos_machine_configuration_apply` attend qu'apid réponde sur 50000 → jamais
- Les deux s'attendent mutuellement → deadlock jusqu'au timeout

## Le fix

Inverser l'approche : livrer la config AU BOOT via le user-data, au lieu de
l'appliquer par le réseau après coup.

1. **`servers.tf`** : ajout de `user_data = data.talos_machine_configuration.controlplane.machine_configuration`
   sur la ressource `hcloud_server.node`.

2. **`talos.tf`** : suppression complète des ressources
   `talos_machine_configuration_apply.*`. Elles ne servent plus à rien : le nœud
   s'auto-configure au boot.

3. Le `talos_machine_bootstrap` est CONSERVÉ : il faut toujours amorcer etcd une
   seule fois après que les nœuds soient configurés. Il dépend désormais de
   `hcloud_server.node` (les serveurs doivent exister et avoir bootté).

## Ordre de création résultant

```
secrets Talos
   │
   ▼
Load Balancer (son IP est dans la config : certSANs + endpoint)
   │
   ▼
data config machine (référence l'IP du LB)
   │
   ▼
serveurs (user_data = la config)   ← Talos s'auto-configure au boot
   │
   ▼
bootstrap etcd (une fois, sur node-0)
   │
   ▼
kubeconfig
```

Pas de cycle de dépendances : le `hcloud_load_balancer_target` sélectionne les
nœuds par label (`label_selector`), donc il ne crée pas de dépendance Tofu
explicite vers les serveurs.

## Leçon SRE (pour le « master SRE » : observabilité + failure-first)

- Le `refused` vs `timed out` est un signal de diagnostic précieux : il a permis
  d'écarter le firewall et de pointer vers « rien n'écoute » dès le départ.
- La console VNC a été l'observabilité décisive : sans elle, on tournait en rond
  sur des hypothèses (snapshot, réseau, firewall). Le log `204 No Content` a
  tranché en une ligne. Sans accès à l'état réel de la machine, on devine.
- Le piège était un mauvais modèle mental de la plateforme, pas un bug de code.
  Chaque plateforme Talos (hcloud, aws, metal, nocloud...) a sa propre source de
  config. Vérifier la doc de la plateforme cible AVANT de coder le provisioning.
