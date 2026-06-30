# BCApps — the home of Business Central application development

**BCApps is the single, open collaboration hub for everything _Business Central application platform_ development.**

This is where Microsoft engineers, partners, and the wider community build the Business Central application — together, in the open. The Microsoft product team and external contributors work side-by-side in this one repository, on the same code, with the same pipelines and the same tooling.

The source code in this repository is available to everyone under the standard [MIT license](https://github.com/microsoft/BCApps/blob/main/LICENSE).

✨ **BCApps runs on [AL-Go for GitHub](https://github.com/microsoft/AL-Go)** — the same build, test, and release automation is available to everyone. ✨

## One repository for Business Central

BCApps is now _the_ repository for Business Central application development, consolidating code that used to live in several separate repositories into a single place. It is the single home for:

- the **System Application**,
- the **Business Foundation**,
- the **Base Application**,
- Microsoft's **first-party apps** (such as E-Documents, Shopify connector, Subscription Billing, Power BI reports, and many more), and
- the **developer tools** — Test Framework, Performance Toolkit, AI Test Toolkit, and others.

One repo. One workflow. One issues list. One place to collaborate — for Microsoft, for partners, and increasingly for AI agents working alongside them.

> **Why this matters:** GitHub becomes Business Central's business application collaboration platform. It levels the playing field — the same code, pipelines, and tooling Microsoft uses to build the product are available to every partner and community contributor.

## Repository structure

All source lives under `src`, organized by application area. Anything that ships in multiple localizations is split by country/region: a `W1` ("worldwide") base plus per-market folders such as `DE`, `US`, or `GB`.

| Path | What's inside |
|---|---|
| `src/System Application` | The System Application and its modules — the foundational platform layer. |
| `src/Business Foundation` | Foundational business logic shared across the application. |
| `src/Layers` | The **Base Application** and Application layers, built per country/region (`W1` plus localizations). |
| `src/Apps` | Microsoft's first-party apps, split into `W1` and country/region variants. |
| `src/GDL` | Additional country/region-specific application content. |
| `src/Tools` | Developer tools — Test Framework, Performance Toolkit, AI Test Toolkit, Red Team Scan. |
| `src/DemoTool` | The tool that generates Business Central demonstration data. |
| `src/DisabledTests` | Test apps that are temporarily disabled. |
| `src/rulesets` | Code-analysis rulesets used when building the apps. |
| `build` | Build orchestration. `eng/projects` defines the AL-Go projects and `eng/CI` the supporting automation; `build.ps1` builds the repo locally. |
| `tools` | Repository-level agent tooling and developer plugins, including the [Copilot PR review](tools/Code%20Review/README.md) integration. |
| `docs` | Repository and feature documentation. |

## Contributing

We welcome contributions across the Business Central application platform — the System Application, Business Foundation, the Base Application, the first-party apps, and the developer tools.

Want to get involved? Start with our **[Contribution Guidelines](CONTRIBUTING.md)**. To build and validate your changes locally, see the **[Local Development Environment guidelines](LOCAL_DEV_ENV.md)**.

Every contribution needs an **approved GitHub issue** before a Pull Request is opened — this saves you from writing code that can't be accepted. The full process is described in [CONTRIBUTING.md](CONTRIBUTING.md).

**⚠IMPORTANT⚠:** This is **not** the right place to report product defects with customer impact to Microsoft! Issues created in this repository might not get picked up by the Microsoft engineering team and do not fall under SLAs (Service Level Agreements); they have no guaranteed time to mitigation, and provided fixes won't get backported to all supported versions of the product. For customer-impacting defects, follow ["Technical Support for Dynamics 365 Business Central"](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/technical-support).

## Building Business Central with agents

Now that the collaboration platform is in place, we're reimagining _how_ the application is built. AI agents are starting to assist at every stage of the engineering process — they assist developers, they don't replace them:

- **Code Review agent** — a "Copilot for PRs" already running in the BCApps CI pipeline. It inspects pull requests, posts review comments, and runs quality checks against shared best practices. See [`tools/Code Review`](tools/Code%20Review/README.md).
- **[BCQuality](https://github.com/microsoft/BCQuality)** — an open, agent-consumable knowledge base of Business Central best practices, patterns, and guidelines. It is layered (Microsoft / Community / Custom) so partners can extend and override the rules the agents follow. The BCApps Copilot reviewer consumes it through the integration under [`tools/Code Review`](tools/Code%20Review/README.md).

The direction is for this agent framework to ship as part of AL-Go for GitHub, so every partner's pipeline can opt into agents — configured through BCQuality — without complex setup.

## Business Central

![image](https://user-images.githubusercontent.com/19796701/178490212-f14a11e4-8b06-437d-8444-ea28156f70c7.png)

[Business Central](https://learn.microsoft.com/dynamics365/business-central/) is a business management solution for small and mid-sized organizations that automates and streamlines business processes and helps you manage your business. Highly adaptable and rich with features, Business Central enables companies to manage their business — including finance, manufacturing, sales, shipping, project management, services, and more. Companies can easily add functionality that is relevant to their region of operation and customized to support even highly specialized industries. Business Central is fast to implement, easy to configure, and simplicity guides innovations in product design, development, implementation, and usability.

## More resources

- **Getting help & support** — see [SUPPORT.md](SUPPORT.md) for where to ask questions and how issues are handled.
- **Reporting security issues** — please follow our [Security Policy](SECURITY.md); do not open public issues for security vulnerabilities.
- This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com).
- New to contributing on GitHub? Follow the [GitHub quickstart guidelines](https://docs.github.com/en/get-started/quickstart/fork-a-repo).
- New to developing for Business Central? Visit the [Developers Learning Catalog](https://learn.microsoft.com/dynamics365/business-central/readiness/readiness-learning-developers).

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos is subject to those third-parties' policies.
