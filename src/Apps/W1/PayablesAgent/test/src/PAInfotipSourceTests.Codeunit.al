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
        Source: JsonToken;
        AgentTaskId: BigInteger;
        WorkingSources, FinalizedSources: Text;
    begin
        // [FEATURE] [AI test 1.0] [Payables Agent] [Infotip Sources]
        // [SCENARIO 618671] Working and finalized draft matches expose the same deduplicated source records.

        // [GIVEN] Vendor "V" and two draft lines sharing the same purchase-line target.
        Vendor."No." := NewDocumentNo();
        Vendor.Name := 'Actual source vendor';
        Vendor.Insert();
        CreatePurchaseLine(PurchaseLine, "Purchase Document Type"::Invoice, NewDocumentNo(), 70000);

        // [GIVEN] The task is inserted with the existing draft's correlation ID.
        AgentTaskId := CreateTask(DraftFixtures.CreateMatchedDraftForTest(Vendor."No.", PurchaseLine.SystemId));

        // [WHEN] Sources are collected before finalization.
        Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);

        // [THEN] Each actual source appears once with its actual description.
        Assert.AreEqual(5, Sources.Count(), 'Header, vendor, two draft lines and one deduplicated surviving target');
        AssertAllSourcesResolve(Sources);
        AssertSource(Sources, Vendor, 1);
        AssertSource(Sources, PurchaseLine, 4);
        Sources.Get(0, Source);
        AssertText(Source.AsObject(), 'description', 'SOURCE-INVOICE');
        Sources.Get(1, Source);
        AssertText(Source.AsObject(), 'description', Vendor.Name);
        Sources.Get(2, Source);
        AssertText(Source.AsObject(), 'description', 'Actual draft source');
        Sources.Get(3, Source);
        AssertText(Source.AsObject(), 'description', 'Actual draft source');
        Sources.Get(4, Source);
        AssertText(Source.AsObject(), 'description', PurchaseLine.Description);
        Sources.WriteTo(WorkingSources);

        // [WHEN] Working matches are transferred to finalized matches and sources are collected again.
        DraftFixtures.FinalizeDraftMatchesForTest(AgentTaskId);
        Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);

        // [THEN] Source identities, descriptions and ordering are unchanged.
        Sources.WriteTo(FinalizedSources);
        Assert.AreEqual(WorkingSources, FinalizedSources, 'Finalized relations retain the same actual source identities and descriptions');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InfotipSources_NativeOutcomeAndMatchedOrder()
    var
        Vendor: Record Vendor;
        Header: Record "Purchase Header";
        Line: Record "Purchase Line";
        OrderLine: Record "Purchase Line";
        ReceiptOrderLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        WorkItem: Codeunit "PA Work Item";
        Sources: JsonArray;
        Source: JsonToken;
        AgentTaskId: BigInteger;
    begin
        // [FEATURE] [AI test 1.0] [Payables Agent] [Infotip Sources]
        // [SCENARIO 618671] Native sources include a receipt-only order target without duplicating a repeated direct target.

        // [GIVEN] Invoice "PI" has two direct links to order line "A" and a receipt-only link to order line "B".
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
        OrderLine.Description := 'Direct target';
        OrderLine.Modify();
        CreatePurchaseLine(ReceiptOrderLine, "Purchase Document Type"::Order, OrderLine."Document No.", 80000);
        ReceiptOrderLine.Description := 'Receipt-only target';
        ReceiptOrderLine.Modify();
        CreatePurchaseLine(Line, Header."Document Type", Header."No.", 10000);
        Line."Order No." := OrderLine."Document No.";
        Line."Order Line No." := OrderLine."Line No.";
        Line.Modify();
        ReceiptLine."Document No." := NewDocumentNo();
        ReceiptLine."Line No." := 90000;
        ReceiptLine."Order No." := ReceiptOrderLine."Document No.";
        ReceiptLine."Order Line No." := ReceiptOrderLine."Line No.";
        ReceiptLine.Insert();
        CreatePurchaseLine(Line, Header."Document Type", Header."No.", 20000);
        Line."Receipt No." := ReceiptLine."Document No.";
        Line."Receipt Line No." := ReceiptLine."Line No.";
        Line.Modify();
        CreatePurchaseLine(Line, Header."Document Type", Header."No.", 30000);
        Line.Description := '';
        Line."Order No." := OrderLine."Document No.";
        Line."Order Line No." := OrderLine."Line No.";
        Line.Modify();
        WorkItem.RegisterOutcome(Header.RecordId());

        // [WHEN] Sources are collected for the native outcome.
        Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);

        // [THEN] The header, vendor, three invoice lines and both distinct order targets are returned once.
        Assert.AreEqual(7, Sources.Count(), 'Native header, actual vendor, three lines and two distinct deduplicated order targets');
        AssertAllSourcesResolve(Sources);
        AssertSource(Sources, Header, 0);
        AssertSource(Sources, Vendor, 1);
        AssertSource(Sources, Line, 4);
        AssertSource(Sources, OrderLine, 5);
        AssertSource(Sources, ReceiptOrderLine, 6);
        Sources.Get(0, Source);
        AssertText(Source.AsObject(), 'description', Header."Vendor Invoice No.");
        Sources.Get(1, Source);
        AssertText(Source.AsObject(), 'description', Vendor.Name);
        Sources.Get(4, Source);
        AssertText(Source.AsObject(), 'description', '');
        Sources.Get(5, Source);
        AssertText(Source.AsObject(), 'description', OrderLine.Description);
        Sources.Get(6, Source);
        AssertText(Source.AsObject(), 'description', ReceiptOrderLine.Description);
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
        // [FEATURE] [AI test 1.0] [Payables Agent] [Infotip Sources]
        // [SCENARIO 618671] Missing tasks or native outcomes fail explicitly rather than returning an empty snapshot.

        // [WHEN] Sources are requested for a missing task.
        asserterror Fixtures.GetTaskInfotipSources(0, Sources);

        // [THEN] The missing task is reported.
        Assert.ExpectedError('does not work on a Payables Agent work item');

        // [GIVEN] A native task without a registered outcome.
        AgentTaskId := CreateNativeTask(WorkItem);

        // [WHEN] Sources are requested for that task.
        asserterror Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);

        // [THEN] The missing outcome is reported.
        Assert.ExpectedError('has no existing unposted purchase outcome');

        // [GIVEN] A fresh native task after the expected error rolled back the previous setup.
        AgentTaskId := CreateNativeTask(WorkItem);

        // [GIVEN] Invoice "PI" is registered as the outcome and then deleted.
        Header."Document Type" := Header."Document Type"::Invoice;
        Header."No." := NewDocumentNo();
        Header.Insert();
        WorkItem.RegisterOutcome(Header.RecordId());
        Header.Delete();

        // [WHEN] Sources are requested for the deleted outcome.
        asserterror Fixtures.GetTaskInfotipSources(AgentTaskId, Sources);

        // [THEN] The missing outcome is reported without a successful empty snapshot.
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
            Assert.AreEqual(3, Descriptor.Keys().Count(), 'Descriptors contain only actual tableId, systemId and description');
            Assert.IsTrue(Descriptor.Contains('description'), 'Description is always included, even when blank');
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
