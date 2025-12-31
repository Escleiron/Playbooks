# Filesystem Health & Recovery Playbook

This Ansible playbook checks critical filesystems, performs conditional cleanup to free space, and runs basic recovery actions (time sync and service restarts). It finishes by verifying CentrifyDC connectivity and prints a final status.

Targets: all hosts in your inventory
Privileges: requires become: true (root)
Facts: gather_facts: false

## What it does

1. RW/RO sanity check
    - Verifies that /var and /tmp are read-write using findmnt.
    - If either is read-only, marks the run as failure and skips cleanup/recovery blocks.
 
2. Space cleanup (only if RW and initial checks passed)

    - Reads usage of /tmp and /var via df.
    - If usage ≥ 80%:
        * /tmp: deletes files older than 3 days, excluding files matching .sap* (e.g. .sap* are preserved).
        * /var: ensures directories /var/log/collectl and /var/log/sosreport exist; removes files older than 3 days in both.

3. Recovery actions (only if still not failed)

    - Restarts chronyd.
    - Forces time sync (chronyc -a makestep) and syncs HW clock (hwclock --systohc).

4. Restarts centrifydc.

    - CentrifyDC verification
    - Runs adinfo and checks for CentrifyDC mode: connected.

5. Final status
    - Prints: The final status is: success|failure.