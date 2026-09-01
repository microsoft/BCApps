// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Agents;

using System.Upgrade;

codeunit 4326 "Agent Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    begin
        InsertDefaultPermissionIfEmpty();
    end;

    procedure InsertDefaultPermissionIfEmpty()
    var
        AgentCreationControl: Record "Agent Creation Control";
        UpgradeTag: Codeunit "Upgrade Tag";
        DefaultPermissionDescriptionLbl: Label 'Default: Allow all users with required permissions to create agents';
        EmptyGuid: Guid;
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(GetDefaultAgentCreationControlUpgradeTag()) then
            exit;

        // If the table already has data, just set the upgrade tag.
        if not AgentCreationControl.IsEmpty() then begin
            UpgradeTag.SetDatabaseUpgradeTag(GetDefaultAgentCreationControlUpgradeTag());
            exit;
        end;

        // Insert default rule.
        AgentCreationControl."User Security ID" := EmptyGuid;
        AgentCreationControl."Agent Metadata Provider" := -1;
        AgentCreationControl."Company Name" := '';
        AgentCreationControl.Description := DefaultPermissionDescriptionLbl;
        AgentCreationControl.Insert();

        UpgradeTag.SetDatabaseUpgradeTag(GetDefaultAgentCreationControlUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure OnGetPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetDefaultAgentCreationControlUpgradeTag());
    end;

    local procedure GetDefaultAgentCreationControlUpgradeTag(): Code[250]
    begin
        exit('MS-AgentDesigner-InsertDefaultCreationPermission-20260310');
    end;
}