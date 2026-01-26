codeunit 144002 "Pmt. Disc. Date Calculation"
{
    // -------------------------------------------------------------------------------------------------
    // Function Name                                                                         TFS ID
    // -------------------------------------------------------------------------------------------------
    // PmtDiscDateEqualDueDateOnSalesOrderWithZeroPmtDisc                                    360325
    // CombineShipmentsWithStdPmtTermsAndZeroPmtDiscount                                     360325

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        InvLineForShptDoesNotExistErr: Label 'Invoice line associated with Shipment %1 does not exist.';

    [Test]
    [Scope('OnPrem')]
    procedure CombineShipmentsWithStdPmtTermsAndZeroPmtDisc()
    var
        SalesHeader: Record "Sales Header";
        DocNo: Code[20];
    begin
        // [SCENARIO 360325] Combine Shipments with "Only Std. Payment Terms" option and zero payment discount.

        Initialize();

        // [GIVEN] Ship sales order with Payment Terms with zero pmt. discount percent.
        CreateSalesOrderWithZeroDiscPmtTerms(SalesHeader);
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        Commit();
        SalesHeader.SetRecFilter();

        // [WHEN] Run Combines Shipments with "Only Std. Payment Terms".
        RunCombineShipmentsReport(SalesHeader);

        // [THEN] Shipment combines in Sales Invoice.
        VerifySalesLineForShipment(DocNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Pmt. Disc. Date Calculation");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Pmt. Disc. Date Calculation");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Pmt. Disc. Date Calculation");
    end;

    local procedure CreateCustWithPmtTermsAndCombineShips(GenBusPostGroupCode: Code[20]; VATBusPostGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostGroupCode);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Customer.Validate("Payment Terms Code", CreatePmtTermsWithDateCalcSetupAndZeroDisc());
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(GenProdPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostGroupCode);
        Item.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesOrderWithZeroDiscPmtTerms(var SalesHeader: Record "Sales Header")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustNo :=
          CreateCustWithPmtTermsAndCombineShips(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        ItemNo :=
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(100));
    end;

    local procedure CreatePmtTermsWithDateCalcSetupAndZeroDisc(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(
          PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        PaymentTerms.Validate("Due Date Calculation");
        Evaluate(
          PaymentTerms."Discount Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        PaymentTerms.Validate("Discount Date Calculation");
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure RunCombineShipmentsReport(var SalesHeader: Record "Sales Header")
    var
        CombineShipments: Report "Combine Shipments";
    begin
        CombineShipments.SetHideDialog(true);
        CombineShipments.InitializeRequest(
          SalesHeader."Posting Date", SalesHeader."Posting Date", false, false, true, false);
        CombineShipments.SetTableView(SalesHeader);
        CombineShipments.UseRequestPage(false);
        CombineShipments.Run();
    end;

    local procedure VerifySalesLineForShipment(DocNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Shipment No.", DocNo);
        Assert.IsFalse(SalesLine.IsEmpty, StrSubstNo(InvLineForShptDoesNotExistErr, DocNo));
    end;
}

