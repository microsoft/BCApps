// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Upgrade;
using System.Environment;

codeunit 7781 "Copilot Telemetry Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    begin
        SendCopilotDataMovementUpgradeTelemetry();
    end;

    internal procedure SendCopilotDataMovementUpgradeTelemetry()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        CopilotTelemetry: Codeunit "Copilot Telemetry";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsOnPrem() then
            exit;

        if UpgradeTag.HasDatabaseUpgradeTag(GetSendCopilotDataMovementUpgradeTelemetryTag()) then
            exit;

        CopilotTelemetry.SendCopilotDataMovementUpdatedTelemetry();

        UpgradeTag.SetUpgradeTag(GetSendCopilotDataMovementUpgradeTelemetryTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure RegisterUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetSendCopilotDataMovementUpgradeTelemetryTag());
    end;

    local procedure GetSendCopilotDataMovementUpgradeTelemetryTag(): Text[250]
    begin
        exit('MS-561464-CopilotDataMovement-20250212');
    end;
}