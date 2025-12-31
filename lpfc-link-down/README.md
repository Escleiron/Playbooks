# lpfc Link Down


This Ansible playbook is designed to detect LPFC (Fibre Channel) link down events on servers. It checks the status of Host Bus Adapters (HBAs) and determines whether any of them are in a "Linkdown" state. If the server is virtual (VMware), no HBA checks are performed. Otherwise, the script scans the system for HBAs and determines their status.
Requirements

    Ansible: Must be installed on the machine running the playbook.
    Access to servers: The playbook should be executed on all configured hosts.
    Superuser permissions: The playbook requires elevated privileges (become: yes) to execute certain commands.

## Playbook Description

This playbook performs the following steps:

    Get the server type:
        Uses the dmidecode command to determine the system manufacturer and register the server type.

    Verify if the server is virtual (VMware):
        If the server is virtual, no further checks are performed.

    Check the status of HBAs:
        Retrieves the current state of all Fibre Channel (FC) host adapters.
        If any HBA is in a "Linkdown" state, the system is marked as "failure". Otherwise, it is marked as "success".

    Handle errors:
        If any error occurs during execution, the status is automatically set to "failure".

## How to Run

To execute the playbook, use the following Ansible command:

    ansible-playbook -i inventory lpfc_link_down_ad_hoc.yml

Ensure that:

    The hosts are correctly configured in your Ansible inventory.
    You have the necessary permissions to run the playbook.

This README provides a clear and concise explanation of the playbook, making it easy for users to understand its functionality and execution.