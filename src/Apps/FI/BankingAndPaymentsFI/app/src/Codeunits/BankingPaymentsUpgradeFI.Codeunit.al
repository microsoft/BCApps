// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

codeunit 13583 "Banking Payments Upgrade FI"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeCompany();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure UpgradeCompany()
    var
        Migrate: Codeunit "Banking Payments Migrate FI";
#if not CLEAN30
        Update: Codeunit "Banking Payments Update FI";
        Module: ModuleInfo;
#endif
    begin
#if not CLEAN30
        NavApp.GetCurrentModuleInfo(Module);
        if not Update.ShouldMigrateDuringUpgrade(Module.AppVersion()) then
            exit;
#endif
        Migrate.MigrateDuringLifecycle();
#if not CLEAN30
        Update.CompleteControlledUpgrade();
#endif
    end;
}
