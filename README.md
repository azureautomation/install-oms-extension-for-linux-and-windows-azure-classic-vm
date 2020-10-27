Install OMS extension for Linux and Windows Azure classic VM
============================================================

            

 

Installs OMS extension for Linux and Windows Azure classic Virtual Machines.

The Runbook takes Subscription Id, Subscription name and VM name and installs OMS Agent on the VM
The runbook needs classic run as connection string to access VM in other subscriptions.
The Runbook also takes WorkspaceId and WorkspaceKey as input.

This Runbook is a child runbook for Onboard-ClassicVMsForOMSUpdateManagement.ps1.

Onboard-ClassicVMsForOMSUpdateManagement invokes this runbook for each VM for a given comma seperated list of Azure subscriptions.

This can be used in scenario to mass onboard list of Azure VM for OMS update management solution.

 

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
