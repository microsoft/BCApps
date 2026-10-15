// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

codeunit 3331 "PA Agent Feature Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "PA Agent Feature Setup" = rimd,
                  tabledata "Payables Agent Setup" = r;

    procedure IsBusinessSkillsEnabled(AgentUserId: Guid): Boolean
    var
        FeatureSetup: Record "PA Agent Feature Setup";
    begin
        if IsNullGuid(AgentUserId) then
            exit(false);
        if not FeatureSetup.Get(AgentUserId) then
            exit(false);
        exit(FeatureSetup."Use Business Skills");
    end;

    procedure TryGetBusinessSkillsEnabled(AgentUserId: Guid; var Enabled: Boolean): Boolean
    var
        FeatureSetup: Record "PA Agent Feature Setup";
    begin
        if IsNullGuid(AgentUserId) then
            exit(false);
        if not FeatureSetup.Get(AgentUserId) then
            exit(false);
        Enabled := FeatureSetup."Use Business Skills";
        exit(true);
    end;

    procedure SetBusinessSkillsEnabled(AgentUserId: Guid; Enabled: Boolean)
    var
        FeatureSetup: Record "PA Agent Feature Setup";
    begin
        if IsNullGuid(AgentUserId) then
            exit;
        if not FeatureSetup.Get(AgentUserId) then begin
            FeatureSetup.Init();
            FeatureSetup."Agent User ID" := AgentUserId;
            FeatureSetup."Use Business Skills" := Enabled;
            FeatureSetup.Insert(true);
            exit;
        end;
        if FeatureSetup."Use Business Skills" = Enabled then
            exit;
        FeatureSetup."Use Business Skills" := Enabled;
        FeatureSetup.Modify(true);
    end;

    procedure MigrateBusinessSkillsSetting()
    var
        FeatureSetup: Record "PA Agent Feature Setup";
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        if not PayablesAgentSetup.GetSetup(false) then
            exit;
        if IsNullGuid(PayablesAgentSetup."User Security Id") then
            exit;
        if FeatureSetup.Get(PayablesAgentSetup."User Security Id") then
            exit;
        SetBusinessSkillsEnabled(PayablesAgentSetup."User Security Id", PayablesAgentSetup."Use Business Skills");
    end;
}
