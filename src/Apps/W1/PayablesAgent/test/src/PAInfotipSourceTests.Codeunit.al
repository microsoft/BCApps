// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

codeunit 133735 "PA Infotip Source Tests"
// [FEATURE] [AI test 1.0] [Payables Agent] [Infotip Sources]
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
        WorkItemId: Guid;
        WorkingSources, FinalizedSources: Text;
    begin
        // [SCENARIO 618671] Working and finalized draft matches expose the same deduplicated source records.
        Initialize();

        // [GIVEN] Vendor "V" and two draft lines sharing the same purchase-line target.
        Vendor."No." := NewDocumentNo();
        Vendor.Name := 'Actual source vendor';
        Vendor.Insert();
        CreatePurchaseLine(PurchaseLine, "Purchase Document Type"::Invoice, NewDocumentNo(), 70000);

        // [GIVEN] The stored draft is identified without creating an agent task.
        WorkItemId := DraftFixtures.CreateMatchedDraftForTest(Vendor."No.", PurchaseLine.SystemId);

        // [WHEN] Sources are collected before finalization.
        Fixtures.GetWorkItemInfotipSources(WorkItemId, Sources);

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
        DraftFixtures.FinalizeDraftMatchesForTest(WorkItemId);
        Fixtures.GetWorkItemInfotipSources(WorkItemId, Sources);

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
        Sources: JsonArray;
        Source: JsonToken;
        WorkItemId: Guid;
    begin
        // [SCENARIO 618671] Native sources include a receipt-only order target without duplicating a repeated direct target.
        Initialize();

        // [GIVEN] Invoice "PI" has two direct links to order line "A" and a receipt-only link to order line "B".
        WorkItemId := CreateNativeWorkItem();
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
        Fixtures.SetWorkItemOutcomeForTest(WorkItemId, Header.RecordId());

        // [WHEN] Sources are collected for the native outcome.
        Fixtures.GetWorkItemInfotipSources(WorkItemId, Sources);

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
        Sources: JsonArray;
        WorkItemId: Guid;
    begin
        // [SCENARIO 618671] Missing tasks or native outcomes fail explicitly rather than returning an empty snapshot.
        Initialize();

        // [WHEN] Sources are requested for a missing task.
        asserterror Fixtures.GetTaskInfotipSources(0, Sources);

        // [THEN] The missing task is reported.
        Assert.ExpectedError('does not work on a Payables Agent work item');
        Assert.ExpectedErrorCode('Dialog');

        // [WHEN] Sources are requested for a missing work item.
        asserterror Fixtures.GetWorkItemInfotipSources(CreateGuid(), Sources);

        // [THEN] The missing work item is reported rather than yielding an empty snapshot.
        Assert.ExpectedError('does not exist');
        Assert.ExpectedErrorCode('Dialog');

        // [GIVEN] A native work item without a stored outcome.
        WorkItemId := CreateNativeWorkItem();

        // [WHEN] Sources are requested for that work item.
        asserterror Fixtures.GetWorkItemInfotipSources(WorkItemId, Sources);

        // [THEN] The missing outcome is reported.
        Assert.ExpectedError('has no existing unposted purchase outcome');
        Assert.ExpectedErrorCode('Dialog');

        // [GIVEN] A fresh native work item after the expected error rolled back the previous setup.
        WorkItemId := CreateNativeWorkItem();

        // [GIVEN] Invoice "PI" is stored as the outcome and then deleted.
        Header."Document Type" := Header."Document Type"::Invoice;
        Header."No." := NewDocumentNo();
        Header.Insert();
        Fixtures.SetWorkItemOutcomeForTest(WorkItemId, Header.RecordId());
        Header.Delete();

        // [WHEN] Sources are requested for the deleted outcome.
        asserterror Fixtures.GetWorkItemInfotipSources(WorkItemId, Sources);

        // [THEN] The missing outcome is reported without a successful empty snapshot.
        Assert.ExpectedError('has no existing unposted purchase outcome');
        Assert.ExpectedErrorCode('Dialog');
        Assert.AreEqual(0, Sources.Count(), 'Missing sources must not become a successful empty snapshot');
    end;

    local procedure Initialize()
    begin
        Clear(Fixtures);
    end;

    local procedure CreateNativeWorkItem(): Guid
    var
        WorkItem: Codeunit "PA Work Item";
    begin
        Assert.IsTrue(Fixtures.ReceiveUpload('invoice.pdf', WorkItem), 'Create a native work item without agent execution');
        exit(WorkItem.GetId());
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
