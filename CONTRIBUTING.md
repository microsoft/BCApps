# Contributing

## What to contribute

This project primarily welcomes contributions of two types:

- Pull Requests for pre-approved features, which are based on BC Ideas (http://aka.ms/bcideas) that have been picked as candidates for code contribution projects.
- Pull Requests with fixes and improvements addressing pre-approved issues, which are non-customer reported.

In either case, **an approved GitHub issue in state "approved", must exist, before a Pull Request can be created**. Once a Pull Request is created it **must** be linked to a GitHub issue.

**⚠IMPORTANT⚠:** This is not the right place to report product defects with customer impact to Microsoft! Issues created in this repository won't get picked up by the Microsoft engineering team and issues reported in this repository do not fall under SLAs (Service Level Agreements) and hence have no guaranteed time to mitigation, just as provided fixes won't get backported to all supported versions of the product.

If your customers are experiencing product defects or you have discovered a severe issue in the product, please follow the steps outlined in ["Technical Support for Dynamics 365 Business Central"](https://docs.microsoft.com/dynamics365/business-central/dev-itpro/technical-support) to get your issue routed to the right team at Microsoft and to get it treated with the right priority.

## How to contribute

In the case that you would like to contribute code to this project, you first must establish what kind of contribution we're dealing with:

**A)** A small bug fix, product improvement, paper cut, conveniences customers just can't live without, things you've been fixing for years and from version to version, things you are now forced to create as per tenant extension and which you can't monetize or things you're just tired of fixing over and over again.

**B)** New capabilities or implementations of larger changes to the existing application platform.

Let's take a look at what it takes to contribute with **A)**:


1. **Create a new issue**

    Before a Pull Request can be created, it is required to have an issue registered, which has been approved for development by Microsoft. This is done to ensure that community members aren't wasting their time on writing code, which later cannot be accepted.

2. **Wait for approval**

    Now that your issue is registered, Microsoft will triage your issue and either approve or reject it. An approved issue will have a label "approved".

3. **Create a Pull Request**

    Now a Pull Request can be created. It is important that the Pull Request is linked to an approved issue. In order to link a issue to a PR, please add "Fixes #" followed by the issue ID. E.g. "Fixes #123". **Pull Requests which aren't linked to approved issues will get rejected.**

   If it is your first contribution, you are required to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.microsoft.com. When you submit a pull request, a CLA-bot will automatically determine whether you need
    to provide a CLA and decorate the Pull Request appropriately (e.g., label, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

    Before creating a Pull Request, you might want to verify your changes work as expected. Refer to [Local Development Environment guidelines](LOCAL_DEV_ENV.md) for more info.


4. **Get a succesful build and code review approval**

    Before your Pull Request can be merged, it must have successful required status checks, all conversations resolved and an approval from a code owner. This code review can be done by both Microsoft and members of the community. This ensures that quality of the code is on par with Microsoft's and the community's standards.

5. **Final validation**

    Before the code can be deployed, Microsoft will do a final validation of the Pull Request and issue. Should the change be mentioned in the release notes? Did some of the initially planned work spill over? Is the work on the issue truly done/done?

6. **Merge the Pull Request**

    You've reached the end! When the Pull Request is completed and merged, the change will ship with an upcoming release of the product.

If you would like to add new capabilities to the product as described in **B)**, the process is similar to **A)**, except you need to link your issue to a idea on [BCIdeas](http://aka.ms/bcideas). Therefore, the process is as follows:

1. **Find or register your idea on [BCIdeas](http://aka.ms/bcideas)**

- Start by searching for existing approved issues here on GitHub related to your idea. If you cannot find an approved issue, look for existing ideas on BCIdeas, which cover the scenario your were thinking about implementing; ideally ideas with some votes. If you find an idea you'd like to use as open source contribution issue, inform Microsoft that you intend to do a contribution and a product manager will tag the idea. In the less likely event that you don't find any idea which points in the direction of the feature you intended to work on, you can go ahead and log a new idea, describing the new capability you would like to add to the product. Don't forget mention that the idea is suitable for open source contribution.
- Wait for approval: If you created a new idea, a Microsoft product manager will revise the idea. If the idea is aligned with the strategy of the application platform and is considered feasible to implement, the idea will get approved and marked as "open for contribution". Once the idea has "open for contribution" mentioned as part of idea title, an issue will be created and approved immediately in this repository.
- Find allies: If you reused an existing idea, check [Application Functionality group on Business Central Yammer portal](https://www.yammer.com/dynamicsnavdev/#/threads/inGroup?type=in_group&feedId=8846299) for any input from other partners (just search for idea title). There you can also find partners in crime (= other developers with same issue) that can help with the development or review of your future PR.

2. **Get the issue into "approved" state**

    Once the issue is created on GitHub, it still needs to be approved. Once approved, the rest of the process is identical to the process described in **A)**.

## Get to Know the System App

Before updating the System Application, familiarize yourself with the following sites on Microsoft Learn:

- [Module architecture](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-blueprint)
- [Get started with modules](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-blueprint)
- [Set up your development environment](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-set-up-an-environment)
- [Create a new module](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-new-module)
- [Create a .NET wrapper module](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-create-a-wrapper-module)
- [Change a module](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-change-a-module)

## More Resources
* This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

* If you are a beginner at contributing, start by following the [GitHub guidelines](https://docs.github.com/en/get-started/quickstart/fork-a-repo).

* If you are new to developing for Business Central, visit [Developers Learning Catalog](https://docs.microsoft.com/dynamics365/business-central/readiness/readiness-learning-developers).
