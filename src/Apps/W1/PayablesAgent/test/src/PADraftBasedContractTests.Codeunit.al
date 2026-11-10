// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;

// Draft-based PA configuration contract; task-backed scenarios belong in runtime/AI validation.
codeunit 133736 "PA Draft Based Contract Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure DeactivationStopsDraftImporter()
    var
        Fixtures: Codeunit "PA Test Fixtures";
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
    begin
        // [SCENARIO] Deactivating the agent also turns off the V1 (draft-based) E-Document importer.
        // [GIVEN] The V1 importer is enabled.
        Fixtures.SeedDraftBasedImporterEnabled();

        // [WHEN] A setup proposal with mailbox monitoring on is applied with the agent deactivated.
        Proposal.LoadOrCreateSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.ApplySetup(false);

        // [THEN] Monitoring is persisted as off and the V1 importer is disabled.
        Stored.LoadOrCreateSetup();
        Check(not Stored.GetMonitorOutlook(), 'Deactivation must persist monitoring off.');
        Check(not Fixtures.IsDraftBasedImporterEnabled(), 'Deactivation must also turn the V1 importer off.');
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
