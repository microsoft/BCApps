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
        PAEDocTestGlue: Codeunit "PA EDoc Unit Test Glue";

    [Test]
    procedure InsertIfNewInsertsNewSender()
    var
        PAKnownSender: Record "PA Known Sender";
        SenderEmailTok: Label 'first-sender@contoso.com', Locked = true;
    begin
        // [GIVEN] A clean Known Sender table and a task whose sender is a given email.
        PAKnownSender.DeleteAll();

        // [WHEN] The agent-side recording path runs.
        PAEDocTestGlue.RecordKnownSender(SenderEmailTok);

        // [THEN] One row exists for that sender.
        PAKnownSender.SetRange(Email, SenderEmailTok);
        Assert.RecordCount(PAKnownSender, 1);
    end;

    [Test]
    procedure InsertIfNewInsertsOnceAcrossRepeatedCalls()
    var
        PAKnownSender: Record "PA Known Sender";
        SenderEmailTok: Label 'pipeline-sender@contoso.com', Locked = true;
    begin
        // [GIVEN] A clean Known Sender table and a task whose sender is a given email.
        PAKnownSender.DeleteAll();

        // [WHEN] The recording path fires multiple times for the same sender
        // [WHEN] (simulating repeated pipeline steps within an agent session).
        PAEDocTestGlue.RecordKnownSender(SenderEmailTok);
        PAEDocTestGlue.RecordKnownSender(SenderEmailTok);
        PAEDocTestGlue.RecordKnownSender(SenderEmailTok);

        // [THEN] Exactly one row exists for that sender.
        PAKnownSender.SetRange(Email, SenderEmailTok);
        Assert.RecordCount(PAKnownSender, 1);
    end;
}
