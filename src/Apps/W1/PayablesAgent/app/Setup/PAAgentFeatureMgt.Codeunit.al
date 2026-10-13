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

    procedure IsBusinessCentralIQEnabled(AgentUserId: Guid): Boolean
    var
        FeatureSetup: Record "PA Agent Feature Setup";
    begin
        if IsNullGuid(AgentUserId) then
            exit(false);
        if not FeatureSetup.Get(AgentUserId) then
            exit(false);
        exit(FeatureSetup."Use Business Central IQ");
    end;

    procedure TryGetBusinessCentralIQEnabled(AgentUserId: Guid; var Enabled: Boolean): Boolean
    var
        FeatureSetup: Record "PA Agent Feature Setup";
    begin
        if IsNullGuid(AgentUserId) then
            exit(false);
        if not FeatureSetup.Get(AgentUserId) then
            exit(false);
        Enabled := FeatureSetup."Use Business Central IQ";
        exit(true);
    end;

    procedure SetBusinessCentralIQEnabled(AgentUserId: Guid; Enabled: Boolean)
    var
        FeatureSetup: Record "PA Agent Feature Setup";
    begin
        if IsNullGuid(AgentUserId) then
            exit;
        if not FeatureSetup.Get(AgentUserId) then begin
            FeatureSetup.Init();
            FeatureSetup."Agent User ID" := AgentUserId;
            FeatureSetup."Use Business Central IQ" := Enabled;
            FeatureSetup.Insert(true);
            exit;
        end;
        if FeatureSetup."Use Business Central IQ" = Enabled then
            exit;
        FeatureSetup."Use Business Central IQ" := Enabled;
        FeatureSetup.Modify(true);
    end;

    procedure MigrateBusinessCentralIQSetting()
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
        SetBusinessCentralIQEnabled(PayablesAgentSetup."User Security Id", PayablesAgentSetup."Use Business Central IQ");
    end;
}
