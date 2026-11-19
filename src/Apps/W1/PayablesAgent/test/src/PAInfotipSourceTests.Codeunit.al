// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Agents;

codeunit 133735 "PA Infotip Source Tests"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    Access = Internal;

    var
        Assert: Codeunit Assert;
        Fixtures: Codeunit "PA Test Fixtures";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InfotipSources_WorkingAndFinalizedDraft()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        DraftFixtures: Codeunit "PA Draft Based Test Fixtures";
        Sources: JsonArray;
        Context: JsonObject;
        AgentTaskId: BigInteger;
        WorkingSources, FinalizedSources: Text;
    begin
        Vendor."No." := NewDocumentNo();
        Vendor.Name := 'Actual source vendor';
        Vendor.Insert();
        CreatePurchaseLine(PurchaseLine, "Purchase Document Type"::Invoice, NewDocumentNo(), 70000);
        AgentTaskId := CreateTask('');
        DraftFixtures.CreateMatchedDraftForTest(AgentTaskId, Vendor."No.", PurchaseLine.SystemId);

        Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);

        Assert.AreEqual(5, Sources.Count(), 'Header, vendor, two draft lines and one deduplicated surviving target');
        AssertAllSourcesResolve(Sources);
        AssertSource(Sources, Vendor, 1);
        AssertSource(Sources, PurchaseLine, 4);
        Context := GetContext(Sources, 0);
        AssertText(Context, 'invoiceNo', 'SOURCE-INVOICE');
        Context := GetContext(Sources, 1);
        AssertText(Context, 'no', Vendor."No.");
        AssertText(Context, 'name', Vendor.Name);
        Context := GetContext(Sources, 2);
        AssertInteger(Context, 'lineNo', 10000);
        Context := GetContext(Sources, 3);
        AssertInteger(Context, 'lineNo', 20000);
        Context := GetContext(Sources, 4);
        AssertText(Context, 'documentType', Format(PurchaseLine."Document Type"));
        AssertText(Context, 'documentNo', PurchaseLine."Document No.");
        AssertInteger(Context, 'lineNo', PurchaseLine."Line No.");
        Sources.WriteTo(WorkingSources);

        DraftFixtures.FinalizeDraftMatchesForTest(AgentTaskId);
        Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);

        Sources.WriteTo(FinalizedSources);
        Assert.AreEqual(WorkingSources, FinalizedSources, 'Finalized relations retain the same actual source identities and context');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InfotipSources_NativeOutcomeAndMatchedOrder()
    var
        Vendor: Record Vendor;
        Header: Record "Purchase Header";
        Line: Record "Purchase Line";
        OrderLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        WorkItem: Codeunit "PA Work Item";
        Sources: JsonArray;
        Context: JsonObject;
        AgentTaskId: BigInteger;
    begin
        AgentTaskId := CreateNativeTask(WorkItem);
        Vendor."No." := NewDocumentNo();
        Vendor.Name := 'Native source vendor';
        Vendor.Insert();
        Header."Document Type" := Header."Document Type"::Invoice;
        Header."No." := NewDocumentNo();
        Header."Buy-from Vendor No." := Vendor."No.";
        Header."Vendor Invoice No." := 'NATIVE-INVOICE';
        Header.Insert();
        CreatePurchaseLine(OrderLine, "Purchase Document Type"::Order, NewDocumentNo(), 70000);
        CreatePurchaseLine(Line, Header."Document Type", Header."No.", 10000);
        Line."Order No." := OrderLine."Document No.";
        Line."Order Line No." := OrderLine."Line No.";
        Line.Modify();
        ReceiptLine."Document No." := NewDocumentNo();
        ReceiptLine."Line No." := 90000;
        ReceiptLine."Order No." := OrderLine."Document No.";
        ReceiptLine."Order Line No." := OrderLine."Line No.";
        ReceiptLine.Insert();
        CreatePurchaseLine(Line, Header."Document Type", Header."No.", 20000);
        Line."Receipt No." := ReceiptLine."Document No.";
        Line."Receipt Line No." := ReceiptLine."Line No.";
        Line.Modify();
        WorkItem.RegisterOutcome(Header.RecordId());

        Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);

        Assert.AreEqual(5, Sources.Count(), 'Native header, actual vendor, two lines and one actual matched order target');
        AssertAllSourcesResolve(Sources);
        AssertSource(Sources, Header, 0);
        AssertSource(Sources, Vendor, 1);
        AssertSource(Sources, Line, 3);
        AssertSource(Sources, OrderLine, 4);
        Context := GetContext(Sources, 0);
        AssertText(Context, 'documentNo', Header."No.");
        AssertText(Context, 'invoiceNo', Header."Vendor Invoice No.");
        Context := GetContext(Sources, 4);
        AssertText(Context, 'documentNo', OrderLine."Document No.");
        AssertInteger(Context, 'lineNo', OrderLine."Line No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InfotipSources_MissingTaskAndOutcomeFail()
    var
        Header: Record "Purchase Header";
        WorkItem: Codeunit "PA Work Item";
        Sources: JsonArray;
        AgentTaskId: BigInteger;
    begin
        asserterror Fixtures.GetTaskInfotipSources(0, Sources);
        Assert.ExpectedError('does not work on a Payables Agent work item');
        AgentTaskId := CreateNativeTask(WorkItem);
        asserterror Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);
        Assert.ExpectedError('has no existing unposted purchase outcome');
        Header."Document Type" := Header."Document Type"::Invoice;
        Header."No." := NewDocumentNo();
        Header.Insert();
        WorkItem.RegisterOutcome(Header.RecordId());
        Header.Delete();

        asserterror Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);
        Assert.ExpectedError('has no existing unposted purchase outcome');
        Assert.AreEqual(0, Sources.Count(), 'Missing sources must not become a successful empty snapshot');
    end;

    local procedure CreateNativeTask(var WorkItem: Codeunit "PA Work Item"): BigInteger
    var
        AgentTaskId: BigInteger;
    begin
        Assert.IsTrue(Fixtures.ReceiveUpload('invoice.pdf', WorkItem), 'Create a native work item without agent execution');
        AgentTaskId := CreateTask(WorkItem.GetAgentTaskExternalId());
        WorkItem.AssociateAgentTask(AgentTaskId);
        exit(AgentTaskId);
    end;

    local procedure CreateTask(ExternalId: Text): BigInteger
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
    begin
        Agent."User Security ID" := CreateGuid();
        Agent."Agent Metadata Provider" := "Agent Metadata Provider"::"Payables Agent";
        Agent.Insert();
        AgentTask."Agent User Security ID" := Agent."User Security ID";
        AgentTask."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AgentTask."Company Name"));
        AgentTask."External ID" := CopyStr(ExternalId, 1, MaxStrLen(AgentTask."External ID"));
        AgentTask.Insert();
        exit(AgentTask.ID);
    end;

    local procedure CreatePurchaseLine(var Line: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        Clear(Line);
        Line."Document Type" := DocumentType;
        Line."Document No." := DocumentNo;
        Line."Line No." := LineNo;
        Line.Description := 'Actual source line';
        Line.Insert();
    end;

    local procedure NewDocumentNo(): Code[20]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;

    local procedure AssertAllSourcesResolve(Sources: JsonArray)
    var
        SourceRecord: RecordRef;
        Source, Property: JsonToken;
        Descriptor: JsonObject;
        SourceSystemId: Guid;
    begin
        foreach Source in Sources do begin
            Descriptor := Source.AsObject();
            Assert.AreEqual(3, Descriptor.Keys().Count(), 'Descriptors contain only actual table, SystemId and semantic context');
            Descriptor.Get('tableId', Property);
            SourceRecord.Open(Property.AsValue().AsInteger());
            Descriptor.Get('systemId', Property);
            Evaluate(SourceSystemId, Property.AsValue().AsText());
            Assert.IsTrue(SourceRecord.GetBySystemId(SourceSystemId), 'The descriptor resolves to a surviving actual record');
            SourceRecord.Close();
        end;
    end;

    local procedure AssertSource(Sources: JsonArray; Expected: RecordRef; Index: Integer)
    var
        Source, Property: JsonToken;
        Descriptor: JsonObject;
        ActualSystemId, ExpectedSystemId: Guid;
    begin
        Sources.Get(Index, Source);
        Descriptor := Source.AsObject();
        AssertInteger(Descriptor, 'tableId', Expected.Number());
        Descriptor.Get('systemId', Property);
        Evaluate(ActualSystemId, Property.AsValue().AsText());
        ExpectedSystemId := Expected.Field(Expected.SystemIdNo()).Value;
        Assert.AreEqual(ExpectedSystemId, ActualSystemId, 'Use the actual source, not a temporary-copy SystemId');
    end;

    local procedure GetContext(Sources: JsonArray; Index: Integer): JsonObject
    var
        Source, Context: JsonToken;
    begin
        Sources.Get(Index, Source);
        Source.AsObject().Get('context', Context);
        exit(Context.AsObject());
    end;

    local procedure AssertText(Object: JsonObject; PropertyName: Text; Expected: Text)
    var
        Property: JsonToken;
    begin
        Object.Get(PropertyName, Property);
        Assert.AreEqual(Expected, Property.AsValue().AsText(), PropertyName);
    end;

    local procedure AssertInteger(Object: JsonObject; PropertyName: Text; Expected: Integer)
    var
        Property: JsonToken;
    begin
        Object.Get(PropertyName, Property);
        Assert.AreEqual(Expected, Property.AsValue().AsInteger(), PropertyName);
    end;
}
