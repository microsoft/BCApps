This module provides functionality for ensuring that the upgrade code is run only one time.

Use the following construct between the upgrade code:

```
if UpgradeTag.HasUpgradeTag(UpgradeTagValue) then
  exit;

DoUpgrade();

UpgradeTag.SetUpgradeTag(UpgradeTagValue);
```

To avoid running upgrade code on the next upgrade, do the following:
1. Register upgrade tags for new companies by subscribing to the OnGetPerCompanyUpgradeTags or OnGetPerDatabaseUpgradeTags events.
2. Register the OnInstallation upgrade tags of the extension, if applicable, by calling the UpgradeTag.SetUpgradeTag(UpgradeTagValue) in the OnInstall triggers.

This module must be used for upgrade purposes only.

Upgrade Tags are used within upgrade codeunits to know which upgrade methods have been run and to prevent executing the same upgrade code twice. 

They can also be used to skip the upgrade methods on a specific company or to fix the upgrade that went wrong.


