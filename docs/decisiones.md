# Decisiones tomadas

| Tema | Decisión | Motivo |
|---|---|---|
| IaC | Bicep (ámbito suscripción: crea el RG y delega en `resources.bicep`) | Viene con `az`, sin estado local; destruir = borrar el RG. |
| Región | México Central (`mexicocentral`) | East US 2 y Brazil South bloqueadas por política de la suscripción; entre las permitidas con capacidad, precio bajo y menor latencia desde Chile. |
| Linux | `vm-soc-linux`, Ubuntu 24.04 LTS, `Standard_B2as_v2` (2 vCPU, 8 GB), disco 64 GB | Wazuh All-in-One requiere ≥4 GB. |
| Windows | `vm-soc-windows`, Windows Server 2022, `Standard_B2as_v2` (2 vCPU, 8 GB) | B2s/B2ms sin capacidad en las regiones permitidas; misma familia burstable. |
| Por qué no `D2s_v5` | Cuota 0 (familia DSv5) en las 3 regiones; en México Central además `NotAvailableForSubscription` | Solo la serie B tiene cuota (4 vCPU). |
| Red | VNet 10.0.0.0/16, `subnet-lab` 10.0.1.0/24, un NSG asociado a la subred | Enunciado. |
| NSG | 22/3389/443 solo desde la IP del estudiante; 1514/1515 e ICMP solo desde 10.0.1.0/24 | Enunciado; nada abierto a Internet. |
| IP pública | Standard estática, una por VM (~0,005 USD/h c/u) | Necesaria para acceder; se conserva al apagar. |
| Autenticación | Linux: clave SSH; Windows: contraseña aleatoria. Ambas en `infra/.secrets/` | No hardcodear secretos. |

## Comparación de regiones (26-sep-2026, precios retail USD/h, pago por uso)

| Región | Cuota serie B | Cuota Dsv5 | Linux B2ms | Windows B2s | Total/h |
|---|---|---|---|---|---|
| East US 2 | 4 vCPU | 0 | 0,0832 | 0,0496 | ≈ 0,133 |
| México Central | 4 vCPU | 0 (no disponible) | 0,0915 | 0,0538 | ≈ 0,145 |
| Brazil South | 4 vCPU | 0 | 0,134 | 0,0752 | ≈ 0,209 |

Proveedores `Microsoft.Compute` y `Microsoft.Network` se registraron manualmente (venían `NotRegistered` en la suscripción nueva).

## Hallazgo del 26-sep-2026: restricciones de la suscripción (resuelto: México Central + B2as_v2)
- La política `sys.regionrestriction` de Azure for Students solo permite: `chilecentral`, `mexicocentral`, `westus`, `northcentralus`, `canadacentral`. **East US 2 y Brazil South están bloqueadas** (`RequestDisallowedByAzure`).
- `Standard_B2ms` / `Standard_B2s` (y `D2s_v5`, cuota 0) dan `SkuNotAvailable` en las 5 regiones permitidas (verificado con `az deployment sub what-if`).
- Alternativas con capacidad y cuota (what-if OK): `Standard_B2as_v2` (2 vCPU, 8 GB, AMD) en mexicocentral, chilecentral y northcentralus; `Standard_B2s_v2` en mexicocentral y chilecentral.
- Precio retail aprox. (Linux+Windows, `Standard_B2as_v2`): mexicocentral 0,175 USD/h; northcentralus 0,169; chilecentral 0,219.
