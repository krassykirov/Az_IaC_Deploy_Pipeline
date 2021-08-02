# Introduction 
Deploy Multiple Azure VMs and related resources via Azure Devops Pipeline

# Jobs sequence and methods used for deployment 

1.	Deploy VNET                                     - ARM Template
2.  Peer Vnet										- PowerShell Script
3.	Deploy KeyVault and DiskEncryptionSet           - PowerShell Script 
4.	Deploy VM Boot Diagnostic Storage Account       - ARM Template
5.	Deploy Multiple VMs                             - ARM Template
6.  Enable VM Backup					            - PowerShell Script	



