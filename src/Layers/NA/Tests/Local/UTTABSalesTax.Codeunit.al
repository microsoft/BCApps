codeunit 141019 "UT TAB Sales Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        TestFieldErr: Label 'TestField';
        LibraryRandom: Codeunit "Library - Random";
        ValueMustNotExistMsg: Label '%1 must not exist.';
        DialogErr: Label 'Dialog';
        ValueMustEqualMsg: Label 'Value must be equal.';
        LibraryTablesUT: Codeunit "Library - Tables UT";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteTaxArea()
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 318 Tax Area.

        // Setup: Create Tax Area and Tax Area Line.
        CreateTaxAreaLine(TaxAreaLine, CreateTaxArea(LibraryRandom.RandIntInRange(0, 1)));  // Country - Option Range 0 to 1.
        TaxArea.Get(TaxAreaLine."Tax Area");

        // Exercise.
        TaxArea.Delete(true);

        // Verify: Verify Tax Area and Tax Area Line is deleted.
        Assert.IsFalse(TaxArea.Get(TaxArea.Code), StrSubstNo(ValueMustNotExistMsg, TaxArea.TableCaption()));
        Assert.IsFalse(TaxAreaLine.Get(TaxAreaLine."Tax Area", TaxAreaLine."Tax Jurisdiction Code"), StrSubstNo(ValueMustNotExistMsg, TaxAreaLine.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CountryOnValidateTaxAreaError()
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        // Purpose of the test is to validate Country - OnValidate Trigger of Table ID - 318 Tax Area.

        // Setup: Create Tax Area and Tax Area Line.
        CreateTaxAreaLine(TaxAreaLine, CreateTaxArea(TaxArea."Country/Region"::CA));
        TaxArea.Get(TaxAreaLine."Tax Area");

        // Exercise.
        asserterror TaxArea.Validate("Country/Region");

        // Verify: Verify Error Code, Actual error - Country must be equal to 'US' in Tax Area - Code. Current value is 'CA'.
        Assert.ExpectedErrorCode(TestFieldErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TaxAreaCodeOnValidateLocation()
    var
        Location: Record Location;
    begin
        // Purpose of the test is to validate Tax Area Code - OnValidate Trigger of Table ID - 14 Location.

        // Setup: Create Tax Area and Location.
        CreateLocation(Location, CreateTaxArea(LibraryRandom.RandIntInRange(0, 1)));  // Country - Option Range 0 to 1.

        // Exercise.
        Location.Validate("Tax Area Code");

        // Verify: Verify Tax Area Code with blank value after validation of Location - Tax Area Code.
        Location.TestField("Tax Area Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TaxExemptionNoOnValidateLocation()
    var
        Location: Record Location;
    begin
        // Purpose of the test is to validate Tax Exemption No. - OnValidate Trigger of Table ID - 14 Location.

        // Setup: Create Tax Area and Location.
        CreateLocation(Location, CreateTaxArea(LibraryRandom.RandIntInRange(0, 1)));  // Country - Option Range 0 to 1.

        // Exercise.
        Location.Validate("Tax Exemption No.");

        // Verify: Verify Tax Exemption No with blank value after validation of Location - Tax Exemption Number.
        Location.TestField("Tax Exemption No.", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ProvincialTaxAreaCodeOnValidateLocation()
    var
        Location: Record Location;
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate Provincial Tax Area Code - OnValidate Trigger of Table ID - 14 Location.

        // Setup: Create Tax Area and Location.
        CreateLocation(Location, CreateTaxArea(TaxArea."Country/Region"::CA));

        // Exercise.
        Location.Validate("Provincial Tax Area Code");

        // Verify: Verify Provincial Tax Area Code with blank value after validation of Location - Provincial Tax Area Code.
        Location.TestField("Provincial Tax Area Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoNotUseForTaxCalculationOnValidateLocation()
    var
        Location: Record Location;
    begin
        // Purpose of the test is to validate Do Not Use For Tax Calculation - OnValidate Trigger of Table ID - 14 Location.

        // Setup: Create Tax Area and Location.
        CreateLocation(Location, CreateTaxArea(LibraryRandom.RandIntInRange(0, 1)));  // Country - Option Range 0 to 1.

        // Exercise.
        Location.Validate("Do Not Use For Tax Calculation");

        // Verify: Verify Tax Area Code, Tax Exemption No and Provincial Tax Area Code with blank value after validation of Location - Do Not Use For Tax Calculation.
        Location.TestField("Tax Area Code", '');
        Location.TestField("Tax Exemption No.", '');
        Location.TestField("Provincial Tax Area Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoOnValidateSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to validate No. - OnValidate Trigger of Table ID - 37 Sales Line.

        // Setup: Create Sales Order.
        CreateSalesOrder(SalesLine);

        // Exercise.
        SalesLine.Validate("No.");

        // Verify: Verify Tax Area Code with blank value and Tax Liable as False after validation of Sales Line - Number.
        SalesLine.TestField("Tax Area Code", '');
        SalesLine.TestField("Tax Liable", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertTaxDetailError()
    var
        TaxDetail: Record "Tax Detail";
        TaxDetail2: Record "Tax Detail";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 322 Tax Detail.

        // Setup: Create Tax Detail.
        CreateTaxDetail(TaxDetail, CreateTaxJurisdiction(), TaxDetail."Tax Type"::"Sales Tax Only");
        TaxDetail2."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";
        TaxDetail2."Tax Group Code" := TaxDetail."Tax Group Code";

        // Exercise.
        asserterror TaxDetail2.Insert(true);

        // Verify: Verify Error Code, Actual error - A tax detail already exists with the same tax jurisdiction, tax group, and tax type.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenameTaxDetailError()
    var
        TaxDetail: Record "Tax Detail";
        TaxDetail2: Record "Tax Detail";
    begin
        // Purpose of the test is to validate OnRename Trigger of Table ID - 322 Tax Detail.

        // Setup: Create two Tax Detail.
        CreateTaxDetail(TaxDetail, CreateTaxJurisdiction(), TaxDetail."Tax Type");  // Using Default Tax Type - Sales and Use Tax.
        CreateTaxDetail(TaxDetail2, TaxDetail."Tax Jurisdiction Code", TaxDetail2."Tax Type"::"Sales Tax Only");
        TaxDetail2."Tax Group Code" := TaxDetail."Tax Group Code";

        // Exercise.
        asserterror TaxDetail2.Rename(TaxDetail2."Tax Jurisdiction Code", TaxDetail2."Tax Group Code", TaxDetail2."Tax Type", TaxDetail2."Effective Date");

        // Verify: Verify Error Code, Actual error - A tax detail already exists with the same tax jurisdiction, tax group, and tax type.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AnyTaxDifferenceRecordsSalesTaxAmountDifference()
    var
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        // Purpose of the test is to validate AnyTaxDifferenceRecords function of Table ID - 10012 Sales Tax Amount Difference.

        // Setup: Create Sales Tax Amount Difference.
        CreateSalesTaxAmountDifference(SalesTaxAmountDifference);

        // Exercise & Verify: Execute function - AnyTaxDifferenceRecords and verify Sales Tax Amount Difference exist.
        Assert.IsTrue(SalesTaxAmountDifference.AnyTaxDifferenceRecords(SalesTaxAmountDifference."Document Product Area".AsInteger(), SalesTaxAmountDifference."Document Type", SalesTaxAmountDifference."Document No."), 'Sales Tax Amount Difference must exist.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TaxAmountOnValidateSalesTaxAmountLineError()
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
    begin
        // Purpose of the test is to validate OnValidate - TaxAmount Trigger of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);

        // Exercise.
        asserterror SalesTaxAmountLine.Validate("Tax Amount");

        // Verify: Verify Error Code, Actual error - Tax Amount must not be negative.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckTaxDifferenceSalesTaxAmountLineError()
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        Currency: Record Currency;
    begin
        // Purpose of the test is to validate CheckTaxDifference function of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line and Currency.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);
        CreateCurrency(Currency);

        // Exercise.
        asserterror SalesTaxAmountLine.CheckTaxDifference(Currency.Code, true, false); // Using New Allow Tax Difference as TRUE and New Prices Including Tax as False.

        // Verify: Verify Error Code, Actual error - Tax Difference of Sales Tax Amount Line must not exceed Max. Tax Difference Allowed of created Currency.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TaxAmountTextSalesTaxAmountLine()
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
    begin
        // Purpose of the test is to validate TaxAmountText function of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);

        // Exercise & Verify: Verify updated Tax Percentage after execution of function - TaxAmountText.
        Assert.AreEqual(StrSubstNo('%1% Tax', SalesTaxAmountLine."Tax %"), SalesTaxAmountLine.TaxAmountText(), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTotalLineAmountWithoutCurrencySalesTaxAmountLine()
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
    begin
        // Purpose of the test is to validate GetTotalLineAmount function of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);

        // Exercise & Verify: Verify updated Line Amount after execution of function - GetTotalLineAmount.
        Assert.AreEqual(SalesTaxAmountLine."Line Amount", SalesTaxAmountLine.GetTotalLineAmount(false, ''), ValueMustEqualMsg);  // Using Subtract Tax as False and Currency Code as blank.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTotalLineAmountWithCurrencySalesTaxAmountLine()
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        Currency: Record Currency;
        TotalLineAmount: Decimal;
    begin
        // Purpose of the test is to validate GetTotalLineAmount function of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line and Currency.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);
        CreateCurrency(Currency);
        TotalLineAmount := Round(SalesTaxAmountLine."Line Amount" / (1 + SalesTaxAmountLine."Tax %" / 100), Currency."Amount Rounding Precision"); // Calculation based on GetTotalLineAmount function of Table Sales Tax Amount Line.

        // Exercise & Verify: Verify updated Line Amount after execution of function - GetTotalLineAmount.
        Assert.AreEqual(TotalLineAmount, SalesTaxAmountLine.GetTotalLineAmount(true, Currency.Code), ValueMustEqualMsg);  // Using Subtract Tax as True.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTotalTaxBaseSalesTaxAmountLine()
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
    begin
        // Purpose of the test is to validate GetTotalTaxBase function of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);

        // Exercise & Verify: Verify updated Tax Base Amount after execution of function - GetTotalTaxBase.
        Assert.AreEqual(SalesTaxAmountLine."Tax Base Amount", SalesTaxAmountLine.GetTotalTaxBase(), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTotalAmountInclTaxSalesTaxAmountLine()
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
    begin
        // Purpose of the test is to validate GetTotalAmountInclTax function of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);

        // Exercise & Verify: Verify updated Amount Including Tax after execution of function - GetTotalAmountInclTax.
        Assert.AreEqual(SalesTaxAmountLine."Amount Including Tax", SalesTaxAmountLine.GetTotalAmountInclTax(), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetInvoiceDiscountPercentSalesTaxAmountLine()
    var
        Currency: Record Currency;
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        InvoiceDiscountAmount: Decimal;
    begin
        // Purpose of the test is to validate SetInvoiceDiscountPercent function of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line and Currency.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);
        CreateCurrency(Currency);
        InvoiceDiscountAmount := Round(SalesTaxAmountLine."Tax %" * SalesTaxAmountLine."Inv. Disc. Base Amount" / 100, Currency."Amount Rounding Precision"); // Calculation based on SetInvoiceDiscountPercent function of Table Sales Tax Amount Line.

        // Exercise: Execute function - SetInvoiceDiscountPercent.
        SalesTaxAmountLine.SetInvoiceDiscountPercent(SalesTaxAmountLine."Tax %", Currency.Code, false, false, 0);  // Using New Prices Including VAT, CalcInvDiscPerVATID as False and New VAT Base Discount Percentage as 0.

        // Verify: Verify updated Invoice Discount Base Amount after execution of function - SetInvoiceDiscountPercent.
        Assert.AreEqual(InvoiceDiscountAmount, SalesTaxAmountLine."Invoice Discount Amount", ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetInvoiceDiscountAmountSalesTaxAmountLine()
    var
        Currency: Record Currency;
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        InvoiceDiscountAmount: Decimal;
    begin
        // Purpose of the test is to validate SetInvoiceDiscountAmount function of Table ID - 10011 Sales Tax Amount Line.

        // Setup: Create Sales Tax Amount Line and Currency.
        CreateSalesTaxAmountLine(SalesTaxAmountLine);
        CreateCurrency(Currency);

        // Calculation based on SetInvoiceDiscountAmount function of Sales Tax Amount Line.
        InvoiceDiscountAmount := Round(SalesTaxAmountLine."Tax %" * SalesTaxAmountLine."Inv. Disc. Base Amount" / SalesTaxAmountLine."Inv. Disc. Base Amount", Currency."Amount Rounding Precision");

        // Exercise: Execute function - SetInvoiceDiscountAmount.
        SalesTaxAmountLine.SetInvoiceDiscountAmount(SalesTaxAmountLine."Tax %", Currency.Code, false, 0);  // New Prices Including VAT - False and New VAT Base Discount Percentage - 0.

        // Verify: Verify updated Invoice Discount Base Amount after execution of function - SetInvoiceDiscountPercent.
        Assert.AreEqual(InvoiceDiscountAmount, SalesTaxAmountLine."Invoice Discount Amount", ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesTaxAmountLinePrintDescriptionLength()
    var
        TaxArea: Record "Tax Area";
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
    begin
        // [FEATURE] [UT] [Tax Area]
        // [SCENARIO 218576] The length of the "Sales Tax Amount Line"."Print Description" field is equal to length of the "Tax Area".Description field

        LibraryTablesUT.CompareFieldTypeAndLength(
          TaxArea, TaxArea.FieldNo(Description), SalesTaxAmountLine, SalesTaxAmountLine.FieldNo("Print Description"));
    end;

    [Test]
    procedure TestCopyTaxDifferenceRecords()
    var
        SalesTaxAmountDifferencePos: Record "Sales Tax Amount Difference";
        SalesTaxAmountDifferenceNeg: Record "Sales Tax Amount Difference";
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
        FromDocumentNo: Code[20];
        ToDocumentNo: Code[20];
    begin
        // [FEATURE] [Tax Difference] [UT]
        // [SCENARIO 377669] Tab 10012 "Sales Tax Amount Difference".CopyTaxDifferenceRecords()

        // [GIVEN] Positive and nagative sales tax amount different lines for the document "A"
        FromDocumentNo := LibraryUtility.GenerateGUID();
        MockSalesTaxAmountDifference(SalesTaxAmountDifferencePos, FromDocumentNo, true);
        MockSalesTaxAmountDifference(SalesTaxAmountDifferenceNeg, FromDocumentNo, false);

        // [WHEN] Invoke SalesTaxAmountDifference.CopyTaxDifferenceRecords() using target document "B"
        ToDocumentNo := LibraryUtility.GenerateGUID();
        SalesTaxAmountDifference.CopyTaxDifferenceRecords(
            SalesTaxAmountDifferencePos."Document Product Area", SalesTaxAmountDifferencePos."Document Type", FromDocumentNo,
            SalesTaxAmountDifferencePos."Document Product Area", SalesTaxAmountDifferencePos."Document Type", ToDocumentNo);

        // [THEN] Two sales tax lines are copied into document "B"
        SalesTaxAmountDifference.SetRange("Document No.", ToDocumentNo);
        Assert.RecordCount(SalesTaxAmountDifference, 2);

        VerifySalesTaxAmountDifference(
            ToDocumentNo, true, SalesTaxAmountDifferencePos."Tax %", SalesTaxAmountDifferencePos."Tax Difference");
        VerifySalesTaxAmountDifference(
            ToDocumentNo, false, SalesTaxAmountDifferenceNeg."Tax %", SalesTaxAmountDifferenceNeg."Tax Difference");
    end;

    local procedure CreateCurrency(var Currency: Record Currency)
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
    end;

    local procedure CreateLocation(var Location: Record Location; TaxAreaCode: Code[20])
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location."Do Not Use For Tax Calculation" := true;
        Location."Tax Area Code" := TaxAreaCode;
        Location."Tax Exemption No." := LibraryUTUtility.GetNewCode();
        Location."Provincial Tax Area Code" := Location."Tax Area Code";
        Location.Insert();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header")
    var
        TaxArea: Record "Tax Area";
    begin
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Tax Area Code" := CreateTaxArea(TaxArea."Country/Region");
        SalesHeader."Bill-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesHeader.Insert();
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader);
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."No." := CreateStandardText();
        SalesLine."Tax Area Code" := SalesHeader."Tax Area Code";
        SalesLine."Tax Liable" := true;
        SalesLine.Insert();
    end;

    local procedure CreateStandardText(): Code[20]
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Code := LibraryUTUtility.GetNewCode();
        StandardText.Insert();
        exit(StandardText.Code);
    end;

    local procedure CreateSalesTaxAmountDifference(var SalesTaxAmountDifference: Record "Sales Tax Amount Difference")
    begin
        SalesTaxAmountDifference."Document No." := LibraryUTUtility.GetNewCode();
        SalesTaxAmountDifference.Insert();
    end;

    local procedure CreateSalesTaxAmountLine(var SalesTaxAmountLine: Record "Sales Tax Amount Line")
    var
        TaxArea: Record "Tax Area";
    begin
        SalesTaxAmountLine."Tax Area Code for Key" := CreateTaxArea(TaxArea."Country/Region");
        SalesTaxAmountLine."Tax Difference" := LibraryRandom.RandDec(10, 2);
        SalesTaxAmountLine."Tax %" := SalesTaxAmountLine."Tax Difference";
        SalesTaxAmountLine."Tax Base Amount" := LibraryRandom.RandDec(10, 2);
        SalesTaxAmountLine."Inv. Disc. Base Amount" := SalesTaxAmountLine."Tax Base Amount";
        SalesTaxAmountLine."Amount Including Tax" := SalesTaxAmountLine."Tax Base Amount";
        SalesTaxAmountLine."Tax Amount" := -SalesTaxAmountLine."Tax Base Amount";
        SalesTaxAmountLine.Insert();
    end;

    local procedure CreateTaxArea(Country: Option): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea."Country/Region" := Country;
        TaxArea.Insert();
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaLine(var TaxAreaLine: Record "Tax Area Line"; TaxArea: Code[20])
    begin
        TaxAreaLine."Tax Area" := TaxArea;
        TaxAreaLine."Tax Jurisdiction Code" := CreateTaxJurisdiction();
        TaxAreaLine.Insert();
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxType: Option)
    begin
        TaxDetail."Tax Jurisdiction Code" := TaxJurisdictionCode;
        TaxDetail."Tax Group Code" := LibraryUTUtility.GetNewCode10();
        TaxDetail."Tax Type" := TaxType;
        TaxDetail.Insert();
    end;

    local procedure CreateTaxJurisdiction(): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Code := LibraryUTUtility.GetNewCode10();
        TaxJurisdiction.Insert();
        exit(TaxJurisdiction.Code);
    end;

    local procedure MockSalesTaxAmountDifference(var SalesTaxAmountDifference: Record "Sales Tax Amount Difference"; DocumentNo: Code[20]; Positive: Boolean)
    begin
        SalesTaxAmountDifference.Init();
        SalesTaxAmountDifference."Document No." := DocumentNo;
        SalesTaxAmountDifference.Positive := Positive;
        SalesTaxAmountDifference."Tax %" := LibraryRandom.RandIntInRange(10, 100);
        if not Positive then
            SalesTaxAmountDifference."Tax %" *= -1;
        SalesTaxAmountDifference."Tax Difference" := LibraryRandom.RandIntInRange(10, 100);
        SalesTaxAmountDifference.Insert();
    end;

    local procedure VerifySalesTaxAmountDifference(DocumentNo: Code[20]; Positive: Boolean; ExpectedTaxPct: Decimal; ExpectedTaxDiff: Decimal)
    var
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        SalesTaxAmountDifference.SetRange("Document No.", DocumentNo);
        SalesTaxAmountDifference.SetRange(Positive, Positive);
        SalesTaxAmountDifference.FindFirst();
        SalesTaxAmountDifference.TestField("Tax %", ExpectedTaxPct);
        SalesTaxAmountDifference.TestField("Tax Difference", ExpectedTaxDiff);
    end;
}

