codeunit 144071 "UT PAG VAT Exemption"
{
    // // [FEATURE] [VAT Exemption]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('NoSeriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageVATExemptionsCustomerCard()
    var
        VATExemption: Record "VAT Exemption";
        CustomerCard: TestPage "Customer Card";
        VATExemptions: TestPage "VAT Exemptions";
        SalesNoSeriesNextNo: Code[10];
    begin
        // [SCENARIO 371988] VAT Exemptions being called by Action of Page - 21 Customer Card should contain correct values
        Initialize();

        // [GIVEN] Created VAT Exemption and opened page - Customer Card.
        SalesNoSeriesNextNo := SetNoSeriesForSales();
        CreateVATExemption(VATExemption, VATExemption.Type::Customer, LibrarySales.CreateCustomerNo());
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", VATExemption."No.");
        VATExemptions.Trap();

        // [WHEN] Using "VAT Exeption" action
        CustomerCard."VAT E&xemption".Invoke();

        // [THEN] VAT Exemption Starting Date, VAT Exemption Ending Date and VAT Exemption Interest Registry Number are filled on page - VAT Exemptions.
        // [THEN] Consecutive VAT Exempt. No. field is visible from the Customer Card page
        // TFS 341871
        VerifyVATExemptionDetail(VATExemptions, SalesNoSeriesNextNo, true);
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('NoSeriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageVATExemptionsVendorCard()
    var
        VATExemption: Record "VAT Exemption";
        VATExemptions: TestPage "VAT Exemptions";
        VendorCard: TestPage "Vendor Card";
        PurchasesNoSeriesNextNo: Code[10];
    begin
        // [SCENARIO 371988] VAT Exemptions being called by Action of Page - 26 Vendor Card should contain correct values
        Initialize();

        // [GIVEN] Created VAT Exemption and opened page - Vendor Card.
        PurchasesNoSeriesNextNo := SetNoSeriesForPurchase();
        CreateVATExemption(VATExemption, VATExemption.Type::Vendor, LibraryPurchase.CreateVendorNo());
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", VATExemption."No.");
        VATExemptions.Trap();

        // [WHEN] Using "VAT Exeption" action
        VendorCard."VAT E&xemption".Invoke();

        // [THEN] VAT Exemption Starting Date, VAT Exemption Ending Date and VAT Exemption Interest Registry Number are filled on page - VAT Exemptions.
        // [THEN] Consecutive VAT Exempt. No. field is not visible from the Vendor Card page
        // TFS 341871
        VerifyVATExemptionDetail(VATExemptions, PurchasesNoSeriesNextNo, false);
        VendorCard.Close();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
    end;

    local procedure CreateVATExemption(var VATExemption: Record "VAT Exemption"; Type: Option; No: Code[20])
    begin
        VATExemption.Type := Type;
        VATExemption."No." := No;
        VATExemption."VAT Exempt. Starting Date" := WorkDate();
        VATExemption."VAT Exempt. Ending Date" := WorkDate();
        VATExemption."VAT Exempt. Int. Registry No." := LibraryUTUtility.GetNewCode();
        VATExemption.Insert(true);
    end;

    local procedure SetNoSeriesForSales(): Code[10]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        SalesSetup.Get();
        SalesSetup."VAT Exemption Nos." := NoSeries.Code;
        SalesSetup.Modify();

        exit(NoSeriesCodeunit.PeekNextNo(NoSeries.Code));
    end;

    local procedure SetNoSeriesForPurchase(): Code[10]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        PurchasesSetup: Record "Purchases & Payables Setup";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        PurchasesSetup.Get();
        PurchasesSetup."VAT Exemption Nos." := NoSeries.Code;
        PurchasesSetup.Modify();

        exit(NoSeriesCodeunit.PeekNextNo(NoSeries.Code));
    end;

    local procedure VerifyVATExemptionDetail(VATExemptions: TestPage "VAT Exemptions"; VATExemptIntRegistryNo: Code[20]; VATProgressiveNoVisible: Boolean)
    begin
        VATExemptions."VAT Exempt. Int. Registry No.".AssistEdit();

        VATExemptions."VAT Exempt. Starting Date".AssertEquals(WorkDate());
        VATExemptions."VAT Exempt. Ending Date".AssertEquals(WorkDate());
        VATExemptions."VAT Exempt. Int. Registry No.".AssertEquals(VATExemptIntRegistryNo);
        Assert.AreEqual(
          VATProgressiveNoVisible, VATExemptions."Consecutive VAT Exempt. No.".Visible(), 'Consecutive VAT Exempt. No. visibility is incorrect');
        VATExemptions.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesPageHandler(var NoSeriesList: Page "No. Series"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;
}

