// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

codeunit 7782 "Copilot Telemetry Install"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    var
        CopilotTelemetryUpgrade: Codeunit "Copilot Telemetry Upgrade";
    begin
        CopilotTelemetryUpgrade.SendCopilotDataMovementUpgradeTelemetry();
    end;
}