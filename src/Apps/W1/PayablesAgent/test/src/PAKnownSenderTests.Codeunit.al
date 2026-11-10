// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;

codeunit 133703 "PA Known Sender Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    var
        Assert: Codeunit Assert;
        PATestFixtures: Codeunit "PA Test Fixtures";

    [Test]
    procedure RecordIfNewInsertsNewSender()
    var
        PAKnownSender: Record "PA Known Sender";
        WorkItem: Codeunit "PA Work Item";
        // Synthetic sender address is the input to this email-source fixture.
#pragma warning disable AA0240
        SenderEmailTok: Label 'first-sender@contoso.com', Locked = true;
#pragma warning restore AA0240
    begin
        // [SCENARIO] Recording a sender for the first time adds it as a known sender.
        // [GIVEN] A clean Known Sender table and an email work item received from a sender.
        PAKnownSender.DeleteAll();
        Assert.IsTrue(PATestFixtures.ReceiveEmail(SenderEmailTok, 'Invoice', WorkItem), 'The email should be received as a work item');

        // [WHEN] The agent-side recording path runs.
        PAKnownSender.RecordIfNew(WorkItem);

        // [THEN] One row exists for that sender.
        PAKnownSender.SetRange(Email, SenderEmailTok);
        Assert.RecordCount(PAKnownSender, 1);
    end;

    [Test]
    procedure RecordIfNewInsertsOnceAcrossRepeatedCalls()
    var
        PAKnownSender: Record "PA Known Sender";
        WorkItem: Codeunit "PA Work Item";
        // Synthetic sender address is the input to this email-source fixture.
#pragma warning disable AA0240
        SenderEmailTok: Label 'pipeline-sender@contoso.com', Locked = true;
#pragma warning restore AA0240
    begin
        // [SCENARIO] Recording the same sender repeatedly adds it only once.
        // [GIVEN] A clean Known Sender table and an email work item received from a sender.
        PAKnownSender.DeleteAll();
        Assert.IsTrue(PATestFixtures.ReceiveEmail(SenderEmailTok, 'Invoice', WorkItem), 'The email should be received as a work item');

        // [WHEN] The recording path fires multiple times for the same sender
        // [WHEN] (simulating repeated pipeline steps within an agent session).
        PAKnownSender.RecordIfNew(WorkItem);
        PAKnownSender.RecordIfNew(WorkItem);
        PAKnownSender.RecordIfNew(WorkItem);

        // [THEN] Exactly one row exists for that sender.
        PAKnownSender.SetRange(Email, SenderEmailTok);
        Assert.RecordCount(PAKnownSender, 1);
    end;
}
