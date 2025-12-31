# Multipath_Failing


This Ansible playbook is designed to perform a multipath recovery action on servers. Its main functionality is to check the state of active paths on multipath disks and determine if the system is in a healthy state. If the server is virtual (VMware), no further checks are performed. If the server is not virtual, it checks that all multipath disks have the same number of active paths.
Requirements

    Ansible: Should be installed on the machine where the playbook will be run.
    Access to servers: The playbook should be executed on all configured hosts.
    Superuser permissions: The playbook requires elevated privileges (become: yes) to execute certain commands.

## Playbook Description

This playbook performs the following steps:

    Get the server type:
        It uses the dmidecode command to retrieve the system manufacturer and registers the server type.
    Verify if the server is virtual (VMware):
        If the server is virtual, it sets the status to "success" without performing further checks.
    Check active paths and multipath disks:
        If the server is not virtual, it checks the number of active paths and ensures that all multipath disks have the same number of active paths.
    Determine the outcome:
        If all disks have 4 active paths, it is considered a "success". Otherwise, it is marked as "failure".
    Error handling:
        If any error occurs during the process, the status is set to "failure".


## How to Run

To execute the playbook, use the following Ansible command:

    ansible-playbook -i inventory multipath_ad_hoc.yml

Make sure that the hosts are correctly configured in your Ansible inventory and that you have the necessary permissions to run the playbook.

This README provides a comprehensive guide on how the playbook works and how to use it, ensuring that any user who reviews it can easily understand its purpose and how to execute it.