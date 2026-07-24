codeunit 134085 "ERM FR Feature Bugs"
{
    //
    //   1. Test to verify that Book Value is zero when the TAX Depreciation Book achieves the Depreciation End Date.
    //   2. Test to verify that Derogatory Amount is only visible in the TAX Depreciation Book.
    //   3. Test to verify that Derogatory Entries are considered only in the TAX Depreciation Book.
    //   4. Test to verify that after posting FA GL Journal there are entries with right FA Posting Date in FA Ledger Entries.
    //   5. Test to verify that Posted Sales Invoice is created successfully with Lot Tracking in Item Ledger Entry.
    //   6. Test to verify that Sales Invoice is printed with associated Shipment after posting Sales Invoice with GetShipmentLine.
    //   7. Test to verify that Sales Invoice is printed without associated Shipment after posting Sales Invoice with GetShipmentLine.
    //   8. Test to verify that relation between Sales Invoice and Sales Shipment is recorded in Shipment Invoiced Table after posting Sales Invoice with GetShipmentLine.
    //   9. Test to verify that relation between Sales Invoice Lines and Sales Shipment Lines is recorded in Shipment Invoiced Table.
    //  10. Test to verify that relation between Sales Invoice and Sales Shipment is recorded in Shipment Invoiced Table.
    //  11. Test to verify VAT Prod. Posting Group on Purchase Line When changed through Vat Rate Change Setup Page.
    //  12. Test to verify Dimension on Payment Slip flow form Vendor.
    //  13. Test to verify Dimension on Payment Slip flow form Customer.
    //
    //   Covers Test Cases for WI - 344026
    //   ----------------------------------------------------------------------------------
    //   Test Function Name                                                       TFS ID
    //   ----------------------------------------------------------------------------------
    //   BookValueAfterPostDepreciationAndDerogatoryFAJnl                         343466
    //   DerogatoryAmountAfterPostDepreciationAndDerogatoryFAJnl                  342860
    //   DerogatoryEntriesAfterPostDepreciationAndDerogatoryFAJnl                 342818
    //   PostingDatesAfterPostDepreciationAndDerogatoryFAJnl                      342877
    //   PostedSalesInvoiceWithDecimalLotTrackingAndProdBOM                       341056
    //   SalesInvoiceWithShipmentOnSalesInvoiceReport                             152143
    //   SalesInvoiceWithoutShipmentOnSalesInvoiceReport                          152602
    //   ShipmentInvoicedForPostedSalesInvoiceGetShipmentLine                     152142
    //   ShipmentInvoicedForMultiLinePostedSalesInvoice                           152141
    //   ShipmentInvoicedForSingleLinePostedSalesInvoice                          152140
    //
    //   Covers Test Cases for WI - 344431.
    //   ----------------------------------------------------------------------------------
    //   Test Function Name                                                       TFS ID
    //   ----------------------------------------------------------------------------------
    //   VATProdPostingGroupVATRateChangePurchaseLine                             300903
    //   DefaultDimensionCodeForVendorOnPaymentSlip                               291748
    //   DefaultDimensionCodeForCustomerOnPaymentSlip                             291748

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure BookValueAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // Test to verify that Book Value is zero when the TAX Depreciation Book achieves the Depreciation End Date.

        // Setup: Create a Fixed Asset with two FA Depreciation Books. Create and post Acquisition Cost for the Fixed Asset.
        Initialize();
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);  // Large random Integer value required.
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');  // Blank Derogatory Calculation.
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);

        // Exercise: Create and post FA GL Journal Type Depreciation and Derogatory.
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // Verify: Verify that Book Value is zero when the TAX Depreciation Book achieves the Depreciation End Date.
        FADepreciationBook.Get(FANo, TaxDepreciationBookCode);
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook.TestField("Book Value", 0);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DerogatoryAmountAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // Test to verify that Derogatory Amount is only visible in the TAX Depreciation Book.

        // Setup: Create a Fixed Asset with two FA Depreciation Books. Create and post Acquisition Cost for the Fixed Asset.
        Initialize();
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);  // Large random Integer value required.
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');  // Blank Derogatory Calculation.
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);  // Calculate Depreciation.

        // Exercise: Create and post FA GL Journal Type Depreciation and Derogatory.
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // Verify: Verify that Derogatory Amount is only visible in the TAX Depreciation Book.
        FADepreciationBook.Get(FANo, TaxDepreciationBookCode);
        FADepreciationBook.CalcFields("Derogatory Amount");
        FADepreciationBook.TestField("Derogatory Amount", -AcquisitionCostAmount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DerogatoryEntriesAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // Test to verify that Derogatory Entries are considered only in the TAX Depreciation Book.

        // Setup: Create a Fixed Asset with two FA Depreciation Books. Create and post Acquisition Cost for the Fixed Asset.
        Initialize();
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);  // Large random Integer value required.
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');  // Blank Derogatory Calculation.
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);  // Calculate Depreciation.

        // Exercise: Create and post FA GL Journal Type Depreciation and Derogatory.
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // Verify: Verify that Derogatory Entries are considered only in the TAX Depreciation Book.
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost", WorkDate(), 2 * AcquisitionCostAmount);
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::Derogatory, CalcDate('<1M>', WorkDate()), -AcquisitionCostAmount);
        VerifyFALedgerEntries(
          FANo, FALedgerEntry."FA Posting Type"::Depreciation, CalcDate('<1Y>', WorkDate()), -AcquisitionCostAmount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingDatesAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // Test to verify that after posting FA GL Journal there are entries with right FA Posting Date in FA Ledger Entries.

        // Setup: Create a Fixed Asset with two FA Depreciation Books. Create and post Acquisition Cost for the Fixed Asset.
        Initialize();
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);  // Large random Integer value required.
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');  // Blank Derogatory Calculation.
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);  // Calculate Depreciation.

        // Exercise: Create and post FA GL Journal Type Depreciation and Derogatory with Derogatory Amount Zero.
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, 0);

        // Verify: Verify that after posting FA GL Journal there are entries with right FA Posting Date in FA Ledger Entries.
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionCostAmount);
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::Derogatory, CalcDate('<1M>', WorkDate()), 0);
        VerifyFALedgerEntries(
          FANo, FALedgerEntry."FA Posting Type"::Depreciation, CalcDate('<1Y>', WorkDate()), -AcquisitionCostAmount);
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.DeleteAll();
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndSetupDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateDepreciationBookAndModifyDerogatoryCalculation(DerogatoryCalculation: Code[10]): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateAndSetupDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", false);
        DepreciationBook.Validate("Derogatory Calc.", DerogatoryCalculation);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBook(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Use random value for Depreciation Ending Date.
        FADepreciationBook.Validate(
          "Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAWithTaxFADepreciationBookAndGLIntegration(var TaxDepreciationBookCode: Code[10]; NormalDepreciationBookCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        UpdateIntegrationInBook(NormalDepreciationBookCode);
        TaxDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation(NormalDepreciationBookCode);
        CreateFixedAssetAndUpdateFAPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", NormalDepreciationBookCode, FixedAsset."FA Posting Group");
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBookCode, FixedAsset."FA Posting Group");
        exit(FixedAsset."No.");
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFixedAssetAndUpdateFAPostingGroup(var FixedAsset: Record "Fixed Asset")
    begin
        CreateFixedAsset(FixedAsset);
        UpdateFAPostingGroup(FixedAsset."FA Posting Group");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingDate: Date; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"Fixed Asset", FANo, Amount);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("FA Posting Date", FAPostingDate);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreatePostDepreciationAndDerogatoryFAJournal(FANo: Code[20]; DepreciationBookCode: Code[10]; DepreciationAmount: Decimal; DerogatoryAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(
          GenJournalLine, CalcDate('<1Y>', WorkDate()), GenJournalLine."FA Posting Type"::Depreciation, FANo,
          DepreciationBookCode, -DepreciationAmount);
        CreateAndPostGenJournalLine(
          GenJournalLine, CalcDate('<1M>', WorkDate()), GenJournalLine."FA Posting Type"::Derogatory, FANo,
          DepreciationBookCode, -DerogatoryAmount);
    end;

    local procedure RunCalculateDepreciationReport(DepreciationBookCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        REPORT.Run(REPORT::"Calculate Depreciation");
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FAJournalSetup2.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateFAPostingGroup(FAPostingGroupCode: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
        RecordRef: RecordRef;
    begin
        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>''''');
        RecordRef.GetTable(FAPostingGroup2);
        LibraryUtility.FindRecord(RecordRef);
        RecordRef.SetTable(FAPostingGroup2);
        FAPostingGroup.TransferFields(FAPostingGroup2, false);
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateIntegrationInBook(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("Integration G/L - Derogatory", true);
        DepreciationBook.Modify(true);
    end;

    local procedure VerifyFALedgerEntries(FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; FAPostingDate: Date; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindSet();
        repeat
            FALedgerEntry.TestField("FA Posting Date", FAPostingDate);
            FALedgerEntry.TestField(Amount, Amount);
        until FALedgerEntry.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationRequestPageHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    var
        DepreciationBookCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationBookCode);
        CalculateDepreciation.DepreciationBook.SetValue(DepreciationBookCode);
        CalculateDepreciation.FAPostingDate.SetValue(WorkDate());
        CalculateDepreciation.PostingDate.SetValue(WorkDate());
        CalculateDepreciation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        SellToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        GetShipmentLines.FILTER.SetFilter("Sell-to Customer No.", SellToCustomerNo);
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(TrackingQuantity);
        ItemTrackingLines."Lot No.".SetValue(TrackingQuantity);
        ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity);
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
