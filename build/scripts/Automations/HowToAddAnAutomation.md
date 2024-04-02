# How to add a new automation

1. Create a folder in `build\scripts\Automations`. The name of the folder is the name of the automation, e.g. "_UpdateAppBaselines_".
1. Create a `run.ps1` file in the new folder. It should contain the script with the automation's logic. The script can accept the following parameters:
   - `Repository`: the repository the automation is running on. Use the parameter in case the automation should behave differently on forks.
   - `TargetBranch`: the branch the automation is running on. Use this parameter to alter logic between branches.
1. Create a new workflow in `.github\workflows` to run your new automation.
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

        - name: Update BC Artifact Version
            env:
            GH_TOKEN: ${{ secrets.GHTOKENWORKFLOW }}
            run: |
                build/scripts/Automations/run.ps1 -Include '<automation name>' -Repository $ENV:GITHUB_REPOSITORY -TargetBranch ${{ matrix.branch }} -Actor $env:GITHUB_ACTOR
    ```
    - In case the automation needs to run on all official branches, use `GetOfficialBranches` action by adding another job:
    ```yaml
      GetBranches:
        name: Get Official Branches
        runs-on: windows-latest
        outputs:
            UpdateBranches: ${{ steps.OfficialBranches.outputs.OfficialBranches }}
        steps:
        - name: Checkout
            uses: actions/checkout@v4

        - name: Get Official Branches
            id: OfficialBranches
            uses: ./.github/actions/GetOfficialBranches
    ```
    Don't forget to add `needs: GetBranches` in `AutomationJob` job properties and change `matrix` to `branch: ${{ fromJson(needs.GetBranches.outputs.UpdateBranches) }}`.

