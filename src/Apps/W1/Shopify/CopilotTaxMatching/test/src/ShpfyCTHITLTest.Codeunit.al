namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy CT HITL Test (ID 30493).
/// Plain (non-AITest) unit tests for the Human-in-the-Loop layer of Shopify Copilot Tax
/// Matching: marker propagation from Shopify order to Sales Header, notification queue
/// behavior, Activity Log helper invocations, and the Capitalize confidence mapping.
/// No LLM call — these tests drive the helpers directly.
/// </summary>
codeunit 30493 "Shpfy CT HITL Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Access = Internal;

    // HITL-1
    [Test]
    procedure MarkerPropagatesToSalesHeader()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        Events: Codeunit "Shpfy Copilot Tax Events";
    begin
        Cleanup();
        CreateOrderHeader(OrderHeader, true);
        CreateSalesHeader(SalesHeader, 'HITL-1');

        Events.HandleSalesHeaderCreated(OrderHeader, SalesHeader);

        LibraryAssert.IsTrue(SalesHeader."Copilot Tax Match Applied", 'Sales Header marker should be set when Order Header marker is true.');
    end;

    // HITL-2
    [Test]
    procedure MarkerFalseDoesNotPropagate()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        Notification: Record "Shpfy Copilot Tax Notification";
        Events: Codeunit "Shpfy Copilot Tax Events";
    begin
        Cleanup();
        CreateOrderHeader(OrderHeader, false);
        CreateSalesHeader(SalesHeader, 'HITL-2');

        Events.HandleSalesHeaderCreated(OrderHeader, SalesHeader);

        LibraryAssert.IsFalse(SalesHeader."Copilot Tax Match Applied", 'Sales Header marker must remain false when Order Header marker is false.');

        Notification.SetRange("Sales Header SystemId", SalesHeader.SystemId);
        LibraryAssert.IsTrue(Notification.IsEmpty(), 'No notification row should be queued when the marker did not propagate.');
    end;

    // HITL-3
    [Test]
    procedure NotificationRowInsertedOnPropagation()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        Notification: Record "Shpfy Copilot Tax Notification";
        Events: Codeunit "Shpfy Copilot Tax Events";
    begin
        Cleanup();
        CreateOrderHeader(OrderHeader, true);
        OrderHeader."Tax Area Code" := 'SHPFY-NYTAX';
        OrderHeader.Modify();
        CreateSalesHeader(SalesHeader, 'HITL-3');
        SalesHeader."Tax Area Code" := 'SHPFY-NYTAX';
        SalesHeader.Modify();

        Events.HandleSalesHeaderCreated(OrderHeader, SalesHeader);

        LibraryAssert.IsTrue(Notification.Get(SalesHeader.SystemId, UserId()),
            'A Shpfy Copilot Tax Notification row should exist keyed by (Sales Header SystemId, current user).');
        LibraryAssert.IsFalse(Notification.Reviewed, 'New notification rows must default to Reviewed = false.');
        LibraryAssert.AreEqual('SHPFY-NYTAX', Notification."Tax Area Code", 'Notification row should capture the Tax Area Code.');
    end;

    // HITL-4
    [Test]
    procedure MarkReviewedFlipsReviewed()
    var
        SalesHeader: Record "Sales Header";
        Notification: Record "Shpfy Copilot Tax Notification";
        Notify: Codeunit "Shpfy Copilot Tax Notify";
        Notif: Notification;
    begin
        Cleanup();
        CreateSalesHeader(SalesHeader, 'HITL-4');

        Notification.Init();
        Notification."Sales Header SystemId" := SalesHeader.SystemId;
        Notification."User Id" := CopyStr(UserId(), 1, MaxStrLen(Notification."User Id"));
        Notification.Created := CurrentDateTime();
        Notification.Reviewed := false;
        Notification.Insert();

        Notif.SetData('SalesHeaderSystemId', Format(SalesHeader.SystemId));
        Notify.MarkReviewed(Notif);

        LibraryAssert.IsTrue(Notification.Get(SalesHeader.SystemId, UserId()), 'Notification row should still exist after MarkReviewed.');
        LibraryAssert.IsTrue(Notification.Reviewed, 'MarkReviewed should set Reviewed = true on the row.');
    end;

    // HITL-5
    [Test]
    procedure ActivityLogHelpersRunWithoutErrors()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        ActivityLog: Codeunit "Shpfy CT Activity Log";
        MatchLog: JsonArray;
        MatchEntry: JsonObject;
        Jurisdictions: List of [Code[10]];
    begin
        Cleanup();
        CreateOrderHeader(OrderHeader, true);

        OrderLine.Init();
        OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
        OrderLine."Line Id" := 9000001;
        OrderLine.Insert();

        if not TaxJurisdiction.Get('NYSTAX') then begin
            TaxJurisdiction.Init();
            TaxJurisdiction.Code := 'NYSTAX';
            TaxJurisdiction.Description := 'New York State Tax';
            TaxJurisdiction.Insert(true);
        end;

        TaxLine.Init();
        TaxLine."Parent Id" := OrderLine."Line Id";
        TaxLine."Line No." := 1;
        TaxLine.Title := 'NEW YORK STATE TAX';
        TaxLine."Rate %" := 4;
        TaxLine."Tax Jurisdiction Code" := 'NYSTAX';
        TaxLine.Insert();

        if not TaxArea.Get('SHPFY-NYTAX') then begin
            TaxArea.Init();
            TaxArea.Code := 'SHPFY-NYTAX';
            TaxArea.Description := 'Shopify - NY';
            TaxArea.Insert(true);
        end;

        MatchEntry.Add('parentId', OrderLine."Line Id");
        MatchEntry.Add('lineNo', 1);
        MatchEntry.Add('jurisdictionCode', 'NYSTAX');
        MatchEntry.Add('confidence', 'High');
        MatchEntry.Add('reason', 'Title matches jurisdiction description.');
        MatchLog.Add(MatchEntry);

        Jurisdictions.Add('NYSTAX');

        ActivityLog.LogPerLineEntries(OrderHeader, MatchLog);
        ActivityLog.LogTaxAreaEntry(OrderHeader, 'SHPFY-NYTAX', false, Jurisdictions);
        ActivityLog.LogTaxAreaEntry(OrderHeader, 'SHPFY-NYTAX', true, Jurisdictions);
    end;

    // HITL-6
    [Test]
    procedure CapitalizeMapsConfidenceCorrectly()
    var
        Matcher: Codeunit "Shpfy Copilot Tax Matcher";
    begin
        LibraryAssert.AreEqual('Low', Matcher.Capitalize('low'), 'low');
        LibraryAssert.AreEqual('Low', Matcher.Capitalize('LOW'), 'LOW');
        LibraryAssert.AreEqual('Medium', Matcher.Capitalize('medium'), 'medium');
        LibraryAssert.AreEqual('Medium', Matcher.Capitalize('Medium'), 'Medium');
        LibraryAssert.AreEqual('High', Matcher.Capitalize('HIGH'), 'HIGH');
        LibraryAssert.AreEqual('Low', Matcher.Capitalize(''), 'empty -> Low (safe fallback)');
        LibraryAssert.AreEqual('Low', Matcher.Capitalize('uncertain'), 'unknown -> Low (safe fallback)');
    end;

    local procedure CreateOrderHeader(var OrderHeader: Record "Shpfy Order Header"; CopilotMarkerApplied: Boolean)
    begin
        NextOrderId += 1;
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := 950000000 + NextOrderId;
        OrderHeader."Copilot Tax Match Applied" := CopilotMarkerApplied;
        OrderHeader.Insert();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; SuffixTok: Text)
    begin
        NextSalesHeaderSequence += 1;
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := CopyStr('CTHITL-' + SuffixTok + '-' + Format(NextSalesHeaderSequence), 1, MaxStrLen(SalesHeader."No."));
        SalesHeader.Insert();
    end;

    local procedure Cleanup()
    var
        Notification: Record "Shpfy Copilot Tax Notification";
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        SalesHeader: Record "Sales Header";
        StartOrderId: BigInteger;
    begin
        Notification.DeleteAll();
        TaxLine.DeleteAll();
        OrderLine.DeleteAll();
        StartOrderId := 950000000;
        OrderHeader.SetFilter("Shopify Order Id", '>=%1', StartOrderId);
        OrderHeader.DeleteAll();
        SalesHeader.SetFilter("No.", 'CTHITL-*');
        SalesHeader.DeleteAll();
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        NextOrderId: BigInteger;
        NextSalesHeaderSequence: Integer;
}
