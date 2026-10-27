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
    procedure InsertIfNewInsertsNewSender()
    var
        PAKnownSender: Record "PA Known Sender";
        PATaskSource: Codeunit "PA Task Source";
        // Synthetic sender address is the input to this email-source fixture.
#pragma warning disable AA0240
        SenderEmailTok: Label 'first-sender@contoso.com', Locked = true;
#pragma warning restore AA0240
    begin
        // [GIVEN] A clean Known Sender table and a task received by email from a sender.
        PAKnownSender.DeleteAll();
        Assert.IsTrue(PATestFixtures.ReceiveEmail(SenderEmailTok, 'Invoice', PATaskSource), 'The email should be received as a source');

        // [WHEN] The agent-side recording path runs.
        PAKnownSender.InsertSourceIfNew(PATaskSource);

        // [THEN] One row exists for that sender.
        PAKnownSender.SetRange(Email, SenderEmailTok);
        Assert.RecordCount(PAKnownSender, 1);
    end;

    [Test]
    procedure InsertIfNewInsertsOnceAcrossRepeatedCalls()
    var
        PAKnownSender: Record "PA Known Sender";
        PATaskSource: Codeunit "PA Task Source";
        // Synthetic sender address is the input to this email-source fixture.
#pragma warning disable AA0240
        SenderEmailTok: Label 'pipeline-sender@contoso.com', Locked = true;
#pragma warning restore AA0240
    begin
        // [GIVEN] A clean Known Sender table and a task received by email from a sender.
        PAKnownSender.DeleteAll();
        Assert.IsTrue(PATestFixtures.ReceiveEmail(SenderEmailTok, 'Invoice', PATaskSource), 'The email should be received as a source');

        // [WHEN] The recording path fires multiple times for the same sender
        // [WHEN] (simulating repeated pipeline steps within an agent session).
        PAKnownSender.InsertSourceIfNew(PATaskSource);
        PAKnownSender.InsertSourceIfNew(PATaskSource);
        PAKnownSender.InsertSourceIfNew(PATaskSource);

        // [THEN] Exactly one row exists for that sender.
        PAKnownSender.SetRange(Email, SenderEmailTok);
        Assert.RecordCount(PAKnownSender, 1);
    end;
}
