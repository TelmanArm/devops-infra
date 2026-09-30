# devops-infra

Kubernetes infrastructure for a nopCommerce + PostgreSQL stack, deployed with Kustomize.
Currently targets a local minikube cluster; Terraform and cloud environments are planned.

## Layout

```
cluster/minikube/start.sh    Provision the local cluster and deploy the stack
k8s/base/                    Kustomize base
├── namespace.yaml           Namespace: demo
├── postgres/                StatefulSet + headless Service + credentials Secret
│                            + db-init ConfigMap (citext extension)
└── nopcommerce/             Deployment + Service + PVC
```

## Requirements

- Docker
- minikube
- kubectl (with kustomize support)

## Usage

```bash
./cluster/minikube/start.sh
```

The script starts the `devops-infra` minikube profile, applies `k8s/base`, waits for
both workloads to roll out, and port-forwards the app to <http://localhost:8084>.
Override the port with `LOCAL_PORT=9090 ./cluster/minikube/start.sh`.

Manual deploy against an existing cluster:

```bash
kubectl apply -k k8s/base
kubectl -n demo get pods
```

Teardown:

```bash
minikube delete --profile=devops-infra
```

## Components

| Workload | Image | Notes |
| --- | --- | --- |
| `db` (StatefulSet) | `postgres:15-alpine` | Headless Service on 5432, 1Gi volume from a `volumeClaimTemplate`, `pg_isready` startup/readiness/liveness probes, `db-init` ConfigMap mounted at `/docker-entrypoint-initdb.d` to enable the `citext` extension that the nopCommerce installer requires |
| `nopcommerce` (Deployment) | `nopcommerceteam/nopcommerce:4.90.8` | Single replica with `Recreate` strategy, 1Gi PVC mounted at `/app/App_Data`, init container seeds the default `App_Data`, long startup probe (~5 min) for first boot |

## Notes

- `k8s/base/postgres/secret.yaml` holds plaintext development credentials and is intended
  for local use only. Replace it with a sealed/SOPS-encrypted secret or an external secret
  store before any shared environment.
- nopCommerce is not yet wired to the `db` StatefulSet — the database is configured through
  the application's first-run installation wizard.
- `init.sql` runs only on first boot, when the postgres entrypoint initialises an empty data
  directory. On a volume that already exists the extension is not added, so delete the `db`
  PVC (or enable `citext` by hand once) to pick it up.
