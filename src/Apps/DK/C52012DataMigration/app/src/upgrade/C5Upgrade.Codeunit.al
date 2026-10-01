// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.C5;

using System.Upgrade;

codeunit 1873 "C5 Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        C5Telemetry: Codeunit "C5 Telemetry";
        UpgradeTag: Codeunit "Upgrade Tag";
        MigrationDateTime: DateTime;
    begin
        if UpgradeTag.HasUpgradeTag(GetSendC5MigrationTelemetryTag()) then
            exit;

        if C5Telemetry.GetCompletedMigrationDateTime(MigrationDateTime) then
            C5Telemetry.SendCompletedMigrationTelemetry(MigrationDateTime);

        UpgradeTag.SetUpgradeTag(GetSendC5MigrationTelemetryTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetSendC5MigrationTelemetryTag());
    end;

    local procedure GetSendC5MigrationTelemetryTag(): Text[250]
    begin
        exit('MS-C5MigrationUptake-20260930');
    end;
}
