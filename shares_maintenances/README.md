= Shares_maintenances =

Toolkit basado en Ansible para '''inspeccionar, montar, desmontar y mantener shares NFS y CIFS'''
en múltiples hosts Linux de forma segura, controlada y auditable.

Este repositorio está diseñado para '''tareas operativas''', '''ventanas de mantenimiento''' y
'''auditorías de infraestructura''', con una clara separación de responsabilidades.

https://github.com/Escleiron/Playbooks/tree/main/Share_maintenance


----

== Estructura del repositorio ==

<pre>
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
</pre>

----

== Inicio rápido (migración típica) ==

#Configurar los shares a buscar en <code>Checks/fstab_pattern.yml</code>.
#Ejecutar <code>Checks/mount_state_snapshot.yml</code>.
# Generar <code>fstab_host_pattern</code> usando <code>>Umount/generate_variable_host_pattern.sh</code>.
# Revisar el patrón generado.
# Ejecutar <code>Umount/umount_share.yml</code>.
# Realizar la migración backend / actualización DNS.
# Restaurar los mounts usando los playbooks de Mount.

----

== Índice ==

* [[#Checks|Checks]]
* [[#Umount|Umount]]
* [[#Mount|Mount]]
* [[#Modify|Modify (Opcional)]]

----

== Checks ==

Este directorio contiene '''herramientas de solo lectura''' utilizadas para auditar y analizar
el estado actual de los mounts NFS y CIFS en todos los hosts gestionados.

=== mount_state_snapshot.yml ===

Playbook de Ansible que recopila un '''snapshot de los shares NFS y CIFS montados''' en todos los hosts objetivo y genera un inventario consolidado en el nodo de control.

==== Características principales ====

* Se ejecuta contra todos los hosts.
* Usa facts <code>ansible_mounts</code>.
* Filtra:
** mounts NFS.
** mounts CIFS.
** Dispositivos que coinciden con un patrón configurable.
* Agrega los resultados de forma centralizada en localhost.
* Genera un fichero de reporte con timestamp.

==== Variables configurables ====
Editar el fichero fstab_pattern.yml con los orígenes que se desean buscar en los servidores:
<syntaxhighlight lang="yaml">
fstab_host_pattern: "SOURCEA|SOURCEB|SOURCEC"
</syntaxhighlight>

==== Uso ====

<syntaxhighlight lang="bash">
ansible-playbook -i $your_inventory Checks/mount_state_snapshot.yml
</syntaxhighlight>

==== Salida ====

<pre>
mount_inventory_YYYY-MM-DD_HH-MM-SS.txt
</pre>

=== mount_inventory_menu.sh ===

Script Bash de ayuda diseñado para analizar y procesar los ficheros de inventario generados por <code>mount_state_snapshot.yml</code>.

Proporciona un menú interactivo para revisar, validar y exportar los datos de mounts.

==== Funcionalidades ====

* Revisar resultados analizados.
* Lista todos los servidores encontrados con recursos compartidos y el número total de hosts únicos.
* Convertir inventario a CSV para enviar analisis y gestiones.

==== Uso ====

<syntaxhighlight lang="bash">
dos2unix mount_inventory_menu.sh
chmod +x mount_inventory_menu.sh
./mount_inventory_menu.sh mount_inventory_YYYY-MM-DD_HH-MM-SS.txt
</syntaxhighlight>

----

== Umount ==

Contiene playbooks usados para desmontar de forma segura shares NFS y CIFS
basándose en el filtrado por origen.

=== generate_variable_host_patter.sh ===

Genera automáticamente la variable de Ansible <code>fstab_host_pattern</code>
a partir de un fichero de inventario de mounts.

==== Uso ====

<syntaxhighlight lang="bash">
cd Umount/
dos2unix generate_variable_host_pattern.sh
chmod +x generate_variable_host_pattern.s
./generate_variable_host_pattern.sh mount_inventory_YYYY-MM-DD_HH-MM-SS.txt
</syntaxhighlight>

==== Salida ====

<syntaxhighlight lang="yaml">
fstab_host_pattern: "//server|server|192.168.1.80"
</syntaxhighlight>

=== umount_share.yml ===

Desmonta sistemas de ficheros NFS y CIFS cuyo origen coincide con un patrón definido.

==== Tags disponibles ====

{| class="wikitable"
! Tag !! Descripción
|-
| nfs || Desmontar solo sistemas NFS
|-
| cifs || Desmontar solo sistemas CIFS
|-
| all_types || Desmontar todos los sistemas coincidentes
|}

----

== Mount ==

Contiene playbooks y scripts auxiliares usados para '''restaurar mounts'''
definidos en <code>/etc/fstab</code>.

Este directorio ofrece '''dos estrategias de montaje''', según el escenario.

=== Opción 1: Montar todos los sistemas definidos en /etc/fstab ===

Usar esta opción cuando se quiera montar todo lo definido en <code>/etc/fstab</code>,
por ejemplo tras un reinicio o una ventana de mantenimiento global.

<syntaxhighlight lang="bash">
ansible-playbook -i $your_inventory Mount/mount_fstab_shares.yml
</syntaxhighlight>

=== Opción 2: Restaurar solo los mounts detectados durante Checks ===

Usar esta opción cuando se quiera restaurar únicamente los sistemas de ficheros
que estaban montados durante la fase de Checks (restauración selectiva y controlada).

==== Procedimiento ====

# Convertir el fichero snapshot a YAML
# Ejecutar el playbook de restauración

<syntaxhighlight lang="bash">
./mount_snapshot_txt_to_yml.sh mount_inventory_YYYY-MM-DD_HH-MM-SS.txt
ansible-playbook -i $your_inventory Mount/mount_state_after_snapshot.yml
</syntaxhighlight>

----

== Modify ==

Reservado para playbooks que modifican configuraciones existentes de shares.

=== update_fstab_sources.yml ===

Playbook de Ansible diseñado para '''actualizar de forma segura las fuentes'''
en <code>/etc/fstab</code>, preservando puntos de montaje y opciones.

==== Dry run (recomendado) ====

<syntaxhighlight lang="bash">
ansible-playbook -i $your_inventory Modify/update_fstab_sources.yml --check
</syntaxhighlight>

==== Aplicar cambios ====

<syntaxhighlight lang="bash">
ansible-playbook -i $your_inventory Modify/update_fstab_sources.yml
</syntaxhighlight>

==== Rollback ====

<pre>
cp /etc/fstab.backup_YYYY-MM-DD_HH-MM-SS /etc/fstab
</pre>


== Ejemplo de ejecución real de una migración (Umount/Mount) ==

=== Repositorio e inventario: === 

<syntaxhighlight lang="bash">
[root@icecube shares_maintenances]# ls -lrt
total 24
drwxr-xr-x. 2 root root    86 Feb  1 14:07 Umount
-rw-r--r--. 1 root root 15616 Feb  1 14:07 README.md
drwxr-xr-x. 2 root root  4096 Feb  1 14:07 OLD
drwxr-xr-x. 2 root root   126 Feb  1 14:07 Mount
drwxr-xr-x. 2 root root    83 Feb  1 14:07 Modify
drwxr-xr-x. 2 root root   110 Feb  1 14:07 Checks
</syntaxhighlight>

<syntaxhighlight lang="bash">
[root@icecube shares_maintenances]# cat inventory
node1
node2
</syntaxhighlight>

=== Checks ===

Definir los sources a buscar en fstab_pattern.yml
<syntaxhighlight lang="bash">
[root@icecube shares_maintenances]# cd Checks/

[root@icecube Checks]# cat fstab_pattern.yml
---
#Define the source shares that what to search
#example fstab_host_pattern: "serverA|serverB|serverC"
fstab_host_pattern: "escleiron|pool_smb|chasis06nfs|chasis116nfs"
[root@icecube Checks]#

</syntaxhighlight>

<syntaxhighlight lang="bash">
[root@icecube Checks]# ansible-playbook -i ../inventory mount_state_snapshot.yml

PLAY [all] *************************************************************************************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************************************************************************************************************************************
ok: [node1]
ok: [node2]

TASK [Initialize per-host mount inventory lines] ***********************************************************************************************************************************************************************************************************************************************
ok: [node1]
ok: [node2]

TASK [Collect NFS mounts (text format)] ********************************************************************************************************************************************************************************************************************************************************
skipping: [node1] => (item={'mount': '/', 'device': '/dev/mapper/rhel-root', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 18182307840, 'size_available': 15454588928, 'block_size': 4096, 'block_total': 4439040, 'block_available': 3773093, 'block_used': 665947, 'inode_total': 8910848, 'inode_available': 8850371, 'inode_used': 60477, 'uuid': '5d6f9d5b-9f52-4542-82de-7cfbd0c1ab18'})
skipping: [node1] => (item={'mount': '/boot', 'device': '/dev/sda1', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 1006632960, 'size_available': 668717056, 'block_size': 4096, 'block_total': 245760, 'block_available': 163261, 'block_used': 82499, 'inode_total': 524288, 'inode_available': 523928, 'inode_used': 360, 'uuid': '8f371388-10e8-4115-9189-41ac30fda258'})
skipping: [node1] => (item={'mount': '/srv/shared', 'device': '/dev/mapper/vg_shared-lv_data', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 42840621056, 'size_available': 42508083200, 'block_size': 4096, 'block_total': 10459136, 'block_available': 10377950, 'block_used': 81186, 'inode_total': 20951040, 'inode_available': 20951037, 'inode_used': 3, 'uuid': 'dea6a144-d98c-4167-b822-1f9e33fe6d5e'})
skipping: [node1] => (item={'mount': '/mnt', 'device': '//pool_smb.jagfloriano.com/compartido', 'fstype': 'cifs', 'options': 'rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=smbuser,uid=0,noforceuid,gid=0,noforcegid,addr=192.168.1.80,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,retrans=1,echo_interval=60,actimeo=1,closetimeo=1', 'size_total': 18182307840, 'size_available': 14461726720, 'block_size': 1024, 'block_total': 17756160, 'block_available': 14122780, 'block_used': 3633380, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': 'N/A'})
ok: [node1] => (item={'mount': '/nfs/001', 'device': 'chasis06nfs:/srv/samba/compartido_nfs_001', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
ok: [node1] => (item={'mount': '/nfs/002', 'device': 'chasis116nfs.jagfloriano.com:/srv/samba/compartido_nfs_002', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/', 'device': '/dev/mapper/rhel-root', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 18182307840, 'size_available': 15459995648, 'block_size': 4096, 'block_total': 4439040, 'block_available': 3774413, 'block_used': 664627, 'inode_total': 8910848, 'inode_available': 8850623, 'inode_used': 60225, 'uuid': '8134d1d7-92bc-4699-854e-67c36a169723'})
skipping: [node2] => (item={'mount': '/boot', 'device': '/dev/sda1', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 1006632960, 'size_available': 668717056, 'block_size': 4096, 'block_total': 245760, 'block_available': 163261, 'block_used': 82499, 'inode_total': 524288, 'inode_available': 523928, 'inode_used': 360, 'uuid': 'b27641c0-d029-4d62-97b9-9929509c36ff'})
ok: [node1] => (item={'mount': '/nfs/003', 'device': 'escleiron.jagfloriano.com:/srv/samba/compartido_nfs_003', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/mnt', 'device': '//192.168.1.80/compartido', 'fstype': 'cifs', 'options': 'rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=smbuser,uid=0,noforceuid,gid=0,noforcegid,addr=192.168.1.80,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,retrans=1,echo_interval=60,actimeo=1,closetimeo=1', 'size_total': 18182307840, 'size_available': 14461726720, 'block_size': 1024, 'block_total': 17756160, 'block_available': 14122780, 'block_used': 3633380, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': 'N/A'})
ok: [node2] => (item={'mount': '/nfs/001', 'device': 'chasis06nfs.jagfloriano.com:/srv/samba/compartido_nfs_001', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
ok: [node2] => (item={'mount': '/nfs/002', 'device': 'chasis116nfs:/srv/samba/compartido_nfs_002', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
ok: [node2] => (item={'mount': '/nfs/003', 'device': 'escleiron:/srv/samba/compartido_nfs_003', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})

TASK [Collect CIFS mounts (text format)] *******************************************************************************************************************************************************************************************************************************************************
skipping: [node1] => (item={'mount': '/', 'device': '/dev/mapper/rhel-root', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 18182307840, 'size_available': 15454588928, 'block_size': 4096, 'block_total': 4439040, 'block_available': 3773093, 'block_used': 665947, 'inode_total': 8910848, 'inode_available': 8850371, 'inode_used': 60477, 'uuid': '5d6f9d5b-9f52-4542-82de-7cfbd0c1ab18'})
skipping: [node1] => (item={'mount': '/boot', 'device': '/dev/sda1', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 1006632960, 'size_available': 668717056, 'block_size': 4096, 'block_total': 245760, 'block_available': 163261, 'block_used': 82499, 'inode_total': 524288, 'inode_available': 523928, 'inode_used': 360, 'uuid': '8f371388-10e8-4115-9189-41ac30fda258'})
skipping: [node1] => (item={'mount': '/srv/shared', 'device': '/dev/mapper/vg_shared-lv_data', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 42840621056, 'size_available': 42508083200, 'block_size': 4096, 'block_total': 10459136, 'block_available': 10377950, 'block_used': 81186, 'inode_total': 20951040, 'inode_available': 20951037, 'inode_used': 3, 'uuid': 'dea6a144-d98c-4167-b822-1f9e33fe6d5e'})
skipping: [node2] => (item={'mount': '/', 'device': '/dev/mapper/rhel-root', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 18182307840, 'size_available': 15459995648, 'block_size': 4096, 'block_total': 4439040, 'block_available': 3774413, 'block_used': 664627, 'inode_total': 8910848, 'inode_available': 8850623, 'inode_used': 60225, 'uuid': '8134d1d7-92bc-4699-854e-67c36a169723'})
skipping: [node2] => (item={'mount': '/boot', 'device': '/dev/sda1', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 1006632960, 'size_available': 668717056, 'block_size': 4096, 'block_total': 245760, 'block_available': 163261, 'block_used': 82499, 'inode_total': 524288, 'inode_available': 523928, 'inode_used': 360, 'uuid': 'b27641c0-d029-4d62-97b9-9929509c36ff'})
ok: [node1] => (item={'mount': '/mnt', 'device': '//pool_smb.jagfloriano.com/compartido', 'fstype': 'cifs', 'options': 'rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=smbuser,uid=0,noforceuid,gid=0,noforcegid,addr=192.168.1.80,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,retrans=1,echo_interval=60,actimeo=1,closetimeo=1', 'size_total': 18182307840, 'size_available': 14461726720, 'block_size': 1024, 'block_total': 17756160, 'block_available': 14122780, 'block_used': 3633380, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': 'N/A'})
skipping: [node1] => (item={'mount': '/nfs/001', 'device': 'chasis06nfs:/srv/samba/compartido_nfs_001', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
skipping: [node1] => (item={'mount': '/nfs/002', 'device': 'chasis116nfs.jagfloriano.com:/srv/samba/compartido_nfs_002', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
skipping: [node1] => (item={'mount': '/nfs/003', 'device': 'escleiron.jagfloriano.com:/srv/samba/compartido_nfs_003', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
ok: [node2] => (item={'mount': '/mnt', 'device': '//192.168.1.80/compartido', 'fstype': 'cifs', 'options': 'rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=smbuser,uid=0,noforceuid,gid=0,noforcegid,addr=192.168.1.80,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,retrans=1,echo_interval=60,actimeo=1,closetimeo=1', 'size_total': 18182307840, 'size_available': 14461726720, 'block_size': 1024, 'block_total': 17756160, 'block_available': 14122780, 'block_used': 3633380, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/nfs/001', 'device': 'chasis06nfs.jagfloriano.com:/srv/samba/compartido_nfs_001', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/nfs/002', 'device': 'chasis116nfs:/srv/samba/compartido_nfs_002', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/nfs/003', 'device': 'escleiron:/srv/samba/compartido_nfs_003', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14461960192, 'block_size': 524288, 'block_total': 34680, 'block_available': 27584, 'block_used': 7096, 'inode_total': 8910848, 'inode_available': 8850836, 'inode_used': 60012, 'uuid': 'N/A'})

TASK [Aggregate inventory lines on localhost] **************************************************************************************************************************************************************************************************************************************************
changed: [node1 -> localhost]

PLAY RECAP *************************************************************************************************************************************************************************************************************************************************************************************
node1                      : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node2                      : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
</syntaxhighlight>

Script para analizar los resultados obtenidos con el playbook:

<syntaxhighlight lang="bash">
[root@icecube Checks]# chmod +x mount_inventory_menu.sh
[root@icecube Checks]# dos2unix mount_inventory_menu.sh
dos2unix: converting file mount_inventory_menu.sh to Unix format...
</syntaxhighlight>

<syntaxhighlight lang="bash">
[root@icecube Checks]# ./mount_inventory_menu.sh mount_inventory_2026-02-02_13-51-15.txt

======================================
 MOUNT INVENTORY MENU
======================================
1) Review analyzed results
2) Show unique servers
3) Convert inventory to CSV
4) Exit
--------------------------------------
Option: 1

==============================
 TOTAL SHARES
==============================
     1  //pool_smb.jagfloriano.com/compartido
     1  escleiron:/srv/samba/compartido_nfs_003
     1  escleiron.jagfloriano.com:/srv/samba/compartido_nfs_003
     1  chasis116nfs:/srv/samba/compartido_nfs_002
     1  chasis116nfs.jagfloriano.com:/srv/samba/compartido_nfs_002
     1  chasis06nfs:/srv/samba/compartido_nfs_001
     1  chasis06nfs.jagfloriano.com:/srv/samba/compartido_nfs_001
     1  //192.168.1.80/compartido

------------------------------
TOTAL 8
------------------------------

==============================
 TOTAL MOUNTPOINTS
==============================
     2  /nfs/003
     2  /nfs/002
     2  /nfs/001
     2  /mnt

------------------------------
TOTAL 8
------------------------------
Press ENTER to continue..

======================================
 MOUNT INVENTORY MENU
======================================
1) Review analyzed results
2) Show unique servers
3) Convert inventory to CSV
4) Exit
--------------------------------------
Option: 2

==============================
 SERVERS
==============================
node1
node2

------------------------------
TOTAL 2
------------------------------
Press ENTER to continue..

======================================
 MOUNT INVENTORY MENU
======================================
1) Review analyzed results
2) Show unique servers
3) Convert inventory to CSV
4) Exit
--------------------------------------
Option: 3
Confirm CSV conversion? (y/n): y
CSV generated successfully: mount_inventory_2026-02-02_13-51-15.csv
Press ENTER to continue..
[root@icecube Checks]#
</syntaxhighlight>

Salida en csv por si fuera necesario:
<syntaxhighlight lang="bash">
[root@icecube Checks]# cat mount_inventory_2026-02-02_13-51-15.csv
SERVER,SHARE,MOUNTPOINT,TYPE
node1,chasis06nfs:/srv/samba/compartido_nfs_001,/nfs/001,NFS
node1,chasis116nfs.jagfloriano.com:/srv/samba/compartido_nfs_002,/nfs/002,NFS
node1,escleiron.jagfloriano.com:/srv/samba/compartido_nfs_003,/nfs/003,NFS
node1,//pool_smb.jagfloriano.com/compartido,/mnt,CIFS
node2,chasis06nfs.jagfloriano.com:/srv/samba/compartido_nfs_001,/nfs/001,NFS
node2,chasis116nfs:/srv/samba/compartido_nfs_002,/nfs/002,NFS
node2,escleiron:/srv/samba/compartido_nfs_003,/nfs/003,NFS
node2,//192.168.1.80/compartido,/mnt,CIFS
</syntaxhighlight>

=== Umount ===
<syntaxhighlight lang="bash">
[root@icecube Umount]# ls -lrt
total 8
-rw-r--r--. 1 root root 1057 Feb  1 14:07 umount_share.yml
-rw-r--r--. 1 root root  643 Feb  1 14:07 generate_variable_host_patter.sh
</syntaxhighlight>

Script para generar las varaibles necesarias para poder desmontar los share encontrados:
<syntaxhighlight lang="bash">
[root@icecube Umount]# chmod +x generate_variable_host_patter.sh
[root@icecube Umount]# dos2unix generate_variable_host_patter.sh
dos2unix: converting file generate_variable_host_patter.sh to Unix format...
</syntaxhighlight>

<syntaxhighlight lang="bash">
[root@icecube Umount]# ./generate_variable_host_patter.sh ../Checks/mount_inventory_2026-02-02_13-51-15.txt
File fstab_pattern.yml generated with this variables:
fstab_host_pattern: "//192.168.1.80|chasis06nfs|chasis06nfs.jagfloriano.com|chasis116nfs|chasis116nfs.jagfloriano.com|escleiron|escleiron.jagfloriano.com|//pool_smb.jagfloriano.com"
[root@icecube Umount]# ls -lrt
total 12
-rw-r--r--. 1 root root 1057 Feb  1 14:07 umount_share.yml
-rwxr-xr-x. 1 root root  614 Feb  2 13:54 generate_variable_host_patter.sh
-rw-r--r--. 1 root root  186 Feb  2 13:55 fstab_pattern.yml
[root@icecube Umount]# cat fstab_pattern.yml
---
fstab_host_pattern: "//192.168.1.80|chasis06nfs|chasis06nfs.jagfloriano.com|chasis116nfs|chasis116nfs.jagfloriano.com|escleiron|escleiron.jagfloriano.com|//pool_smb.jagfloriano.com"
[root@icecube Umount]#

[root@icecube Umount]# ansible-playbook -i ../inventory umount_share.yml
[WARNING]: Collection ansible.posix does not support Ansible version 2.14.18

PLAY [all] *************************************************************************************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************************************************************************************************************************************
ok: [node1]
ok: [node2]

TASK [Unmount NFS filesystems from selected sources] *******************************************************************************************************************************************************************************************************************************************
skipping: [node1] => (item={'mount': '/', 'device': '/dev/mapper/rhel-root', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 18182307840, 'size_available': 15452352512, 'block_size': 4096, 'block_total': 4439040, 'block_available': 3772547, 'block_used': 666493, 'inode_total': 8910848, 'inode_available': 8850371, 'inode_used': 60477, 'uuid': '5d6f9d5b-9f52-4542-82de-7cfbd0c1ab18'})
skipping: [node1] => (item={'mount': '/boot', 'device': '/dev/sda1', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 1006632960, 'size_available': 668717056, 'block_size': 4096, 'block_total': 245760, 'block_available': 163261, 'block_used': 82499, 'inode_total': 524288, 'inode_available': 523928, 'inode_used': 360, 'uuid': '8f371388-10e8-4115-9189-41ac30fda258'})
skipping: [node1] => (item={'mount': '/srv/shared', 'device': '/dev/mapper/vg_shared-lv_data', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 42840621056, 'size_available': 42508083200, 'block_size': 4096, 'block_total': 10459136, 'block_available': 10377950, 'block_used': 81186, 'inode_total': 20951040, 'inode_available': 20951037, 'inode_used': 3, 'uuid': 'dea6a144-d98c-4167-b822-1f9e33fe6d5e'})
skipping: [node1] => (item={'mount': '/mnt', 'device': '//pool_smb.jagfloriano.com/compartido', 'fstype': 'cifs', 'options': 'rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=smbuser,uid=0,noforceuid,gid=0,noforcegid,addr=192.168.1.80,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,retrans=1,echo_interval=60,actimeo=1,closetimeo=1', 'size_total': 18182307840, 'size_available': 14453321728, 'block_size': 1024, 'block_total': 17756160, 'block_available': 14114572, 'block_used': 3641588, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/', 'device': '/dev/mapper/rhel-root', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 18182307840, 'size_available': 15460462592, 'block_size': 4096, 'block_total': 4439040, 'block_available': 3774527, 'block_used': 664513, 'inode_total': 8910848, 'inode_available': 8850623, 'inode_used': 60225, 'uuid': '8134d1d7-92bc-4699-854e-67c36a169723'})
skipping: [node2] => (item={'mount': '/boot', 'device': '/dev/sda1', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 1006632960, 'size_available': 668717056, 'block_size': 4096, 'block_total': 245760, 'block_available': 163261, 'block_used': 82499, 'inode_total': 524288, 'inode_available': 523928, 'inode_used': 360, 'uuid': 'b27641c0-d029-4d62-97b9-9929509c36ff'})
skipping: [node2] => (item={'mount': '/mnt', 'device': '//192.168.1.80/compartido', 'fstype': 'cifs', 'options': 'rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=smbuser,uid=0,noforceuid,gid=0,noforcegid,addr=192.168.1.80,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,retrans=1,echo_interval=60,actimeo=1,closetimeo=1', 'size_total': 18182307840, 'size_available': 14453321728, 'block_size': 1024, 'block_total': 17756160, 'block_available': 14114572, 'block_used': 3641588, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': 'N/A'})
changed: [node2] => (item={'mount': '/nfs/001', 'device': 'chasis06nfs.jagfloriano.com:/srv/samba/compartido_nfs_001', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
changed: [node1] => (item={'mount': '/nfs/001', 'device': 'chasis06nfs:/srv/samba/compartido_nfs_001', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
changed: [node2] => (item={'mount': '/nfs/002', 'device': 'chasis116nfs:/srv/samba/compartido_nfs_002', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
changed: [node1] => (item={'mount': '/nfs/002', 'device': 'chasis116nfs.jagfloriano.com:/srv/samba/compartido_nfs_002', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
changed: [node2] => (item={'mount': '/nfs/003', 'device': 'escleiron:/srv/samba/compartido_nfs_003', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
changed: [node1] => (item={'mount': '/nfs/003', 'device': 'escleiron.jagfloriano.com:/srv/samba/compartido_nfs_003', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})

TASK [Unmount CIFS filesystems from selected sources] ******************************************************************************************************************************************************************************************************************************************
skipping: [node1] => (item={'mount': '/', 'device': '/dev/mapper/rhel-root', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 18182307840, 'size_available': 15452352512, 'block_size': 4096, 'block_total': 4439040, 'block_available': 3772547, 'block_used': 666493, 'inode_total': 8910848, 'inode_available': 8850371, 'inode_used': 60477, 'uuid': '5d6f9d5b-9f52-4542-82de-7cfbd0c1ab18'})
skipping: [node1] => (item={'mount': '/boot', 'device': '/dev/sda1', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 1006632960, 'size_available': 668717056, 'block_size': 4096, 'block_total': 245760, 'block_available': 163261, 'block_used': 82499, 'inode_total': 524288, 'inode_available': 523928, 'inode_used': 360, 'uuid': '8f371388-10e8-4115-9189-41ac30fda258'})
skipping: [node1] => (item={'mount': '/srv/shared', 'device': '/dev/mapper/vg_shared-lv_data', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 42840621056, 'size_available': 42508083200, 'block_size': 4096, 'block_total': 10459136, 'block_available': 10377950, 'block_used': 81186, 'inode_total': 20951040, 'inode_available': 20951037, 'inode_used': 3, 'uuid': 'dea6a144-d98c-4167-b822-1f9e33fe6d5e'})
skipping: [node2] => (item={'mount': '/', 'device': '/dev/mapper/rhel-root', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 18182307840, 'size_available': 15460462592, 'block_size': 4096, 'block_total': 4439040, 'block_available': 3774527, 'block_used': 664513, 'inode_total': 8910848, 'inode_available': 8850623, 'inode_used': 60225, 'uuid': '8134d1d7-92bc-4699-854e-67c36a169723'})
skipping: [node2] => (item={'mount': '/boot', 'device': '/dev/sda1', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 1006632960, 'size_available': 668717056, 'block_size': 4096, 'block_total': 245760, 'block_available': 163261, 'block_used': 82499, 'inode_total': 524288, 'inode_available': 523928, 'inode_used': 360, 'uuid': 'b27641c0-d029-4d62-97b9-9929509c36ff'})
changed: [node1] => (item={'mount': '/mnt', 'device': '//pool_smb.jagfloriano.com/compartido', 'fstype': 'cifs', 'options': 'rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=smbuser,uid=0,noforceuid,gid=0,noforcegid,addr=192.168.1.80,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,retrans=1,echo_interval=60,actimeo=1,closetimeo=1', 'size_total': 18182307840, 'size_available': 14453321728, 'block_size': 1024, 'block_total': 17756160, 'block_available': 14114572, 'block_used': 3641588, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': 'N/A'})
skipping: [node1] => (item={'mount': '/nfs/001', 'device': 'chasis06nfs:/srv/samba/compartido_nfs_001', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
skipping: [node1] => (item={'mount': '/nfs/002', 'device': 'chasis116nfs.jagfloriano.com:/srv/samba/compartido_nfs_002', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
skipping: [node1] => (item={'mount': '/nfs/003', 'device': 'escleiron.jagfloriano.com:/srv/samba/compartido_nfs_003', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.81,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
changed: [node2] => (item={'mount': '/mnt', 'device': '//192.168.1.80/compartido', 'fstype': 'cifs', 'options': 'rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=smbuser,uid=0,noforceuid,gid=0,noforcegid,addr=192.168.1.80,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,retrans=1,echo_interval=60,actimeo=1,closetimeo=1', 'size_total': 18182307840, 'size_available': 14453321728, 'block_size': 1024, 'block_total': 17756160, 'block_available': 14114572, 'block_used': 3641588, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/nfs/001', 'device': 'chasis06nfs.jagfloriano.com:/srv/samba/compartido_nfs_001', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/nfs/002', 'device': 'chasis116nfs:/srv/samba/compartido_nfs_002', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})
skipping: [node2] => (item={'mount': '/nfs/003', 'device': 'escleiron:/srv/samba/compartido_nfs_003', 'fstype': 'nfs4', 'options': 'rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.82,local_lock=none,addr=192.168.1.80', 'size_total': 18182307840, 'size_available': 14453571584, 'block_size': 524288, 'block_total': 34680, 'block_available': 27568, 'block_used': 7112, 'inode_total': 8910848, 'inode_available': 8850833, 'inode_used': 60015, 'uuid': 'N/A'})

PLAY RECAP *************************************************************************************************************************************************************************************************************************************************************************************
node1                      : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node2                      : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

[root@icecube Umount]#
</syntaxhighlight>

Revision:
<syntaxhighlight lang="bash">
[root@icecube Umount]# ansible all -i ../inventory -m shell -a "df -hT|grep -e cifs -e nfs" -b
node2 | FAILED | rc=1 >>
non-zero return code
node1 | FAILED | rc=1 >>
non-zero return code
[root@icecube Umount]#
</syntaxhighlight>

=== Mount ===

<syntaxhighlight lang="bash">
[root@icecube Mount]# ls -lrt
total 12
-rw-r--r--. 1 root root 575 Feb  1 14:07 mount_state_after_snapshot.yml
-rw-r--r--. 1 root root 668 Feb  1 14:07 mount_snapshot_txt_to_yml.sh
-rw-r--r--. 1 root root 116 Feb  1 14:07 mount_fstab_shares.yml
</syntaxhighlight>

<syntaxhighlight lang="bash">
[root@icecube Mount]# chmod +x mount_snapshot_txt_to_yml.sh
[root@icecube Mount]# dos2unix mount_snapshot_txt_to_yml.sh
dos2unix: converting file mount_snapshot_txt_to_yml.sh to Unix format...
[root@icecube Mount]# 
</syntaxhighlight>

<syntaxhighlight lang="bash">
[root@icecube Mount]# ls -lrt
total 16
-rw-r--r--. 1 root root 575 Feb  1 14:07 mount_state_after_snapshot.yml
-rw-r--r--. 1 root root 116 Feb  1 14:07 mount_fstab_shares.yml
-rwxr-xr-x. 1 root root 635 Feb  2 13:56 mount_snapshot_txt_to_yml.sh
-rw-r--r--. 1 root root 170 Feb  2 13:57 mount_snapshot.yml

[root@icecube Mount]# cat mount_snapshot.yml
mounts:
  node1:
  - path: /nfs/001
  - path: /nfs/002
  - path: /nfs/003
  - path: /mnt
  node2:
  - path: /nfs/001
  - path: /nfs/002
  - path: /nfs/003
  - path: /mnt
[root@icecube Mount]#
</syntaxhighlight>

<syntaxhighlight lang="bash">
[root@icecube Mount]# ansible-playbook -i ../inventory mount_state_after_snapshot.yml

PLAY [all] *************************************************************************************************************************************************************************************************************************************************************************************

TASK [Load mount snapshot] *********************************************************************************************************************************************************************************************************************************************************************
ok: [node1 -> localhost]
ok: [node2 -> localhost]

TASK [Mount paths defined in fstab] ************************************************************************************************************************************************************************************************************************************************************
changed: [node1] => (item={'path': '/nfs/001'})
changed: [node2] => (item={'path': '/nfs/001'})
changed: [node1] => (item={'path': '/nfs/002'})
changed: [node2] => (item={'path': '/nfs/002'})
changed: [node1] => (item={'path': '/nfs/003'})
changed: [node2] => (item={'path': '/nfs/003'})
changed: [node1] => (item={'path': '/mnt'})
changed: [node2] => (item={'path': '/mnt'})

PLAY RECAP *************************************************************************************************************************************************************************************************************************************************************************************
node1                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node2                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0


</syntaxhighlight>

Revision:

<syntaxhighlight lang="bash">
[root@icecube Mount]# ansible all -i ../inventory -m shell -a "df -hT|grep -e cifs -e nfs" -b
node2 | CHANGED | rc=0 >>
chasis06nfs.jagfloriano.com:/srv/samba/compartido_nfs_001 nfs4       17G  3.5G   14G  21% /nfs/001
chasis116nfs:/srv/samba/compartido_nfs_002                nfs4       17G  3.5G   14G  21% /nfs/002
escleiron:/srv/samba/compartido_nfs_003                   nfs4       17G  3.5G   14G  21% /nfs/003
//192.168.1.80/compartido                                 cifs       17G  3.5G   14G  21% /mnt
node1 | CHANGED | rc=0 >>
chasis06nfs:/srv/samba/compartido_nfs_001                  nfs4       17G  3.5G   14G  21% /nfs/001
chasis116nfs.jagfloriano.com:/srv/samba/compartido_nfs_002 nfs4       17G  3.5G   14G  21% /nfs/002
escleiron.jagfloriano.com:/srv/samba/compartido_nfs_003    nfs4       17G  3.5G   14G  21% /nfs/003
//pool_smb.jagfloriano.com/compartido                      cifs       17G  3.5G   14G  21% /mnt
</syntaxhighlight>
