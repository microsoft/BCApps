// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Diagnostics;
using System.Environment;
using System.Upgrade;

codeunit 104046 "Upgrade Monitored Field"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeNotificationCount();
    end;

    local procedure UpgradeNotificationCount()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeEntry: Record "Change Log Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUpgradeMonitorNotificationUpgradeTag()) then
            exit;

        if FieldMonitoringSetup.Get() then begin
            ChangeEntry.SetFilter("Field Log Entry Feature", '%1|%2', ChangeEntry."Field Log Entry Feature"::"Monitor Sensitive Fields", ChangeEntry."Field Log Entry Feature"::All);
            FieldMonitoringSetup."Notification Count" := ChangeEntry.Count - FieldMonitoringSetup."Notification Count";
            FieldMonitoringSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUpgradeMonitorNotificationUpgradeTag());
    end;
}

