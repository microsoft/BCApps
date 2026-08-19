namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy TMA HITL Test (ID 134716).
/// Plain (non-AITest) unit tests for the Human-in-the-Loop layer of the Shopify Tax Matching
/// Agent: marker propagation from Shopify order to Sales Header, notification queue
/// behavior, Activity Log helper invocations, and the Capitalize confidence mapping.
/// No LLM call — these tests drive the helpers directly.
/// </summary>
codeunit 134716 "Shpfy TMA HITL Test"
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
        TMAEvents: Codeunit "Shpfy TMA Events";
    begin
        Cleanup();
        CreateOrderHeader(OrderHeader, true);
        CreateSalesHeader(SalesHeader, 'HITL-1');

        TMAEvents.HandleSalesHeaderCreated(OrderHeader, SalesHeader);

        LibraryAssert.IsTrue(SalesHeader."Tax Match Applied", 'Sales Header marker should be set when Order Header marker is true.');
    end;

    // HITL-2
    [Test]
    procedure MarkerFalseDoesNotPropagate()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        TMAEvents: Codeunit "Shpfy TMA Events";
    begin
        Cleanup();
        CreateOrderHeader(OrderHeader, false);
        CreateSalesHeader(SalesHeader, 'HITL-2');

        TMAEvents.HandleSalesHeaderCreated(OrderHeader, SalesHeader);

        LibraryAssert.IsFalse(SalesHeader."Tax Match Applied", 'Sales Header marker must remain false when Order Header marker is false.');
    end;

    // HITL-3
    [Test]
    procedure MarkReviewedSetsOrderReviewed()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        TMANotify: Codeunit "Shpfy TMA Notify";
        Notif: Notification;
    begin
        Cleanup();
        CreateSalesHeader(SalesHeader, 'HITL-3');
        CreateOrderHeader(OrderHeader, true);
        OrderHeader."Sales Order No." := SalesHeader."No.";
        OrderHeader.Modify();

        Notif.SetData('SalesHeaderSystemId', Format(SalesHeader.SystemId));
        TMANotify.MarkReviewed(Notif);

        OrderHeader.Get(OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(OrderHeader."Tax Match Reviewed",
            'MarkReviewed should set the originating order''s Tax Match Reviewed flag (resolved via Sales Order No.).');
    end;

    // HITL-4
    [Test]
    procedure DisableForUserMarksOrderReviewed()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        TMANotify: Codeunit "Shpfy TMA Notify";
        Notif: Notification;
    begin
        Cleanup();
        CreateSalesHeader(SalesHeader, 'HITL-4');
        CreateOrderHeader(OrderHeader, true);
        OrderHeader."Sales Order No." := SalesHeader."No.";
        OrderHeader.Modify();

        Notif.SetData('SalesHeaderSystemId', Format(SalesHeader.SystemId));
        TMANotify.DisableForUser(Notif);

        OrderHeader.Get(OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(OrderHeader."Tax Match Reviewed",
            'DisableForUser should also mark the order reviewed so the prompt stops firing.');
    end;

    // HITL-5
    [Test]
    procedure ActivityLogHelpersRunWithoutErrors()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        CTActivityLog: Codeunit "Shpfy TMA Activity Log";
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

        OrderTaxLine.Init();
        OrderTaxLine."Parent Id" := OrderLine."Line Id";
        OrderTaxLine."Line No." := 1;
        OrderTaxLine.Title := 'NEW YORK STATE TAX';
        OrderTaxLine."Rate %" := 4;
        OrderTaxLine."Tax Jurisdiction Code" := 'NYSTAX';
        OrderTaxLine.Insert();

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

        CTActivityLog.LogPerLineEntries(OrderHeader, MatchLog);
        CTActivityLog.LogTaxAreaEntry(OrderHeader, 'SHPFY-NYTAX', false, Jurisdictions);
        CTActivityLog.LogTaxAreaEntry(OrderHeader, 'SHPFY-NYTAX', true, Jurisdictions);
    end;

    // HITL-6
    [Test]
    procedure CapitalizeMapsConfidenceCorrectly()
    var
        TMAMatcher: Codeunit "Shpfy TMA Matcher";
    begin
        LibraryAssert.AreEqual('Low', TMAMatcher.Capitalize('low'), 'low');
        LibraryAssert.AreEqual('Low', TMAMatcher.Capitalize('LOW'), 'LOW');
        LibraryAssert.AreEqual('Medium', TMAMatcher.Capitalize('medium'), 'medium');
        LibraryAssert.AreEqual('Medium', TMAMatcher.Capitalize('Medium'), 'Medium');
        LibraryAssert.AreEqual('High', TMAMatcher.Capitalize('HIGH'), 'HIGH');
        LibraryAssert.AreEqual('Low', TMAMatcher.Capitalize(''), 'empty -> Low (safe fallback)');
        LibraryAssert.AreEqual('Low', TMAMatcher.Capitalize('uncertain'), 'unknown -> Low (safe fallback)');
    end;

    local procedure CreateOrderHeader(var OrderHeader: Record "Shpfy Order Header"; MarkerApplied: Boolean)
    begin
        NextOrderId += 1;
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := 950000000 + NextOrderId;
        OrderHeader."Tax Match Applied" := MarkerApplied;
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
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        SalesHeader: Record "Sales Header";
        StartOrderId: BigInteger;
    begin
        OrderTaxLine.DeleteAll();
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
