// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

using System.Agents;
using System.Environment.Consumption;
using System.TestLibraries.Utilities;

codeunit 133959 "Agent Consumption Test"
{
    Subtype = Test;

    [Test]
    procedure PendingAndClaimedCreditsAreNotProjectedAsFinal()
    var
        Source: Record "AI Consumption Log Entry" temporary;
        Buffer: Record "Agent AI Consumption Buffer" temporary;
        Consumption: Codeunit "Agent AI Consumption";
        Assert: Codeunit "Library Assert";
    begin
        Source.Id := 1;
        Source."Agent Task Id" := 10;
        Source."AI Credits" := 99;
        Source."Reporting State" := Source."Reporting State"::Pending;
        Consumption.AddEntry(Source, Buffer);
        Assert.IsTrue(Buffer."Pricing Pending", 'Pending usage must remain explicit.');
        Assert.AreEqual(0, Buffer."AI Credits", 'Pending values must not contribute completed credits.');

        Source.Id := 2;
        Source."Reporting State" := Source."Reporting State"::Claimed;
        Consumption.AddEntry(Source, Buffer);
        Assert.IsTrue(Buffer."Pricing Pending", 'Claimed is not completed pricing.');
        Assert.AreEqual(0, Buffer."AI Credits", 'Claimed values must not contribute completed credits.');

        Source.Id := 3;
        Source."AI Credits" := 7.5;
        Source."Reporting State" := Source."Reporting State"::Completed;
        Consumption.AddEntry(Source, Buffer);
        Assert.IsFalse(Buffer."Pricing Pending", 'Completed usage must be distinguishable from pending usage.');
        Assert.AreEqual(7.5, Buffer."AI Credits", 'Completed credits must retain their measured value.');
    end;

    [Test]
    procedure CompletedZeroIsNotPending()
    var
        Source: Record "AI Consumption Log Entry" temporary;
        Buffer: Record "Agent AI Consumption Buffer" temporary;
        Consumption: Codeunit "Agent AI Consumption";
        Assert: Codeunit "Library Assert";
    begin
        Source.Id := 1;
        Source."Reporting State" := Source."Reporting State"::Completed;
        Consumption.AddEntry(Source, Buffer);
        Assert.AreEqual(0, Buffer."AI Credits", 'A finalized zero charge must remain zero.');
        Assert.IsFalse(Buffer."Pricing Pending", 'A finalized zero charge must not be confused with missing pricing.');
    end;
}
