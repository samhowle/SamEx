# Salesforce DX User Guide

This guide helps Salesforce developers who are new to Salesforce Developer Experience (SFDX) and Visual Studio Code to get started. This guide includes information on how to set up VS Code with Salesforce Extensions for VS Code, connect to orgs through Salesforce CLI, connect to a source repository, and how to effectively manage source control using tools such as the , and Git.

#### **Official Documentation**

[Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)

[Salesforce Command Line Interface (CLI)](https://developer.salesforce.com/tools/sfdxcli])

#### **Trailhead Modules (New to SFDX? Start here!)**

[Quick Start: VS Code for SFDX](https://trailhead.salesforce.com/content/learn/projects/quickstart-vscode-salesforce)

[Quick Start: SFDX Development](https://trailhead.salesforce.com/content/learn/projects/quick-start-salesforce-dx)

---

## **Part 1: Configure VS Code**

* Install the latest version of Visual Studio Code onto your computer
* Install the latest version of Salesforce CLI (see link above under "Official Documentation")

### Setting Up Git

* Install the latest version of Git, if not already done. This can be found on [Git's official website](https://git-scm.com/downloads).

* Once Git is installed, you need to configure your Git user details so that information is associated with the commits you make in the repository. This can be done through the `git config` command to specify your name and email address that Git will associate with your commits. Execute the following commands with your name and email address:

	`git config --global user.name "Your Name"`

	`git config --global user.email "youremail@domain.com"`

* Confirm yout Git configuration items by executing the following command:

	`git config --list`

* Which will return the following output:

<div class="context">

	user.name=Your Name
	user.email=youremail@domain.com

</div>

* Set VS Code as default Git editor when prompting user input

	##### `git config --global core.editor "code --wait"`

### Clone the remote source repository from Bitbucket into a local copy on your computer
* Remote repository: https://stash.corp.appnexus.com/projects/XAN/repos/app_sfdxappnexus/browse
	* From the Terminal in VS Code, navigate to the directory where you want to save the repository folder
	* Clone the repository from Bitbucket
		`git clone https://github.com/samhowle/SamEx.git`

	**Documentation**
	* Cloning a Repository: https://www.atlassian.com/git/tutorials/setting-up-a-repository/git-clone
	* Introduction to Linux terminal commands: https://maker.pro/linux/tutorial/basic-linux-commands-for-beginners
    	* `pwd` --> "Print working directory" (returns the current directory path your terminal has open)
    	* `ls` --> List files and folders within the current directory
    	* `cd` --> "Change directory" (follow this command with a path name you want to open)

###
### **VS Code Extensions**

* Install required VS Code Extensions
	* [Salesforce Extension Pack](https://developer.salesforce.com/tools/vscode/)
	* [Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph)
		* ##### Configure Issue Linking (to automatically convert Jira ticket numbers into links)
			* ##### Issue Regex: `([SFA]+-\d+)`
			* ##### Issue URL: https://jira.xandr-services.com/browse/$1
	* [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)
	* [Salesforce Package.xml Generator Extension for VS Code](https://marketplace.visualstudio.com/items?itemName=VignaeshRamA.sfdx-package-xml-generator)
	* [Prettier - Code formatter](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
	* [TODO Highlight v2](https://marketplace.visualstudio.com/items?itemName=jgclark.vscode-todo-highlight)
* (Optional) Install additional utility extensions
	* [VSCode Icons](https://marketplace.visualstudio.com/items?itemName=vscode-icons-team.vscode-icons)
	* [Bookmarks](https://marketplace.visualstudio.com/items?itemName=alefragnani.Bookmarks)
	* [Sort Lines](https://marketplace.visualstudio.com/items?itemName=Tyriar.sort-lines)
### **VS Code Settings**
The next step is to configure your `settings.json` file which contains the settings configuration for VS Code on your machine. This file can be found in the following directory (MacOS) -->

**`~/Library/Application Support/Code/User/settings.json`**

Required settings for this team are included below, but it's **recommended to start off with the `recommended-settings.json` file in this root directory**. This will contain all required team settings along with additional recommendations for a smoother development experience in VS Code. Please make sure to install the above VS Code extensions first before updating the sfdx-project.json file since some of these settings directly relate to extensions.

<br>


#### **Required**
* Tab width set to 4 spaces
	##### `"editor.tabSize": 4,`

	##### `"prettier.tabWidth": 4,`

* Auto-remove trailing whitespace

	##### `"files.trimTrailingWhitespace": true,`
* Render whitespace and ensure that tabs are preferred over spaces

	##### `"editor.renderWhitespace": "boundary",`
	##### `"editor.detectIndentation": false,`
	##### `"editor.insertSpaces": false,`
	##### `"diffEditor.ignoreTrimWhitespace": true,`

* ##### **IMPORTANT** - Use the `Convert Indentation to Tabs` VS Code command often. This will automatically convert spaces to tabs for consistent whitespace rendering (which otherwise will be recognized as a change to the file, even if no functional changes were made.)

#### **Recommended**
* Theme: Dark+ (default dark)
	##### Dark theme and syntax highlighting to help reduce eye strain and to identify keywords and recognized syntax in code.
	<br>
---

## **Part 2: Branching Model**

There are two primary branches that contain shared development work from the entire team, which are the `master` and `develop` branches.

### **master (Production Branch)**

The **master** branch represents the "source of truth" for what is currently (supposed to be) in the production org. In theory, this branch should be "deployable" meaning that it could be deployed to production at any time since it should contain the exact version that's been approved and testing for Production. This includes all changes from the previous release, and then any hotfix branches that were deployed mid-sprint for various updates that were deemed to be made available right away (routine maintenance updates, fixing production errors, etc.).

### **develop (QA Branch)**

The **develop** branch contains all on-going work that has passed the code review stage and is ready for QA testing and sign-off. This branch generally corresponds to the version that the **QA** sandbox is running on, and will be a combination of everything in **master** plus open feature branches that have been completed and merged into the shared source. Once a developer has completed the work for a Jira ticket, and done their own smoke-testing to verify that it's complete and ready for more thorough QA testing, they should create a Pull Request from the feature branch into develop which would then be merged once the code review is passed.

### **staging (UAT Branch)**

The **staging** branch is used for tickets that have passed QA testing and are ready to be deployed to UAT for final stakeholder review & sign-off. **This branch should reflect what version is currently live in the UAT sandbox, even if they are not yet signed-off for Production**. Once tickets are confirmed that they are ready for production deployment then they should be promoted to the current **release/** branch. If bugs and/or additional changes are required as a result of UAT review, then a **bugfix/** branch should be created to track those fixes before re-testing. This **staging** branch was created 10/25/2022 to help avoid conflicts where tickets had already been merged to the release branch for UAT review, but ultimately were not ready for that sprint's release and had to be removed. This can happen often if additional requirements are requested, conflicts were identified, or if the business is not ready for the changes to be live in production for any reason.


Beyond **master**, **develop**, and **staging** there are a few standardized prefixes that are to be used to identify the purpose of a "short-lived" branch that is created during development and before being merged upstream (first into develop, and eventually into master). Depending on the situation you will need to identify the branch with a "type" which is done by adding a prefix to the beginning of the branch name so that it can categorized and merged appropriately.

### **feature/**
The most common type, feature branches correspond 1-1 with a Jira ticket or a unique set of changes for new functionality. These are always **created from develop**, and once the work is complete will be submitted as a Pull Request back into develop that's merged once approved. Feature branches will be deleted at the end of the sprint once the work has been merged, or deleted entirely if the feature request is cancelled. In some cases, a feature branch will carry into the next sprint if the work is not fully completed/tested/signed-off by the end of it's intended release. When this happens, the feature branch should be rebased on develop once that sprint's release is complete and merged into develop (so that the feature branch will then be working from the latest version of develop with the latest commits). This can be done with the following command while the feature branch is checked out locally-->

`git pull --rebase origin develop`

### **release/**
One release branch is created for each Sprint, and is formatted as `release/year-quarter-sprintnumber` (ie- **release/2021-2Q-6**). The release branch is typically created at the beginning of a new sprint and changes are merged from the **staging** branch once they've received client sign-off during the UAT review (which occurs once the ticket has already passed code review and QA testing). This release branch contains pending production changes which are typically deployed at the end of the current sprint, but can also occur during mid-sprint deployments if they changes are needed sooner.

Following a production sprint release, or any mid-sprint production changes/deployments, those commits should immediately be merged to the **master** branch to reflect that status. The **staging** branch should then be rebased on top of master (or fast-forward merge the new commits, if a re-base is not necessary). Next, the **develop** branch should be rebased on top of staging, or fast-forward merge, to make sure that all 3 shared branches are in sync and share the same history. **master** --> **staging** --> **develop** --> new **feature/** branches.

Lastly, a Git "tag" needs to be created on the most recent commit in **master** from the release to record a new production version of the application. This tag maps back to the Fix Version (ie- Release Version) in Jira, the Sprint, and eventually will be used in a CI/CD workflow to build production images to be archived for historical purposes and also available to use as part of a future automated CI deployment pipelines. The tag should be named in a similar format (ie- `release-2021-2Q-6`).

<p style="text-align:center;"><img src="screenshots/ReleaseTags.png" alt="Release Tags screenshot" width="60%"/></p>

### **hotfix/**
Hotfix branches are used for immediate changes for production. These are created from **master**, and are intended for changes that are ready to be deployed to production in the middle of a sprint. These can be routine maintenance updates (layout changes, permission updates, field updates, etc) or to fix a production bug that needs to be resolved quickly. These are also created to capture changes made manually in production, although that should be avoided unless necessary. Once the work is complete, and the hotfix branch is deployed to production (which would be the master branch + those specific hotfix changes) then it should be merged into the **develop** and **release** branches so that the changes are incorporated along with everything else worked on for that sprint.
### **bugfix/**
Bugfix branches are typically used to address issues raised during UAT testing, and are created from the current sprint's **release** branch. For example, if a bug is identified in the UAT sandbox during the final rounds of testing then a bugfix branch would be created to patch the issue, especially since the original feature branch may already be deleted or otherwise more complicated to use for the update since it's already a few levels removed (feature --> develop --> release). These bugfix branches can also be used in other situations where the stakeholder changed their mind, requested last minute updates, or if something was missed. Once the work is completed, the bugfix branch is first merged into the release branch and then also the develop branch to maintain consistency. However, since **develop** will be updated from master following the release anyways, any gaps created should be addressed shortly afterwards.

---
## Part 3: Tips for working with SFDX in VS Code

<ac:image ac:height="250"><ri:attachment ri:filename="Screen Shot 2020-03-19 at 12.32.09 PM.png"></ri:attachment></ac:image>

### Using the Metadata API (MDAPI) for Deletion

* All the items that should be deleted should be placed under `deploy/pre/predestruct/main/default` or `deploy/post/postdestruct/main/default` folder based on whether the file should be deleted before the main package is deployed, or afterwards. This is usually done in postdestruct, and can even be run as a second deployment after releasing the main package as a safeguard.
* All the items that should be deleted should follow the same structure as `force-app/main/default`. For example-
	* If an Apex Class is being deleted, it should be under deploy/post/postdestruct/main/default/classes folder. 
	* If a Contact Custom Field is being deleted, it should be under deploy/post/postdestruct/main/default/objects/Contact/fields folder. 
* Once the deploy folder is updated, run the following command in Terminal
	* sh scripts/deploy.sh -u <alias> -l RunLocalTests -c
		* Note: Use `-c` to validate-only without deploying the package. This is preferred, and Quick Release can be used for a faster deployment without running Apex tests again.

### Using SFDX Commands

* Run the following command in Terminal to deploy with all Tests,
	* `SFDX force:source:deploy -u <alias> -p force-app/main/default -l RunLocalTests`
* To Deploy/Retreive full source without Apex tests (sandbox only), Right click on `force-app folder` and choose `SFDX: Retrieve Source from Org` or `SFDX: Deploy Source to Org`
	* This should primarilly be used to deploy full source to a personal developer sandbox in lieu of a refresh (ie- Production does not have all of the required changes).
### Retrieve Metadata files directly from a Salesforce Environment

TODO: TBD (add content for Package.xml generator tool)
**[SFDX's Org Browser](https://developer.salesforce.com/tools/vscode/en/user-guide/org-browser/)** gives you the ability to retrieve metadata files directly from a Salesforce production or sandbox instance even if they are not currently in the repository root folder (force-app/main/default). This can be used to add new files to source control that were created directly in Salesforce or to retrieve other files that otherwise are not currently in the source repository. **Note: **This will only add these files to the local branch until changes are staged and committed to the remote branch in **[Stash](https://stash.corp.appnexus.com/projects/XAN/repos/app_sfdxappnexus/browse)** .

TODO: screenshot for using Org Browser + Package.xml generator

TODO: screenshot showing checked out branch vs default org

### Common Errors

**1. Errors when deploying/retrieving changes to/from an environment**

* **Error Message:** `ERROR running force:source:retrieve: The path ~/Projects/app_sfdxadworks/deploy, specified in sfdx-project.json, does not exist`
* **Root Cause:** The `deploy` folder does not exist in the project root folder.
* **Solution:** Simply create an empty folder named `deploy` in your directory (same level as the `force-app` folder).

**2. Errors when attempting an interactive rebase, or other Git operations that require an editor for input**
* **Error Message:**

	`hint: Waiting for your editor to close the file... code --wait: code: command not found.`

	`error: There was a problem with the editor 'code --wait'.`

* **Root Cause** Caused when the `code` command is not added in PATH.
* **Solution:**
	* Confirm that you've completed the Initial Setup step in Part 1 to set VS Code as your git editor. If not, run this command --> `git config --global core.editor "code --wait"`
	* Press `Shift + Command + P` to open the Command Palette
	* Search/Select the command `Shell Command: Install 'code' command in PATH`
	* If prompted, confirm VS Code to be the default Git editor for all workspaces
	* To verify the updated git configuration, run the terminal command `git config --global --edit`

**3. Errors when attempting an interactive rebase, or other Git operations that require an editor for input**
* **Error Message:**
* **Root Cause** Caused when the `code` command is not added in PATH.
* **Solution:**


**4. Errors when trying to retrieve/deploy files to/from an environment**
* **Error Message:** `ERROR running force:source:deploy:  The encrypted data is not properly formatted.`
* **Solution:** Uninstall Salesforce CLI and re-install using either the MacOS Installer, or NPM (try with Installer first).
  * Follow the instructions in the documentation below:
  * https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm

---

## **Part 4: Git Commands**

### Refreshing Local Git Branches (should be done often)
At the beginning of each work day, and often throughout the day, the remote repository should be checked for updates to download locally. This will not automatically merge any changes, but will ensure that all local branches indicate their position compared to the remote branch (especially for public branches like `develop`, `master` and `release/` branches). When applicable, Git will download updates to display in VS Code and allow you to pull them into your local branch (or hard reset) as necessary.

**Fetching updates from remote**
`git fetch --all`

**Pruning stale remote tracking references**

https://stackoverflow.com/questions/1856499/differences-between-git-remote-update-and-fetch/17512004

**Installing Git**
Source: https://www.digitalocean.com/community/tutorials/how-to-contribute-to-open-source-getting-started-with-git

https://www.digitalocean.com/community/tutorials/how-to-contribute-to-open-source-getting-started-with-git#setting-up-git

## **Part 5: SFDX Documentation: Package vs Org Development Models**

There are two types of developer processes or models supported in Salesforce Extensions for VS Code and Salesforce CLI. These models are explained below. Each model offers pros and cons and is fully supported.

### Package Development Model

The package development model allows you to create self-contained applications or libraries that are deployed to your org as a single package. These packages are typically developed against source-tracked orgs called scratch orgs. This development model is geared toward a more modern type of software development process that uses org source tracking, source control, and continuous integration and deployment.

If you are starting a new project, we recommend that you consider the package development model. To start developing with this model in Visual Studio Code, see [Package Development Model with VS Code](https://forcedotcom.github.io/salesforcedx-vscode/articles/user-guide/package-development-model). For details about the model, see the [Package Development Model](https://trailhead.salesforce.com/en/content/learn/modules/sfdx_dev_model) Trailhead module.

If you are developing against scratch orgs, use the command `SFDX: Create Project` (VS Code) or `sfdx force:project:create` (Salesforce CLI)  to create your project. If you used another command, you might want to start over with that command.

When working with source-tracked orgs, use the commands `SFDX: Push Source to Org` (VS Code) or `sfdx force:source:push` (Salesforce CLI) and `SFDX: Pull Source from Org` (VS Code) or `sfdx force:source:pull` (Salesforce CLI). Do not use the `Retrieve` and `Deploy` commands with scratch orgs.

### Org Development Model

The org development model allows you to connect directly to a non-source-tracked org (sandbox, Developer Edition (DE) org, Trailhead Playground, or even a production org) to retrieve and deploy code directly. This model is similar to the type of development you have done in the past using tools such as Force.com IDE or MavensMate.

To start developing with this model in Visual Studio Code, see [Org Development Model with VS Code](https://forcedotcom.github.io/salesforcedx-vscode/articles/user-guide/org-development-model). For details about the model, see the [Org Development Model](https://trailhead.salesforce.com/content/learn/modules/org-development-model) Trailhead module.

If you are developing against non-source-tracked orgs, use the command `SFDX: Create Project with Manifest` (VS Code) or `sfdx force:project:create --manifest` (Salesforce CLI) to create your project. If you used another command, you might want to start over with this command to create a Salesforce DX project.

When working with non-source-tracked orgs, use the commands `SFDX: Deploy Source to Org` (VS Code) or `sfdx force:source:deploy` (Salesforce CLI) and `SFDX: Retrieve Source from Org` (VS Code) or `sfdx force:source:retrieve` (Salesforce CLI). The `Push` and `Pull` commands work only on orgs with source tracking (scratch orgs).