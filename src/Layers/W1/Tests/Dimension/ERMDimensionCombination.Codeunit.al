codeunit 134479 "ERM Dimension Combination"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Combination Restriction]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        DimensionCombinationError: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked', Locked = true;
        LineDimensionCombinationError: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked', Locked = true;
        HeaderDimensionCombinationError: Label 'The combination of dimensions used in %1 %2 is blocked', Locked = true;
        BlockedDimensionCombinationErr: Label 'Dimensions %1 and %2 can''t be used concurrently.', Comment = '%1=First Dimension;%2=Second Dimension';
        DimensionValueCombinationErr: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. Dimension combinations %5 - %6 and %7 - %8 can''t be used concurrently.', Comment = '%1: TableCaption, %2: Field(Gen. Journal Template), %3: Field(Gen. Journal Batch), %4: Field(Line No.), %5: Field(Dimension Code), %6: Field(Dimension Value Code), %7: Field(Dimension Code), %8: Field(Code)';
        ColumnInvisibleErr: Label 'Last column should be visible.';
        ColumnVisibleErr: Label 'Last column should be invisible.';

    [Test]
    [Scope('OnPrem')]
    procedure DimensionCombinationRule()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test error occurs on Posting General Journal with Dimension Combination for Combination Restriction Blocked.

        // [GIVEN] Create Dimension, Dimension Value, Customer with Default Dimension, Dimension Combination for Combination
        // Restriction Blocked and General Journal with Dimension.
        Initialize();
        CreateCustomerWithDimension(DefaultDimension);
        CreateDimensionCombination(DimensionCombination, DimensionValue, DefaultDimension."Dimension Code");
        UpdateCombinationRestriction(DimensionCombination, DimensionCombination."Combination Restriction"::Blocked);
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, DefaultDimension."No.");

        // [WHEN] Post the General Journal.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify error occurs "Dimension Combination Blocked" on Posting General Journal.
        Assert.ExpectedError(
          StrSubstNo(
            DimensionCombinationError, GenJournalLine.TableCaption(), GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryCombination()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionCombination: Record "Dimension Combination";
        DimensionValueCombination: Record "Dimension Value Combination";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        DimensionSetID: Integer;
    begin
        // [SCENARIO] Test Dimension on Customer Ledger Entry after Posting General Journal with Limited Dimension Combination.

        // [GIVEN] Create Dimension, Dimension Value, Customer with Default Dimension, Dimension Combination for Combination
        // Restriction Limited and General Journal with Dimension.
        Initialize();
        CreateCustomerWithDimension(DefaultDimension);
        CreateDimensionCombination(DimensionCombination, DimensionValue, DefaultDimension."Dimension Code");
        UpdateCombinationRestriction(DimensionCombination, DimensionCombination."Combination Restriction"::Limited);
        LibraryDimension.CreateDimValueCombination(
          DimensionValueCombination, DefaultDimension."Dimension Code", DimensionValue."Dimension Code",
          DefaultDimension."Dimension Value Code", DimensionValue.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, DefaultDimension."No.");
        DimensionSetID := GenJournalLine."Dimension Set ID";

        // [WHEN] Post the General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify Dimension on Customer Ledger Entry.
        VerifyCustomerLedgerDimension(DefaultDimension."No.", DimensionSetID);
        VerifyDimensionSetEntry(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code", DimensionSetID);
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, DimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithBlockedDimensionsOnLine()
    var
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Test the Posting of Sales Invoice with restricts dimension.

        // [GIVEN] Create Dimension, Dimension Value, Customer with Default Dimension, Dimension Combination for Combination
        // Restriction Blocked and Create Sales Invoice with dimensions.
        Initialize();
        CreateCustomerWithDimension(DefaultDimension);
        CreateDimensionCombination(DimensionCombination, DimensionValue, DefaultDimension."Dimension Code");
        UpdateCombinationRestriction(DimensionCombination, DimensionCombination."Combination Restriction"::Blocked);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, DefaultDimension."No.");
        CreateSalesLine(SalesLine, SalesHeader);
        UpdateSalesLineDimensionSetID(SalesLine, DimensionValue);

        // [WHEN] Post Sales Invoice.
        LibraryErrorMessage.TrapErrorMessages();
        Assert.IsFalse(SalesHeader.SendToPosting(CODEUNIT::"Sales-Post"), 'Posting should fail');

        // [THEN] Verify Restrict Dimension Error.
        LibraryErrorMessage.GetTestPage(ErrorMessagesPage);
        ErrorMessagesPage."Additional Information".AssertEquals(
          StrSubstNo(
            LineDimensionCombinationError, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithBlockedDimensionsOnLine()
    var
        Item: Record Item;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Test error occurs on Posting Purchase Invoice with Blocked Dimensions on Line.

        // [GIVEN] Create Item, Vendor with Default Dimension, Dimension Combination for Combination Restriction Blocked and Create Purchase Invoice with dimensions on line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateVendorWithDimension(DefaultDimension);
        CreateDimensionCombination(DimensionCombination, DimensionValue, DefaultDimension."Dimension Code");
        UpdateCombinationRestriction(DimensionCombination, DimensionCombination."Combination Restriction"::Blocked);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, DefaultDimension."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        UpdatePurchaseLineDimensionSetID(PurchaseLine, DimensionValue);

        // [WHEN] Post Purchase Invoice.
        LibraryErrorMessage.TrapErrorMessages();
        Assert.IsFalse(PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post"), 'Posting should fail');

        // [THEN] Verify Blocked Dimension Error.
        LibraryErrorMessage.GetTestPage(ErrorMessagesPage);
        ErrorMessagesPage."Additional Information".AssertEquals(
          StrSubstNo(
            LineDimensionCombinationError, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithBlockedDimensionsOnHeader()
    var
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Test error occurs on Posting Purchase Invoice with Blocked Dimensions on Header.

        // [GIVEN] Create Vendor with Default Dimension, Dimension Combination for Combination Restriction Blocked and Create Purchase Invoice with dimensions on header.
        Initialize();
        CreateVendorWithDimension(DefaultDimension);
        CreateDimensionCombination(DimensionCombination, DimensionValue, DefaultDimension."Dimension Code");
        UpdateCombinationRestriction(DimensionCombination, DimensionCombination."Combination Restriction"::Blocked);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, DefaultDimension."No.");
        UpdatePurchaseHeaderDimensionSetID(PurchaseHeader, DimensionValue);

        // [WHEN] Post Purchase Invoice.
        LibraryErrorMessage.TrapErrorMessages();
        Assert.IsFalse(PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post"), 'Posting should fail');

        // [THEN] Verify Blocked Dimension Error.
        LibraryErrorMessage.GetTestPage(ErrorMessagesPage);
        ErrorMessagesPage."Additional Information".AssertEquals(
          StrSubstNo(
            HeaderDimensionCombinationError, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGLBudgetEntryWithBlockedDimensions()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        NewDimSetID: Integer;
    begin
        // [SCENARIO] Creating G/L Budget Entry with dimensions, witch included in blocked Dimension Combination. It should not be possible to enter blocked Dimension Combinations in G/L Budget Entry
        Initialize();
        // [GIVEN] Create blocked Dimension Combination and Dimension Set
        NewDimSetID := CreateBlockedDimensionCombination(DimensionValue1, DimensionValue2);
        // [GIVEN] Create G/L Budget Entry with dimensions created below
        CreateGLBudgetEntry(GLBudgetEntry, DimensionValue1."Dimension Code", DimensionValue2."Dimension Code");
        // [WHEN] Create G/L Budget Entry and assign blocked Dimension Set
        asserterror GLBudgetEntry.Validate("Dimension Set ID", NewDimSetID);
        // [THEN] Expected error
        Assert.ExpectedError(
          StrSubstNo(BlockedDimensionCombinationErr, DimensionValue1."Dimension Code", DimensionValue2."Dimension Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorBlockDimensionCombination()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionCombination: Record "Dimension Combination";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [SCENARIO 379598] Gen Journal Line with blank PK fields throws dimension error without referencing to these fields
        Initialize();

        // [GIVEN] Blocked dimension combination
        CreateCustomerWithDimension(DefaultDimension);
        CreateDimensionCombination(DimensionCombination, DimensionValue, DefaultDimension."Dimension Code");
        UpdateCombinationRestriction(DimensionCombination, DimensionCombination."Combination Restriction"::Blocked);

        // [GIVEN] Gen. Journal Line with blocked dimension combination and blank PK fields
        MockGenJournalLineWithDim(GenJournalLine, DefaultDimension."No.", DimensionValue);

        // [WHEN] Invoke "Gen. Jnl.-Post Line".RunWithCheck
        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] Error occurs "Dimensions X and Y can't be used concurrently."
        Assert.ExpectedError(
          StrSubstNo(
            BlockedDimensionCombinationErr, DimensionCombination."Dimension 1 Code",
            DimensionCombination."Dimension 2 Code"));
    end;

    [Test]
    [HandlerFunctions('MyDimValueCombinationsPageHandler,BlockDimValueCombinationStrMenuHandler')]
    [Scope('OnPrem')]
    procedure RestrictionOnLastColumnInDimValueCombMatrixBlocksPosting()
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 380833] Gen. Journal Line cannot be posted with a blocked combination of dimension values when that restriction is set on the last (32-nd) column in Dimension Value Combination Matrix.
        Initialize();

        // [GIVEN] Dimension "D" with 32 values "D1..D32".
        // [GIVEN] Customer with Default Dimension "C" and value "C1".
        // [GIVEN] Combination of values "C1" and "D32" is blocked.
        CreateDimensionsWithLimitedCombinationRestriction(DimensionValue, DefaultDimension);

        // [GIVEN] Gen. Journal Line with dimensions values "C1" and "D32" is created.
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, DefaultDimension."No.");

        // [WHEN] Post the General Journal.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The posting fails. An error is thrown reading that the combinations of dimension values is blocked.
        Assert.ExpectedError(
          StrSubstNo(
            DimensionValueCombinationErr, GenJournalLine.TableCaption(), GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name", GenJournalLine."Line No.", DefaultDimension."Dimension Code",
            DefaultDimension."Dimension Value Code", DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    [Test]
    [HandlerFunctions('MyDimValueCombinationsCheckVisibilityPageHandler')]
    [Scope('OnPrem')]
    procedure ColumnVisibilityInDimValueCombMatrixIsUpdatedOnNextColumnAction()
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 380833] The last column in Dimension Value Combination Matrix should become invisible when a set of dimension values in columns is shifted left by clicking "Next Column" button.
        Initialize();

        // [GIVEN] Dimension "D" with 32 values "D1..D32".
        // [GIVEN] Dimension "C" with value "C1".

        // [WHEN] Click "Next Column" button on Dimension Value Combination with "C1" in row and "D1..D32" in columns.
        CreateDimensionsWithLimitedCombinationRestriction(DimensionValue, DefaultDimension);

        // [THEN] Column 32 becomes invisible.
        // The vefication is done is MyDimValueCombinationsCheckVisibilityPageHandler.
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Combination");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Combination");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Combination");
    end;

    local procedure CreateCustomerWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateDimensionCombination(var DimensionCombination: Record "Dimension Combination"; var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    begin
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDimensionCombination(DimensionCombination, DimensionCode, DimensionValue."Dimension Code");
    end;

    local procedure CreateBlockedDimensionCombination(var DimensionValue1: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value") NewDimSetID: Integer
    var
        DimensionCombination: Record "Dimension Combination";
    begin
        CreateDimensionWithValue(DimensionValue1);
        CreateDimensionWithValue(DimensionValue2);
        LibraryDimension.CreateDimensionCombination(DimensionCombination,
          DimensionValue1."Dimension Code", DimensionValue2."Dimension Code");
        UpdateCombinationRestriction(DimensionCombination, DimensionCombination."Combination Restriction"::Blocked);
        NewDimSetID := LibraryDimension.CreateDimSet(NewDimSetID, DimensionValue1."Dimension Code", DimensionValue1.Code);
        NewDimSetID := LibraryDimension.CreateDimSet(NewDimSetID, DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDimensionWithSetOfValues(var DimensionValue: Record "Dimension Value"; NoOfValues: Integer)
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        for i := 1 to NoOfValues do
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDimensionsWithLimitedCombinationRestriction(var DimensionValue: Record "Dimension Value"; var DefaultDimension: Record "Default Dimension")
    var
        DimensionCombination: Record "Dimension Combination";
        MyDimValueCombinations: Page "MyDim Value Combinations";
    begin
        CreateDimensionWithSetOfValues(DimensionValue, 32); // 32 is a maximum number of columns in Dim. Values Combination Matrix
        CreateCustomerWithDimension(DefaultDimension);

        LibraryDimension.CreateDimensionCombination(
          DimensionCombination, DimensionValue."Dimension Code", DefaultDimension."Dimension Code");
        UpdateCombinationRestriction(DimensionCombination, DimensionCombination."Combination Restriction"::Limited);
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Value Code");
        MyDimValueCombinations.Load(DefaultDimension."Dimension Code", DimensionValue."Dimension Code", true);
        MyDimValueCombinations.RunModal();
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJournalLineWithDimension(var GenJournalLine: Record "Gen. Journal Line"; DimensionValue: Record "Dimension Value"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindJournalBatchAndTemplate(GenJournalBatch);
        CreateJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, AccountNo,
          LibraryRandom.RandDec(100, 2));  // Use Random because value is not important.
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);
    end;

    local procedure MockGenJournalLineWithDim(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        SourceCode: Record "Source Code";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        Clear(GenJournalLine);
        GenJournalLine.Init();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate("Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Document No." :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line");
        GenJournalLine.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryERM.CreateSourceCode(SourceCode);
        GenJournalLine."Source Code" := SourceCode.Code;
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        // Using Random Number Generator for Amount and Quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader,
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVendorWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Vendor: Record Vendor;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateGLBudgetEntry(var GLBudgetEntry: Record "G/L Budget Entry"; Dimension1Code: Code[20]; Dimension2Code: Code[20])
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        GLBudgetName.Validate("Budget Dimension 1 Code", Dimension1Code);
        GLBudgetName.Validate("Budget Dimension 2 Code", Dimension2Code);
        GLBudgetName.Modify(true);
        GLBudgetEntry.Init();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), GLAccount."No.", GLBudgetName.Name);
    end;

    local procedure FindJournalBatchAndTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);  // Added fix to make test world ready.
    end;

    local procedure UpdateCombinationRestriction(var DimensionCombination: Record "Dimension Combination"; CombinationRestriction: Option)
    begin
        DimensionCombination.Validate("Combination Restriction", CombinationRestriction);
        DimensionCombination.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderDimensionSetID(var PurchaseHeader: Record "Purchase Header"; DimensionValue: Record "Dimension Value")
    begin
        PurchaseHeader.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(PurchaseHeader."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseLineDimensionSetID(var PurchaseLine: Record "Purchase Line"; DimensionValue: Record "Dimension Value")
    begin
        PurchaseLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(PurchaseLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesLineDimensionSetID(var SalesLine: Record "Sales Line"; DimensionValue: Record "Dimension Value")
    begin
        SalesLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(SalesLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        SalesLine.Modify(true);
    end;

    local procedure VerifyCustomerLedgerDimension(CustomerNo: Code[20]; DimensionSetID: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyDimensionSetEntry(DimensionCode: Code[20]; DimensionValueCode: Code[20]; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MyDimValueCombinationsPageHandler(var MyDimValueCombinations: TestPage "MyDim Value Combinations")
    begin
        MyDimValueCombinations.MatrixForm.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        MyDimValueCombinations.MatrixForm.Field32.AssistEdit();
        MyDimValueCombinations.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MyDimValueCombinationsCheckVisibilityPageHandler(var MyDimValueCombinations: TestPage "MyDim Value Combinations")
    begin
        Assert.IsTrue(MyDimValueCombinations.MatrixForm.Field32.Visible(), ColumnInvisibleErr);
        MyDimValueCombinations.NextColumn.Invoke();
        Assert.IsFalse(MyDimValueCombinations.MatrixForm.Field32.Visible(), ColumnVisibleErr);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure BlockDimValueCombinationStrMenuHandler(Options: Text; var Choice: Integer; Instructions: Text)
    begin
        Choice := 2;
    end;
}

