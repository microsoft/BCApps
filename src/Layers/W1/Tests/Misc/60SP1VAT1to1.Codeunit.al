codeunit 132517 "6.0SP1 - VAT 1 to 1"
{
    Permissions = TableData "Service Header" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Entry - VAT Entry Link]
        isInitialized := false;
    end;

    var
        GenPostingSetup1: Record "General Posting Setup";
        GenPostingSetup2: Record "General Posting Setup";
        Currency: Record Currency;
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryDim: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        LinePrice1: Decimal;
        LinePrice2: Decimal;
        LineCost1: Decimal;
        LineCost2: Decimal;
        Quantity1: Decimal;
        Quantity2: Decimal;
        VATPct1: Decimal;
        VATPct2: Decimal;
        LineAmt1: Decimal;
        LineAmt2: Decimal;
        InvDisc: Decimal;
        LineDisc: Decimal;
        GLEntryDimError: Label 'Wrong Dim on GL entry %1! Expected ID: %2, Actual ID: %3';
        GLEntryACYError: Label 'ACY amount is not correct on G/L Entry %1: Actual: %2, Expected: %3!';
        VATEntryACYError: Label 'Wrong ACY amount on VAT Entry%1! Expected: %2, Actual: %3';
        VATLinkError: Label 'Wrong VAT link on VAT Entry %1.';
        GenBusPostingGrp: Code[20];
        VATPostingGrp: Code[20];
        CustPostingGrp: Code[20];
        VendPostingGrp: Code[20];
        SalesLineDiscAcc1: Code[20];
        SalesLineDiscAcc2: Code[20];
        SalesInvDiscAcc1: Code[20];
        SalesInvDiscAcc2: Code[20];
        SalesAcc1: Code[20];
        SalesAcc2: Code[20];
        SalesVATAcc: Code[20];
        ReceivableAcc: Code[20];
        PurchLineDiscAcc1: Code[20];
        PurchLineDiscAcc2: Code[20];
        PurchInvDiscAcc1: Code[20];
        PurchInvDiscAcc2: Code[20];
        PurchAcc1: Code[20];
        PurchAcc2: Code[20];
        PurchVATAcc: Code[20];
        PayableAcc: Code[20];
        CustPmtDiscCreditAcc: Code[20];
        CustPmtDiscDebitAcc: Code[20];
        VendPmtDiscCreditAcc: Code[20];
        VendPmtDiscDebitAcc: Code[20];
        TotalEntryNumberError: Label 'Wrong number of %1.Expected:%2, Actual:%3.';
        GLEntryError: Label 'GL Entry not find! Expecting: Account:%1, Amountl: %2.';
        VATEntryError: Label 'VAT Entry not find! Expecting: Base:%1, VATAmount:%2.';
        Item1: Code[20];
        Item2: Code[20];
        Item3: Code[20];
        ACYAcc: Code[20];
        RecordNotFoundError: Label '%1 not found.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"6.0SP1 - VAT 1 to 1");

        // Lazy Setup.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"6.0SP1 - VAT 1 to 1");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGenProdPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        // Prepare specific country setup for Reverse Charge VAT Calculation type
        SetupReverseChargeVAT();

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"6.0SP1 - VAT 1 to 1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58502_Sales()
    begin
        // TFS DynamicsNAV60 Test Case ID 58502 : line discount-Post to same sales GL account
        Initialize();
        GeneralSetup(true);
        DataSetup_Sales('Invoice', true, 15, 0, Item1, Item2);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58502_Validate(LineAmt1, VATPct1, LineAmt2, VATPct2, LineDisc / 100, SalesLineDiscAcc1, SalesAcc1, SalesVATAcc, ReceivableAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58502_Purch()
    begin
        // TFS DynamicsNAV60 Test Case ID 58502 : line discount-Post to same sales GL account
        Initialize();
        GeneralSetup(true);
        DataSetup_Purch('Invoice', true, 15, 0, Item1, Item2);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58502_Validate(-LineAmt1, VATPct1, -LineAmt2, VATPct2, LineDisc / 100, PurchLineDiscAcc1, PurchAcc1, PurchVATAcc, PayableAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58502_Service()
    begin
        // [FEATURE] [Service] [Line Discount]
        // [SCENARIO PS58502] Line discount-Post to same sales GL account

        // [GIVEN] Two Items with the same Gen. Prod. Posting group
        // [GIVEN] Service Invoice, "Price Incl. VAT"="Yes", with 2 Item lines, where "Line Discount"=15%
        // [WHEN] Post the Service Invoice
        // [THEN] G/L Entry (COUNT=5,"G/L Account No.",Amount); VAT Entry (COUNT=2,Base,Amount);
        // [THEN] "G/L Entry - VAT Entry Link": amounts are equal in linked entries

        Initialize();
        GeneralSetup(true);
        DataSetup_Service('Invoice', true, 15, 0, Item1, Item2);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58502_Validate(LineAmt1, VATPct1, LineAmt2, VATPct2, LineDisc / 100, SalesLineDiscAcc1, SalesAcc1, SalesVATAcc, ReceivableAcc);
    end;

    local procedure S_58502_Validate(LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; LineDiscount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20]; Account4: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        TotalLineAmtExclVAT1: Decimal;
        TotalLineAmtExclVAT2: Decimal;
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalLineDisc1: Decimal;
        TotalLineDisc2: Decimal;
        TotalLineDiscVAT1: Decimal;
        TotalLineDiscVAT2: Decimal;
    begin
        TotalLineAmtExclVAT1 := LineAmt1 / (1 + VATPct1);
        TotalLineAmtExclVAT2 := LineAmt2 / (1 + VATPct2);
        TotalLineVAT1 := TotalLineAmtExclVAT1 * VATPercent1;
        TotalLineVAT2 := TotalLineAmtExclVAT2 * VATPercent2;
        TotalLineDisc1 := TotalLineAmtExclVAT1 * LineDiscount;
        TotalLineDisc2 := TotalLineAmtExclVAT2 * LineDiscount;
        TotalLineDiscVAT1 := TotalLineDisc1 * VATPercent1;
        TotalLineDiscVAT2 := TotalLineDisc2 * VATPercent2;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 5, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 5, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, TotalLineDisc1 + TotalLineDisc2);
        ValidateGLEntry(GLRegister, Account3, TotalLineDiscVAT1 + TotalLineDiscVAT2);
        ValidateGLEntry(GLRegister, Account2, -TotalLineAmtExclVAT1 - TotalLineAmtExclVAT2);
        ValidateGLEntry(GLRegister, Account3, -TotalLineVAT1 - TotalLineVAT2);
        ValidateGLEntry(GLRegister, Account4, (LineAmt1 + LineAmt2) * (1 - LineDiscount));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 2, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 2, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, TotalLineDisc1 + TotalLineDisc2, TotalLineDiscVAT1 + TotalLineDiscVAT2, 0);
        ValidateVATEntry(GLRegister, -TotalLineAmtExclVAT1 - TotalLineAmtExclVAT2, -TotalLineVAT1 - TotalLineVAT2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58503_Sales()
    begin
        // TFS DynamicsNAV60 Test Case ID 58503 :  line discount-Post to different sales GL account
        Initialize();
        GeneralSetup(true);
        DataSetup_Sales('Credit Memo', false, 15, 0, Item1, Item3);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58503_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          SalesLineDiscAcc2,
          SalesLineDiscAcc1,
          SalesVATAcc,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58503_Purch()
    begin
        // TFS DynamicsNAV60 Test Case ID 58503 :  line discount-Post to different sales GL account
        Initialize();
        GeneralSetup(true);
        DataSetup_Purch('Credit Memo', false, 15, 0, Item1, Item3);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58503_Validate(-LineAmt1,
          VATPct1,
          -LineAmt2,
          VATPct2,
          LineDisc / 100,
          PurchLineDiscAcc2,
          PurchLineDiscAcc1,
          PurchVATAcc,
          PurchAcc2,
          PurchAcc1,
          PayableAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58503_Service()
    begin
        // [FEATURE] [Service] [Line Discount]
        // [SCENARIO PS58503] Line discount-Post to different sales GL account

        // [GIVEN] Two Items with the different Gen. Prod. Posting group
        // [GIVEN] Service Credit Memo, "Price Incl. VAT"="No", with 2 Item lines, where "Line Discount"=15%
        // [WHEN] Post the Service Credit Memo
        // [THEN] G/L Entry (COUNT=9,"G/L Account No.",Amount); VAT Entry (COUNT=4,Base,Amount);
        // [THEN] "G/L Entry - VAT Entry Link": amounts are equal in linked entries
        Initialize();
        GeneralSetup(true);
        DataSetup_Service('Credit Memo', false, 15, 0, Item1, Item3);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58503_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          SalesLineDiscAcc2,
          SalesLineDiscAcc1,
          SalesVATAcc,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc);
    end;

    local procedure S_58503_Validate(LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; LineDiscount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20]; Account4: Text[20]; Account5: Text[20]; Account6: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalLineDisc1: Decimal;
        TotalLineDisc2: Decimal;
        TotalLineDiscVAT1: Decimal;
        TotalLineDiscVAT2: Decimal;
    begin
        TotalLineVAT1 := LineAmt1 * VATPercent1;
        TotalLineVAT2 := LineAmt2 * VATPercent2;
        TotalLineDisc1 := LineAmt1 * LineDiscount;
        TotalLineDisc2 := LineAmt2 * LineDiscount;
        TotalLineDiscVAT1 := TotalLineDisc1 * VATPercent1;
        TotalLineDiscVAT2 := TotalLineDisc2 * VATPercent2;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 9, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 9, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, -TotalLineDisc2);
        ValidateGLEntry(GLRegister, Account3, -TotalLineDiscVAT2);
        ValidateGLEntry(GLRegister, Account2, -TotalLineDisc1);
        ValidateGLEntry(GLRegister, Account3, -TotalLineDiscVAT1);
        ValidateGLEntry(GLRegister, Account4, LineAmt2);
        ValidateGLEntry(GLRegister, Account3, TotalLineVAT2);
        ValidateGLEntry(GLRegister, Account5, LineAmt1);
        ValidateGLEntry(GLRegister, Account3, TotalLineVAT1);
        ValidateGLEntry(GLRegister, Account6,
          -LineAmt1 * (1 - LineDiscount) * (1 + VATPercent1) - LineAmt2 * (1 - LineDiscount) * (1 + VATPercent2));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 4, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 4, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, -TotalLineDisc2, -TotalLineDiscVAT2, 0);
        ValidateVATEntry(GLRegister, -TotalLineDisc1, -TotalLineDiscVAT1, 0);
        ValidateVATEntry(GLRegister, LineAmt2, TotalLineVAT2, 0);
        ValidateVATEntry(GLRegister, LineAmt1, TotalLineVAT1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58504_Sales()
    begin
        // TFS DynamicsNAV60 Test Case ID 58504 :  invoice discount-Post to same sales GL account
        Initialize();
        GeneralSetup(true);
        DataSetup_Sales('Invoice', true, 0, 15, Item1, Item2);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58504_Validate(LineAmt1, VATPct1, LineAmt2, VATPct2, InvDisc / 100, SalesInvDiscAcc1, SalesVATAcc, SalesAcc1, ReceivableAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58504_Purch()
    begin
        // TFS DynamicsNAV60 Test Case ID 58504 :  invoice discount-Post to same sales GL account
        Initialize();
        GeneralSetup(true);
        DataSetup_Purch('Invoice', true, 0, 15, Item1, Item2);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58504_Validate(-LineAmt1, VATPct1, -LineAmt2, VATPct2, InvDisc / 100, PurchInvDiscAcc1, PurchVATAcc, PurchAcc1, PayableAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58504_Service()
    begin
        // [FEATURE] [Service] [Invoice Discount]
        // [SCENARIO PS58504] invoice discount-Post to same sales GL account

        // [GIVEN] Two Items with the same Gen. Prod. Posting group
        // [GIVEN] Service Invoice, "Price Incl. VAT"="Yes", with 2 Item lines, where "Invoice Discount"=15%
        // [WHEN] Post the Service Invoice
        // [THEN] G/L Entry (COUNT=5,"G/L Account No.",Amount); VAT Entry (COUNT=2,Base,Amount);
        // [THEN] "G/L Entry - VAT Entry Link": amounts are equal in linked entries
        Initialize();
        GeneralSetup(true);
        DataSetup_Service('Invoice', true, 0, 15, Item1, Item2);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58504_Validate(LineAmt1, VATPct1, LineAmt2, VATPct2, InvDisc / 100, SalesInvDiscAcc1, SalesVATAcc, SalesAcc1, ReceivableAcc);
    end;

    local procedure S_58504_Validate(LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; InvDiscount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20]; Account4: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        TotalLineAmtExclVAT1: Decimal;
        TotalLineAmtExclVAT2: Decimal;
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalInvDiscount: Decimal;
        TotalInvDiscountVAT: Decimal;
    begin
        TotalLineAmtExclVAT1 := LineAmt1 / (1 + VATPercent1);
        TotalLineAmtExclVAT2 := LineAmt2 / (1 + VATPercent2);
        TotalLineVAT1 := TotalLineAmtExclVAT1 * VATPercent1;
        TotalLineVAT2 := TotalLineAmtExclVAT2 * VATPercent2;
        TotalInvDiscount := (TotalLineAmtExclVAT1 + TotalLineAmtExclVAT2) * InvDiscount;
        TotalInvDiscountVAT := TotalLineAmtExclVAT1 * InvDiscount * VATPercent1 + TotalLineAmtExclVAT2 * InvDiscount * VATPercent2;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 5, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 5, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, TotalInvDiscount);
        ValidateGLEntry(GLRegister, Account2, TotalInvDiscountVAT);
        ValidateGLEntry(GLRegister, Account3, -TotalLineAmtExclVAT1 - TotalLineAmtExclVAT2);
        ValidateGLEntry(GLRegister, Account2, -TotalLineVAT1 - TotalLineVAT2);
        ValidateGLEntry(GLRegister, Account4, (LineAmt1 + LineAmt2) * (1 - InvDiscount));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 2, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 2, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, TotalInvDiscount, TotalInvDiscountVAT, 0);
        ValidateVATEntry(GLRegister, -TotalLineAmtExclVAT1 - TotalLineAmtExclVAT2, -TotalLineVAT1 - TotalLineVAT2, 0);
    end;

    [Test]
    [HandlerFunctions('S_58505_Catch_Report')]
    [Scope('OnPrem')]
    procedure S_58505_Sales()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        DiffSalesInvAcc: Code[20];
        LineDim: Code[20];
        LineDimValue: Code[20];
        DefaultDim: Code[20];
        DefaultDimValue: Code[20];
        LineDimSetID1: Integer;
        LineDimSetID2: Integer;
    begin
        // TFS DynamicsNAV60 Test Case ID 58505 : invoice discount + line discount - different GL account - different sales GL account
        Initialize();
        GeneralSetup(true);
        // Create Addtional reporting currency
        S_58505_Create_ACY(Currency);
        S_58505_Set_ACY(Currency.Code);

        LibraryERM.CreateGLAccount(GLAccount);
        DiffSalesInvAcc := GLAccount."No.";

        // Set Sales Inv. Disc. Account
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", DiffSalesInvAcc);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", DiffSalesInvAcc);
        GenPostingSetup2.Modify(true);

        InvDisc := 15;
        LineDisc := 15;

        CreateCustomer(Customer, GenBusPostingGrp, CustPostingGrp, InvDisc);

        S_58505_DimSetup(LineDim, LineDimValue, DefaultDim, DefaultDimValue);

        // Insert default dimension on customer
        S_58505_Insert_Default_Dim(18, Customer."No.", DefaultDim, DefaultDimValue);

        // Create a sales CM
        CreateSalesHeader(SalesHeader, Customer, SalesHeader."Document Type"::"Credit Memo", false);
        DocLineDataSetup('Sales', false);

        CreateSalesLine(SalesHeader, SalesLine1, SalesLine1.Type::Item, Item1, Quantity1, LinePrice1, LineDisc);
        VATPct1 := SalesLine1."VAT %" / 100; // Get VAT% on the line
        LineDimSetID1 := SalesLine1."Dimension Set ID"; // Get Line Dimension set ID on line 1

        CreateSalesLine(SalesHeader, SalesLine2, SalesLine2.Type::Item, Item3, Quantity2, LinePrice2, LineDisc);
        VATPct2 := SalesLine2."VAT %" / 100; // Get VAT% on the line
        LineDimSetID2 := SalesLine2."Dimension Set ID"; // Get Line Dimension set ID on line 2
        // Insert new line dimension on the second line
        LineDimSetID2 := S_58505_Insert_Line_Dim(LineDimSetID2, LineDim, LineDimValue);
        // Link to new dimension set ID
        SalesLine2.Validate("Dimension Set ID", LineDimSetID2);
        SalesLine2.Modify(true);

        // Post
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58505_Validate('Sales',
          LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          DiffSalesInvAcc,
          SalesVATAcc,
          SalesLineDiscAcc1,
          SalesLineDiscAcc2,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc,
          LineDimSetID1,
          LineDimSetID2);

        // tear down
        S_58505_Set_ACY('');

        // Cleanup: delete Currency ACY
        S_58505_Delete_ACY(Currency.Code);
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [HandlerFunctions('S_58505_Catch_Report')]
    [Scope('OnPrem')]
    procedure S_58505_Purch()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        DiffPurchInvAcc: Code[20];
        LineDim: Code[20];
        LineDimValue: Code[20];
        DefaultDim: Code[20];
        DefaultDimValue: Code[20];
        LineDimSetID1: Integer;
        LineDimSetID2: Integer;
    begin
        // TFS DynamicsNAV60 Test Case ID 58505 : invoice discount + line discount - different GL account - different sales GL account
        Initialize();
        GeneralSetup(true);
        // Create Addtional reporting currency
        S_58505_Create_ACY(Currency);
        S_58505_Set_ACY(Currency.Code);

        LibraryERM.CreateGLAccount(GLAccount);
        DiffPurchInvAcc := GLAccount."No.";

        // Set Purch. Inv. Disc. Account
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", DiffPurchInvAcc);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", DiffPurchInvAcc);
        GenPostingSetup2.Modify(true);

        InvDisc := 15;
        LineDisc := 15;

        CreateVendor(Vendor, GenBusPostingGrp, VendPostingGrp, InvDisc);

        S_58505_DimSetup(LineDim, LineDimValue, DefaultDim, DefaultDimValue);

        // Insert default demension on vendor
        S_58505_Insert_Default_Dim(23, Vendor."No.", DefaultDim, DefaultDimValue);

        // Create a purchase CM
        CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::"Credit Memo", false);
        DocLineDataSetup('Purchase', false);

        CreatePurchLine(PurchHeader, PurchLine1, PurchLine1.Type::Item, Item1, Quantity1, LineCost1, LineDisc);
        VATPct1 := PurchLine1."VAT %" / 100; // Get VAT% on the line
        LineDimSetID1 := PurchLine1."Dimension Set ID"; // Get Line Dimension set ID on line 1

        CreatePurchLine(PurchHeader, PurchLine2, PurchLine2.Type::Item, Item3, Quantity2, LineCost2, LineDisc);
        VATPct2 := PurchLine2."VAT %" / 100; // Get VAT% on the line
        LineDimSetID2 := PurchLine2."Dimension Set ID"; // Get Line Dimension set ID on line 2
        // Insert new line dimension on the second line
        LineDimSetID2 := S_58505_Insert_Line_Dim(LineDimSetID2, LineDim, LineDimValue);
        // Link to new dimension set ID
        PurchLine2.Validate("Dimension Set ID", LineDimSetID2);
        PurchLine2.Modify(true);

        // Post
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58505_Validate('Purch',
          -LineAmt1,
          VATPct1,
          -LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          DiffPurchInvAcc,
          PurchVATAcc,
          PurchLineDiscAcc1,
          PurchLineDiscAcc2,
          PurchAcc2,
          PurchAcc1,
          PayableAcc,
          LineDimSetID1,
          LineDimSetID2);

        // tear down
        S_58505_Set_ACY('');

        // Cleanup: delete Currency ACY
        S_58505_Delete_ACY(Currency.Code);
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [HandlerFunctions('S_58505_Catch_Report')]
    [Scope('OnPrem')]
    procedure S_58505_Service()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine1: Record "Service Line";
        ServiceLine2: Record "Service Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        DiffSalesInvAcc: Code[20];
        LineDim: Code[20];
        LineDimValue: Code[20];
        DefaultDim: Code[20];
        DefaultDimValue: Code[20];
        LineDimSetID1: Integer;
        LineDimSetID2: Integer;
    begin
        // [FEATURE] [Service] [Invoice Discount] [Line Discount] [ACY] [Dimensions]
        // [SCENARIO PS58505] Invoice Discount + Line Discount - different GL account - different sales GL account

        // [GIVEN] Two Items with the same Gen. Prod. Posting group
        // [GIVEN] Service Credit Memo, "Price Incl. VAT"="No", with 2 Item lines,
        // [GIVEN] Service Lines have "Invoice Discount"=15%, "Line Discount"=15%, different Dim Set Ids
        // [WHEN] Post the Service Credit Memo
        // [THEN] G/L Entry (COUNT=13,"G/L Account No.",Amount,"Additional-Currency Amount","Dimension Set ID");
        // [THEN] VAT Entry (COUNT=6,Base,Amount,"Additional-Currency Base","Additional-Currency Amount");
        // [THEN] "G/L Entry - VAT Entry Link": amounts are equal in linked entries
        Initialize();
        GeneralSetup(true);
        // Create Addtional reporting currency
        S_58505_Create_ACY(Currency);
        S_58505_Set_ACY(Currency.Code);

        LibraryERM.CreateGLAccount(GLAccount);
        DiffSalesInvAcc := GLAccount."No.";

        GenPostingSetup1.Validate("Sales Inv. Disc. Account", DiffSalesInvAcc);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", DiffSalesInvAcc);
        GenPostingSetup2.Modify(true);

        InvDisc := 15;
        LineDisc := 15;

        CreateCustomer(Customer, GenBusPostingGrp, CustPostingGrp, InvDisc);

        S_58505_DimSetup(LineDim, LineDimValue, DefaultDim, DefaultDimValue);

        S_58505_Insert_Default_Dim(18, Customer."No.", DefaultDim, DefaultDimValue);

        // Create a service Credit Memo
        CreateServiceHeader(ServiceHeader, Customer, ServiceHeader."Document Type"::"Credit Memo", false);
        DocLineDataSetup('Service', false);

        CreateServiceLine(ServiceHeader, ServiceLine1, ServiceLine1.Type::Item, Item1, Quantity1, LinePrice1, LineDisc);
        VATPct1 := ServiceLine1."VAT %" / 100; // Get VAT% on the line
        LineDimSetID1 := ServiceLine1."Dimension Set ID"; // Get Line Dimension set ID on line 1

        CreateServiceLine(ServiceHeader, ServiceLine2, ServiceLine2.Type::Item, Item3, Quantity2, LinePrice2, LineDisc);
        VATPct2 := ServiceLine2."VAT %" / 100; // Get VAT% on the line
        LineDimSetID2 := ServiceLine2."Dimension Set ID"; // Get Line Dimension set ID on line 2
        // Insert new line dimension on the second line
        LineDimSetID2 := S_58505_Insert_Line_Dim(LineDimSetID2, LineDim, LineDimValue);
        // Link to new dimension set ID
        ServiceLine2.Validate("Dimension Set ID", LineDimSetID2);
        ServiceLine2.Modify(true);

        // Post
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58505_Validate('Service',
          LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          DiffSalesInvAcc,
          SalesVATAcc,
          SalesLineDiscAcc1,
          SalesLineDiscAcc2,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc,
          LineDimSetID1,
          LineDimSetID2);

        // tear down
        S_58505_Set_ACY('');

        // Cleanup: delete Currency ACY
        S_58505_Delete_ACY(Currency.Code);
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    local procedure S_58505_Validate(DocType: Text[30]; LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; LineDiscount: Decimal; InvDiscount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20]; Account4: Text[20]; Account5: Text[20]; Account6: Text[20]; Account7: Text[20]; DimSetID1: Integer; DimSetID2: Integer)
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalLineDisc1: Decimal;
        TotalLineDisc2: Decimal;
        TotalLineDiscVAT1: Decimal;
        TotalLineDiscVAT2: Decimal;
        TotalInvDiscount1: Decimal;
        TotalInvDiscount2: Decimal;
        TotalInvDiscountVAT1: Decimal;
        TotalInvDiscountVAT2: Decimal;
    begin
        TotalLineVAT1 := LineAmt1 * VATPercent1;
        TotalLineVAT2 := LineAmt2 * VATPercent2;
        TotalLineDisc1 := LineAmt1 * LineDiscount;
        TotalLineDisc2 := LineAmt2 * LineDiscount;
        TotalLineDiscVAT1 := TotalLineDisc1 * VATPercent1;
        TotalLineDiscVAT2 := TotalLineDisc2 * VATPercent2;
        TotalInvDiscount1 := LineAmt1 * (1 - LineDiscount) * InvDiscount;
        TotalInvDiscount2 := LineAmt2 * (1 - LineDiscount) * InvDiscount;
        TotalInvDiscountVAT1 := TotalInvDiscount1 * VATPercent1;
        TotalInvDiscountVAT2 := TotalInvDiscount2 * VATPercent2;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 13, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 13, GLEntry.Count));
        // Validate account and amount on GL entries
        S_58505_Validate_GL_Entry(GLRegister, Account1, -TotalInvDiscount2, DimSetID2);
        S_58505_Validate_GL_Entry(GLRegister, Account2, -TotalInvDiscountVAT2, DimSetID2);
        S_58505_Validate_GL_Entry(GLRegister, Account1, -TotalInvDiscount1, DimSetID1);
        S_58505_Validate_GL_Entry(GLRegister, Account2, Round(-TotalInvDiscountVAT1, 1 / 100, '='), DimSetID1);
        S_58505_Validate_GL_Entry(GLRegister, Account4, -TotalLineDisc2, DimSetID2);
        S_58505_Validate_GL_Entry(GLRegister, Account2, -TotalLineDiscVAT2, DimSetID2);
        S_58505_Validate_GL_Entry(GLRegister, Account3, -TotalLineDisc1, DimSetID1);
        S_58505_Validate_GL_Entry(GLRegister, Account2, -TotalLineDiscVAT1, DimSetID1);
        S_58505_Validate_GL_Entry(GLRegister, Account5, LineAmt2, DimSetID2);
        S_58505_Validate_GL_Entry(GLRegister, Account2, TotalLineVAT2, DimSetID2);
        S_58505_Validate_GL_Entry(GLRegister, Account6, LineAmt1, DimSetID1);
        if (DocType = 'Sales') or (DocType = 'Service') then
            S_58505_Validate_GL_Entry(GLRegister, Account2, TotalLineVAT1 + 1 / 100, DimSetID1); // 0,01 VAT rounding
        if DocType = 'Purch' then
            S_58505_Validate_GL_Entry(GLRegister, Account2, TotalLineVAT1 - 1 / 100, DimSetID1); // 0,01 VAT rounding
        S_58505_Validate_GL_Entry(GLRegister, Account7,
          Round(-LineAmt1 * (1 - LineDiscount) * (1 - InvDiscount) * (1 + VATPercent1) -
            LineAmt2 * (1 - LineDiscount) * (1 - InvDiscount) * (1 + VATPercent2), 1 / 100, '='), DimSetID1);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 6, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 6, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        S_58505_Validate_VAT_Entry(GLRegister, -TotalInvDiscount2, -TotalInvDiscountVAT2);
        S_58505_Validate_VAT_Entry(GLRegister, -TotalInvDiscount1, Round(-TotalInvDiscountVAT1, 1 / 100, '='));
        S_58505_Validate_VAT_Entry(GLRegister, -TotalLineDisc2, -TotalLineDiscVAT2);
        S_58505_Validate_VAT_Entry(GLRegister, -TotalLineDisc1, -TotalLineDiscVAT1);
        S_58505_Validate_VAT_Entry(GLRegister, LineAmt2, TotalLineVAT2);
        if (DocType = 'Sales') or (DocType = 'Service') then
            S_58505_Validate_VAT_Entry(GLRegister, LineAmt1, TotalLineVAT1 + 1 / 100); // 0,01 VAT rounding
        if DocType = 'Purch' then
            S_58505_Validate_VAT_Entry(GLRegister, LineAmt1, TotalLineVAT1 - 1 / 100); // 0,01 VAT rounding
    end;

    local procedure S_58505_Create_ACY(var Currency: Record Currency)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        DateForm: DateFormula;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);

        CurrencyExchangeRate.Init();
        CurrencyExchangeRate.Validate("Currency Code", Currency.Code);
        Evaluate(DateForm, '<-12Y>');
        CurrencyExchangeRate.Validate("Starting Date", CalcDate(DateForm, WorkDate()));
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 20);
        CurrencyExchangeRate.Insert(true);

        // Create GL account for Adjust Addtional report currency
        LibraryERM.CreateGLAccount(GLAccount);
        ACYAcc := GLAccount."No.";
    end;

    local procedure S_58505_Delete_ACY(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.Delete(true);
    end;

    local procedure S_58505_DimSetup(var LineDim: Code[20]; var LineDimValue: Code[20]; var DefaultDim: Code[20]; var DefaultDimValue: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        FindDefaultDim(Dimension, DimensionValue);
        DefaultDim := Dimension.Code;
        DefaultDimValue := DimensionValue.Code;

        FindLineDim(Dimension, DimensionValue, DefaultDim);
        LineDim := Dimension.Code;
        LineDimValue := DimensionValue.Code;
    end;

    local procedure S_58505_Set_ACY(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Commit();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Additional Reporting Currency", CurrencyCode);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure S_58505_Insert_Default_Dim(TableID: Integer; No: Code[20]; DefaultDim: Code[20]; DefaultDimValue: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.SetRange("Dimension Code", DefaultDim);
        DefaultDimension.SetRange("Dimension Value Code", DefaultDimValue);
        if not DefaultDimension.FindFirst() then
            LibraryDim.CreateDefaultDimension(DefaultDimension, TableID, No, DefaultDim, DefaultDimValue)
            ;
    end;

    local procedure S_58505_Insert_Line_Dim(DimSetID: Integer; LineDim: Code[20]; LineDimValue: Code[20]): Integer
    var
        NewDimSetID: Integer;
    begin
        NewDimSetID := LibraryDim.CreateDimSet(DimSetID, LineDim, LineDimValue);
        exit(NewDimSetID);
    end;

    local procedure S_58505_Validate_GL_Entry(GLRegister: Record "G/L Register"; Account: Code[20]; Amount: Decimal; DimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
        ExchangeRate: Decimal;
    begin
        // Validate Account and amount on GL entry
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetFilter("G/L Account No.", Account);
        GLEntry.SetFilter(Amount, '%1', Amount);
        Assert.IsTrue(GLEntry.FindFirst(), StrSubstNo(GLEntryError, Account, Amount));

        // Validate ACY amount on the GL Entry line
        ExchangeRate := 5; // From function S_58505_Set_ACY: Exchange Rate Amount/Relational Exch. Rate Amount= 100/20 = 5
        Assert.AreEqual(Amount * ExchangeRate, GLEntry."Additional-Currency Amount",
          StrSubstNo(GLEntryACYError, GLEntry."Entry No.", GLEntry."Additional-Currency Amount", Amount * ExchangeRate));

        // Validate Dimension on the GL Entry Line
        Assert.AreEqual(DimSetID, GLEntry."Dimension Set ID", StrSubstNo(GLEntryDimError, GLEntry."Entry No.",
            DimSetID, GLEntry."Dimension Set ID"));
    end;

    local procedure S_58505_Validate_VAT_Entry(GLRegister: Record "G/L Register"; VATBase: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        ExchangeRate: Decimal;
    begin
        // Validate base and amount on VAT entry
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        VATEntry.SetFilter(Base, '%1', VATBase);
        VATEntry.SetFilter(Amount, '%1', VATAmount);
        Assert.IsTrue(VATEntry.FindFirst(), StrSubstNo(VATEntryError, VATBase, VATAmount));

        // Validate ACY amount on the VAT Entry line
        ExchangeRate := 5; // From function S_58505_Set_ACY: Exchange Rate Amount/Relational Exch. Rate Amount= 100/20 = 5
        Assert.AreEqual(VATBase * ExchangeRate, VATEntry."Additional-Currency Base",
          StrSubstNo(VATEntryACYError, VATEntry."Entry No.", VATBase * ExchangeRate, VATEntry."Additional-Currency Base"));
        Assert.AreEqual(VATAmount * ExchangeRate, VATEntry."Additional-Currency Amount",
          StrSubstNo(VATEntryACYError, VATEntry."Entry No.", VATAmount * ExchangeRate, VATEntry."Additional-Currency Amount"));

        // Validate VAT link
        ValidateVATLink(VATEntry, 0, VATEntry."Entry No.");
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure S_58505_Catch_Report(var AdjACYReport: Report "Adjust Add. Reporting Currency")
    begin
        AdjACYReport.InitializeRequest('S58505-1', ACYAcc);
        AdjACYReport.UseRequestPage(false);
        AdjACYReport.RunModal();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58506_Sales()
    var
        GLAccount: Record "G/L Account";
        DiffSalesInvAcc: Text[20];
    begin
        // TFS DynamicsNAV60 Test Case ID 58506 :  invoice discount + line discount - different GL account - same sales GL account
        Initialize();
        GeneralSetup(true);
        LibraryERM.CreateGLAccount(GLAccount);
        DiffSalesInvAcc := GLAccount."No.";
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", DiffSalesInvAcc);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", DiffSalesInvAcc);
        GenPostingSetup2.Modify(true);

        DataSetup_Sales('Credit Memo', false, 15, 15, Item1, Item2);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58506_Validate('Sales',
          LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          DiffSalesInvAcc,
          SalesVATAcc,
          SalesLineDiscAcc1,
          SalesAcc1,
          ReceivableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58506_Purch()
    var
        GLAccount: Record "G/L Account";
        DiffPurchInvAcc: Code[20];
    begin
        // TFS DynamicsNAV60 Test Case ID 58506 :  invoice discount + line discount - different GL account - same sales GL account
        Initialize();
        GeneralSetup(true);
        LibraryERM.CreateGLAccount(GLAccount);
        DiffPurchInvAcc := GLAccount."No.";
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", DiffPurchInvAcc);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", DiffPurchInvAcc);
        GenPostingSetup2.Modify(true);

        DataSetup_Purch('Credit Memo', false, 15, 15, Item1, Item2);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58506_Validate('Purch',
          -LineAmt1,
          VATPct1,
          -LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          DiffPurchInvAcc,
          PurchVATAcc,
          PurchLineDiscAcc1,
          PurchAcc1,
          PayableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58506_Service()
    var
        GLAccount: Record "G/L Account";
        DiffSalesInvAcc: Code[20];
    begin
        // [FEATURE] [Service] [Invoice Discount] [Line Discount]
        // [SCENARIO PS58506] invoice discount + line discount - different GL account - same sales GL account

        // [GIVEN] "Sales Inv. Disc. Account" is the same
        // [GIVEN] Two Items with the same Gen. Prod. Posting group
        // [GIVEN] Service Credit Memo, "Price Incl. VAT"="No", with 2 Item lines,
        // [GIVEN] Service Lines have "Invoice Discount"=15%, "Line Discount"=15%
        // [WHEN] Post the Service Credit Memo
        // [THEN] G/L Entry (COUNT=7,"G/L Account No.",Amount); VAT Entry (COUNT=3,Base,Amount);
        // [THEN] "G/L Entry - VAT Entry Link": amounts are equal in linked entries
        Initialize();
        GeneralSetup(true);
        LibraryERM.CreateGLAccount(GLAccount);
        DiffSalesInvAcc := GLAccount."No.";
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", DiffSalesInvAcc);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", DiffSalesInvAcc);
        GenPostingSetup2.Modify(true);

        DataSetup_Service('Credit Memo', false, 15, 15, Item1, Item2);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58506_Validate('Service',
          LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          DiffSalesInvAcc,
          SalesVATAcc,
          SalesLineDiscAcc1,
          SalesAcc1,
          ReceivableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    local procedure S_58506_Validate(DocType: Text[30]; LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; LineDiscount: Decimal; InvDiscount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20]; Account4: Text[20]; Account5: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalLineDisc1: Decimal;
        TotalLineDisc2: Decimal;
        TotalLineDiscVAT1: Decimal;
        TotalLineDiscVAT2: Decimal;
        TotalInvDiscount1: Decimal;
        TotalInvDiscount2: Decimal;
        TotalInvDiscountVAT1: Decimal;
        TotalInvDiscountVAT2: Decimal;
    begin
        TotalLineVAT1 := LineAmt1 * VATPercent1;
        TotalLineVAT2 := LineAmt2 * VATPercent2;
        TotalLineDisc1 := LineAmt1 * LineDiscount;
        TotalLineDisc2 := LineAmt2 * LineDiscount;
        TotalLineDiscVAT1 := TotalLineDisc1 * VATPercent1;
        TotalLineDiscVAT2 := TotalLineDisc2 * VATPercent2;
        TotalInvDiscount1 := LineAmt1 * (1 - LineDiscount) * InvDiscount;
        TotalInvDiscount2 := LineAmt2 * (1 - LineDiscount) * InvDiscount;
        TotalInvDiscountVAT1 := TotalInvDiscount1 * VATPercent1;
        TotalInvDiscountVAT2 := TotalInvDiscount2 * VATPercent2;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 7, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 7, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, -TotalInvDiscount1 - TotalInvDiscount2);
        ValidateGLEntry(GLRegister, Account2, Round(-TotalInvDiscountVAT1 - TotalInvDiscountVAT2, 1 / 100, '='));
        ValidateGLEntry(GLRegister, Account3, -TotalLineDisc1 - TotalLineDisc2);
        ValidateGLEntry(GLRegister, Account2, -TotalLineDiscVAT1 - TotalLineDiscVAT2);
        ValidateGLEntry(GLRegister, Account4, LineAmt1 + LineAmt2);
        if (DocType = 'Sales') or (DocType = 'Service') then
            ValidateGLEntry(GLRegister, Account2, (TotalLineVAT1 + 1 / 100) + TotalLineVAT2); // 0,01 VAT rounding
        if DocType = 'Purch' then
            ValidateGLEntry(GLRegister, Account2, (TotalLineVAT1 - 1 / 100) + TotalLineVAT2); // 0,01 VAT rounding
        ValidateGLEntry(GLRegister, Account5,
          Round(-LineAmt1 * (1 - LineDiscount) * (1 - InvDiscount) * (1 + VATPercent1) -
            LineAmt2 * (1 - LineDiscount) * (1 - InvDiscount) * (1 + VATPercent2), 1 / 100, '='));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 3, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 3, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, -TotalInvDiscount1 - TotalInvDiscount2,
          Round(-TotalInvDiscountVAT1 - TotalInvDiscountVAT2, 1 / 100, '='), 0);
        ValidateVATEntry(GLRegister, -TotalLineDisc1 - TotalLineDisc2, -TotalLineDiscVAT1 - TotalLineDiscVAT2, 0);
        if (DocType = 'Sales') or (DocType = 'Service') then
            ValidateVATEntry(GLRegister, LineAmt1 + LineAmt2, (TotalLineVAT1 + 1 / 100) + TotalLineVAT2, 0); // 0,01 VAT rounding
        if DocType = 'Purch' then
            ValidateVATEntry(GLRegister, LineAmt1 + LineAmt2, (TotalLineVAT1 - 1 / 100) + TotalLineVAT2, 0); // 0,01 VAT rounding
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58507_Sales()
    begin
        // TFS DynamicsNAV60 Test Case ID 58507 :  invoice discount + line discount - same GL account -different sales GL account
        Initialize();
        GeneralSetup(true);
        // Set Invoice discount and line discount to same account
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc2);
        GenPostingSetup2.Modify(true);

        DataSetup_Sales('Invoice', true, 15, 15, Item1, Item3);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58507_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          SalesLineDiscAcc2,
          SalesLineDiscAcc1,
          SalesVATAcc,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58507_Sales_Prepay()
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Customer: Record Customer;
        SalesReceivableSetup: Record "Sales & Receivables Setup";
        GenPostingSetup: Record "General Posting Setup";
        NoSeries: Record "No. Series";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        SalesPostPrepmt: Codeunit "Sales-Post Prepayments";
        PrePayment: Decimal;
        SalesPrepayAcc: Code[20];
    begin
        // TFS DynamicsNAV60 Test Case ID 58507 :
        // invoice discount + line discount - same GL account -different sales GL account(+ prepayment)
        Initialize();
        GeneralSetup(true);
        // Set Invoice discount and line discount to same account
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc2);
        GenPostingSetup2.Modify(true);

        // Setup No series for prepayment invoice
        NoSeries.FindFirst();
        SalesReceivableSetup.Get();
        SalesReceivableSetup.Validate("Posted Prepmt. Inv. Nos.", NoSeries.Code);
        SalesReceivableSetup.Modify(true);

        // Find VAT Product posting group through item
        Item.Get(Item1);
        LibraryERM.CreateGLAccount(GLAccount);
        SalesPrepayAcc := GLAccount."No.";
        GLAccount.Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        GenPostingSetup.ModifyAll("Sales Prepayments Account", SalesPrepayAcc, true);
        InvDisc := 15;
        CreateCustomer(Customer, GenBusPostingGrp, CustPostingGrp, InvDisc);

        // Create a sales order
        CreateSalesHeader(SalesHeader, Customer, SalesHeader."Document Type"::Order, true);
        PrePayment := 10;
        SalesHeader.Validate("Prepayment %", PrePayment);
        SalesHeader.Modify(true);

        DocLineDataSetup('Sales', true);
        LineDisc := 15;

        CreateSalesLine(SalesHeader, SalesLine1, SalesLine1.Type::Item, Item1, Quantity1, LinePrice1, LineDisc);
        VATPct1 := SalesLine1."VAT %" / 100; // Get VAT% on the line
        CreateSalesLine(SalesHeader, SalesLine2, SalesLine2.Type::Item, Item3, Quantity2, LinePrice2, LineDisc);
        VATPct2 := SalesLine2."VAT %" / 100; // Get VAT% on the line
        // Post prepayment invoice
        SalesPostPrepmt.Invoice(SalesHeader);

        // Post
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Validate GL, VAT & VAT GL link entry
        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58507_Prepay_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          PrePayment / 100,
          SalesLineDiscAcc2,
          SalesLineDiscAcc1,
          SalesVATAcc,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc,
          SalesPrepayAcc);

        // Test cleanup
        GenPostingSetup1.Find();
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Find();
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58507_Purch()
    begin
        // TFS DynamicsNAV60 Test Case ID 58507 :  invoice discount + line discount - same GL account -different sales GL account
        Initialize();
        GeneralSetup(true);
        // Set Invoice discount and line discount to same account
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", PurchLineDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", PurchLineDiscAcc2);
        GenPostingSetup2.Modify(true);

        DataSetup_Purch('Invoice', true, 15, 15, Item1, Item3);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58507_Validate(-LineAmt1,
          VATPct1,
          -LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          PurchLineDiscAcc2,
          PurchLineDiscAcc1,
          PurchVATAcc,
          PurchAcc2,
          PurchAcc1,
          PayableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58507_Purch_Prepay()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchasePaybleSetup: Record "Purchases & Payables Setup";
        GenPostingSetup: Record "General Posting Setup";
        NoSeries: Record "No. Series";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        PurchPostPrepmt: Codeunit "Purchase-Post Prepayments";
        PrePayment: Decimal;
        PurchPrepayAcc: Code[20];
    begin
        // TFS DynamicsNAV60 Test Case ID 58507 :
        // invoice discount + line discount - same GL account -different sales GL account(+ prepayment)
        Initialize();
        GeneralSetup(true);
        // Set Invoice discount and line discount to same account
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", PurchLineDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", PurchLineDiscAcc2);
        GenPostingSetup2.Modify(true);

        // Setup No series for prepayment invoice
        NoSeries.FindFirst();
        PurchasePaybleSetup.Get();
        PurchasePaybleSetup.Validate("Posted Prepmt. Inv. Nos.", NoSeries.Code);
        PurchasePaybleSetup.Modify(true);
        InvDisc := 15;
        CreateVendor(Vendor, GenBusPostingGrp, VendPostingGrp, InvDisc);

        // Find VAT Product posting group through item
        Item.Get(Item1);
        LibraryERM.CreateGLAccount(GLAccount);
        PurchPrepayAcc := GLAccount."No.";
        GLAccount.Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        GenPostingSetup.ModifyAll("Purch. Prepayments Account", PurchPrepayAcc, true);

        // Create a purchase invoice
        CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::Order, true);
        PrePayment := 10;
        PurchHeader.Validate("Prepayment %", PrePayment);
        PurchHeader.Validate("Vendor Invoice No.", '');
        PurchHeader.Modify(true);

        LineDisc := 15;
        DocLineDataSetup('Purchase', true);
        CreatePurchLine(PurchHeader, PurchLine1, PurchLine1.Type::Item, Item1, Quantity1, LineCost1, LineDisc);
        VATPct1 := PurchLine1."VAT %" / 100; // Get VAT% on the line
        CreatePurchLine(PurchHeader, PurchLine2, PurchLine2.Type::Item, Item3, Quantity2, LineCost2, LineDisc);
        VATPct2 := PurchLine2."VAT %" / 100; // Get VAT% on the line
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine1);
        // Post prepayment invoice
        PurchPostPrepmt.Invoice(PurchHeader);

        // Post
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Validate GL, VAT & VAT GL link entry
        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58507_Prepay_Validate(-LineAmt1,
          VATPct1,
          -LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          PrePayment / 100,
          PurchLineDiscAcc2,
          PurchLineDiscAcc1,
          PurchVATAcc,
          PurchAcc2,
          PurchAcc1,
          PayableAcc,
          PurchPrepayAcc);

        // Test cleanup
        GenPostingSetup1.Find();
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Find();
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58507_Service()
    begin
        // [FEATURE] [Service] [Invoice Discount] [Line Discount]
        // [SCENARIO PS58507] invoice discount + line discount - same GL account -different sales GL account

        // [GIVEN] Two Items with the diff Gen. Prod. Posting group
        // [GIVEN] Service Invoice, "Price Incl. VAT"="Yes", with 2 Item lines,
        // [GIVEN] Service Lines have "Invoice Discount"=15%, "Line Discount"=15%, different Dim Set Ids
        // [WHEN] Post the Service Invoice
        // [THEN] G/L Entry (COUNT=9,"G/L Account No.",Amount); VAT Entry (COUNT=4,Base,Amount);
        // [THEN] "G/L Entry - VAT Entry Link": amounts are equal in linked entries
        Initialize();
        GeneralSetup(true);
        // Set Invoice discount and line discount to same account
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc2);
        GenPostingSetup2.Modify(true);

        DataSetup_Service('Invoice', true, 15, 15, Item1, Item3);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58507_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          SalesLineDiscAcc2,
          SalesLineDiscAcc1,
          SalesVATAcc,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    local procedure S_58507_Validate(LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; LineDiscount: Decimal; InvDiscount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20]; Account4: Text[20]; Account5: Text[20]; Account6: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        TotalLineAmtExclVAT1: Decimal;
        TotalLineAmtExclVAT2: Decimal;
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalLineDisc1: Decimal;
        TotalLineDisc2: Decimal;
        TotalLineDiscVAT1: Decimal;
        TotalLineDiscVAT2: Decimal;
        TotalInvDiscount1: Decimal;
        TotalInvDiscount2: Decimal;
        TotalInvDiscountVAT1: Decimal;
        TotalInvDiscountVAT2: Decimal;
    begin
        TotalLineAmtExclVAT1 := LineAmt1 / (1 + VATPercent1);
        TotalLineAmtExclVAT2 := LineAmt2 / (1 + VATPercent2);
        TotalLineVAT1 := TotalLineAmtExclVAT1 * VATPercent1;
        TotalLineVAT2 := TotalLineAmtExclVAT2 * VATPercent2;
        TotalLineDisc1 := TotalLineAmtExclVAT1 * LineDiscount;
        TotalLineDisc2 := TotalLineAmtExclVAT2 * LineDiscount;
        TotalLineDiscVAT1 := TotalLineDisc1 * VATPercent1;
        TotalLineDiscVAT2 := TotalLineDisc2 * VATPercent2;
        TotalInvDiscount1 := TotalLineAmtExclVAT1 * (1 - LineDiscount) * InvDiscount;
        TotalInvDiscount2 := TotalLineAmtExclVAT2 * (1 - LineDiscount) * InvDiscount;
        TotalInvDiscountVAT1 := TotalInvDiscount1 * VATPercent1;
        TotalInvDiscountVAT2 := TotalInvDiscount2 * VATPercent2;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 9, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 9, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, TotalLineDisc2 + TotalInvDiscount2);
        ValidateGLEntry(GLRegister, Account3, TotalLineDiscVAT2 + TotalInvDiscountVAT2);
        ValidateGLEntry(GLRegister, Account2, TotalLineDisc1 + TotalInvDiscount1);
        ValidateGLEntry(GLRegister, Account3, Round(TotalLineDiscVAT1 + TotalInvDiscountVAT1, 1 / 100, '='));
        ValidateGLEntry(GLRegister, Account4, -TotalLineAmtExclVAT2);
        ValidateGLEntry(GLRegister, Account3, -TotalLineVAT2);
        ValidateGLEntry(GLRegister, Account5, -TotalLineAmtExclVAT1);
        ValidateGLEntry(GLRegister, Account3, -TotalLineVAT1);
        ValidateGLEntry(GLRegister, Account6,
          Round(LineAmt1 * (1 - LineDiscount) * (1 - InvDiscount) + LineAmt2 * (1 - LineDiscount) * (1 - InvDiscount), 1 / 100, '<'));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 4, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 4, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, TotalLineDisc2 + TotalInvDiscount2, TotalLineDiscVAT2 + TotalInvDiscountVAT2, 0);
        ValidateVATEntry(GLRegister, TotalLineDisc1 + TotalInvDiscount1, Round(TotalLineDiscVAT1 + TotalInvDiscountVAT1, 1 / 100, '='), 0);
        ValidateVATEntry(GLRegister, -TotalLineAmtExclVAT2, -TotalLineVAT2, 0);
        ValidateVATEntry(GLRegister, -TotalLineAmtExclVAT1, -TotalLineVAT1, 0);
    end;

    local procedure S_58507_Prepay_Validate(LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; LineDiscount: Decimal; InvDiscount: Decimal; PrePayment: Decimal; Account1: Code[20]; Account2: Code[20]; Account3: Code[20]; Account4: Code[20]; Account5: Code[20]; Account6: Code[20]; Account7: Code[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        IsEntryTypeSale: Boolean;
        PrepaymentAmount: Decimal;
        TotalLineAmtExclVAT1: Decimal;
        TotalLineAmtExclVAT2: Decimal;
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalLineDisc1: Decimal;
        TotalLineDisc2: Decimal;
        TotalLineDiscVAT1: Decimal;
        TotalLineDiscVAT2: Decimal;
        TotalLineAmtExclDisc1: Decimal;
        TotalLineAmtExclDisc2: Decimal;
        TotalInvDiscount1: Decimal;
        TotalInvDiscount2: Decimal;
        TotalInvDiscountVAT1: Decimal;
        TotalInvDiscountVAT2: Decimal;
        GLEntryAmount: Decimal;
        AmountExclPrepayment: Decimal;
    begin
        TotalLineAmtExclVAT1 := LineAmt1 / (1 + VATPercent1);
        TotalLineAmtExclVAT2 := LineAmt2 / (1 + VATPercent2);
        TotalLineVAT1 := TotalLineAmtExclVAT1 * VATPercent1;
        TotalLineVAT2 := TotalLineAmtExclVAT2 * VATPercent2;
        TotalLineDisc1 := TotalLineAmtExclVAT1 * LineDiscount;
        TotalLineDisc2 := TotalLineAmtExclVAT2 * LineDiscount;
        TotalLineDiscVAT1 := TotalLineDisc1 * VATPercent1;
        TotalLineDiscVAT2 := TotalLineDisc2 * VATPercent2;
        TotalLineAmtExclDisc1 := TotalLineAmtExclVAT1 * (1 - LineDiscount);
        TotalLineAmtExclDisc2 := TotalLineAmtExclVAT2 * (1 - LineDiscount);
        TotalInvDiscount1 := TotalLineAmtExclDisc1 * InvDiscount;
        TotalInvDiscount2 := TotalLineAmtExclDisc2 * InvDiscount;
        TotalInvDiscountVAT1 := TotalInvDiscount1 * VATPercent1;
        TotalInvDiscountVAT2 := TotalInvDiscount2 * VATPercent2;

        IsEntryTypeSale := SalesDocumentExist();
        if IsEntryTypeSale then begin
            TotalLineAmtExclDisc1 := TotalLineAmtExclDisc1 - TotalInvDiscount1;
            TotalLineAmtExclDisc2 := TotalLineAmtExclDisc2 - TotalInvDiscount2;

            PrepaymentAmount := Round(
                (TotalLineAmtExclDisc1 * (1 + VATPercent1) + TotalLineAmtExclDisc2 * (1 + VATPercent2)) * PrePayment,
                Currency."Amount Rounding Precision");
        end else begin
            TotalLineAmtExclDisc1 := TotalLineAmtExclDisc1 - TotalInvDiscount1;
            TotalLineAmtExclDisc2 := TotalLineAmtExclDisc2 - TotalInvDiscount2;

            PrepaymentAmount := Round(
                (TotalLineAmtExclDisc1 * (1 + VATPercent1) + TotalLineAmtExclDisc2 * (1 + VATPercent2)) * PrePayment,
                Currency."Amount Rounding Precision");
        end;
        // Validate prepayment invoice ledger entry and VAT entry
        GLRegister.Next(GLRegister.Count - 1);
        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        GLEntryAmount := (TotalLineAmtExclDisc1 * VATPercent1 + TotalLineAmtExclDisc2 * VATPercent2) * PrePayment;

        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account7, -(TotalLineAmtExclDisc1 + TotalLineAmtExclDisc2) * PrePayment);
        ValidateGLEntry(GLRegister, Account3, -Round(GLEntryAmount, Currency."Amount Rounding Precision"));

        ValidateGLEntry(GLRegister, Account6, PrepaymentAmount);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 1, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 1, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, -(TotalLineAmtExclDisc1 + TotalLineAmtExclDisc2) * PrePayment,
          -Round(GLEntryAmount, Currency."Amount Rounding Precision"), 0);

        // Validate invoicing ledger entry and vat entry
        GLRegister.Next();
        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 11, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 11, GLEntry.Count));

        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, TotalLineDisc2 + TotalInvDiscount2);
        ValidateGLEntry(GLRegister, Account3, TotalLineDiscVAT2 + TotalInvDiscountVAT2);
        ValidateGLEntry(GLRegister, Account2, TotalLineDisc1 + TotalInvDiscount1);
        ValidateGLEntry(GLRegister, Account3, Round(TotalLineDiscVAT1 + TotalInvDiscountVAT1, 1 / 100, '='));
        ValidateGLEntry(GLRegister, Account4, -TotalLineAmtExclVAT2);
        ValidateGLEntry(GLRegister, Account3, -TotalLineVAT2);
        ValidateGLEntry(GLRegister, Account5, -TotalLineAmtExclVAT1);
        ValidateGLEntry(GLRegister, Account3, -TotalLineVAT1);
        ValidateGLEntry(GLRegister, Account7, (TotalLineAmtExclDisc1 + TotalLineAmtExclDisc2) * PrePayment);
        ValidateGLEntry(GLRegister, Account3, Round(GLEntryAmount, Currency."Amount Rounding Precision"));
        AmountExclPrepayment := Round(TotalLineAmtExclDisc1 * (1 + VATPercent1) + TotalLineAmtExclDisc2 * (1 + VATPercent2), 1 / 100, '<') - PrepaymentAmount;

        if IsEntryTypeSale then
            ValidateGLEntry(GLRegister, Account6, AmountExclPrepayment)
        else
            ValidateGLEntry(GLRegister, Account6, AmountExclPrepayment);
        /*             ValidateGLEntry(GLRegister, Account6,
                      Round(TotalLineAmtExclDisc1 * (1 - InvDiscount) * (1 + VATPercent1) +
                        TotalLineAmtExclDisc2 * (1 - InvDiscount) * (1 + VATPercent2), 1 / 100, '<') - PrepaymentAmount);

         */        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 5, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 5, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, TotalLineDisc2 + TotalInvDiscount2, TotalLineDiscVAT2 + TotalInvDiscountVAT2, 0);
        ValidateVATEntry(GLRegister, TotalLineDisc1 + TotalInvDiscount1, Round(TotalLineDiscVAT1 + TotalInvDiscountVAT1, 1 / 100, '='), 0);
        ValidateVATEntry(GLRegister, -TotalLineAmtExclVAT2, -TotalLineVAT2, 0);
        ValidateVATEntry(GLRegister, -TotalLineAmtExclVAT1, -TotalLineVAT1, 0);
        ValidateVATEntry(GLRegister, (TotalLineAmtExclDisc1 + TotalLineAmtExclDisc2) * PrePayment,
            Round(GLEntryAmount, Currency."Amount Rounding Precision"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58508_Sales()
    begin
        // TFS DynamicsNAV60 Test Case ID 58508 :  invoice discount + line discount - same GL account -same sales GL account
        Initialize();
        GeneralSetup(true);
        // Set Invoice discount and line discount to same account
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc2);
        GenPostingSetup2.Modify(true);

        DataSetup_Sales('Invoice', true, 15, 15, Item1, Item2);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58508_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          SalesLineDiscAcc1,
          SalesVATAcc,
          SalesAcc1,
          ReceivableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58508_Purch()
    begin
        // TFS DynamicsNAV60 Test Case ID 58508 :  invoice discount + line discount - same GL account -same sales GL account
        Initialize();
        GeneralSetup(true);
        // Set Invoice discount and line discount to same account
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", PurchLineDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", PurchLineDiscAcc2);
        GenPostingSetup2.Modify(true);

        DataSetup_Purch('Invoice', true, 15, 15, Item1, Item2);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58508_Validate(-LineAmt1,
          VATPct1,
          -LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          PurchLineDiscAcc1,
          PurchVATAcc,
          PurchAcc1,
          PayableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Purch. Inv. Disc. Account", PurchInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58508_Service()
    begin
        // [FEATURE] [Service] [Invoice Discount] [Line Discount]
        // [SCENARIO PS58508] invoice discount + line discount - same GL account -same sales GL account

        // [GIVEN] Two Items with the same Gen. Prod. Posting group
        // [GIVEN] Service Invoice, "Price Incl. VAT"="Yes", with 2 Item lines,
        // [GIVEN] Service Lines have "Invoice Discount"=15%, "Line Discount"=15%
        // [WHEN] Post the Service Invoice
        // [THEN] G/L Entry (COUNT=5,"G/L Account No.",Amount); VAT Entry (COUNT=2,Base,Amount);
        // [THEN] "G/L Entry - VAT Entry Link": amounts are equal in linked entries
        Initialize();
        GeneralSetup(true);
        // Set Invoice discount and line discount to same account
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesLineDiscAcc2);
        GenPostingSetup2.Modify(true);

        DataSetup_Service('Invoice', true, 15, 15, Item1, Item2);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58508_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          LineDisc / 100,
          InvDisc / 100,
          SalesLineDiscAcc1,
          SalesVATAcc,
          SalesAcc1,
          ReceivableAcc);

        // Test cleanup
        GenPostingSetup1.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc1);
        GenPostingSetup1.Modify(true);
        GenPostingSetup2.Validate("Sales Inv. Disc. Account", SalesInvDiscAcc2);
        GenPostingSetup2.Modify(true);
    end;

    local procedure S_58508_Validate(LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; LineDiscount: Decimal; InvDiscount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20]; Account4: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        TotalLineAmtExclVAT1: Decimal;
        TotalLineAmtExclVAT2: Decimal;
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalLineDisc1: Decimal;
        TotalLineDisc2: Decimal;
        TotalLineDiscVAT1: Decimal;
        TotalLineDiscVAT2: Decimal;
        TotalInvDiscount1: Decimal;
        TotalInvDiscount2: Decimal;
        TotalInvDiscountVAT1: Decimal;
        TotalInvDiscountVAT2: Decimal;
    begin
        TotalLineAmtExclVAT1 := LineAmt1 / (1 + VATPercent1);
        TotalLineAmtExclVAT2 := LineAmt2 / (1 + VATPercent2);
        TotalLineVAT1 := TotalLineAmtExclVAT1 * VATPercent1;
        TotalLineVAT2 := TotalLineAmtExclVAT2 * VATPercent2;
        TotalLineDisc1 := TotalLineAmtExclVAT1 * LineDiscount;
        TotalLineDisc2 := TotalLineAmtExclVAT2 * LineDiscount;
        TotalLineDiscVAT1 := TotalLineDisc1 * VATPercent1;
        TotalLineDiscVAT2 := TotalLineDisc2 * VATPercent2;
        TotalInvDiscount1 := TotalLineAmtExclVAT1 * (1 - LineDiscount) * InvDiscount;
        TotalInvDiscount2 := TotalLineAmtExclVAT2 * (1 - LineDiscount) * InvDiscount;
        TotalInvDiscountVAT1 := TotalInvDiscount1 * VATPercent1;
        TotalInvDiscountVAT2 := TotalInvDiscount2 * VATPercent2;

        GLRegister.FindLast();
        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 5, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 5, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, TotalLineDisc1 + TotalLineDisc2 + TotalInvDiscount1 + TotalInvDiscount2);
        ValidateGLEntry(GLRegister, Account2,
          Round(TotalLineDiscVAT1 + TotalInvDiscountVAT1 + TotalLineDiscVAT2 + TotalInvDiscountVAT2, 1 / 100, '='));
        ValidateGLEntry(GLRegister, Account3, -TotalLineAmtExclVAT1 - TotalLineAmtExclVAT2);
        ValidateGLEntry(GLRegister, Account2, -TotalLineVAT1 - TotalLineVAT2);
        ValidateGLEntry(GLRegister, Account4, Round((LineAmt1 + LineAmt2) * (1 - LineDiscount) * (1 - InvDiscount), 1 / 100, '<'));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 2, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 2, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, TotalLineDisc1 + TotalLineDisc2 + TotalInvDiscount1 + TotalInvDiscount2,
          Round(TotalLineDiscVAT1 + TotalInvDiscountVAT1 + TotalLineDiscVAT2 + TotalInvDiscountVAT2, 1 / 100, '='), 0);
        ValidateVATEntry(GLRegister, -TotalLineAmtExclVAT1 - TotalLineAmtExclVAT2, -TotalLineVAT1 - TotalLineVAT2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58509_Sales()
    begin
        // TFS DynamicsNAV60 Test Case ID 58509 :  invoice discount-Post to different sales GL account
        Initialize();
        GeneralSetup(true);
        DataSetup_Sales('Credit Memo', false, 0, 15, Item1, Item3);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58509_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          InvDisc / 100,
          SalesInvDiscAcc2,
          SalesInvDiscAcc1,
          SalesVATAcc,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58509_Purch()
    begin
        // TFS DynamicsNAV60 Test Case ID 58509 :  invoice discount-Post to different sales GL account
        Initialize();
        GeneralSetup(true);
        DataSetup_Purch('Credit Memo', false, 0, 15, Item1, Item3);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;

        S_58509_Validate(-LineAmt1,
          VATPct1,
          -LineAmt2,
          VATPct2,
          InvDisc / 100,
          PurchInvDiscAcc2,
          PurchInvDiscAcc1,
          PurchVATAcc,
          PurchAcc2,
          PurchAcc1,
          PayableAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58509_Service()
    begin
        // [FEATURE] [Service] [Invoice Discount]
        // [SCENARIO PS58508] invoice discount-Post to different sales GL account

        // [GIVEN] Two Items with the diff Gen. Prod. Posting group
        // [GIVEN] Service Invoice, "Price Incl. VAT"="No", with 2 Item lines, "Invoice Discount"=15%,
        // [WHEN] Post the Service Invoice
        // [THEN] G/L Entry (COUNT=9,"G/L Account No.",Amount); VAT Entry (COUNT=4,Base,Amount);
        // [THEN] "G/L Entry - VAT Entry Link": amounts are equal in linked entries
        Initialize();
        GeneralSetup(true);
        DataSetup_Service('Credit Memo', false, 0, 15, Item1, Item3);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;

        S_58509_Validate(LineAmt1,
          VATPct1,
          LineAmt2,
          VATPct2,
          InvDisc / 100,
          SalesInvDiscAcc2,
          SalesInvDiscAcc1,
          SalesVATAcc,
          SalesAcc2,
          SalesAcc1,
          ReceivableAcc);
    end;

    local procedure S_58509_Validate(LineAmt1: Decimal; VATPercent1: Decimal; LineAmt2: Decimal; VATPercent2: Decimal; InvDiscount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20]; Account4: Text[20]; Account5: Text[20]; Account6: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        TotalLineVAT1: Decimal;
        TotalLineVAT2: Decimal;
        TotalInvDiscount1: Decimal;
        TotalInvDiscount2: Decimal;
        TotalInvDiscountVAT1: Decimal;
        TotalInvDiscountVAT2: Decimal;
    begin
        TotalLineVAT1 := LineAmt1 * VATPercent1;
        TotalLineVAT2 := LineAmt2 * VATPercent2;
        TotalInvDiscount1 := LineAmt1 * InvDiscount;
        TotalInvDiscount2 := LineAmt2 * InvDiscount;
        TotalInvDiscountVAT1 := TotalInvDiscount1 * VATPercent1;
        TotalInvDiscountVAT2 := TotalInvDiscount2 * VATPercent2;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 9, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 9, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, -TotalInvDiscount2);
        ValidateGLEntry(GLRegister, Account3, -TotalInvDiscountVAT2);
        ValidateGLEntry(GLRegister, Account2, -TotalInvDiscount1);
        ValidateGLEntry(GLRegister, Account3, -TotalInvDiscountVAT1);
        ValidateGLEntry(GLRegister, Account4, LineAmt2);
        ValidateGLEntry(GLRegister, Account3, TotalLineVAT2);
        ValidateGLEntry(GLRegister, Account5, LineAmt1);
        ValidateGLEntry(GLRegister, Account3, TotalLineVAT1);
        ValidateGLEntry(GLRegister, Account6,
          -LineAmt1 * (1 - InvDiscount) * (1 + VATPercent1) - LineAmt2 * (1 - InvDiscount) * (1 + VATPercent2));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 4, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 4, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, -TotalInvDiscount2, -TotalInvDiscountVAT2, 0);
        ValidateVATEntry(GLRegister, -TotalInvDiscount1, -TotalInvDiscountVAT1, 0);
        ValidateVATEntry(GLRegister, LineAmt2, TotalLineVAT2, 0);
        ValidateVATEntry(GLRegister, LineAmt1, TotalLineVAT1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58848_Sales()
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        PayAmount: Decimal;
        TotalLineAmt: Decimal;
        TotalInvDiscount: Decimal;
        TotalLineDisc: Decimal;
        TotalInvAmount: Decimal;
        PmtDiscAmount: Decimal;
        PmtDiscount: Decimal;
        GLAccountUsed: Code[20];
        DiffSalesInvDiscAcc: Code[20];
        OrigSalesInvDiscAcc: Code[20];
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
        PmtDiscountDate: Date;
    begin
        // TFS DynamicsNAV60 Test Case ID 58848 :  Reverse Charge VAT- - Pmt. Disc.Excl VAT(Yes) - Adjust for Payment Disc.(No)
        Initialize();
        GeneralSetup(false);
        BankSetup(BankAcc, GLBankAccNo);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        JournalSetup(JournalTemplate, JournalBatch);

        // Find VAT Posting Setup for reverse charge
        FindReverseChargeVATPostSetup(VATPostingSetup, false);
        GLAccountUsed := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        GLAccount.Get(GLAccountUsed);
        GenBusPostingGroup.Get(GLAccount."Gen. Bus. Posting Group");
        GenProdPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");

        LibraryERM.CreateGLAccount(GLAccount);
        DiffSalesInvDiscAcc := GLAccount."No.";
        GeneralPostingSetup.Get(GenBusPostingGroup.Code, GenProdPostingGroup.Code);
        OrigSalesInvDiscAcc := GeneralPostingSetup."Sales Inv. Disc. Account";
        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", DiffSalesInvDiscAcc);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", SalesLineDiscAcc1);
        GeneralPostingSetup.Modify(true);

        InvDisc := 15;
        PmtDiscount := 5;
        LinePrice1 := 1000;
        Quantity1 := 1;
        LineDisc := 15;
        CreateCustomerwithVAT(Customer, GenBusPostingGroup.Code, VATPostingSetup."VAT Bus. Posting Group", CustPostingGrp, InvDisc);

        // Step 1: Create a sales invoice
        CreateSalesHeader(SalesHeader, Customer, SalesHeader."Document Type"::Invoice, false);
        SalesHeader.Validate("Payment Discount %", PmtDiscount);
        PmtDiscountDate := CalcDate('<1W>', SalesHeader."Posting Date");
        SalesHeader.Validate("Pmt. Discount Date", PmtDiscountDate);
        SalesHeader.Modify(true);

        CreateSalesLine(SalesHeader, SalesLine1, SalesLine1.Type::"G/L Account", GLAccountUsed, Quantity1, LinePrice1, LineDisc);
        SalesLine1.Validate("Allow Invoice Disc.", true);
        SalesLine1.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LineDisc := LineDisc / 100;
        InvDisc := InvDisc / 100;
        TotalLineAmt := LinePrice1 * Quantity1;
        TotalLineDisc := TotalLineAmt * LineDisc;
        TotalInvDiscount := TotalLineAmt * (1 - LineDisc) * InvDisc;
        TotalInvAmount := (TotalLineAmt - TotalLineDisc) * (1 - InvDisc);
        PmtDiscAmount := Round(TotalInvAmount * PmtDiscount / 100, 1 / 100, '=');
        PayAmount := TotalInvAmount - PmtDiscAmount;

        // Validate No of GL entries
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 4, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 4, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, DiffSalesInvDiscAcc, TotalInvDiscount);
        ValidateGLEntry(GLRegister, SalesLineDiscAcc1, TotalLineDisc);
        ValidateGLEntry(GLRegister, GLAccountUsed, -TotalLineAmt);
        ValidateGLEntry(GLRegister, ReceivableAcc, TotalInvAmount);

        // Validate No of VAT Entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 3, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 3, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, TotalInvDiscount, 0, 0);
        ValidateVATEntry(GLRegister, TotalLineDisc, 0, 0);
        ValidateVATEntry(GLRegister, -TotalLineAmt, 0, 0);

        // Step 2: post payment and apply to invoice
        Post_Payment_And_Apply(JournalTemplate, JournalBatch, 'Customer', Customer."No.", -PayAmount, 'Payment', BankAcc, PmtDiscountDate);

        GLRegister.FindLast();
        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, GLBankAccNo, PayAmount);
        ValidateGLEntry(GLRegister, ReceivableAcc, -TotalInvAmount);
        ValidateGLEntry(GLRegister, CustPmtDiscDebitAcc, PmtDiscAmount);

        // Validate No of VAT Entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 0, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 0, VATEntry.Count));

        // Test Cleanup
        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", OrigSalesInvDiscAcc);
        GeneralPostingSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58848_Purch()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATpostingSetup: Record "VAT Posting Setup";
        GLRegister: Record "G/L Register";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        VATPct: Decimal;
        PayAmount: Decimal;
        TotalLineCost: Decimal;
        TotalLineDisc: Decimal;
        TotalInvDiscount: Decimal;
        TotalInvAmount: Decimal;
        PmtDiscAmount: Decimal;
        PmtDiscount: Decimal;
        GLAccountUsed: Code[20];
        DiffPurchInvDiscAcc: Code[20];
        ReverseChrgVATAcc: Code[20];
        PurchVATAcc58848: Code[20];
        OrigPurchInvDiscAcc: Code[20];
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
        PmtDiscountDate: Date;
    begin
        // TFS DynamicsNAV60 Test Case ID 58848 :  Reverse Charge VAT- - Pmt. Disc.Excl VAT(Yes) - Adjust for Payment Disc.(No)
        Initialize();
        GeneralSetup(false);
        BankSetup(BankAcc, GLBankAccNo);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        JournalSetup(JournalTemplate, JournalBatch);

        // Find VAT Posting Setup for reverse charge
        FindReverseChargeVATPostSetup(VATpostingSetup, false);
        PurchVATAcc58848 := VATpostingSetup."Purchase VAT Account";
        ReverseChrgVATAcc := VATpostingSetup."Reverse Chrg. VAT Acc.";
        GLAccountUsed := LibraryERM.CreateGLAccountWithVATPostingSetup(VATpostingSetup, "General Posting Type"::" ");
        GLAccount.Get(GLAccountUsed);
        GenBusPostingGroup.Get(GLAccount."Gen. Bus. Posting Group");
        GenProdPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");

        LibraryERM.CreateGLAccount(GLAccount);
        DiffPurchInvDiscAcc := GLAccount."No.";
        GeneralPostingSetup.Get(GenBusPostingGroup.Code, GenProdPostingGroup.Code);
        OrigPurchInvDiscAcc := GeneralPostingSetup."Purch. Inv. Disc. Account";
        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", DiffPurchInvDiscAcc);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", PurchLineDiscAcc1);
        GeneralPostingSetup.Modify(true);

        InvDisc := 15;
        PmtDiscount := 5;
        LineCost1 := 1000;
        Quantity1 := 1;
        LineDisc := 15;

        CreateVendorwithVAT(Vendor, GenBusPostingGroup.Code, VATpostingSetup."VAT Bus. Posting Group", VendPostingGrp, InvDisc);

        // Step 1: Create a purchase invoice
        CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::Invoice, false);
        PurchHeader.Validate("Payment Discount %", PmtDiscount);
        PmtDiscountDate := CalcDate('<1W>', PurchHeader."Posting Date");
        PurchHeader.Validate("Pmt. Discount Date", PmtDiscountDate);
        PurchHeader.Modify(true);

        CreatePurchLine(PurchHeader, PurchLine1, PurchLine1.Type::"G/L Account", GLAccountUsed, Quantity1, LineCost1, LineDisc);
        PurchLine1.Validate("Allow Invoice Disc.", true);
        PurchLine1.Modify(true);

        VATpostingSetup.Get(PurchLine1."VAT Bus. Posting Group", PurchLine1."VAT Prod. Posting Group");
        VATPct := VATpostingSetup."VAT %" / 100;

        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        LineDisc := LineDisc / 100;
        InvDisc := InvDisc / 100;
        TotalLineCost := LineCost1 * Quantity1;
        TotalLineDisc := TotalLineCost * LineDisc;
        TotalInvDiscount := TotalLineCost * (1 - LineDisc) * InvDisc;
        TotalInvAmount := (TotalLineCost - TotalLineDisc) * (1 - InvDisc);
        PmtDiscAmount := Round(TotalInvAmount * PmtDiscount / 100, 1 / 100, '=');
        PayAmount := TotalInvAmount - PmtDiscAmount;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 10, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 10, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, DiffPurchInvDiscAcc, -TotalInvDiscount);
        ValidateGLEntry(GLRegister, PurchVATAcc58848, Round(-TotalInvDiscount * VATPct, LibraryERM.GetAmountRoundingPrecision()));
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, Round(TotalInvDiscount * VATPct, LibraryERM.GetAmountRoundingPrecision()));
        ValidateGLEntry(GLRegister, PurchLineDiscAcc1, -TotalLineDisc);
        ValidateGLEntry(GLRegister, PurchVATAcc58848, -TotalLineDisc * VATPct);
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, TotalLineDisc * VATPct);
        ValidateGLEntry(GLRegister, GLAccountUsed, TotalLineCost);
        ValidateGLEntry(GLRegister, PurchVATAcc58848, TotalLineCost * VATPct);
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, -TotalLineCost * VATPct);
        ValidateGLEntry(GLRegister, PayableAcc, -TotalInvAmount);

        // Validate No of VAT Entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 3, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 3, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, -TotalInvDiscount, Round(-TotalInvDiscount * VATPct, LibraryERM.GetAmountRoundingPrecision()), 0);
        ValidateVATEntry(GLRegister, -TotalLineDisc, -TotalLineDisc * VATPct, 0);
        ValidateVATEntry(GLRegister, TotalLineCost, TotalLineCost * VATPct, 0);

        // step 2: create payment and apply to invoice
        Post_Payment_And_Apply(JournalTemplate, JournalBatch, 'Vendor', Vendor."No.", PayAmount, 'Payment', BankAcc, PmtDiscountDate);

        GLRegister.FindLast();
        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, GLBankAccNo, -PayAmount);
        ValidateGLEntry(GLRegister, PayableAcc, TotalInvAmount);
        ValidateGLEntry(GLRegister, VendPmtDiscCreditAcc, -PmtDiscAmount);

        // Validate No of VAT entry
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 0, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 0, VATEntry.Count));

        // Test Cleanup
        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", OrigPurchInvDiscAcc);
        GeneralPostingSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_59013_Sales()
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VatPostingSetup: Record "VAT Posting Setup";
        GLRegister: Record "G/L Register";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        TotalLineAmt: Decimal;
        TotalInvDiscount: Decimal;
        TotalLineDisc: Decimal;
        TotalInvAmount: Decimal;
        PmtDiscAmount: Decimal;
        PayAmount: Decimal;
        PmtDiscount: Decimal;
        SalesPmtDiscDebitAcc: Code[20];
        SalesPmtDiscCreditAcc: Code[20];
        DiffSalesInvDiscAcc: Code[20];
        GLAccountUsed: Code[20];
        OrigSalesInvDiscAcc: Code[20];
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
        PmtDiscountDate: Date;
    begin
        // TFS DynamicsNAV60 Test Case ID 59013 :  Reverse Charge VAT - Pmt. Disc.Excl VAT(No) - Adjust for Payment Disc.(Yes)
        Initialize();
        GeneralSetup(false);
        BankSetup(BankAcc, GLBankAccNo);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        JournalSetup(JournalTemplate, JournalBatch);

        LibraryERM.CreateGLAccount(GLAccount);
        DiffSalesInvDiscAcc := GLAccount."No.";
        LibraryERM.CreateGLAccount(GLAccount);
        SalesPmtDiscDebitAcc := GLAccount."No.";
        LibraryERM.CreateGLAccount(GLAccount);
        SalesPmtDiscCreditAcc := GLAccount."No.";

        // Find VAT Posting Setup for reverse charge
        FindReverseChargeVATPostSetup(VatPostingSetup, true);
        GLAccountUsed := LibraryERM.CreateGLAccountWithVATPostingSetup(VatPostingSetup, "General Posting Type"::" ");
        GLAccount.Get(GLAccountUsed);
        GenBusPostingGroup.Get(GLAccount."Gen. Bus. Posting Group");
        GenProdPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");

        GeneralPostingSetup.Get(GenBusPostingGroup.Code, GenProdPostingGroup.Code);
        OrigSalesInvDiscAcc := GeneralPostingSetup."Sales Inv. Disc. Account";
        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", DiffSalesInvDiscAcc);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", SalesLineDiscAcc1);
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", SalesPmtDiscDebitAcc);
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", SalesPmtDiscCreditAcc);
        GeneralPostingSetup.Modify(true);

        InvDisc := 15;
        LinePrice1 := 1000;
        Quantity1 := 1;
        LineDisc := 15;

        CreateCustomerwithVAT(Customer, GenBusPostingGroup.Code, VatPostingSetup."VAT Bus. Posting Group", CustPostingGrp, InvDisc);
        // Step 1: Create a sales invoice
        CreateSalesHeader(SalesHeader, Customer, SalesHeader."Document Type"::Invoice, true);
        PmtDiscount := 5;
        SalesHeader.Validate("Payment Discount %", PmtDiscount);
        PmtDiscountDate := CalcDate('<1W>', SalesHeader."Posting Date");
        SalesHeader.Validate("Pmt. Discount Date", PmtDiscountDate);
        SalesHeader.Modify(true);

        CreateSalesLine(SalesHeader, SalesLine1, SalesLine1.Type::"G/L Account", GLAccountUsed, Quantity1, LinePrice1, LineDisc);
        SalesLine1.Validate("Allow Invoice Disc.", true);
        SalesLine1.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LineDisc := LineDisc / 100;
        InvDisc := InvDisc / 100;
        TotalLineAmt := LinePrice1 * Quantity1;
        TotalLineDisc := TotalLineAmt * LineDisc;
        TotalInvDiscount := TotalLineAmt * (1 - LineDisc) * InvDisc;
        TotalInvAmount := (TotalLineAmt - TotalLineDisc) * (1 - InvDisc);
        PmtDiscAmount := Round(TotalInvAmount * PmtDiscount / 100, 1 / 100, '=');
        PayAmount := TotalInvAmount - PmtDiscAmount;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 4, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 4, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, DiffSalesInvDiscAcc, TotalInvDiscount);
        ValidateGLEntry(GLRegister, SalesLineDiscAcc1, TotalLineDisc);
        ValidateGLEntry(GLRegister, GLAccountUsed, -TotalLineAmt);
        ValidateGLEntry(GLRegister, ReceivableAcc, TotalInvAmount);

        // Validate No of VAT entry
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 3, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 3, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, TotalInvDiscount, 0, 0);
        ValidateVATEntry(GLRegister, TotalLineDisc, 0, 0);
        ValidateVATEntry(GLRegister, -TotalLineAmt, 0, 0);

        // Step 2: Post payment and apply to invoice
        Post_Payment_And_Apply(JournalTemplate, JournalBatch, 'Customer', Customer."No.", -PayAmount, 'Payment', BankAcc, PmtDiscountDate);
        PmtDiscount := PmtDiscount / 100;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, GLBankAccNo, PayAmount);
        ValidateGLEntry(GLRegister, ReceivableAcc, -TotalInvAmount);
        ValidateGLEntry(GLRegister, SalesPmtDiscDebitAcc, PmtDiscAmount);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 3, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 3, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, Round(-TotalInvDiscount * PmtDiscount), 0, 0);
        ValidateVATEntry(GLRegister, Round(-TotalLineDisc * PmtDiscount), 0, 0);
        ValidateVATEntry(GLRegister, PmtDiscAmount + Round(TotalLineDisc * PmtDiscount) + Round(TotalInvDiscount * PmtDiscount), 0, 0);

        // test cleanup
        VatPostingSetup.SetRange("VAT Calculation Type", VatPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VatPostingSetup.SetFilter("VAT %", '<>0');
        VatPostingSetup.FindFirst();
        VatPostingSetup.Validate("Adjust for Payment Discount", false);
        VatPostingSetup.Modify(true);

        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", OrigSalesInvDiscAcc);
        GeneralPostingSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_59013_Purch()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATpostingSetup: Record "VAT Posting Setup";
        GLRegister: Record "G/L Register";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        PayAmount: Decimal;
        VATPct: Decimal;
        TotalLineDisc: Decimal;
        TotalLineDiscVAT: Decimal;
        TotalLineCost: Decimal;
        TotalLineVAT: Decimal;
        TotalInvDiscount: Decimal;
        TotalInvDiscountVAT: Decimal;
        TotalInvAmount: Decimal;
        PmtDiscAmount: Decimal;
        PmtDiscount: Decimal;
        ReverseChrgVATAcc: Code[20];
        PurchPmtDiscDebitAcc: Code[20];
        PurchPmtDiscCreditAcc: Code[20];
        GLAccountUsed: Code[20];
        DiffPurchInvDiscAcc: Code[20];
        PurchVATAcc59013: Code[20];
        OrigPurchInvDiscAcc: Code[20];
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
        PmtDiscountDate: Date;
    begin
        // TFS DynamicsNAV60 Test Case ID 59013 :  Reverse Charge VAT - Pmt. Disc.Excl VAT(No) - Adjust for Payment Disc.(Yes)
        Initialize();
        GeneralSetup(false);
        BankSetup(BankAcc, GLBankAccNo);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        JournalSetup(JournalTemplate, JournalBatch);

        // Create GL account and use them on General Posting Setup
        LibraryERM.CreateGLAccount(GLAccount);
        DiffPurchInvDiscAcc := GLAccount."No.";
        LibraryERM.CreateGLAccount(GLAccount);
        PurchPmtDiscDebitAcc := GLAccount."No.";
        LibraryERM.CreateGLAccount(GLAccount);
        PurchPmtDiscCreditAcc := GLAccount."No.";

        // Find VAT Posting Setup for reverse charge
        FindReverseChargeVATPostSetup(VATpostingSetup, true);
        ReverseChrgVATAcc := VATpostingSetup."Reverse Chrg. VAT Acc.";
        PurchVATAcc59013 := VATpostingSetup."Purchase VAT Account";
        GLAccountUsed := LibraryERM.CreateGLAccountWithVATPostingSetup(VATpostingSetup, "General Posting Type"::" ");
        GLAccount.Get(GLAccountUsed);
        GenBusPostingGroup.Get(GLAccount."Gen. Bus. Posting Group");
        GenProdPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");

        GeneralPostingSetup.Get(GenBusPostingGroup.Code, GenProdPostingGroup.Code);
        OrigPurchInvDiscAcc := GeneralPostingSetup."Purch. Inv. Disc. Account";
        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", DiffPurchInvDiscAcc);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", PurchLineDiscAcc1);
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", PurchPmtDiscDebitAcc);
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", PurchPmtDiscCreditAcc);
        GeneralPostingSetup.Modify(true);

        InvDisc := 15;
        LineCost1 := 1000;
        Quantity1 := 1;
        LineDisc := 15;
        PmtDiscount := 5;

        CreateVendorwithVAT(Vendor, GenBusPostingGroup.Code, VATpostingSetup."VAT Bus. Posting Group", VendPostingGrp, InvDisc);

        // Step 1: Create a purchase invoice
        CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::Invoice, true);
        PurchHeader.Validate("Payment Discount %", PmtDiscount);
        PmtDiscountDate := CalcDate('<1W>', PurchHeader."Posting Date");
        PurchHeader.Validate("Pmt. Discount Date", PmtDiscountDate);
        PurchHeader.Modify(true);

        CreatePurchLine(PurchHeader, PurchLine1, PurchLine1.Type::"G/L Account", GLAccountUsed, Quantity1, LineCost1, LineDisc);
        PurchLine1.Validate("Allow Invoice Disc.", true);
        PurchLine1.Modify(true);

        VATpostingSetup.Get(PurchLine1."VAT Bus. Posting Group", PurchLine1."VAT Prod. Posting Group");
        VATPct := VATpostingSetup."VAT %" / 100;

        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        InvDisc := InvDisc / 100;
        LineDisc := LineDisc / 100;
        TotalLineCost := LineCost1 * Quantity1;
        TotalLineVAT := TotalLineCost * VATPct;
        TotalLineDisc := TotalLineCost * LineDisc;
        TotalLineDiscVAT := TotalLineDisc * VATPct;
        TotalInvDiscount := TotalLineCost * (1 - LineDisc) * InvDisc;
        TotalInvDiscountVAT := TotalInvDiscount * VATPct;
        TotalInvAmount := (TotalLineCost - TotalLineDisc) * (1 - InvDisc);
        PmtDiscAmount := Round(TotalInvAmount * PmtDiscount / 100, 1 / 100, '=');
        PayAmount := TotalInvAmount - PmtDiscAmount;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 10, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 10, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, DiffPurchInvDiscAcc, -TotalInvDiscount);
        ValidateGLEntry(GLRegister, PurchVATAcc59013, Round(-TotalInvDiscountVAT, LibraryERM.GetAmountRoundingPrecision()));
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, Round(TotalInvDiscountVAT, LibraryERM.GetAmountRoundingPrecision()));
        ValidateGLEntry(GLRegister, PurchLineDiscAcc1, -TotalLineDisc);
        ValidateGLEntry(GLRegister, PurchVATAcc59013, -TotalLineDiscVAT);
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, TotalLineDiscVAT);
        ValidateGLEntry(GLRegister, GLAccountUsed, TotalLineCost);
        ValidateGLEntry(GLRegister, PurchVATAcc59013, TotalLineVAT);
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, -TotalLineVAT);
        ValidateGLEntry(GLRegister, PayableAcc, -TotalInvAmount);

        // Validate No of VAT entry
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 3, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 3, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, -TotalInvDiscount, Round(-TotalInvDiscountVAT, LibraryERM.GetAmountRoundingPrecision()), 0);
        ValidateVATEntry(GLRegister, -TotalLineDisc, -TotalLineDiscVAT, 0);
        ValidateVATEntry(GLRegister, TotalLineCost, TotalLineVAT, 0);

        // Step 2: post payment and apply to invoice
        Post_Payment_And_Apply(JournalTemplate, JournalBatch, 'Vendor', Vendor."No.", PayAmount, 'Payment', BankAcc, PmtDiscountDate);
        PmtDiscount := PmtDiscount / 100;

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 9, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 9, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, GLBankAccNo, -PayAmount);
        ValidateGLEntry(GLRegister, PurchVATAcc59013, Round(TotalInvDiscountVAT * PmtDiscount, LibraryERM.GetAmountRoundingPrecision()));
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, -Round(TotalInvDiscountVAT * PmtDiscount));
        ValidateGLEntry(GLRegister, PurchVATAcc59013, Round(TotalLineDiscVAT * PmtDiscount));
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, -Round(TotalLineDiscVAT * PmtDiscount));
        ValidateGLEntry(GLRegister, PurchVATAcc59013, -Round(TotalLineVAT * PmtDiscount));
        ValidateGLEntry(GLRegister, ReverseChrgVATAcc, Round(TotalLineVAT * PmtDiscount));
        ValidateGLEntry(GLRegister, PayableAcc, TotalInvAmount);
        ValidateGLEntry(GLRegister, PurchPmtDiscCreditAcc, -PmtDiscAmount);

        // Validate VAT enntry and link
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 3, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 3, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, Round(TotalInvDiscount * PmtDiscount),
          Round(TotalInvDiscount * PmtDiscount * VATPct, LibraryERM.GetAmountRoundingPrecision()), 0);
        ValidateVATEntry(GLRegister, Round(TotalLineDisc * PmtDiscount), Round(Round(TotalLineDisc * PmtDiscount) * VATPct), 0);
        ValidateVATEntry(GLRegister, -PmtDiscAmount - Round(TotalLineDisc * PmtDiscount) - Round(TotalInvDiscount * PmtDiscount),
          -Round(Round(TotalLineCost * PmtDiscount) * VATPct), 0);

        // test cleanup
        VATpostingSetup.SetRange("VAT Calculation Type", VATpostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATpostingSetup.SetFilter("VAT %", '<>0');
        VATpostingSetup.FindFirst();
        VATpostingSetup.Validate("Adjust for Payment Discount", false);
        VATpostingSetup.Modify(true);

        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", OrigPurchInvDiscAcc);
        GeneralPostingSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58822_Substract_Y()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        DepreciationBook: Record "Depreciation Book";
        GLAccount: Record "G/L Account";
        LineAmt: Decimal;
        VATPct: Decimal;
        LineCost: Decimal;
        Quantity: Integer;
        LineVAT: Decimal;
        LineDiscAmount: Decimal;
        LineDiscVAT: Decimal;
        PurchaseFADiscAcc: Code[20];
        AssetNo: Code[20];
        AcquisitionCostAcc: Code[20];
    begin
        // TFS DynamicsNAV60 Test Case ID 58822 :  invoice discount + line discount - Purchase Fixed Asset
        Initialize();
        GeneralSetup(false);
        S_58822_FASetup(AssetNo, AcquisitionCostAcc);

        CreateVendor(Vendor, GenBusPostingGrp, VendPostingGrp, 0);

        LibraryERM.CreateGLAccount(GLAccount);
        PurchaseFADiscAcc := GLAccount."No.";
        GeneralPostingSetup.ModifyAll("Purch. FA Disc. Account", PurchaseFADiscAcc, true);
        DepreciationBook.ModifyAll("Subtract Disc. in Purch. Inv.", true, true);

        // Create a purchase invoice
        CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::Invoice, false);
        LineCost := 1000;
        LineDisc := 15;
        Quantity := 1;
        CreatePurchLine(PurchHeader, PurchLine, PurchLine.Type::"Fixed Asset", AssetNo, Quantity, LineCost, LineDisc);
        VATPct := PurchLine."VAT %" / 100; // Get VAT% on the line
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        PurchLineDiscAcc1 := GeneralPostingSetup."Purch. Line Disc. Account";

        // Post
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        GLRegister.FindLast();

        LineDisc := LineDisc / 100;
        LineAmt := LineCost * Quantity;
        LineVAT := LineAmt * VATPct;
        LineDiscAmount := LineAmt * LineDisc;
        LineDiscVAT := LineDiscAmount * VATPct;

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 9, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 9, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, AcquisitionCostAcc, LineAmt);
        ValidateGLEntry(GLRegister, PurchVATAcc, LineVAT);
        ValidateGLEntry(GLRegister, AcquisitionCostAcc, -LineDiscAmount);
        ValidateGLEntry(GLRegister, PurchVATAcc, -LineDiscVAT);
        ValidateGLEntry(GLRegister, PurchaseFADiscAcc, LineDiscAmount);
        ValidateGLEntry(GLRegister, PurchVATAcc, LineDiscVAT);
        ValidateGLEntry(GLRegister, PurchLineDiscAcc1, -LineDiscAmount);
        ValidateGLEntry(GLRegister, PurchVATAcc, -LineDiscVAT);
        ValidateGLEntry(GLRegister, PayableAcc, -LineAmt * (1 - LineDisc) * (1 + VATPct));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 4, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 4, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, LineAmt, LineVAT, 0);
        ValidateVATEntry(GLRegister, -LineDiscAmount, -LineDiscVAT, 0);
        ValidateVATEntry(GLRegister, LineDiscAmount, LineDiscVAT, 0);
        ValidateVATEntry(GLRegister, -LineDiscAmount, -LineDiscVAT, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58822_Substract_N()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        GLAccount: Record "G/L Account";
        DepreciationBook: Record "Depreciation Book";
        LineAmt: Decimal;
        VATPct: Decimal;
        LineCost: Decimal;
        Quantity: Integer;
        LineVAT: Decimal;
        LineDiscAmount: Decimal;
        LineDiscVAT: Decimal;
        PurchaseFADiscAcc: Code[20];
        AssetNo: Code[20];
        AcquisitionCostAcc: Code[20];
    begin
        // TFS DynamicsNAV60 Test Case ID 58822 :  invoice discount + line discount - Purchase Fixed Asset
        Initialize();
        GeneralSetup(false);
        S_58822_FASetup(AssetNo, AcquisitionCostAcc);

        CreateVendor(Vendor, GenBusPostingGrp, VendPostingGrp, 0);
        LibraryERM.CreateGLAccount(GLAccount);
        PurchaseFADiscAcc := GLAccount."No.";
        GeneralPostingSetup.ModifyAll("Purch. FA Disc. Account", PurchaseFADiscAcc, true);
        DepreciationBook.ModifyAll("Subtract Disc. in Purch. Inv.", false, true);

        // Create a purchase invoice
        CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::Invoice, false);
        LineCost := 1000;
        LineDisc := 15;
        Quantity := 1;
        CreatePurchLine(PurchHeader, PurchLine, PurchLine.Type::"Fixed Asset", AssetNo, Quantity, LineCost, LineDisc);
        VATPct := PurchLine."VAT %" / 100; // Get VAT% on the line
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        PurchLineDiscAcc1 := GeneralPostingSetup."Purch. Line Disc. Account";

        // Post
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Validate No of GL entries
        GLRegister.FindLast();

        LineDisc := LineDisc / 100;
        LineAmt := LineCost * Quantity;
        LineVAT := LineAmt * VATPct;
        LineDiscAmount := LineAmt * LineDisc;
        LineDiscVAT := LineDiscAmount * VATPct;

        // Validate No of GL entry
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 5, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 5, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, AcquisitionCostAcc, LineAmt);
        ValidateGLEntry(GLRegister, PurchVATAcc, LineVAT);
        ValidateGLEntry(GLRegister, PurchLineDiscAcc1, -LineDiscAmount);
        ValidateGLEntry(GLRegister, PurchVATAcc, -LineDiscVAT);
        ValidateGLEntry(GLRegister, PayableAcc, -LineAmt * (1 - LineDisc) * (1 + VATPct));

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 2, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 2, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, LineAmt, LineVAT, 0);
        ValidateVATEntry(GLRegister, -LineDiscAmount, -LineDiscVAT, 0);
    end;

    local procedure S_58822_FASetup(var AssetNo: Code[20]; var AcquisitionCostAcc: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FindFixedAsset(FixedAsset);
        AssetNo := FixedAsset."No.";
        FADepreciationBook.SetRange("FA No.", AssetNo);
        FADepreciationBook.FindFirst();
        FindFAPostingGroup(FAPostingGroup, FADepreciationBook."FA Posting Group");
        AcquisitionCostAcc := FAPostingGroup."Acquisition Cost Account";
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58849_Normal()
    var
        Vendor: Record Vendor;
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        LineAmt: Decimal;
        VATPct: Decimal;
        PurchaseVATAcc: Code[20];
        VATBusPostingGroup: Code[20];
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
    begin
        // TFS DynamicsNAV60 Test Case ID 58849 :  Full VAT
        Initialize();
        GeneralSetup(false);
        JournalSetup(JournalTemplate, JournalBatch);

        CreateVendor(Vendor, GenBusPostingGrp, VendPostingGrp, 0);
        CreateVATProdPostingGroup(VATProdPostingGroup);

        // Find VAT Bus Posting Group through Gen Bus Posting Group
        GenBusPostingGroup.SetRange(Code, GenBusPostingGrp);
        GenBusPostingGroup.FindFirst();
        VATBusPostingGroup := GenBusPostingGroup."Def. VAT Bus. Posting Group";

        // Create GL account to be used as purchase VAT account
        LibraryERM.CreateGLAccount(GLAccount);
        PurchaseVATAcc := GLAccount."No.";
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup.Code);
        GLAccount.Modify(true);

        // Create new VAT Posting Setup
        VATPct := 100;
        CreateVATPostingSetup(VATPostingSetup,
          VATBusPostingGroup, VATProdPostingGroup.Code, VATPostingSetup."VAT Calculation Type"::"Full VAT", VATPct);
        VATPostingSetup.Validate("Purchase VAT Account", PurchaseVATAcc);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.Modify(true);

        // Create a general journal Line
        LineAmt := 1000;
        CreateJournalLine(GenJournalLine,
          JournalTemplate, JournalBatch, GenJournalLine."Account Type"::"G/L Account", PurchaseVATAcc, WorkDate(),
          GenJournalLine."Document Type"::Invoice, LineAmt, GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLRegister.FindLast();
        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, PurchaseVATAcc, 0);
        ValidateGLEntry(GLRegister, PurchaseVATAcc, LineAmt);
        ValidateGLEntry(GLRegister, PayableAcc, -LineAmt);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 1, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 1, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, 0, LineAmt, 0);

        VATProdPostingGroup.Delete(true);
    end;

    [Test]
    [HandlerFunctions('HandleConform,MessageHandler')]
    [Scope('OnPrem')]
    procedure S_58849_Unrealized()
    var
        Vendor: Record Vendor;
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        LineAmt: Decimal;
        VATPct: Decimal;
        UnrealizedVATEntryNo: Integer;
        RegisterNo: Integer;
        PurchaseVATAcc: Code[20];
        UnrealVATPurchAcc: Code[20];
        VATBusPostingGroup: Code[20];
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
    begin
        // TFS DynamicsNAV60 Test Case ID 58849 :  Full VAT
        Initialize();
        GeneralSetup(false);
        BankSetup(BankAcc, GLBankAccNo);
        JournalSetup(JournalTemplate, JournalBatch);

        // Setup unrealized VAT
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", true);
        GeneralLedgerSetup.Modify(true);

        CreateVendor(Vendor, GenBusPostingGrp, VendPostingGrp, 0);

        // Find VAT Bus Posting Group through Gen Bus Posting Group
        GenBusPostingGroup.SetRange(Code, GenBusPostingGrp);
        GenBusPostingGroup.FindFirst();
        VATBusPostingGroup := GenBusPostingGroup."Def. VAT Bus. Posting Group";

        // Create VAT product group Full
        CreateVATProdPostingGroup(VATProdPostingGroup);

        // Create GL account 5615 to be used as unrealized purchase VAT account
        LibraryERM.CreateGLAccount(GLAccount);
        UnrealVATPurchAcc := GLAccount."No.";

        // Create GL account 5640 to be used as purchase VAT account
        LibraryERM.CreateGLAccount(GLAccount);
        PurchaseVATAcc := GLAccount."No.";
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup.Code);
        GLAccount.Modify(true);

        // Create new VAT Posting Setup
        VATPct := 100;
        CreateVATPostingSetup(VATPostingSetup,
          VATBusPostingGroup, VATProdPostingGroup.Code, VATPostingSetup."VAT Calculation Type"::"Full VAT", VATPct);
        VATPostingSetup.Validate("Purchase VAT Account", PurchaseVATAcc);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", UnrealVATPurchAcc);
        VATPostingSetup.Modify(true);

        // Step1:  Create a general journal Line invoice
        LineAmt := 1000;
        GenJournalLine.Init();
        GenJournalLine.DeleteAll();
        CreateJournalLine(GenJournalLine,
          JournalTemplate, JournalBatch, GenJournalLine."Account Type"::"G/L Account", PurchaseVATAcc, WorkDate(),
          GenJournalLine."Document Type"::Invoice, LineAmt, GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLRegister.FindLast();
        // Get register Entry No. for later reversal
        RegisterNo := GLRegister."No.";

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, PurchaseVATAcc, 0);
        ValidateGLEntry(GLRegister, UnrealVATPurchAcc, LineAmt);
        ValidateGLEntry(GLRegister, PayableAcc, -LineAmt);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 1, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 1, VATEntry.Count));

        // For validation of unrealized VAT
        VATEntry.FindFirst();
        UnrealizedVATEntryNo := VATEntry."Entry No.";
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, 0, 0, 0);

        // Step 2: Create a general journal line payment and apply to above invoice
        Commit();
        CreateJournalLine(GenJournalLine,
          JournalTemplate, JournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.", WorkDate(),
          GenJournalLine."Document Type"::Payment, LineAmt, GenJournalLine."Bal. Account Type"::"Bank Account", BankAcc);
        VendLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgerEntry.FindLast();
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 4, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 4, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, GLBankAccNo, -LineAmt);
        ValidateGLEntry(GLRegister, UnrealVATPurchAcc, -LineAmt);
        ValidateGLEntry(GLRegister, PurchaseVATAcc, LineAmt);
        ValidateGLEntry(GLRegister, PayableAcc, LineAmt);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 1, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 1, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, 0, LineAmt, UnrealizedVATEntryNo);

        // Step3: Unapply payment and Invoice
        VendLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgerEntry.FindLast();
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgerEntry."Entry No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.FindLast();
        ApplyUnapplyParameters."Document No." := VendLedgerEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := VendLedgerEntry."Posting Date";
        VendEntryApplyPostedEntries.PostUnApplyVendor(DtldVendLedgEntry, ApplyUnapplyParameters);

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 2, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 2, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, UnrealVATPurchAcc, LineAmt);
        ValidateGLEntry(GLRegister, PurchaseVATAcc, -LineAmt);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 1, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 1, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, 0, -LineAmt, UnrealizedVATEntryNo);

        // Step 4: Reverse invoice
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(RegisterNo);

        GLRegister.FindLast();

        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, PayableAcc, LineAmt);
        ValidateGLEntry(GLRegister, UnrealVATPurchAcc, -LineAmt);
        ValidateGLEntry(GLRegister, PurchaseVATAcc, 0);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 1, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 1, VATEntry.Count));
        // Validate base and VAT Amount on VAT entry and VAT link
        ValidateVATEntry(GLRegister, 0, 0, UnrealizedVATEntryNo);

        // Test Cleanup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Unrealized VAT" := false;
        GeneralLedgerSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58923_Sales()
    var
        Customer: Record Customer;
        PayDiscAmount: Decimal;
        InvoiceAmount: Decimal;
        Payamount: Decimal;
        InvoiceAmountExclVAT: Decimal;
        LineAmtExclDisc1: Decimal;
        LineAmtExclDisc2: Decimal;
        PmtDiscount: Decimal;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
        PmtDiscountDate: Date;
    begin
        // TFS DynamicsNAV60 Test Case ID 58923 :  Normal VAT - Payment discount + Pmt. Disc. Excl. VAT( Yes)
        Initialize();
        GeneralSetup(true);
        BankSetup(BankAcc, GLBankAccNo);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(true);
        JournalSetup(JournalTemplate, JournalBatch);

        DataSetup_Sales_PayDisc(Customer, 'Invoice', false, 15, 0, Item1, Item3, PmtDiscount, PmtDiscountDate);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;
        LineAmtExclDisc1 := LineAmt1 * (1 - LineDisc);
        LineAmtExclDisc2 := LineAmt2 * (1 - LineDisc);
        InvoiceAmountExclVAT := LineAmtExclDisc1 + LineAmtExclDisc2;
        InvoiceAmount := LineAmtExclDisc1 * (1 + VATPct1) + LineAmtExclDisc2 * (1 + VATPct2);
        PayDiscAmount := InvoiceAmountExclVAT * PmtDiscount;
        Payamount := InvoiceAmount - PayDiscAmount;

        // Post payment and apply to invoice
        Post_Payment_And_Apply(JournalTemplate, JournalBatch, 'Customer', Customer."No.", -Payamount, 'Payment', BankAcc, PmtDiscountDate);

        S_58923_Validate(Payamount, InvoiceAmount, PayDiscAmount, GLBankAccNo, ReceivableAcc, CustPmtDiscDebitAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58923_Purch()
    var
        Vendor: Record Vendor;
        PayDiscAmount: Decimal;
        InvoiceAmount: Decimal;
        Payamount: Decimal;
        InvoiceAmountExclVAT: Decimal;
        LineAmtExclDisc1: Decimal;
        LineAmtExclDisc2: Decimal;
        PmtDiscount: Decimal;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
        PmtDiscountDate: Date;
    begin
        // TFS DynamicsNAV60 Test Case ID 58923 :  Normal VAT - Payment discount + Pmt. Disc. Excl. VAT( Yes)
        Initialize();
        GeneralSetup(true);
        BankSetup(BankAcc, GLBankAccNo);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(true);
        JournalSetup(JournalTemplate, JournalBatch);
        DataSetup_Purch_PayDisc(Vendor, 'Credit Memo', false, 15, 0, Item1, Item3, PmtDiscount, PmtDiscountDate);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;
        LineAmtExclDisc1 := LineAmt1 * (1 - LineDisc);
        LineAmtExclDisc2 := LineAmt2 * (1 - LineDisc);
        InvoiceAmountExclVAT := LineAmtExclDisc1 + LineAmtExclDisc2;
        InvoiceAmount := LineAmtExclDisc1 * (1 + VATPct1) + LineAmtExclDisc2 * (1 + VATPct2);
        PayDiscAmount := InvoiceAmountExclVAT * PmtDiscount;
        Payamount := InvoiceAmount - PayDiscAmount;

        // Post refund and apply to credit memo
        Post_Payment_And_Apply(JournalTemplate, JournalBatch, 'Vendor', Vendor."No.", -Payamount, 'Refund', BankAcc, PmtDiscountDate);

        S_58923_Validate(Payamount, InvoiceAmount, PayDiscAmount, GLBankAccNo, PayableAcc, VendPmtDiscDebitAcc);
    end;

    local procedure S_58923_Validate(PayAmount: Decimal; InvAmount: Decimal; PayDiscAmount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, PayAmount);
        ValidateGLEntry(GLRegister, Account2, -InvAmount);
        ValidateGLEntry(GLRegister, Account3, PayDiscAmount);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 0, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 0, VATEntry.Count));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58931_Sales()
    var
        Customer: Record Customer;
        PayDiscAmount: Decimal;
        Payamount: Decimal;
        LineAmtExclDisc1: Decimal;
        LineAmtExclDisc2: Decimal;
        InvoiceAmount: Decimal;
        PmtDiscount: Decimal;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
        PmtDiscountDate: Date;
    begin
        // TFS DynamicsNAV60 Test Case ID 58931 :
        // Normal VAT - Payment discount + Pmt. Disc. Excl. VAT( No) + Adjust for Payment Disc(No).
        Initialize();
        GeneralSetup(true);
        BankSetup(BankAcc, GLBankAccNo);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        JournalSetup(JournalTemplate, JournalBatch);
        DataSetup_Sales_PayDisc(Customer, 'Credit Memo', false, 15, 0, Item1, Item3, PmtDiscount, PmtDiscountDate);

        LineAmt1 := LinePrice1 * Quantity1;
        LineAmt2 := LinePrice2 * Quantity2;
        LineAmtExclDisc1 := LineAmt1 * (1 - LineDisc);
        LineAmtExclDisc2 := LineAmt2 * (1 - LineDisc);
        InvoiceAmount := Round(LineAmtExclDisc1 * (1 + VATPct1) + LineAmtExclDisc2 * (1 + VATPct2), 1 / 100, '=');
        PayDiscAmount := Round(InvoiceAmount * PmtDiscount, 1 / 100, '=');
        Payamount := InvoiceAmount - PayDiscAmount;

        // Post refund and apply to credit memo
        Post_Payment_And_Apply(JournalTemplate, JournalBatch, 'Customer', Customer."No.", Payamount, 'Refund', BankAcc, PmtDiscountDate);

        S_58931_Validate(Payamount, InvoiceAmount, PayDiscAmount, GLBankAccNo, ReceivableAcc, CustPmtDiscCreditAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S_58931_Purch()
    var
        Vendor: Record Vendor;
        InvoiceAmount: Decimal;
        PayDiscAmount: Decimal;
        Payamount: Decimal;
        LineAmtExclDisc1: Decimal;
        LineAmtExclDisc2: Decimal;
        PmtDiscount: Decimal;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        BankAcc: Code[20];
        GLBankAccNo: Code[20];
        PmtDiscountDate: Date;
    begin
        // TFS DynamicsNAV60 Test Case ID 58931 :
        // Normal VAT - Payment discount + Pmt. Disc. Excl. VAT( No) + Adjust for Payment Disc(No).
        Initialize();
        GeneralSetup(true);
        BankSetup(BankAcc, GLBankAccNo);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        JournalSetup(JournalTemplate, JournalBatch);
        DataSetup_Purch_PayDisc(Vendor, 'Invoice', false, 15, 0, Item1, Item3, PmtDiscount, PmtDiscountDate);

        LineAmt1 := LineCost1 * Quantity1;
        LineAmt2 := LineCost2 * Quantity2;
        LineAmtExclDisc1 := LineAmt1 * (1 - LineDisc);
        LineAmtExclDisc2 := LineAmt2 * (1 - LineDisc);
        InvoiceAmount := Round(LineAmtExclDisc1 * (1 + VATPct1) + LineAmtExclDisc2 * (1 + VATPct2), 1 / 100, '=');
        PayDiscAmount := Round(InvoiceAmount * PmtDiscount, 1 / 100, '=');
        Payamount := InvoiceAmount - PayDiscAmount;

        // Post payment and apply to invoice
        Post_Payment_And_Apply(JournalTemplate, JournalBatch, 'Vendor', Vendor."No.", Payamount, 'Payment', BankAcc, PmtDiscountDate);

        S_58931_Validate(Payamount, InvoiceAmount, PayDiscAmount, GLBankAccNo, PayableAcc, VendPmtDiscCreditAcc);
    end;

    local procedure S_58931_Validate(PayAmount: Decimal; Invamount: Decimal; PayDiscAmount: Decimal; Account1: Text[20]; Account2: Text[20]; Account3: Text[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        // Validate No of GL entries
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.IsTrue(GLEntry.Count = 3, StrSubstNo(TotalEntryNumberError, GLEntry.TableName, 3, GLEntry.Count));
        // Validate account and amount on GL entries
        ValidateGLEntry(GLRegister, Account1, -PayAmount);
        ValidateGLEntry(GLRegister, Account2, Invamount);
        ValidateGLEntry(GLRegister, Account3, -PayDiscAmount);

        // Validate No of VAT entries
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        Assert.IsTrue(VATEntry.Count = 0, StrSubstNo(TotalEntryNumberError, VATEntry.TableName, 0, VATEntry.Count));
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; DocType: Enum "Sales Document Type"; InclVAT: Boolean)
    begin
        // Create Sales header, return document No
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        if InclVAT then
            SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal; LineDisc: Decimal)
    begin
        // Create Sales Line
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", LineDisc);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; var Vendor: Record Vendor; DocType: Enum "Purchase Document Type"; InclVAT: Boolean)
    begin
        // Create Purchases header, return document No
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, Vendor."No.");
        if InclVAT then
            PurchHeader.Validate("Prices Including VAT", true);
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; UnitCost: Decimal; LineDisc: Decimal)
    begin
        // Create Purchases Line
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Type, No, Quantity);
        PurchLine.Validate("Direct Unit Cost", UnitCost);
        PurchLine.Validate("Line Discount %", LineDisc);
        PurchLine.Validate("Prepayment %", PurchLine."Prepayment %");
        PurchLine.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; var Customer: Record Customer; DocType: Enum "Service Document Type"; InclVAT: Boolean)
    begin
        // Create Service header, return document No
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, Customer."No.");
        ServiceHeader.Validate("Posting Date", WorkDate());
        if InclVAT then
            ServiceHeader.Validate("Prices Including VAT", true);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; Type: Enum "Service Line Type"; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal; LineDisc: Decimal)
    begin
        // Create Service Line
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, ItemNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Validate("Line Discount %", LineDisc);
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; GenBusPostingGroup: Code[20]; CustomerPostingGroup: Code[20]; InvDiscount: Decimal)
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        LibrarySales.CreateCustomer(Customer);
        if Customer."Gen. Bus. Posting Group" <> GenBusPostingGroup then
            Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        if Customer."VAT Bus. Posting Group" <> VATPostingGrp then
            Customer."VAT Bus. Posting Group" := VATPostingGrp;
        if Customer."Customer Posting Group" <> CustomerPostingGroup then
            Customer.Validate("Customer Posting Group", CustomerPostingGroup);
        Customer.Modify(true);

        if InvDisc <> 0 then begin
            CustInvDisc.Init();
            CustInvDisc.Validate(Code, Customer."No.");
            CustInvDisc.Validate("Discount %", InvDiscount);
            CustInvDisc.Insert(true);
        end;
    end;

    local procedure CreateCustomerwithVAT(var Customer: Record Customer; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; CustomerPostingGroup: Code[20]; InvDiscount: Decimal)
    begin
        CreateCustomer(Customer, GenBusPostingGroup, CustomerPostingGroup, InvDiscount);

        if Customer."VAT Bus. Posting Group" <> VATBusPostingGroup then
            Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; GenBusPostingGroup: Code[20]; VendorPostingGroup: Code[20]; InvDiscount: Decimal)
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if Vendor."Gen. Bus. Posting Group" <> GenBusPostingGroup then
            Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        if Vendor."VAT Bus. Posting Group" <> VATPostingGrp then
            Vendor."VAT Bus. Posting Group" := VATPostingGrp;
        if Vendor."Vendor Posting Group" <> VendorPostingGroup then
            Vendor.Validate("Vendor Posting Group", VendorPostingGroup);
        Vendor.Modify(true);

        if InvDisc <> 0 then begin
            VendInvDisc.Init();
            VendInvDisc.Validate(Code, Vendor."No.");
            VendInvDisc.Validate("Discount %", InvDiscount);
            VendInvDisc.Insert(true);
        end;
    end;

    local procedure CreateVendorwithVAT(var Vendor: Record Vendor; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; VendorPostingGroup: Code[20]; InvDiscount: Decimal)
    begin
        CreateVendor(Vendor, GenBusPostingGroup, VendorPostingGroup, InvDiscount);

        if Vendor."VAT Bus. Posting Group" <> VATBusPostingGroup then
            Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        ItemRec: Record Item;
    begin
        LibraryInventory.CreateItem(ItemRec);
        ItemRec.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemRec.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemRec.Modify(true);

        exit(ItemRec."No.");
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms"; DueDateCal: Text[30]; DiscDateCal: Text[30]; Discount: Decimal; Choice: Boolean)
    var
        PaymentTermsCode: Code[10];
        DueDate: DateFormula;
        DiscDate: DateFormula;
    begin
        PaymentTerms.Init();
        repeat
            PaymentTermsCode := Format(LibraryRandom.RandInt(2147483647)) // max int
        until not PaymentTerms.Get(PaymentTermsCode);
        PaymentTerms.Validate(Code, PaymentTermsCode);
        PaymentTerms.Insert(true);
        Evaluate(DueDate, DueDateCal);
        Evaluate(DiscDate, DiscDateCal);
        PaymentTerms.Validate("Due Date Calculation", DueDate);
        PaymentTerms.Validate("Discount Date Calculation", DiscDate);
        PaymentTerms.Validate("Discount %", Discount);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", Choice);
        PaymentTerms.Modify(true);
    end;

    local procedure CreateVATProdPostingGroup(var VATProdPostingGroup: Record "VAT Product Posting Group")
    begin
        VATProdPostingGroup.Init();
        VATProdPostingGroup.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(VATProdPostingGroup.FieldNo(Code), DATABASE::"VAT Product Posting Group"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"VAT Product Posting Group", VATProdPostingGroup.FieldNo(Code))));
        VATProdPostingGroup.Insert(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATCalType: Enum "Tax Calculation Type"; VATPct: Decimal)
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        if not VATPostingSetup.FindFirst() then begin
            VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
            VATPostingSetup.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            VATPostingSetup.Insert(true);
            VATPostingSetup.Validate("VAT Calculation Type", VATCalType);
            VATPostingSetup.Validate("VAT %", VATPct);
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JnlTemplate: Code[10]; JnlBatch: Code[10]; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; PostingDate: Date; DocType: Enum "Gen. Journal Document Type"; Amount: Decimal; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, JnlTemplate, JnlBatch, DocType, AccType, AccNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", BalAccType);
        GenJournalLine.Validate("Bal. Account No.", BalAccNo);
        GenJournalLine.Modify(true);
    end;

    local procedure DataSetup_Purch(DocType: Text[30]; InclVAT: Boolean; LineDis: Decimal; InvDis: Decimal; ItemNo1: Code[20]; ItemNo2: Code[20])
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
    begin
        // Create Vendor
        InvDisc := InvDis;
        CreateVendor(Vendor, GenBusPostingGrp, VendPostingGrp, InvDisc);

        // Create purchases header
        if DocType = 'Invoice' then
            CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::Invoice, InclVAT);
        if DocType = 'Credit Memo' then
            CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::"Credit Memo", InclVAT);

        // Create purchases lines
        DocLineDataSetup('Purchase', InclVAT);
        LineDisc := LineDis;
        CreatePurchLine(PurchHeader, PurchLine1, PurchLine1.Type::Item, ItemNo1, Quantity1, LineCost1, LineDisc);
        VATPct1 := PurchLine1."VAT %" / 100; // Get VAT% on the line
        CreatePurchLine(PurchHeader, PurchLine2, PurchLine2.Type::Item, ItemNo2, Quantity2, LineCost2, LineDisc);
        VATPct2 := PurchLine2."VAT %" / 100; // Get VAT% on the line

        // Post purchases document
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure DataSetup_Purch_PayDisc(var Vendor: Record Vendor; DocType: Text[30]; InclVAT: Boolean; LineDis: Decimal; InvDis: Decimal; ItemNo1: Code[20]; ItemNo2: Code[20]; var PaymentDiscount: Decimal; var PmtDiscountDate: Date)
    var
        PaymentTerms: Record "Payment Terms";
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
    begin
        // Create Vendor
        InvDisc := InvDis;
        PaymentDiscount := 5;
        CreateVendor(Vendor, GenBusPostingGrp, VendPostingGrp, InvDisc);

        // Create purchases header
        if DocType = 'Invoice' then begin
            CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::Invoice, InclVAT);
            // Setup Payment Discount
            PurchHeader.Validate("Payment Discount %", PaymentDiscount);
            PmtDiscountDate := CalcDate('<1W>', PurchHeader."Posting Date");
            PurchHeader.Validate("Pmt. Discount Date", PmtDiscountDate);
            PurchHeader.Modify(true);
        end;

        if DocType = 'Credit Memo' then begin
            CreatePaymentTerms(PaymentTerms, '1M', '1W', PaymentDiscount, true);
            CreatePurchHeader(PurchHeader, Vendor, PurchHeader."Document Type"::"Credit Memo", InclVAT);
            // Setup Payment Discount
            PurchHeader.Validate("Payment Terms Code", PaymentTerms.Code);
            PurchHeader.Modify(true);
            PmtDiscountDate := PurchHeader."Pmt. Discount Date";
        end;

        // Create purchases lines
        DocLineDataSetup('Purchase', InclVAT);
        LineDisc := LineDis;
        CreatePurchLine(PurchHeader, PurchLine1, PurchLine1.Type::Item, ItemNo1, Quantity1, LineCost1, LineDisc);
        VATPct1 := PurchLine1."VAT %" / 100; // Get VAT% on the line
        CreatePurchLine(PurchHeader, PurchLine2, PurchLine2.Type::Item, ItemNo2, Quantity2, LineCost2, LineDisc);
        VATPct2 := PurchLine2."VAT %" / 100; // Get VAT% on the line

        // Post purchases document
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        PaymentDiscount := PaymentDiscount / 100;
        LineDisc := LineDisc / 100;
    end;

    local procedure DataSetup_Sales(DocType: Text[30]; InclVAT: Boolean; LineDis: Decimal; InvDis: Decimal; ItemNo1: Code[20]; ItemNo2: Code[20])
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Create Customer
        InvDisc := InvDis;
        CreateCustomer(Customer, GenBusPostingGrp, CustPostingGrp, InvDisc);

        // Create sales header
        if DocType = 'Invoice' then
            CreateSalesHeader(SalesHeader, Customer, SalesHeader."Document Type"::Invoice, InclVAT);
        if DocType = 'Credit Memo' then
            CreateSalesHeader(SalesHeader, Customer, SalesHeader."Document Type"::"Credit Memo", InclVAT);

        // Create Sales lines
        DocLineDataSetup('Sales', InclVAT);
        LineDisc := LineDis;
        CreateSalesLine(SalesHeader, SalesLine1, SalesLine1.Type::Item, ItemNo1, Quantity1, LinePrice1, LineDisc);
        VATPct1 := SalesLine1."VAT %" / 100; // Get VAT% on the line
        CreateSalesLine(SalesHeader, SalesLine2, SalesLine2.Type::Item, ItemNo2, Quantity2, LinePrice2, LineDisc);
        VATPct2 := SalesLine2."VAT %" / 100; // Get VAT% on the line

        // Post sales document
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure DataSetup_Sales_PayDisc(var Customer: Record Customer; DocType: Text[30]; InclVAT: Boolean; LineDis: Decimal; InvDis: Decimal; ItemNo1: Code[20]; ItemNo2: Code[20]; var PaymentDiscount: Decimal; var PmtDiscountDate: Date)
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        InvDisc := InvDis;
        PaymentDiscount := 5;

        // Create Customer
        CreateCustomer(Customer, GenBusPostingGrp, CustPostingGrp, InvDisc);

        // Create sales header
        if DocType = 'Invoice' then begin
            CreateSalesHeader(SalesHeader, Customer, SalesHeader."Document Type"::Invoice, InclVAT);
            // Setup Payment Discount
            SalesHeader.Validate("Payment Discount %", PaymentDiscount);
            PmtDiscountDate := CalcDate('<1W>', SalesHeader."Posting Date");
            SalesHeader.Validate("Pmt. Discount Date", PmtDiscountDate);
            SalesHeader.Modify(true);
        end;

        if DocType = 'Credit Memo' then begin
            CreatePaymentTerms(PaymentTerms, '1M', '1W', PaymentDiscount, true);
            CreateSalesHeader(SalesHeader, Customer, SalesHeader."Document Type"::"Credit Memo", InclVAT);
            // Setup Payment Discount
            SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
            SalesHeader.Modify(true);
            PmtDiscountDate := SalesHeader."Pmt. Discount Date";
        end;

        // Create Sales lines
        DocLineDataSetup('Sales', InclVAT);
        LineDisc := LineDis;
        CreateSalesLine(SalesHeader, SalesLine1, SalesLine1.Type::Item, ItemNo1, Quantity1, LinePrice1, LineDisc);
        VATPct1 := SalesLine1."VAT %" / 100; // Get VAT% on the line
        CreateSalesLine(SalesHeader, SalesLine2, SalesLine2.Type::Item, ItemNo2, Quantity2, LinePrice2, LineDisc);
        VATPct2 := SalesLine2."VAT %" / 100; // Get VAT% on the line

        // Post sales document
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PaymentDiscount := PaymentDiscount / 100;
        LineDisc := LineDisc / 100;
    end;

    local procedure DataSetup_Service(DocType: Text[30]; InclVAT: Boolean; LineDis: Decimal; InvDis: Decimal; ItemNo1: Code[20]; ItemNo2: Code[20])
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine1: Record "Service Line";
        ServiceLine2: Record "Service Line";
    begin
        // Create Customer
        InvDisc := InvDis;
        CreateCustomer(Customer, GenBusPostingGrp, CustPostingGrp, InvDisc);

        // Create service header
        if DocType = 'Invoice' then
            CreateServiceHeader(ServiceHeader, Customer, ServiceHeader."Document Type"::Invoice, InclVAT);
        if DocType = 'Credit Memo' then
            CreateServiceHeader(ServiceHeader, Customer, ServiceHeader."Document Type"::"Credit Memo", InclVAT);
        DocLineDataSetup('Service', InclVAT);
        LineDisc := LineDis;
        CreateServiceLine(ServiceHeader, ServiceLine1, ServiceLine1.Type::Item, ItemNo1, Quantity1, LinePrice1, LineDisc);
        VATPct1 := ServiceLine1."VAT %" / 100; // Get VAT% on the line
        CreateServiceLine(ServiceHeader, ServiceLine2, ServiceLine2.Type::Item, ItemNo2, Quantity2, LinePrice2, LineDisc);
        VATPct2 := ServiceLine2."VAT %" / 100; // Get VAT% on the line

        // Post
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure DocLineDataSetup(DocType: Text[30]; InclVAT: Boolean)
    begin
        if (DocType = 'Sales') or (DocType = 'Service') then
            if InclVAT then begin
                LinePrice1 := 1250;
                LinePrice2 := 2500;
            end else begin
                LinePrice1 := 1000;
                LinePrice2 := 2000;
            end
        else
            if InclVAT then begin
                LineCost1 := 1250;
                LineCost2 := 2500;
            end else begin
                LineCost1 := 1000;
                LineCost2 := 2000;
            end;

        Quantity1 := 1;
        Quantity2 := 1;
    end;

    local procedure FindDefaultDim(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    begin
        Dimension.Reset();
        Dimension.SetRange(Blocked, false);
        Dimension.FindFirst();

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.FindFirst();
    end;

    local procedure FindLineDim(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value"; DimCode: Code[20])
    begin
        Dimension.Reset();
        Dimension.SetRange(Blocked, false);
        Dimension.SetFilter(Code, '<>' + DimCode);
        Dimension.FindFirst();

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.FindFirst();
    end;

    local procedure FindFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        FixedAsset.FindFirst();
    end;

    local procedure FindFAPostingGroup(var FAPostingGroup: Record "FA Posting Group"; FAPostingGrp: Code[20])
    begin
        FAPostingGroup.SetRange(Code, FAPostingGrp);
        FAPostingGroup.FindFirst();
    end;

    local procedure FindGenBusPostingGroup(var GenBusPostingGroup: Record "Gen. Business Posting Group"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        GenBusPostingGroup.SetRange("Def. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenBusPostingGroup.SetRange("Auto Insert Default", true);
        GenBusPostingGroup.FindFirst();
    end;

    local procedure FindCustPostingGroup(var CustPostingGroup: Record "Customer Posting Group")
    begin
        CustPostingGroup.FindFirst();
    end;

    local procedure FindDiffGenProdPostingGroup(var GenProdPostingGroup: Record "Gen. Product Posting Group"; VATProdPostingCroupCode: Code[20]; GenProdPostingGroupCode: Code[20])
    begin
        GenProdPostingGroup.SetRange("Def. VAT Prod. Posting Group", VATProdPostingCroupCode);
        GenProdPostingGroup.SetRange("Auto Insert Default", true);
        GenProdPostingGroup.SetFilter(Code, '<>' + GenProdPostingGroupCode);
        GenProdPostingGroup.FindFirst();
    end;

    local procedure FindPostingSetup(var GenPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GenBusPostingGroupFilter: Text[1024];
        GenProdPostingGroupFilter: Text[1024];
        SetupFound: Boolean;
    begin
        // Build Filter for Gen. Business Posting Group.
        GenBusPostingGroup.SetFilter("Def. VAT Bus. Posting Group", '<>%1', '');
        GenBusPostingGroup.SetRange("Auto Insert Default", true);
        if GenBusPostingGroup.FindSet() then
            repeat
                GenBusPostingGroupFilter := UpdateFilter(GenBusPostingGroupFilter, GenBusPostingGroup.Code);
            until GenBusPostingGroup.Next() = 0;

        // Build Filter for Gen. Product Posting Group.
        GenProdPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        GenProdPostingGroup.SetRange("Auto Insert Default", true);
        if GenProdPostingGroup.FindSet() then
            repeat
                GenProdPostingGroupFilter := UpdateFilter(GenProdPostingGroupFilter, GenProdPostingGroup.Code);
            until GenProdPostingGroup.Next() = 0;

        // Find General Posting Setup with VAT Posting Setup.
        SetupFound := false;
        GenPostingSetup.SetFilter("Gen. Bus. Posting Group", GenBusPostingGroupFilter);
        GenPostingSetup.SetFilter("Gen. Prod. Posting Group", GenProdPostingGroupFilter);
        if GenPostingSetup.FindSet() then
            repeat
                GenBusPostingGroup.Get(GenPostingSetup."Gen. Bus. Posting Group");
                GenProdPostingGroup.Get(GenPostingSetup."Gen. Prod. Posting Group");
                VATPostingSetup.Get(GenBusPostingGroup."Def. VAT Bus. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
                if (VATPostingSetup."VAT Calculation Type" = VATCalculationType) and (VATPostingSetup."VAT %" > 0) then
                    SetupFound := true
                else
                    if GenPostingSetup.Next() = 0 then
                        Error(RecordNotFoundError, GenPostingSetup.TableCaption());
            until SetupFound;
    end;

    local procedure Post_Payment_And_Apply(JournalTemplate: Code[10]; JournalBatch: Code[10]; AccType: Text[30]; AccNo: Text[20]; Amount: Decimal; DocType: Text[30]; BankAcc: Code[20]; PmtDiscountDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerentry: Record "Vendor Ledger Entry";
    begin
        GenJournalLine.Init();
        GenJournalLine.DeleteAll();

        if AccType = 'Customer' then begin
            if DocType = 'Refund' then begin
                CreateJournalLine(GenJournalLine,
                  JournalTemplate, JournalBatch, GenJournalLine."Account Type"::Customer, AccNo, WorkDate(),
                  GenJournalLine."Document Type"::Refund, 0, GenJournalLine."Bal. Account Type"::"Bank Account", BankAcc);
                CustLedgerEntry.SetRange("Customer No.", AccNo);
                CustLedgerEntry.FindLast();
                GenJournalLine.Validate("Posting Date", CalcDate('<-1D>', PmtDiscountDate));
                GenJournalLine.Validate(Amount, Amount);
                GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::"Credit Memo");
                GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
                GenJournalLine.Modify(true);
            end;
            if DocType = 'Payment' then begin
                CreateJournalLine(GenJournalLine,
                  JournalTemplate, JournalBatch, GenJournalLine."Account Type"::Customer, AccNo, WorkDate(),
                  GenJournalLine."Document Type"::Payment, 0, GenJournalLine."Bal. Account Type"::"Bank Account", BankAcc);
                CustLedgerEntry.SetRange("Customer No.", AccNo);
                CustLedgerEntry.FindLast();
                GenJournalLine.Validate("Posting Date", CalcDate('<-1D>', PmtDiscountDate));
                GenJournalLine.Validate(Amount, Amount);
                GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
                GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
                GenJournalLine.Modify(true);
            end;
        end;

        if AccType = 'Vendor' then begin
            if DocType = 'Refund' then begin
                CreateJournalLine(GenJournalLine,
                  JournalTemplate, JournalBatch, GenJournalLine."Account Type"::Vendor, AccNo, WorkDate(),
                  GenJournalLine."Document Type"::Refund, 0, GenJournalLine."Bal. Account Type"::"Bank Account", BankAcc);
                VendorLedgerentry.SetRange("Vendor No.", AccNo);
                VendorLedgerentry.FindLast();
                GenJournalLine.Validate("Posting Date", CalcDate('<-1D>', PmtDiscountDate));
                GenJournalLine.Validate(Amount, Amount);
                GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::"Credit Memo");
                GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerentry."Document No.");
                GenJournalLine.Modify(true);
            end;
            if DocType = 'Payment' then begin
                CreateJournalLine(GenJournalLine,
                  JournalTemplate, JournalBatch, GenJournalLine."Account Type"::Vendor, AccNo, WorkDate(),
                  GenJournalLine."Document Type"::Payment, 0, GenJournalLine."Bal. Account Type"::"Bank Account", BankAcc);
                VendorLedgerentry.SetRange("Vendor No.", AccNo);
                VendorLedgerentry.FindLast();
                GenJournalLine.Validate("Posting Date", CalcDate('<-1D>', PmtDiscountDate));
                GenJournalLine.Validate(Amount, Amount);
                GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
                GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerentry."Document No.");
                GenJournalLine.Modify(true);
            end;
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateAccounts(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        if GeneralPostingSetup."COGS Account" = '' then begin
            LibraryERM.CreateGLAccount(GLAccount);
            GeneralPostingSetup."COGS Account" := GLAccount."No.";
            GeneralPostingSetup.Modify();
        end;
    end;

    local procedure BankSetup(var BankAcc: Code[20]; var GLBankAccNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccount.SetRange("Currency Code", '');
        BankAccount.FindFirst();
        BankAcc := BankAccount."No.";
        BankAccPostingGroup.SetRange(Code, BankAccount."Bank Acc. Posting Group");
        BankAccPostingGroup.FindFirst();
        GLBankAccNo := BankAccPostingGroup."G/L Account No.";
    end;

    local procedure GeneralSetup(SetupItem: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroup1: Record "Gen. Product Posting Group";
        GenProdPostingGroup2: Record "Gen. Product Posting Group";
        CustPostingGroup: Record "Customer Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        // Setup Cal. Inv. Disc. on sales
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", true);
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Modify(true);

        // Setup Cal. Inv. Disc. on purchase
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", true);
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Modify(true);

        // Find General Posting Setup with groups that have corresponding Def. VAT groups assigned.
        // Required to decrease dependency on demo data (important for country execution).
        FindPostingSetup(GenPostingSetup1, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateAccounts(GenPostingSetup1);
        SalesVATAcc := VATPostingSetup."Sales VAT Account";
        PurchVATAcc := VATPostingSetup."Purchase VAT Account";

        GenBusPostingGrp := GenPostingSetup1."Gen. Bus. Posting Group";
        VATPostingGrp := VATPostingSetup."VAT Bus. Posting Group";

        FindCustPostingGroup(CustPostingGroup);
        CustPostingGrp := CustPostingGroup.Code;
        ReceivableAcc := CustPostingGroup."Receivables Account";
        CustPmtDiscCreditAcc := CustPostingGroup."Payment Disc. Credit Acc.";
        CustPmtDiscDebitAcc := CustPostingGroup."Payment Disc. Debit Acc.";

        VendorPostingGroup.FindFirst();
        VendPostingGrp := VendorPostingGroup.Code;
        PayableAcc := VendorPostingGroup."Payables Account";
        VendPmtDiscCreditAcc := VendorPostingGroup."Payment Disc. Credit Acc.";
        VendPmtDiscDebitAcc := VendorPostingGroup."Payment Disc. Debit Acc.";

        // Setup test items: item1 and item2 have same Gen. Prod. Posting group, item3 has different Gen. Prod. Posting group
        GenProdPostingGroup1.Get(GenPostingSetup1."Gen. Prod. Posting Group");
        SalesAcc1 := GenPostingSetup1."Sales Account";
        if GenPostingSetup1."Sales Line Disc. Account" = '' then
            GenPostingSetup1."Sales Line Disc. Account" := LibraryERM.CreateGLAccountNo();
        SalesLineDiscAcc1 := GenPostingSetup1."Sales Line Disc. Account";
        SalesInvDiscAcc1 := GenPostingSetup1."Sales Inv. Disc. Account";
        PurchAcc1 := GenPostingSetup1."Purch. Account";
        if GenPostingSetup1."Purch. Line Disc. Account" = '' then
            GenPostingSetup1."Purch. Line Disc. Account" := LibraryERM.CreateGLAccountNo();
        PurchLineDiscAcc1 := GenPostingSetup1."Purch. Line Disc. Account";
        PurchInvDiscAcc1 := GenPostingSetup1."Purch. Inv. Disc. Account";

        // Setup test items: item3 has different Gen. Prod. Posting group from item1 and item2
        FindDiffGenProdPostingGroup(
          GenProdPostingGroup2, VATPostingSetup."VAT Prod. Posting Group", GenPostingSetup1."Gen. Prod. Posting Group");
        GenPostingSetup2.Get(GenPostingSetup1."Gen. Bus. Posting Group", GenProdPostingGroup2.Code);
        UpdateAccounts(GenPostingSetup2);
        SalesAcc2 := GenPostingSetup2."Sales Account";
        SalesLineDiscAcc2 := GenPostingSetup2."Sales Line Disc. Account";
        SalesInvDiscAcc2 := GenPostingSetup2."Sales Inv. Disc. Account";
        PurchAcc2 := GenPostingSetup2."Purch. Account";
        PurchLineDiscAcc2 := GenPostingSetup2."Purch. Line Disc. Account";
        PurchInvDiscAcc2 := GenPostingSetup2."Purch. Inv. Disc. Account";

        if SetupItem then begin
            Item1 := CreateItem(GenProdPostingGroup1.Code, VATPostingSetup."VAT Prod. Posting Group");
            Item2 := CreateItem(GenProdPostingGroup1.Code, VATPostingSetup."VAT Prod. Posting Group");
            Item3 := CreateItem(GenProdPostingGroup2.Code, VATPostingSetup."VAT Prod. Posting Group");
        end;
    end;

    local procedure JournalSetup(var JournalTemplate: Code[10]; var JournalBatch: Code[10])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.SetFilter("No. Series", '<>''''');
        GenJnlTemplate.FindFirst();
        JournalTemplate := GenJnlTemplate.Name;
        GenJnlBatch.SetRange("Journal Template Name", JournalTemplate);
        GenJnlBatch.FindFirst();
        JournalBatch := GenJnlBatch.Name;
    end;

    local procedure ValidateGLEntry(GLRegister: Record "G/L Register"; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        // Validate account and amount on GL entry
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetFilter(Amount, '%1', ExpectedAmount);
        Assert.IsTrue(GLEntry.FindFirst(), StrSubstNo(GLEntryError, GLAccountNo, ExpectedAmount));
    end;

    local procedure ValidateVATEntry(GLRegister: Record "G/L Register"; VATBase: Decimal; VATAmount: Decimal; UnrealizedVATEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        // Validate base and amount on VAT entry
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        VATEntry.SetFilter(Base, '%1', VATBase);
        VATEntry.SetFilter(Amount, '%1', VATAmount);
        Assert.IsTrue(VATEntry.FindFirst(), StrSubstNo(VATEntryError, VATBase, VATAmount));

        // Validate VAT link
        ValidateVATLink(VATEntry, UnrealizedVATEntryNo, VATEntry."Entry No.");
    end;

    local procedure ValidateVATLink(var VATEntry: Record "VAT Entry"; UnrealizedVATEntryNo: Integer; EntryNo: Integer)
    var
        GLVATLink: Record "G/L Entry - VAT Entry Link";
        GLEntry: Record "G/L Entry";
        GLVatLink2: Record "G/L Entry - VAT Entry Link";
        VATEntry2: Record "VAT Entry";
        GLAmount: Decimal;
        Base: Decimal;
    begin
        GLAmount := 0;
        GLVATLink.SetRange("VAT Entry No.", VATEntry."Entry No.");

        if GLVATLink.FindSet() then begin
            repeat
                GLVatLink2.SetRange("G/L Entry No.", GLVATLink."G/L Entry No.");
                GLVatLink2.FindSet();
                repeat
                    if GLVatLink2."VAT Entry No." <> VATEntry."Entry No." then begin
                        VATEntry2.Get(GLVatLink2."VAT Entry No.");
                        Base := Base + VATEntry2.Base;
                    end else
                        if (VATEntry."Unrealized VAT Entry No." <> 0) and
                           (VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT")
                        then
                            Base += VATEntry.Amount
                        else
                            Base += VATEntry.Base;
                until GLVatLink2.Next() = 0;
                GLEntry.Get(GLVATLink."G/L Entry No.");
                GLAmount += GLEntry.Amount;
            until GLVATLink.Next() = 0;
            Assert.IsTrue(GLAmount = Base, StrSubstNo(VATLinkError, EntryNo));
        end else
            // TODO: Known issue TFS 53978
            if VATEntry."Unrealized VAT Entry No." = UnrealizedVATEntryNo then;
        // Assert.IsTrue(VATEntry."Unrealized VAT Entry No." = UnrealizedVATEntryNo,STRSUBSTNO(UnrealizedVATLinkError,EntryNo));
    end;

    local procedure UpdateFilter(OldFilter: Text[1024]; "Code": Code[20]) NewFilter: Text[1024]
    begin
        if OldFilter = '' then
            NewFilter := Code
        else
            NewFilter := CopyStr(OldFilter + '|' + Code, 1, MaxStrLen(NewFilter));
    end;

    local procedure SalesDocumentExist(): Boolean
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        GLRegister.Next(GLRegister.Count - 1);
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.FindSet();

        if SalesInvoiceHeader.Get(GLEntry."Document No.") then
            exit(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConform(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
        exit;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    local procedure SetupReverseChargeVAT()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindReverseChargeVATPostSetup(VATPostingSetup, false);
        FindGenBusPostingGroup(GenBusPostingGroup, VATPostingSetup);
        GenProdPostingGroup.SetRange("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenProdPostingGroup.SetRange("Auto Insert Default", true);
        if not GenProdPostingGroup.FindFirst() then begin
            CreateGenProdPostGroupWithDefVAT(GenProdPostingGroup, VATPostingSetup);
            CreateGLAccWithGenPostingSetup(GenBusPostingGroup.Code, GenProdPostingGroup.Code);
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProdPostingGroup.Code);
            LibraryERMCountryData.UpdateGeneralPostingSetup();
        end
    end;

    local procedure FindReverseChargeVATPostSetup(var VATPostingSetup: Record "VAT Posting Setup"; AdjForPaymentDisc: Boolean)
    begin
        VATPostingSetup.Reset();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjForPaymentDisc);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGenProdPostGroupWithDefVAT(var GenProdPostingGroup: Record "Gen. Product Posting Group"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenProdPostingGroup.Validate("Auto Insert Default", true);
        GenProdPostingGroup.Modify(true);
    end;

    local procedure CreateGLAccWithGenPostingSetup(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        GLAccount.Modify(true);
    end;
}

