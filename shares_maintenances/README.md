# Shares_maintenances

Toolkit basado en Ansible para '''inspeccionar, montar, desmontar y mantener shares NFS y CIFS'''en múltiples hosts Linux de forma segura, controlada y auditable.

Este repositorio está diseñado para '''tareas operativas''', '''ventanas de mantenimiento''' y '''auditorías de infraestructura''', con una clara separación de responsabilidades.

----

## Estructura del repositorio

```
shares_maintenances
├── Checks
│   ├── mount_state_snapshot.yml
│   ├── mount_inventory_menu.sh
│   └── fstab_pattern.yml
├── Umount
│   ├── generate_variable_host_patter.sh
│   └── umount_share.yml
├── Mount
│   ├── mount_fstab_shares.yml
│   ├── mount_snapshot_txt_to_yml.sh
│   └── mount_state_after_snapshot.yml
├── Modify
│   ├── replace_fstab_sources.yml
│   └── fstab_source_map.yml
└── README.md
```
----

## Inicio rápido (migración típica) 

1. Configurar los shares a buscar en <code>Checks/fstab_pattern.yml</code>.
2.Ejecutar <code>Checks/mount_state_snapshot.yml</code>.
3. Generar <code>fstab_host_pattern</code> usando <code>>Umount/generate_variable_host_pattern.sh</code>.
4. Revisar el patrón generado.
5. Ejecutar <code>Umount/umount_share.yml</code>.
6. Realizar la migración backend / actualización DNS.
7. Restaurar los mounts usando los playbooks de Mount.

----

## Checks 

Este directorio contiene '''herramientas de solo lectura''' utilizadas para auditar y analizar el estado actual de los mounts NFS y CIFS en todos los hosts gestionados.

### mount_state_snapshot.yml

Playbook de Ansible que recopila un '''snapshot de los shares NFS y CIFS montados''' en todos los hosts objetivo y genera un inventario consolidado en el nodo de control.

#### Características principales

* Se ejecuta contra todos los hosts.
* Usa facts <code>ansible_mounts</code>.
* Filtra:
** mounts NFS.
** mounts CIFS.
** Dispositivos que coinciden con un patrón configurable.
* Agrega los resultados de forma centralizada en localhost.
* Genera un fichero de reporte con timestamp.

#### Variables configurables 
Editar el fichero fstab_pattern.yml con los orígenes que se desean buscar en los servidores:
```yaml
fstab_host_pattern: "SOURCEA|SOURCEB|SOURCEC"
```

#### Uso

```bash
ansible-playbook -i $your_inventory Checks/mount_state_snapshot.yml
```

#### Output 
```
mount_inventory_YYYY-MM-DD_HH-MM-SS.txt
```

### mount_inventory_menu.sh 

Script Bash de ayuda diseñado para analizar y procesar los ficheros de inventario generados por <code>mount_state_snapshot.yml</code>.

Proporciona un menú interactivo para revisar, validar y exportar los datos de mounts.

#### Funcionalidades 

* Revisar resultados analizados.
* Lista todos los servidores encontrados con recursos compartidos y el número total de hosts únicos.
* Convertir inventario a CSV para enviar analisis y gestiones.

#### Uso 

```bash
dos2unix mount_inventory_menu.sh
chmod +x mount_inventory_menu.sh
./mount_inventory_menu.sh mount_inventory_YYYY-MM-DD_HH-MM-SS.txt
```

----

### Umount 

Contiene playbooks usados para desmontar de forma segura shares NFS y CIFS
basándose en el filtrado por origen.

#### generate_variable_host_patter.sh ===

Genera automáticamente la variable de Ansible <code>fstab_host_pattern</code> a partir de un fichero de inventario de mounts.

##### Uso 

```bash
cd Umount/
dos2unix generate_variable_host_pattern.sh
chmod +x generate_variable_host_pattern.s
./generate_variable_host_pattern.sh mount_inventory_YYYY-MM-DD_HH-MM-SS.txt
```

#### Output 

```yaml
fstab_host_pattern: "//server|server|192.168.1.80"
```

#### umount_share.yml 

Desmonta sistemas de ficheros NFS y CIFS cuyo origen coincide con un patrón definido.

##### Tags disponibles 

🏷 Available Tags
| Tag       | Description                      |
| --------- | -------------------------------- |
| `nfs`     | Unmount only NFS filesystems     |
| `cifs`    | Unmount only CIFS filesystems    |
| `all_types` | Unmount all matching filesystems |

----

## Mount

Contiene playbooks y scripts auxiliares usados para '''restaurar mounts''' definidos en <code>/etc/fstab</code>.

Este directorio ofrece '''dos estrategias de montaje''', según el escenario.

### Opción 1: Montar todos los sistemas definidos en /etc/fstab

Usar esta opción cuando se quiera montar todo lo definido en <code>/etc/fstab</code>,
por ejemplo tras un reinicio o una ventana de mantenimiento global.

```bash
ansible-playbook -i $your_inventory Mount/mount_fstab_shares.yml
```

### Opción 2: Restaurar solo los mounts detectados durante Checks 

Usar esta opción cuando se quiera restaurar únicamente los sistemas de ficheros
que estaban montados durante la fase de Checks (restauración selectiva y controlada).

#### Procedimiento 

##### Convertir el fichero snapshot a YAML
##### Ejecutar el playbook de restauración

```bash
./mount_snapshot_txt_to_yml.sh mount_inventory_YYYY-MM-DD_HH-MM-SS.txt
ansible-playbook -i $your_inventory Mount/mount_state_after_snapshot.yml
```

----

## Modify 

Reservado para playbooks que modifican configuraciones existentes de shares.

### update_fstab_sources.yml 

Playbook de Ansible diseñado para '''actualizar de forma segura las fuentes''' en <code>/etc/fstab</code>, preservando puntos de montaje y opciones.

### Dry run (recomendado) 

```bash
ansible-playbook -i $your_inventory Modify/update_fstab_sources.yml --check
```

#### Aplicar cambios 

```bash
ansible-playbook -i $your_inventory Modify/update_fstab_sources.yml
```

##### Rollback 

```bash
cp /etc/fstab.backup_YYYY-MM-DD_HH-MM-SS /etc/fstab
```
