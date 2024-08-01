Readme file for csr-approval

To ensure that the kubeconfig used by the CSR management script has sufficient permissions, you should perform all the steps on the Helper node. This node is already set up for centralized functions and is suitable for running scripts and managing configurations.
Steps to Ensure Sufficient Permissions

1    Log in to the Helper Node:
    Ensure you are logged into the Helper node where you will be running the CSR management script.

2    Create or Use an Admin Kubeconfig:
    Ensure the kubeconfig file you are using has cluster admin privileges. This can typically be done by using the admin kubeconfig file generated during the OpenShift installation.

    If you have the admin kubeconfig file, copy it to the Helper node:
    #scp /path/to/admin.kubeconfig helper:/path/to/admin.kubeconfig

3    Set the KUBECONFIG Environment Variable:
	Set the KUBECONFIG environment variable to use the admin kubeconfig:
	#export KUBECONFIG=/path/to/admin.kubeconfig


4	Verify Access:
	Verify that the kubeconfig has the necessary permissions by running a few oc commands:


	#oc whoami
	#oc get nodes
	#oc get csr

5	Run the Prerequisites Deployment Script:

    This script installs the necessary tools, checks the OS, gathers the email credentials and SMTP server address, and sets up the crontab for running the CSR approval script every 5 minutes.
    Example: ./csr-approval-prereqs.sh




6	Ensure the CSR management script uses this kubeconfig file. 
*****The admin kubeconfig file is typically generated during the OpenShift installation process and is located on the machine where the OpenShift installer was run. Here are the typical locations for the kubeconfig file based on the method you used to install OpenShift:

   		If you used the OpenShift Installer (openshift-install):
    	The admin kubeconfig file is usually located in the directory where you executed the openshift-install command. For example, if you ran the installer from /root/openshift-install, the admin kubeconfig file would be located at:
   		 /root/openshift-install/auth/kubeconfig


   	Copying the Admin Kubeconfig to the Helper Node
   	Here’s how you can copy the admin kubeconfig file from the machine where the OpenShift installation was performed to the Helper node:

    Locate the kubeconfig file:
    a.	Determine the path to the kubeconfig file. For example:

    	#ls /root/openshift-install/auth/kubeconfig

    b. 	Copy the kubeconfig file to the Helper node:
    	#scp /root/openshift-install/auth/kubeconfig helper:/home/user/admin.kubeconfig

	c. 	Set up the KUBECONFIG environment variable on the Helper node:

		#ssh helper
		#export KUBECONFIG=/home/user/admin.kubeconfig

	d. 	Verify the setup:
		Check if you can use the oc command to interact with the cluster from the Helper node:
		#oc get nodes
		
	By following these steps, you will ensure that the Helper node can properly interact with the OpenShift cluster using the admin credentials.

7	The CSR Approval Script:

    This script will be automatically called every 5 minutes by the cron job set up by the prerequisites script.
    It logs all actions to /var/log/csr-approval.log.

8	Check Logs:

    Prerequisites log: /var/log/csr-approval-prereqs.log
    CSR approval log: /var/log/csr-approval.log

9	Configuration File:

    The email and SMTP details will be stored in /etc/csr-approval-config.
