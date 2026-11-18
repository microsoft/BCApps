# How to add a new automation

1. Create a folder in `.github\actions\RunAutomations`. The name of the folder is the name of the automation, e.g. "_UpdateAppBaselines_".
2. Create a `run.ps1` file in the new folder. It should contain the script with the automation's logic.
   - The script can accept the following parameters:
     - `Repository`: the repository the automation is running on. Use the parameter in case the automation should behave differently on forks.
     - `TargetBranch`: the branch the automation is running on. Use this parameter to alter logic between branches.
   - The script returns an object with the following properties. The information from this object will be used to potentially create an automation pull request.
     - `Files`: Files changed by the automation that will be included in the pull request.
     - `Message`: Message to display as an automaton result and use as commit message and pull request description.
3. Create a new workflow in `.github\workflows` to run your new automation.
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
            uses: actions/checkout@v4
            with:
            ref: ${{ matrix.branch }}

        - name:<automation name>
            uses: microsoft/BCApps/.github/actions/RunAutomation@main
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
        - name: Get Official Branches
            id: getOfficialBranches
            uses: mazhelez/BCApps/.github/actions/GetGitBranches@main
            with:
              include: "['main', 'releases/*']"
    ```
    Add parameter `include` with value `"['main', 'releases/*']"` if order to run the automation for `main` and all release branches. In rare cases, automation can be enabled on other branches as well.
    Don't forget to add `needs: GetBranches` in `AutomationJob` job properties and change `matrix` to `branch: ${{ fromJson(needs.GetBranches.outputs.UpdateBranches) }}`.

