# How to add a new automation

> [!NOTE]
> Automations run through `RunAutomation` are automatically skipped on branches that are out of support (branches with the "Branch is out of support" ruleset). No pull request is created for those branches, so you don't need to handle this in your automation.

1. Create a folder in `.github\actions\RunAutomations`. The name of the folder is the name of the automation, e.g. "_UpdateAppBaselines_".
2. Create a `run.ps1` file in the new folder. It should contain the script with the automation's logic.
   - The script can accept the following parameters:
     - `Repository`: the repository the automation is running on. Use the parameter in case the automation should behave differently on forks.
     - `TargetBranch`: the branch the automation is running on. Use this parameter to alter logic between branches.
   - The script returns an object with the following properties. The information from this object will be used to potentially create an automation pull request.
     - `Files`: Files changed by the automation that will be included in the pull request.
     - `Message`: Message to display as an automaton result and use as commit message and pull request description.
3. Create a new workflow in `.github\workflows` to run your new automation.
    - Reference the actions in this repository locally (`./...`) rather than as `microsoft/BCApps/...@main`, so the action code always matches the workflow's commit. Local actions require the repository to be checked out first. When the job checks out another branch (e.g. `${{ matrix.branch }}`), check out the workflow's own commit into `_actions` and reference the action from there.
    - Add a job to run the script:
    ```yaml
    AutomationJob:
        name: "[${{ matrix.branch }}] <automation name>"
        permissions:
        contents: write
        environment: Official-Build
        runs-on: windows-latest
        strategy:
        matrix:
            branch: <list of branches to run the automation on>
        fail-fast: false
        steps:
        - name: Checkout
            uses: actions/checkout@<pinned SHA> # <version>
            with:
            ref: ${{ matrix.branch }}

        - name: Checkout actions
            uses: actions/checkout@<pinned SHA> # <version>
            with:
            path: _actions
            sparse-checkout: |
                .github/actions
                build/scripts

        - name:<automation name>
            uses: ./_actions/.github/actions/RunAutomation
            with:
                automations: <automation name>
                targetBranch: ${{ matrix.branch }}
    ```
    - In case the automation needs to run on all official branches, use `GetGitBranches` action with by adding another job:
    ```yaml
    GetBranches:
        name: Get Official Branches
        runs-on: ubuntu-latest
        outputs:
          updateBranches: ${{ steps.getOfficialBranches.outputs.branchesJson }}
        steps:
        - name: Checkout
            uses: actions/checkout@<pinned SHA> # <version>

        - name: Get Official Branches
            id: getOfficialBranches
            uses: ./.github/actions/GetGitBranches
            with:
              include: "['main', 'releases/*']"
    ```
    Add parameter `include` with value `"['main', 'releases/*']"` if order to run the automation for `main` and all release branches. In rare cases, automation can be enabled on other branches as well.
    Don't forget to add `needs: GetBranches` in `AutomationJob` job properties and change `matrix` to `branch: ${{ fromJson(needs.GetBranches.outputs.UpdateBranches) }}`.

