# MCC-MKE-demo_environment_AWS
This will create you a MCC + first MKE child cluster on AWS
# 
Just read the Word document explaining how this is going to work.

In general:
Step 1: Prepares the bootstrap node
  - Downloads the software currently MCC 2.10
  - Installs docker
  - Installs and configures AWSCLI

Step 1a: Internal or external
  - Meaning you would already have a bootstrapper user (Internal) 
  or you don't (any customer).
  If you don't the EC2 instance temporarly needs Admin rights so it can deploy an AWS CloudFormation script which creates the user + policies needed.
  Then you would allign the Sourceme.ksh file with its IAM credentials + remove the Admin rights from the EC2.
  If you already have the credentials then fill them into the sourceme.ksh file BEFORE running step 1. Admin rights are then NOT needed.
  
  
  
  Step 2:
  - Install MCC
  - Install MKE child cluster called demo + creating a namespace demo.
  - I have gift wrapped the normal bootstrapper.sh so the customer will not see the (expected) errors of the MCC installation.
    This scripts just generates a . every minute. It should finish before the | finish line (normally).
    If it doesn't and/or the customers wants to see the real installation show - tail kaas-bootstrap/nohup.out from the installation directory.
    Because the wrapper is looking for the right (read: finished) end-result. With a real error that will never come.... ;-)
    My good practise is to look for the MCC bastion is come online - after that I will have a (tea) break of about 45 minutes as I expect the script to finish succesfull.
    
    
    Step 3: Expect more to come as my peers are creating use cases and MSR into the environment.
    
