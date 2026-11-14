// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

codeunit 4409 "SOA Agent Feature Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "SOA Agent Feature Setup" = rimd;

    internal procedure IsBusinessIQEnabled(AgentUserID: Guid): Boolean
    var
        FeatureSetup: Record "SOA Agent Feature Setup";
    begin
        if IsNullGuid(AgentUserID) then
            exit(false);
        if not FeatureSetup.Get(AgentUserID) then
            exit(false);

        exit(FeatureSetup."Use Business IQ");
    end;

    internal procedure SetBusinessIQEnabled(AgentUserID: Guid; Enabled: Boolean)
    var
        FeatureSetup: Record "SOA Agent Feature Setup";
    begin
        FeatureSetup."Agent User ID" := AgentUserID;
        FeatureSetup.TestField("Agent User ID");
        if not FeatureSetup.Get(AgentUserID) then begin
            FeatureSetup."Use Business IQ" := Enabled;
            FeatureSetup.Insert(true);
            exit;
        end;

        if FeatureSetup."Use Business IQ" = Enabled then
            exit;

        FeatureSetup."Use Business IQ" := Enabled;
        FeatureSetup.Modify(true);
    end;
}
