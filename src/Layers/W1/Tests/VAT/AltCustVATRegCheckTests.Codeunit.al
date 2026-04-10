codeunit 134240 "Alt. Cust VAT Reg. Check Tests"
{
    Subtype = Test;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAltCustVATReg: Codeunit "Library - Alt. Cust. VAT Reg.";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        CannotChangeVATDataWhenPrepmtErr: Label 'You cannot make this change because it leads to a different VAT Registration No., Gen. Bus. Posting Group or VAT Bus. Posting Group than in the sales document. Since you have posted a prepayment invoice, such a change will cause an inconsistency in the ledger entries.';
        CannotChangeVATDataWhenPartiallyPostedErr: Label 'You cannot make this change because it leads to a different VAT Registration No., Gen. Bus. Posting Group or VAT Bus. Posting Group than in the sales document. Since you have posted a partial shipment, such a change will cause an inconsistency in the ledger entries.';

    trigger OnRun()
    begin
        // [FEATURE] [Alternative Customer VAT Registration]
    end;

    [Test]
    procedure ChangeVATCountryRegionCodeConnectedToAltCustVATRegWhenPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        // [SCENARIO 525644] Stan cannot change the VAT Country/Region code connected to the Alternative Customer VAT Registration
        // [SCENARIO 525644] when the prepayment has been posted

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(false);
        // [GIVEN] Sales order with prepayment
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithUnitPrice(
            SalesLine, SalesHeader, CreateItem(SalesHeader), LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        // [GIVEN] Posted prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Reopen sales order
        ReleaseSalesDocument.PerformManualReopen(SalesHeader);
        // [GIVEN] Alternative Customer VAT Registration with country "X" is created for the customer
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, SalesHeader."Sell-to Customer No.");
        // [WHEN] Change "VAT Country/Region Code" to "X"
        asserterror SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] The error is thrown
        Assert.ExpectedError(CannotChangeVATDataWhenPrepmtErr);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    procedure ChangeVATCountryRegionCodePartialPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        // [SCENARIO 525644] Stan cannot change the VAT Country/Region code connected to the Alternative Customer VAT Registration
        // [SCENARIO 525644] when sales order has been already posted partially

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(false);
        // [GIVEN] Sales order with a line where quantity = 10
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLineWithUnitPrice(
            SalesLine, SalesHeader, CreateItem(SalesHeader), LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        // [GIVEN] Set "Qty. To Ship" = 5
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 3);
        SalesLine.Modify(true);
        // [GIVEN] Post shipment
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [GIVEN] Reopen sales order
        ReleaseSalesDocument.PerformManualReopen(SalesHeader);
        // [GIVEN] Alternative Customer VAT Registration with country "X" is created for the customer
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, SalesHeader."Sell-to Customer No.");
        // [WHEN] Change "VAT Country/Region Code" to "X"
        asserterror SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] The error is thrown
        Assert.ExpectedError(CannotChangeVATDataWhenPartiallyPostedErr);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    procedure ChangeVATCountryRegionCodeBackFromConnectedToAltCustVATRegWhenPrepayment()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        // [SCENARIO 545060] Stan cannot change the VAT Country/Region code back from the one connected to the Alternative Customer VAT Registration
        // [SCENARIO 545060] when the prepayment has been posted

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(false);
        // [GIVEN] Customer with country "X"
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Alternative Customer VAT Registration with country "Y" is created for the customer
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.");
        // [GIVEN] Sales order with prepayment and "VAT Country/Region Code" = "Y"
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithUnitPrice(
            SalesLine, SalesHeader, CreateItem(SalesHeader), LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        // [GIVEN] Posted prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Reopen sales order
        ReleaseSalesDocument.PerformManualReopen(SalesHeader);
        // [WHEN] Change "VAT Country/Region Code" back to "X"
        asserterror SalesHeader.Validate("VAT Country/Region Code", Customer."Country/Region Code");
        // [THEN] The error is thrown
        Assert.ExpectedError(CannotChangeVATDataWhenPrepmtErr);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    procedure ChangeVATCountryRegionCodeBackPartialPosting()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        // [SCENARIO 545060] Stan cannot change the VAT Country/Region code back from the one connected to the Alternative Customer VAT Registration
        // [SCENARIO 545060] when sales order has been already posted partially

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(false);
        // [GIVEN] Customer with country "X"
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Alternative Customer VAT Registration with country "Y" is created for the customer
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.");
        // [GIVEN] Sales order with "VAT Country/Region Code" = "Y"
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithUnitPrice(
            SalesLine, SalesHeader, CreateItem(SalesHeader), LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        // [GIVEN] Set "Qty. To Ship" = 5
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 3);
        SalesLine.Modify(true);
        // [GIVEN] Post shipment
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [GIVEN] Reopen sales order
        ReleaseSalesDocument.PerformManualReopen(SalesHeader);
        // [WHEN] Change "VAT Country/Region Code" back to "X"
        asserterror SalesHeader.Validate("VAT Country/Region Code", Customer."Country/Region Code");
        // [THEN] The error is thrown
        Assert.ExpectedError(CannotChangeVATDataWhenPartiallyPostedErr);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Alt. Cust VAT Reg. Check Tests");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Alt. Cust VAT Reg. Check Tests");
        LibrarySales.SetInvoiceRounding(false);
        LibrarySetupStorage.Save(Database::"VAT Setup");
        LibrarySetupStorage.SaveSalesSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Alt. Cust VAT Reg. Check Tests");
    end;

    local procedure CreateItem(SalesHeader: Record "Sales Header"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        Item: Record Item;
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindFirst();
        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", SalesHeader."Gen. Bus. Posting Group");
        GeneralPostingSetup.SetFilter("COGS Account", '<>%1', '');
        GeneralPostingSetup.FindFirst();
        LibraryInventory.CreateItemWithPostingSetup(
            Item, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        GeneralPostingSetup.Validate("Sales Prepayments Account", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        exit(Item."No.");
    end;
}