// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Agents;

codeunit 4331 "Agent Install"
{
    Access = Internal;
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    var
        AgentUpgrade: Codeunit "Agent Upgrade";
    begin
        AgentUpgrade.InsertDefaultPermissionIfEmpty();
    end;
}