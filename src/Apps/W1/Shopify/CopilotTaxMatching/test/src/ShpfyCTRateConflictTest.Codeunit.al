namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Account;
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

    // JC2 regression — every matched jurisdiction with a blank Report-to (auto-created or
    // pre-existing) gets Report-to = the first (state) jurisdiction, including the state itself.
    [Test]
    procedure ReapplySetsReportToOnBlankJurisdictions()
    var
        OrderHeader: Record "Shpfy Order Header";
        TaxJurisdiction: Record "Tax Jurisdiction";
        Shop: Record "Shpfy Shop";
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        HasRateConflict: Boolean;
    begin
        Cleanup();
        Shop := CreateShop();
        // Two product lines with pre-existing jurisdictions that both have a BLANK Report-to
        // (mirrors a DB where jurisdictions already exist from earlier runs).
        CreateTwoLineJurisdictionScenario(OrderHeader, Shop);

        CopilotTaxMatcher.ReapplyFromAssignedLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);

        TaxJurisdiction.Get('NYSTAX');
        LibraryAssert.AreEqual('NYSTAX', TaxJurisdiction."Report-to Jurisdiction", 'The state jurisdiction must report to itself, not stay blank.');
        TaxJurisdiction.Get('NYCTAX');
        LibraryAssert.AreEqual('NYSTAX', TaxJurisdiction."Report-to Jurisdiction", 'The city jurisdiction must report to the state.');
    end;

    // An existing admin-maintained Report-to must never be overwritten.
    [Test]
    procedure ReapplyPreservesExistingReportTo()
    var
        OrderHeader: Record "Shpfy Order Header";
        TaxJurisdiction: Record "Tax Jurisdiction";
        Shop: Record "Shpfy Shop";
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        HasRateConflict: Boolean;
    begin
        Cleanup();
        Shop := CreateShop();
        CreateTwoLineJurisdictionScenario(OrderHeader, Shop);
        // Admin has NYCTAX reporting to a custom jurisdiction, not the state.
        EnsureJurisdiction('CUSTOMRPT');
        TaxJurisdiction.Get('NYCTAX');
        TaxJurisdiction."Report-to Jurisdiction" := 'CUSTOMRPT';
        TaxJurisdiction.Modify();

        CopilotTaxMatcher.ReapplyFromAssignedLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);

        TaxJurisdiction.Get('NYCTAX');
        LibraryAssert.AreEqual('CUSTOMRPT', TaxJurisdiction."Report-to Jurisdiction", 'An existing Report-to must be preserved, not overwritten.');
    end;

    // Shipping tax line is first-class: its own rate seeds the shipping-group Tax Detail.
    [Test]
    procedure ReapplySeedsShippingBracketFromShippingTaxLine()
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
        // Shipping charge with its own tax line at 8%, no existing shipping-group bracket.
        CreateShippingScenario(OrderHeader, Shop, 8, 0);

        CopilotTaxMatcher.ReapplyFromAssignedLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);

        LibraryAssert.IsFalse(HasRateConflict, 'No existing shipping bracket means no conflict.');
        TaxDetail.SetRange("Tax Jurisdiction Code", 'NYSTAX');
        TaxDetail.SetRange("Tax Group Code", 'FREIGHT');
        TaxDetail.SetRange("Tax Below Maximum", 8);
        LibraryAssert.IsFalse(TaxDetail.IsEmpty(), 'A shipping-group Tax Detail should be seeded at the shipping tax line''s own rate.');
    end;

    // Shipping rate conflict now holds like product lines (BC shipping rate != Shopify's).
    [Test]
    procedure ReapplyDetectsShippingRateConflict()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        HasRateConflict: Boolean;
    begin
        Cleanup();
        Shop := CreateShop();
        // BC has NYSTAX x FREIGHT at 5%, but the shipping tax line charged 8%.
        CreateShippingScenario(OrderHeader, Shop, 8, 5);

        CopilotTaxMatcher.ReapplyFromAssignedLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);

        LibraryAssert.IsTrue(HasRateConflict, 'A shipping tax line whose rate differs from BC must flag a rate conflict.');
        LibraryAssert.AreEqual(5, GetEffectiveBcRate('NYSTAX', 'FREIGHT'), 'The existing shipping Tax Detail rate must be left untouched.');
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

    // Guard — matching runs only when enabled, no Tax Area yet, and not tax exempt.
    [Test]
    procedure ShouldAttemptMatchWhenEligible()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildGuardRecords(OrderHeader, Shop, true, '', false);
        LibraryAssert.IsTrue(CopilotTaxEvents.ShouldAttemptMatch(OrderHeader, Shop),
            'Matching should run for an enabled shop, no existing Tax Area, not tax exempt.');
    end;

    [Test]
    procedure ShouldNotAttemptMatchWhenDisabled()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildGuardRecords(OrderHeader, Shop, false, '', false);
        LibraryAssert.IsFalse(CopilotTaxEvents.ShouldAttemptMatch(OrderHeader, Shop),
            'Matching must not run when the shop has Copilot Tax Matching disabled.');
    end;

    // P4 idempotency — a Tax Area already resolved (e.g. by address-based MapTaxArea or re-import).
    [Test]
    procedure ShouldNotAttemptMatchWhenTaxAreaAlreadySet()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildGuardRecords(OrderHeader, Shop, true, 'EXISTING', false);
        LibraryAssert.IsFalse(CopilotTaxEvents.ShouldAttemptMatch(OrderHeader, Shop),
            'Matching must not run when the order already has a Tax Area Code.');
    end;

    [Test]
    procedure ShouldNotAttemptMatchWhenTaxExempt()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        CopilotTaxEvents: Codeunit "Shpfy Copilot Tax Events";
    begin
        BuildGuardRecords(OrderHeader, Shop, true, '', true);
        LibraryAssert.IsFalse(CopilotTaxEvents.ShouldAttemptMatch(OrderHeader, Shop),
            'Matching must not run for a tax-exempt order.');
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

    local procedure BuildGuardRecords(var OrderHeader: Record "Shpfy Order Header"; var Shop: Record "Shpfy Shop"; Enabled: Boolean; ExistingTaxAreaCode: Code[20]; TaxExempt: Boolean)
    begin
        // In-memory records — ShouldAttemptMatch only reads these fields.
        Clear(Shop);
        Shop.Code := 'CTMTEST';
        Shop."Copilot Tax Matching Enabled" := Enabled;

        Clear(OrderHeader);
        OrderHeader."Shopify Order Id" := NextId();
        OrderHeader."Tax Area Code" := ExistingTaxAreaCode;
        OrderHeader."Tax Exempt" := TaxExempt;
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

    local procedure CreateTwoLineJurisdictionScenario(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop")
    var
        OrderLine: Record "Shpfy Order Line";
        LineId: BigInteger;
    begin
        // Both jurisdictions pre-exist with a blank Report-to (as after earlier runs).
        EnsureJurisdiction('NYSTAX');
        EnsureJurisdiction('NYCTAX');
        EnsureItem('ITEM001', 'TAXABLE');

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

        InsertMatchedTaxLine(LineId, 1, 'NEW YORK STATE TAX', 4, 'NYSTAX');
        InsertMatchedTaxLine(LineId, 2, 'NEW YORK CITY TAX', 4.5, 'NYCTAX');
    end;

    local procedure InsertMatchedTaxLine(ParentId: BigInteger; LineNo: Integer; LineTitle: Text; RatePct: Decimal; JurisdictionCode: Code[10])
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
    begin
        OrderTaxLine.Init();
        OrderTaxLine."Parent Id" := ParentId;
        OrderTaxLine."Line No." := LineNo;
        OrderTaxLine.Title := CopyStr(LineTitle, 1, MaxStrLen(OrderTaxLine.Title));
        OrderTaxLine."Rate %" := RatePct;
        OrderTaxLine."Tax Jurisdiction Code" := JurisdictionCode;
        OrderTaxLine.Insert();
    end;

    local procedure CreateShippingScenario(var OrderHeader: Record "Shpfy Order Header"; var Shop: Record "Shpfy Shop"; ShopifyRate: Decimal; ExistingBcRate: Decimal)
    var
        ShippingCharge: Record "Shpfy Order Shipping Charges";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ShippingLineId: BigInteger;
    begin
        EnsureJurisdiction('NYSTAX');
        EnsureShippingAccount(Shop, 'SHIPACC', 'FREIGHT');

        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := NextId();
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Document Date" := 20260115D;
        OrderHeader.Insert();

        ShippingLineId := OrderHeader."Shopify Order Id" + 5000;
        ShippingCharge.Init();
        ShippingCharge."Shopify Shipping Line Id" := ShippingLineId;
        ShippingCharge."Shopify Order Id" := OrderHeader."Shopify Order Id";
        ShippingCharge.Title := 'Standard Shipping';
        ShippingCharge.Insert();

        OrderTaxLine.Init();
        OrderTaxLine."Parent Id" := ShippingLineId;
        OrderTaxLine."Line No." := 1;
        OrderTaxLine.Title := 'NEW YORK STATE TAX';
        OrderTaxLine."Rate %" := ShopifyRate;
        OrderTaxLine."Tax Jurisdiction Code" := 'NYSTAX';
        OrderTaxLine.Insert();

        if ExistingBcRate <> 0 then
            CreateTaxDetail('NYSTAX', 'FREIGHT', ExistingBcRate, 20260101D);
    end;

    local procedure EnsureShippingAccount(var Shop: Record "Shpfy Shop"; AccountNo: Code[20]; TaxGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        TaxGroup: Record "Tax Group";
    begin
        if not TaxGroup.Get(TaxGroupCode) then begin
            TaxGroup.Init();
            TaxGroup.Code := TaxGroupCode;
            TaxGroup.Description := TaxGroupCode;
            TaxGroup.Insert(true);
        end;
        if not GLAccount.Get(AccountNo) then begin
            GLAccount.Init();
            GLAccount."No." := AccountNo;
            GLAccount.Name := AccountNo;
            GLAccount."Tax Group Code" := TaxGroupCode;
            GLAccount.Insert(false);
        end;
        Shop."Shipping Charges Account" := AccountNo;
        Shop.Modify();
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
        ShippingCharge: Record "Shpfy Order Shipping Charges";
        Shop: Record "Shpfy Shop";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxGroup: Record "Tax Group";
        Item: Record Item;
        GLAccount: Record "G/L Account";
    begin
        OrderTaxLine.DeleteAll();
        OrderLine.DeleteAll();
        ShippingCharge.DeleteAll();
        OrderHeader.SetFilter("Shopify Order Id", '>=%1', 960000000);
        OrderHeader.DeleteAll();
        Shop.SetRange(Code, 'CTMTEST');
        Shop.DeleteAll();
        TaxDetail.DeleteAll();
        TaxJurisdiction.DeleteAll();
        TaxGroup.DeleteAll();
        Item.DeleteAll();
        if GLAccount.Get('SHIPACC') then
            GLAccount.Delete();
    end;
}
