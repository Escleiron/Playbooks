# Shares Management – Ansible Playbooks

Este directorio contiene una colección de playbooks de Ansible orientados a la **gestión y verificación de montajes de red** (NFS y CIFS) en sistemas Linux.

Los playbooks permiten:
- Verificar puntos de montaje activos
- Identificar montajes por origen (servidor)
- Montar shares definidos en `/etc/fstab`
- Desmontar montajes NFS de forma controlada

Todos los playbooks están pensados para ejecutarse con privilegios de **root**.
