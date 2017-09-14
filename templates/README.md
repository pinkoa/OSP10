# Introduction
This repo contains the master OSP 10 templates. Do not check your locally deployed templated into this repo, rather create a new repo under the vcp-sites group.



# About VCP Git Repo
This repo houses VCP templates for distribution to other internal Verizon Groups.

Two types of repos will be used to check in templates
* Master Repo - Generic templates to be cloned for local deployments
* Site Specific Repos - A repo that is a clone of a Master repo, modified, used to deploy a specific environment, and then checked into git for management.


# How to Create a Site Specific Repo
After deploying using these master templates, you will need to check your specific templates into GIT. Make sure to include the deploy script, undercloud.conf, and network-environment.yaml (the top-level template). You will need to log into the [master git hub server](http://tpavcpgit.vici.verizon.com/dashboard/projects) and create a new repo by clicking on "New Project". Choose your *project path* and *project name*. Add a description to your project, leave *Visibility Level* as *Private* and select *Create Project*.

Then follow the instructions to push files into the repo. Example below.


`cd existing_folder
git init
git remote add origin git@tpavcpgit.vici.verizon.com:my-test-site/test-proj.git
git add .
git commit
git push -u origin master`

You will be prompted to enter your credentials


# Create a README.md
When creating a repo, you should also create a README.md. This file should provide a brief overview of the deployment. 

Include the following in your README.md
* Site
* Custom Templates Used
* Any additional information required


# How to use the deploy script
Look for a deployment script with the name deploy.sh or deploy-oneliner.sh. This will contain the exact deploy command used to deploy using this repo. Additional templates can be included in your deployment by including them using the *-e* option.



# How to use the custom Post/Pre install Templates.
Verizon TCP Labs use mulitple pre and post deployment templates for customizing OSP deployments. Required templates will differ per environment depending on storage backend, integration into Active Directory, SSL/TLS, etc. See link below for more info.

[http://wiki.vici.verizon.com/wiki/OpenStack_director_Pre-Deploy_using_Multiple_Configuration_Files](http://wiki.vici.verizon.com/wiki/OpenStack_director_Pre-Deploy_using_Multiple_Configuration_Files)
 

