namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy CT Rate Conflict Test (ID 134720).
/// Plain (non-AITest) unit tests for the rate-conflict lifecycle of Shopify Copilot Tax
/// Matching: the on-approve recheck/flip of the Copilot Tax Rate Conflict flag
/// (ReapplyFromAssignedLines), the Sales Document creation gate decision
/// (IsSalesDocumentCreationHeld), and Undo Approval. No LLM call — these tests drive the
/// helpers directly against records built in the test database.
/// </summary>
codeunit 134720 "Shpfy CT Rate Conflict Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Access = Internal;

    var
        LibraryAssert: Codeunit "Library Assert";
        NextOrderId: BigInteger;

    // RD1 / RD6 — a matched jurisdiction whose BC Tax Detail rate differs from Shopify's is
    // detected as a rate conflict; the jurisdiction stays assigned and the existing detail is
    // left untouched.
    [Test]
    procedure ReapplyDetectsRateConflict()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        Shop: Record "Shpfy Shop";
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        HasRateConflict: Boolean;
    begin
        Cleanup();
        Shop := CreateShop();
        // BC has NYSTAX x TAXABLE at 10%, but Shopify charged 20% on the line.
        CreateConflictScenario(OrderHeader, Shop, 20, 10);

        CopilotTaxMatcher.ReapplyFromAssignedLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);

        LibraryAssert.IsTrue(HasRateConflict, 'A differing BC Tax Detail rate should be flagged as a rate conflict.');

        OrderTaxLine.Get(GetLineId(OrderHeader), 1);
        LibraryAssert.AreEqual('NYSTAX', OrderTaxLine."Tax Jurisdiction Code", 'The jurisdiction must stay assigned on a rate conflict.');

        LibraryAssert.AreEqual(10, GetEffectiveBcRate('NYSTAX', 'TAXABLE'), 'The existing Tax Detail rate must be left untouched.');
    end;

    // RD5 — after the user corrects the Tax Detail rate to match Shopify, re-applying clears the
    // rate conflict (this is what Approve does before releasing the order).
    [Test]
    procedure ReapplyClearsConflictWhenRateFixed()
    var
        OrderHeader: Record "Shpfy Order Header";
        TaxDetail: Record "Tax Detail";
        Shop: Record "Shpfy Shop";
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        HasRateConflict: Boolean;
    begin
        Cleanup();
        Shop := CreateShop();
        CreateConflictScenario(OrderHeader, Shop, 20, 10);

        // User fixes the conflicting Tax Detail rate to match Shopify.
        TaxDetail.SetRange("Tax Jurisdiction Code", 'NYSTAX');
        TaxDetail.SetRange("Tax Group Code", 'TAXABLE');
        TaxDetail.FindFirst();
        TaxDetail."Tax Below Maximum" := 20;
        TaxDetail.Modify();

        CopilotTaxMatcher.ReapplyFromAssignedLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);

        LibraryAssert.IsFalse(HasRateConflict, 'Correcting the Tax Detail rate should clear the rate conflict on re-apply.');
    end;

    // TD1 — no existing bracket: re-apply seeds one at Shopify's rate and reports no conflict.
    [Test]
    procedure ReapplyNoConflictWhenNoBracket()
    var
        OrderHeader: Record "Shpfy Order Header";
        TaxDetail: Record "Tax Detail";
        Shop: Record "Shpfy Shop";
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        HasRateConflict: Boolean;
    begin
        Cleanup();
        Shop := CreateShop();
        // No existing Tax Detail (pass 0 to skip creating one).
        CreateConflictScenario(OrderHeader, Shop, 20, 0);

        CopilotTaxMatcher.ReapplyFromAssignedLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);

        LibraryAssert.IsFalse(HasRateConflict, 'No existing bracket means no conflict.');
        TaxDetail.SetRange("Tax Jurisdiction Code", 'NYSTAX');
        TaxDetail.SetRange("Tax Group Code", 'TAXABLE');
        LibraryAssert.IsFalse(TaxDetail.IsEmpty(), 'A Tax Detail should have been seeded at Shopify''s rate.');
    end;

    // RD3 — order held for creation when the shop requires review.
    [Test]
    procedure GateHeldWhenReviewRequired()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildOrderAndShop(OrderHeader, Shop, true, false, true, false);
        LibraryAssert.IsTrue(CopilotTaxEvents.IsSalesDocumentCreationHeld(OrderHeader, Shop),
            'A matched, not-yet-reviewed order must be held when the shop requires review.');
    end;

    // RD4 — order held for creation on a rate conflict even when review is not required.
    [Test]
    procedure GateHeldWhenRateConflictAndReviewNotRequired()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildOrderAndShop(OrderHeader, Shop, true, false, false, true);
        LibraryAssert.IsTrue(CopilotTaxEvents.IsSalesDocumentCreationHeld(OrderHeader, Shop),
            'A rate conflict must hold the order regardless of the review-required toggle.');
    end;

    // Non-blocking, no conflict — the order is released (created automatically).
    [Test]
    procedure GateNotHeldWhenNonBlockingNoConflict()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildOrderAndShop(OrderHeader, Shop, true, false, false, false);
        LibraryAssert.IsFalse(CopilotTaxEvents.IsSalesDocumentCreationHeld(OrderHeader, Shop),
            'With no review requirement and no conflict, the order must not be held.');
    end;

    // Already approved — never held.
    [Test]
    procedure GateNotHeldWhenReviewed()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildOrderAndShop(OrderHeader, Shop, true, true, true, true);
        LibraryAssert.IsFalse(CopilotTaxEvents.IsSalesDocumentCreationHeld(OrderHeader, Shop),
            'An approved order must never be held.');
    end;

    // Not Copilot-matched — never held.
    [Test]
    procedure GateNotHeldWhenNotApplied()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildOrderAndShop(OrderHeader, Shop, false, false, true, true);
        LibraryAssert.IsFalse(CopilotTaxEvents.IsSalesDocumentCreationHeld(OrderHeader, Shop),
            'An order Copilot did not match must not be held.');
    end;

    // RD9 — Undo Approval clears the reviewed flag, so a held order is held again.
    [Test]
    procedure UndoApprovalReholdsOrder()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxNotify: Codeunit "Shpfy Copilot Tax Notify";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        Cleanup();
        Shop := CreateShop();
        Shop."Tax Match Review Required" := true;
        Shop.Modify();

        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := NextId();
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Copilot Tax Match Applied" := true;
        OrderHeader."Copilot Tax Match Reviewed" := true;
        OrderHeader.Insert();

        CopilotTaxNotify.UndoApproval(OrderHeader);

        LibraryAssert.IsFalse(OrderHeader."Copilot Tax Match Reviewed", 'Undo Approval must clear the reviewed flag.');
        LibraryAssert.IsTrue(CopilotTaxEvents.IsSalesDocumentCreationHeld(OrderHeader, Shop),
            'After Undo Approval a review-required order must be held again.');
    end;

    // Undo Approval on a not-yet-approved order is a harmless no-op.
    [Test]
    procedure UndoApprovalNoOpWhenNotReviewed()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxNotify: Codeunit "Shpfy Copilot Tax Notify";
    begin
        Cleanup();
        Shop := CreateShop();

        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := NextId();
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Copilot Tax Match Applied" := true;
        OrderHeader."Copilot Tax Match Reviewed" := false;
        OrderHeader.Insert();

        CopilotTaxNotify.UndoApproval(OrderHeader);

        LibraryAssert.IsFalse(OrderHeader."Copilot Tax Match Reviewed", 'Undo Approval on a not-reviewed order stays not-reviewed.');
    end;

    local procedure BuildOrderAndShop(var OrderHeader: Record "Shpfy Order Header"; var Shop: Record "Shpfy Shop"; Applied: Boolean; Reviewed: Boolean; ReviewRequired: Boolean; RateConflict: Boolean)
    begin
        // In-memory records are enough — IsSalesDocumentCreationHeld only reads these fields.
        Clear(Shop);
        Shop.Code := 'CTMTEST';
        Shop."Tax Match Review Required" := ReviewRequired;

        Clear(OrderHeader);
        OrderHeader."Shopify Order Id" := NextId();
        OrderHeader."Copilot Tax Match Applied" := Applied;
        OrderHeader."Copilot Tax Match Reviewed" := Reviewed;
        OrderHeader."Copilot Tax Rate Conflict" := RateConflict;
    end;

    local procedure CreateConflictScenario(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; ShopifyRate: Decimal; ExistingBcRate: Decimal)
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        LineId: BigInteger;
    begin
        EnsureItem('ITEM001', 'TAXABLE');
        EnsureJurisdiction('NYSTAX');

        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := NextId();
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Document Date" := 20260115D;
        OrderHeader.Insert();

        LineId := OrderHeader."Shopify Order Id" + 1;
        OrderLine.Init();
        OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
        OrderLine."Line Id" := LineId;
        OrderLine."Item No." := 'ITEM001';
        OrderLine.Insert();

        OrderTaxLine.Init();
        OrderTaxLine."Parent Id" := LineId;
        OrderTaxLine."Line No." := 1;
        OrderTaxLine.Title := 'NEW YORK STATE TAX';
        OrderTaxLine."Rate %" := ShopifyRate;
        OrderTaxLine."Tax Jurisdiction Code" := 'NYSTAX';
        OrderTaxLine.Insert();

        if ExistingBcRate <> 0 then
            CreateTaxDetail('NYSTAX', 'TAXABLE', ExistingBcRate, 20260101D);

        if TaxJurisdiction.Get('NYSTAX') then;
    end;

    local procedure CreateTaxDetail(JurisdictionCode: Code[10]; TaxGroupCode: Code[20]; Rate: Decimal; EffectiveDate: Date)
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxDetail.Init();
        TaxDetail."Tax Jurisdiction Code" := JurisdictionCode;
        TaxDetail."Tax Group Code" := TaxGroupCode;
        TaxDetail."Tax Type" := TaxDetail."Tax Type"::"Sales and Use Tax";
        TaxDetail."Effective Date" := EffectiveDate;
        TaxDetail."Tax Below Maximum" := Rate;
        TaxDetail.Insert(true);
    end;

    local procedure EnsureItem(ItemNo: Code[20]; TaxGroupCode: Code[20])
    var
        Item: Record Item;
        TaxGroup: Record "Tax Group";
    begin
        if (TaxGroupCode <> '') and not TaxGroup.Get(TaxGroupCode) then begin
            TaxGroup.Init();
            TaxGroup.Code := TaxGroupCode;
            TaxGroup.Description := TaxGroupCode;
            TaxGroup.Insert(true);
        end;
        if Item.Get(ItemNo) then
            exit;
        Item.Init();
        Item."No." := ItemNo;
        Item.Description := ItemNo;
        Item."Tax Group Code" := TaxGroupCode;
        Item.Insert(true);
    end;

    local procedure EnsureJurisdiction(JurisdictionCode: Code[10])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if TaxJurisdiction.Get(JurisdictionCode) then
            exit;
        TaxJurisdiction.Init();
        TaxJurisdiction.Code := JurisdictionCode;
        TaxJurisdiction.Description := JurisdictionCode;
        TaxJurisdiction.Insert(true);
    end;

    local procedure CreateShop(): Record "Shpfy Shop"
    var
        Shop: Record "Shpfy Shop";
    begin
        if Shop.Get('CTMTEST') then
            exit(Shop);
        Shop.Init();
        Shop.Code := 'CTMTEST';
        Shop."Shopify URL" := 'https://ctm-test.myshopify.com';
        Shop."Copilot Tax Matching Enabled" := true;
        Shop.Insert();
        exit(Shop);
    end;

    local procedure GetLineId(OrderHeader: Record "Shpfy Order Header"): BigInteger
    begin
        exit(OrderHeader."Shopify Order Id" + 1);
    end;

    local procedure GetEffectiveBcRate(JurisdictionCode: Code[10]; TaxGroupCode: Code[20]): Decimal
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxDetail.SetRange("Tax Jurisdiction Code", JurisdictionCode);
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst();
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure NextId(): BigInteger
    begin
        NextOrderId += 1;
        exit(960000000 + NextOrderId);
    end;

    local procedure Cleanup()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        Shop: Record "Shpfy Shop";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxGroup: Record "Tax Group";
        Item: Record Item;
    begin
        OrderTaxLine.DeleteAll();
        OrderLine.DeleteAll();
        OrderHeader.SetFilter("Shopify Order Id", '>=%1', 960000000);
        OrderHeader.DeleteAll();
        Shop.SetRange(Code, 'CTMTEST');
        Shop.DeleteAll();
        TaxDetail.DeleteAll();
        TaxJurisdiction.DeleteAll();
        TaxGroup.DeleteAll();
        Item.DeleteAll();
    end;
}
