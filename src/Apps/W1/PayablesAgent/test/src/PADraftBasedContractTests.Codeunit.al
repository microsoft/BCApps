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
    procedure DeactivationStopsBackingImporter()
    var
        Fixtures: Codeunit "PA Test Fixtures";
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
    begin
        Fixtures.SeedDraftBasedImporterEnabled();
        Proposal.GetSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.ApplySetup(false);

        Stored.GetSetup();
        Check(not Stored.GetMonitorOutlook(), 'Deactivation must persist monitoring off.');
        Check(not Fixtures.IsDraftBasedImporterEnabled(), 'Deactivation must also turn the backing importer off.');
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
