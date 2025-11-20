codeunit 134380 "ERM Dimension"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Dimension Set Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Value Posting]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDim: Codeunit "Library - Dimension";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        TestDim: Code[20];
        TestDim2: Code[20];
        TestDimValue: Code[20];
        TestDimValue2: Code[20];
        TestDim2Value: Code[20];
        ErrorText: Text[250];
        MandatoryError: Label 'A dimension used in Gen. Journal Line %1, %2, %3 has caused an error. Select a Dimension Value Code for the Dimension Code %4 for Customer %5.';
        SameCodeOrNoCodeError: Label 'A dimension used in Gen. Journal Line %1, %2, %3 has caused an error. The %4 must be %5 for %6 %7 for %8 %9. Currently it''s %10.', Comment = '%4 = "Dimension value code" caption, %5 = expected "Dimension value code" value, %6 = "Dimension code" caption, %7 = "Dimension Code" value, %8 = Table caption (Vendor), %9 = Table value (XYZ), %10 = current "Dimension value code" value';
        BlankLbl: Label 'blank';
        CombinationError: Label 'A dimension used in Gen. Journal Line %1, %2, %3 has caused an error. The %4 must be %5 for %6 %7. Currently it''s %8.', Comment = '%4 = "Dimension value code" caption, %5 = expected "Dimension value code" value, %6 = "Dimension code" caption, %7 = "Dimension Code" value, %8 = current "Dimension value code" value';
        UnknownError: Label 'Unexpected Error.';
        GeneralLineMustNotExistError: Label 'General Journal Line must not exist.';
        BlockedErr: Label 'is blocked';
        BlockedLevel: Option Dimension,"Dimension Value";
        DimValueNotFoundErr: Label 'contains a value (%1) that cannot be found in the related table (Dimension Value).', Comment = '%1 = Dimension Value Code';
        CountOfLocalTablesErr: Label 'Count of local tables should be %1, but it is %2.';

    [Test]
    procedure DimValueListHidesBlockedDimValues()
    var
        Dimension: Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        TestDimensionValueList: TestPage "Dimension Value List";
    begin
        Initialize();
        LibraryDim.CreateDimension(Dimension);
        LibraryDim.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        LibraryDim.CreateDimensionValue(DimensionValue[2], Dimension.Code);
        DimensionValue[2].Blocked := true;
        DimensionValue[2].Modify();

        TestDimensionValueList.OpenEdit();
        TestDimensionValueList.Filter.SetFilter("Dimension Code", Dimension.Code);
        Assert.IsTrue(TestDimensionValueList.First(), 'not found 1st line');
        TestDimensionValueList.Code.AssertEquals(DimensionValue[1].Code);
        Assert.IsTrue(TestDimensionValueList.Next(), 'not found 2nd line');
        TestDimensionValueList.Code.AssertEquals(DimensionValue[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValPosting_Mandatory()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        GenJnlLine: Record "Gen. Journal Line";
        DimSetID: Integer;
    begin
        // Test codeunit 408, function CheckDimValueposting.
        // Combination: Code mandatory + Specific account value posting
        // replace 140761,140764,140755,140758

        Initialize();
        ValPosting_Setup(GLAccount, Customer, DefaultDimension, GenJnlLine, DefaultDimension."Value Posting"::"Code Mandatory");
        DimSetID := GenJnlLine."Dimension Set ID";
        ModifyJnlDimSetID(GenJnlLine, 0);
        // Necessary to be able to run possitive test after negative test.
        Commit();

        ErrorText := StrSubstNo(MandatoryError, JournalTemplate, JournalBatch, GenJnlLine."Line No.", TestDim, Customer."No.");

        NegativeTest(GenJnlLine, ErrorText);
        PossitiveTest(GenJnlLine, DimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValPosting_SameCode()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        GenJnlLine: Record "Gen. Journal Line";
        DimSetID: Integer;
        NewDimSetID: Integer;
    begin
        // Test codeunit 408, function CheckDimValueposting.
        // Parameters: Same Code + specific account value posting
        // replace 140762,140765,140756,140759

        Initialize();
        ValPosting_Setup(GLAccount, Customer, DefaultDimension, GenJnlLine, DefaultDimension."Value Posting"::"Same Code");
        DimSetID := GenJnlLine."Dimension Set ID";
        NewDimSetID := LibraryDim.EditDimSet(DimSetID, TestDim, TestDimValue2);
        ModifyJnlDimSetID(GenJnlLine, NewDimSetID);
        // Necessary to be able to run possitive test after negative test.
        Commit();

        ErrorText := StrSubstNo(SameCodeOrNoCodeError, JournalTemplate, JournalBatch, GenJnlLine."Line No.", DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code", DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", Customer.TableCaption, Customer."No.", TestDimValue2);

        NegativeTest(GenJnlLine, ErrorText);
        PossitiveTest(GenJnlLine, DimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValPosting_NoCode()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        GenJnlLine: Record "Gen. Journal Line";
        DimSetID: Integer;
    begin
        // Test codeunit 408, function CheckDimValueposting.
        // Parameters: No Code + specific account value posting
        // replace 140763,140766,140758,140760

        Initialize();
        ValPosting_Setup(GLAccount, Customer, DefaultDimension, GenJnlLine, DefaultDimension."Value Posting"::"No Code");
        DimSetID := LibraryDim.CreateDimSet(DimSetID, TestDim, TestDimValue);
        ModifyJnlDimSetID(GenJnlLine, DimSetID);
        // Necessary to be able to run possitive test after negative test.
        Commit();

        ErrorText := StrSubstNo(SameCodeOrNoCodeError, JournalTemplate, JournalBatch, GenJnlLine."Line No.", DefaultDimension.FieldCaption("Dimension Value Code"), BlankLbl, DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", Customer.TableCaption, Customer."No.", TestDimValue);

        NegativeTest(GenJnlLine, ErrorText);
        PossitiveTest(GenJnlLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValPosting_Blank()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // Test codeunit 408, function CheckDimValueposting.
        // Parameters: Blank + specific account value posting

        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimCustomer(DefaultDimension, Customer."No.", TestDim, TestDimValue, DefaultDimension."Value Posting"::" ");
        CreateDefaultDimCustomer(DefaultDimension, Customer."No.", TestDim2, TestDim2Value, DefaultDimension."Value Posting"::" ");

        CreateJournalLine(GenJnlLine, JournalTemplate, JournalBatch, GenJnlLine."Account Type"::Customer, Customer."No.",
          GenJnlLine."Document Type"::Invoice, 100, GenJnlLine."Bal. Account Type"::"G/L Account", GLAccount."No.");

        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValPosting_Combination()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        GenJnlLine: Record "Gen. Journal Line";
        DimSetID: Integer;
        NewDimSetID: Integer;
    begin
        // [SCENARIO] More specific default dimension overrides more generic default dimension.
        Initialize();
        // [GIVEN] Default Dimension for all Customers with "Value Posting"::"Code Mandatory"
        LibraryDim.CreateAccTypeDefaultDimension(DefaultDimension, DATABASE::Customer, TestDim, TestDimValue,
          DefaultDimension."Value Posting"::"Code Mandatory");
        // [GIVEN] Default Dimension for Customers 'C0001' with "Value Posting"::"Same Code" expects dim value code 'A'
        ValPosting_Setup(GLAccount, Customer, DefaultDimension, GenJnlLine, DefaultDimension."Value Posting"::"Same Code");
        DimSetID := GenJnlLine."Dimension Set ID";
        NewDimSetID := LibraryDim.EditDimSet(DimSetID, TestDim, TestDimValue2);
        ModifyJnlDimSetID(GenJnlLine, NewDimSetID);
        // Necessary to be able to run possitive test after negative test.
        Commit();

        // [WHEN] Post the journal lines, where dimension value code is 'B'
        // [THEN] Error: Dimension value has to be same as the default dimensions for the customer. 
        ErrorText := StrSubstNo(SameCodeOrNoCodeError, JournalTemplate, JournalBatch, GenJnlLine."Line No.", DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code", DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", Customer.TableCaption, Customer."No.", TestDimValue2);

        NegativeTest(GenJnlLine, ErrorText);

        // [WHEN] Post the journal lines, where dimension value code is 'A'
        // [THEN] Journal line is posted
        PossitiveTest(GenJnlLine, DimSetID);

        // Test cleanup
        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", DATABASE::Customer);
        DefaultDimension.SetRange("No.", ' ');
        DefaultDimension.SetRange("Dimension Code", TestDim);
        DefaultDimension.FindFirst();
        DefaultDimension.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWithoutDimensionValuePostingErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Test Post General Journal Line without dimension value posting error.

        // Setup: Create Account Type Default Dimension. Create Vendor and G/L Account.
        Initialize();
        VendorNo := CreateInitialSetupForVendorAccountTypeDefaultDimension(DefaultDimension, GLAccountNo);

        // Exercise: Create and post General Journal Line.
        CreateJournalLine(
          GenJournalLine, JournalTemplate, JournalBatch, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(100, 2), GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify there is no remaining General Journal Line after posting.
        GenJournalLine.SetRange("Journal Template Name", JournalTemplate);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatch);
        Assert.IsFalse(GenJournalLine.FindFirst(), GeneralLineMustNotExistError);

        // Tear down: Reset Account Type Default Dimension.
        DefaultDimension.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWithDimensionValuePostingErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Test Post General Journal Line with dimension value posting error.

        // Setup: Create Account Type Default Dimension. Create Vendor and G/L Account.
        Initialize();
        VendorNo := CreateInitialSetupForVendorAccountTypeDefaultDimension(DefaultDimension, GLAccountNo);

        // Exercise: Create General Journal Line. Change Dimension Value Code and post General Journal Line.
        CreateJournalLine(
          GenJournalLine, JournalTemplate, JournalBatch, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(100, 2), GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);
        UpdateDimensionValueCode(GenJournalLine."Dimension Set ID");
        Commit();  // COMMIT Required for Verification and Tear down.

        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify error occurs on posting General Journal Line with different Dimension Value Code.
        Assert.AreEqual(
          StrSubstNo(CombinationError, JournalTemplate, JournalBatch, GenJournalLine."Line No.", DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code", DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", TestDimValue2), GetLastErrorText,
          UnknownError);

        // Tear down: Reset Account Type Default Dimension.
        DefaultDimension.Delete(true);
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimensionSetEntry()
    var
        GeneralJournal: TestPage "General Journal";
        DocumentNo: Code[20];
    begin
        // Test setup dimensions on editable dimension set entry page and validate correct dimension data posting.

        // Setup: Create General Journal Line by General Journal Page.
        Initialize();
        DocumentNo := CreateJournalLineByGeneralJournalPage();

        // Exercise: Set Journal Line Dimensions in EditDimensionSetEntriesPageHandler Function. Post General Journal.
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(JournalBatch);
        GeneralJournal.Dimensions.Invoke();
        GeneralJournal.Post.Invoke();

        // Verify: Verify Posted Journal Line Dimensions.
        VerifyPostedJournalLineDimensions(FindDimensionSetID(DocumentNo), TestDim, TestDimValue);
        VerifyPostedJournalLineDimensions(FindDimensionSetID(DocumentNo), TestDim2, TestDim2Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateShortcutDimValues_DimensionBlocked()
    begin
        // Verify that validate of shortcut for blocked dimension leads to error
        BlockedDimensionShortcutScenario(BlockedLevel::Dimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateShortcutDimValues_DimensionValueBlocked()
    begin
        // Verify that validate of shortcut of blocked dimension value leads to error
        BlockedDimensionShortcutScenario(BlockedLevel::"Dimension Value");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReclasDimensionSetBufferDimValueNameLength()
    var
        ReclasDimensionSetBuffer: Record "Reclas. Dimension Set Buffer";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379473] TAB 482 "Reclas. Dimension Set Buffer" has correct text length for "Dimension Value Name", "New Dimension Value Name" fields
        Initialize();

        // [GIVEN] Dimension Code "DIM". Two Dimension Values for given dimension code:
        // [GIVEN] "DIMVAL1" with "Name" = "X" (50-chars length)
        // [GIVEN] "DIMVAL2" with "Name" = "Y" (50-chars length)
        CreateTwoDimValuesWithLongNames(DimensionValue);

        // [GIVEN] TAB 482 "Reclas. Dimension Set Buffer" record with "Dimension Code" = "DIM"
        ReclasDimensionSetBuffer.Init();
        ReclasDimensionSetBuffer.Validate("Dimension Code", DimensionValue[1]."Dimension Code");

        // [WHEN] Validate "Dimension Value Code" = "DIMVAL1", "New Dimension Value Code" = "DIMVAL2"
        ReclasDimensionSetBuffer.Validate("Dimension Value Code", DimensionValue[1].Code);
        ReclasDimensionSetBuffer.Validate("New Dimension Value Code", DimensionValue[2].Code);

        // [THEN] ReclasDimensionSetBuffer."Dimension Value Name" = "X"
        // [THEN] ReclasDimensionSetBuffer."New Dimension Value Name" = "Y"
        VerifyReclasDimSetBufferDimNames(ReclasDimensionSetBuffer, DimensionValue[1].Name, DimensionValue[2].Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_LookupDimValueFilterWithBlankDimension()
    var
        DimensionValue: Record "Dimension Value";
        LookupDimFilter: Text;
        LookupOk: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 213513] Dimension Filter has no value selects when call LookUpDimFilter of table "Dimension Value" with blank Dimension Code

        Initialize();
        LookupOk := DimensionValue.LookUpDimFilter('', LookupDimFilter);
        Assert.IsFalse(LookupOk, 'LookUpDimFilter returns True with blank dimension');
        Assert.AreEqual('', LookupDimFilter, 'LookUpDimFilter returns not blank Dimension Filter with blank dimension');
    end;

    [Test]
    [HandlerFunctions('SelectDimFromDimValueListModalPageHandler')]
    [Scope('OnPrem')]
    procedure UT_LookupDimValueFilterSelectDimValue()
    var
        DimensionValue: Record "Dimension Value";
        LookupDimFilter: Text;
        LookupOk: Boolean;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 213513] Dimension Filter has value when call LookUpDimFilter of table "Dimension Value" and select value on "Dimension Value List" page

        Initialize();
        LibraryDim.CreateDimWithDimValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LookupOk := DimensionValue.LookUpDimFilter(DimensionValue."Dimension Code", LookupDimFilter);
        Assert.IsTrue(LookupOk, 'LookUpDimFilter returns false');
        Assert.AreEqual(DimensionValue.Code, LookupDimFilter, 'LookUpDimFilter returns incorrect Dimension Filter');
    end;

    [Test]
    [HandlerFunctions('CancelSelectionFromDimValueListModalPageHandler')]
    [Scope('OnPrem')]
    procedure UT_LookupDimValueFilterNoSelection()
    var
        DimensionValue: Record "Dimension Value";
        LookupDimFilter: Text;
        LookupOk: Boolean;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 213513] Dimension Filter has no value when call LookUpDimFilter of table "Dimension Value" and cancel selection on "Dimension Value List" page

        Initialize();
        LibraryDim.CreateDimWithDimValue(DimensionValue);
        LookupOk := DimensionValue.LookUpDimFilter(DimensionValue."Dimension Code", LookupDimFilter);
        Assert.IsFalse(LookupOk, 'LookUpDimFilter returns true');
        Assert.AreEqual('', LookupDimFilter, 'LookUpDimFilter returns not blank Dimension Filter when no value was selected');
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DimensionsMultipleInItemListUnderSaaS()
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ItemList: TestPage "Item List";
    begin
        // [FEATURE] [UI] [SaaS] [Purchase]
        // [SCENARIO 215311] Action "Dimensions - Multiple" can be accessed on "Item List" page under SaaS
        Initialize();

        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Item with Default Dimension "X" with value "X1"
        LibraryInventory.CreateItem(Item);
        LibraryDim.CreateDefaultDimensionItem(DefaultDimension, Item."No.", TestDim, TestDimValue);

        // [GIVEN] Opened page "Item List"
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        LibraryVariableStorage.Enqueue(TestDim);
        LibraryVariableStorage.Enqueue(TestDimValue);

        // [WHEN] Press "Dimensions - Multiple" action on "Item List" page
        ItemList.DimensionsMultiple.Invoke();

        // [THEN] "Default Dimensions Multiple" page opens with "Dimension Code" = "X" and "Dimension Value Code" = "X1"
        // Verification done in DefaultDimensionsMultipleModalPageHandler

        LibraryVariableStorage.AssertEmpty(); // verifies that all passed values was used in handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_DimensionsSingleInCustomerListUnderSaaS()
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CustomerList: TestPage "Customer List";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [FEATURE] [UI] [SaaS] [Sales]
        // [SCENARIO 215311] Action "Dimensions - Single" can be accessed on "Customer List" page under SaaS

        Initialize();

        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Customer with Default Dimension "X" with value "X1"
        LibrarySales.CreateCustomer(Customer);
        LibraryDim.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", TestDim, TestDimValue);

        // [GIVEN] Opened page "Customer List"
        DefaultDimensions.Trap();
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [WHEN] Press "Dimensions - Single" action on "Customer List" page
        CustomerList.DimensionsSingle.Invoke();

        // [THEN] "Default Dimensions" page opens with "Dimension Code" = "X" and "Dimension Value Code" = "X1"
        DefaultDimensions."Dimension Code".AssertEquals(TestDim);
        DefaultDimensions."Dimension Value Code".AssertEquals(TestDimValue);
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DimensionsMultipleInCustomerListUnderSaaS()
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CustomerList: TestPage "Customer List";
    begin
        // [FEATURE] [UI] [SaaS] [Sales]
        // [SCENARIO 215311] Action "Dimensions - Multiple" can be accessed on "Customer List" page under SaaS

        Initialize();

        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Customer with Default Dimension "X" with value "X1"
        LibrarySales.CreateCustomer(Customer);
        LibraryDim.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", TestDim, TestDimValue);

        // [GIVEN] Opened page "Customer List"
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(TestDim);
        LibraryVariableStorage.Enqueue(TestDimValue);

        // [WHEN] Press "Dimensions - Multiple" action on "Customer List" page
        CustomerList.DimensionsMultiple.Invoke();

        // [THEN] "Default Dimensions Multiple" page opens with "Dimension Code" = "X" and "Dimension Value Code" = "X1"
        // Verification done in DefaultDimensionsMultipleModalPageHandler

        LibraryVariableStorage.AssertEmpty(); // verifies that all passed values was used in handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_DimensionsSingleInVendorListUnderSaaS()
    var
        Vendor: Record Vendor;
        DefaultDimension: Record "Default Dimension";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        VendorList: TestPage "Vendor List";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [FEATURE] [UI] [SaaS] [Purchase]
        // [SCENARIO 215311] Action "Dimensions - Single" can be accessed on "Vendor List" page under SaaS

        Initialize();

        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Vendor with Default Dimension "X" with value "X1"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDim.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", TestDim, TestDimValue);

        // [GIVEN] Opened page "Vendor List"
        DefaultDimensions.Trap();
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [WHEN] Press "Dimensions - Single" action on "Vendor List" page
        VendorList.DimensionsSingle.Invoke();

        // [THEN] "Default Dimensions" page opens with "Dimension Code" = "X" and "Dimension Value Code" = "X1"
        DefaultDimensions."Dimension Code".AssertEquals(TestDim);
        DefaultDimensions."Dimension Value Code".AssertEquals(TestDimValue);
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DimensionsMultipleInVendorListUnderSaaS()
    var
        Vendor: Record Vendor;
        DefaultDimension: Record "Default Dimension";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI] [SaaS] [Purchase]
        // [SCENARIO 215311] Action "Dimensions - Multiple" can be accessed on "Vendor List" page under SaaS

        Initialize();

        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Vendor with Default Dimension "X" with value "X1"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDim.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", TestDim, TestDimValue);

        // [GIVEN] Opened page "Vendor List"
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);
        LibraryVariableStorage.Enqueue(TestDim);
        LibraryVariableStorage.Enqueue(TestDimValue);

        // [WHEN] Press "Dimensions - Multiple" action on "Vendor List" page
        VendorList.DimensionsMultiple.Invoke();

        // [THEN] "Default Dimensions Multiple" page opens with "Dimension Code" = "X" and "Dimension Value Code" = "X1"
        // Verification done in DefaultDimensionsMultipleModalPageHandler

        LibraryVariableStorage.AssertEmpty(); // verifies that all passed values was used in handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_DimensionsSingleInItemListUnderSaaS()
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ItemList: TestPage "Item List";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [FEATURE] [UI] [SaaS] [Purchase]
        // [SCENARIO 215311] Action "Dimensions - Single" can be accessed on "Item List" page under SaaS

        Initialize();

        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Item with Default Dimension "X" with value "X1"
        LibraryInventory.CreateItem(Item);
        LibraryDim.CreateDefaultDimensionItem(DefaultDimension, Item."No.", TestDim, TestDimValue);

        // [GIVEN] Opened page "Item List"
        DefaultDimensions.Trap();
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        // [WHEN] Press "Dimensions - Single" action on "Item List" page
        ItemList.DimensionsSingle.Invoke();

        // [THEN] "Default Dimensions" page opens with "Dimension Code" = "X" and "Dimension Value Code" = "X1"
        DefaultDimensions."Dimension Code".AssertEquals(TestDim);
        DefaultDimensions."Dimension Value Code".AssertEquals(TestDimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShortcutDimensionsUpdatedOnDimSetIDValidation()
    var
        TempAllObj: Record AllObj temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: array[2] of Record "Dimension Value";
        StandardSalesLine: Record "Standard Sales Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
        JobJournalLine: Record "Job Journal Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ReminderHeader: Record "Reminder Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ResJournalLine: Record "Res. Journal Line";
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        FAAllocation: Record "FA Allocation";
        FAJournalLine: Record "FA Journal Line";
        InsuranceJournalLine: Record "Insurance Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceContractHeader: Record "Service Contract Header";
        StandardServiceLine: Record "Standard Service Line";
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PlanningComponent: Record "Planning Component";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        DimSetID: Integer;
        CountOfTablesWithFieldRelatedToDimSetEntryTable: Integer;
        CountOfTablesIgnored: Integer;
        CountOfLocalTablesIgnored: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217862] "Shortcut Dimension 1 Code" and "Shortcut Dimension 2 Code" updates on "Dimension Set ID" validation in all application tables except ignored

        Initialize();

        // [GIVEN] Dimension Set ID with two global dimensions: "DEPARTMENT" = "ADM"; "PROJECT" = "TOYOTA"
        GeneralLedgerSetup.Get();
        LibraryDim.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDim.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Global Dimension 2 Code");
        DimSetID := LibraryDim.CreateDimSet(0, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        DimSetID := LibraryDim.CreateDimSet(DimSetID, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] 118 tables in database which have field related to table "Dimension Set ID"
        CountOfTablesWithFieldRelatedToDimSetEntryTable := GetCountOfTablesWithFieldRelatedToDimSetEntryTable();

        // [GIVEN] Number of W1 tables ignored. They are either have "Dimension Set ID" field and do not have shortcut dimensions OR posted tables such as Item Ledger Entry where should be no logic for this field
        CountOfTablesIgnored := 78;

        // [GIVEN] 16 local tables ignored
        // There is additional codeunit which listens exposed event OnGetLocalTablesWithDimSetIDValidationIgnored and returns a count of local tables
        LibraryDim.GetLocalTablesWithDimSetIDValidationIgnored(CountOfLocalTablesIgnored);

        // [WHEN] Validate "Dimension Set ID" in all application tables except ignored and count tables validated
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, StandardSalesLine, StandardSalesLine.FieldNo("Dimension Set ID"),
          StandardSalesLine.FieldNo("Shortcut Dimension 1 Code"), StandardSalesLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, StandardPurchaseLine, StandardPurchaseLine.FieldNo("Dimension Set ID"),
          StandardPurchaseLine.FieldNo("Shortcut Dimension 1 Code"), StandardPurchaseLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, JobJournalLine, JobJournalLine.FieldNo("Dimension Set ID"),
          JobJournalLine.FieldNo("Shortcut Dimension 1 Code"), JobJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, GenJnlAllocation, GenJnlAllocation.FieldNo("Dimension Set ID"),
          GenJnlAllocation.FieldNo("Shortcut Dimension 1 Code"), GenJnlAllocation.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, BankAccReconciliation, BankAccReconciliation.FieldNo("Dimension Set ID"),
          BankAccReconciliation.FieldNo("Shortcut Dimension 1 Code"), BankAccReconciliation.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, BankAccReconciliationLine, BankAccReconciliationLine.FieldNo("Dimension Set ID"),
          BankAccReconciliationLine.FieldNo("Shortcut Dimension 1 Code"), BankAccReconciliationLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ReminderHeader, ReminderHeader.FieldNo("Dimension Set ID"),
          ReminderHeader.FieldNo("Shortcut Dimension 1 Code"), ReminderHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, FinanceChargeMemoHeader, FinanceChargeMemoHeader.FieldNo("Dimension Set ID"),
          FinanceChargeMemoHeader.FieldNo("Shortcut Dimension 1 Code"), FinanceChargeMemoHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, SalesHeader, SalesHeader.FieldNo("Dimension Set ID"),
          SalesHeader.FieldNo("Shortcut Dimension 1 Code"), SalesHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, SalesLine, SalesLine.FieldNo("Dimension Set ID"),
          SalesLine.FieldNo("Shortcut Dimension 1 Code"), SalesLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PurchaseHeader, PurchaseHeader.FieldNo("Dimension Set ID"),
          PurchaseHeader.FieldNo("Shortcut Dimension 1 Code"), PurchaseHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PurchaseLine, PurchaseLine.FieldNo("Dimension Set ID"),
          PurchaseLine.FieldNo("Shortcut Dimension 1 Code"), PurchaseLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ResJournalLine, ResJournalLine.FieldNo("Dimension Set ID"),
          ResJournalLine.FieldNo("Shortcut Dimension 1 Code"), ResJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, RequisitionLine, RequisitionLine.FieldNo("Dimension Set ID"),
          RequisitionLine.FieldNo("Shortcut Dimension 1 Code"), RequisitionLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ProductionOrder, ProductionOrder.FieldNo("Dimension Set ID"),
          ProductionOrder.FieldNo("Shortcut Dimension 1 Code"), ProductionOrder.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ProdOrderLine, ProdOrderLine.FieldNo("Dimension Set ID"),
          ProdOrderLine.FieldNo("Shortcut Dimension 1 Code"), ProdOrderLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ProdOrderComponent, ProdOrderComponent.FieldNo("Dimension Set ID"),
          ProdOrderComponent.FieldNo("Shortcut Dimension 1 Code"), ProdOrderComponent.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, FAAllocation, FAAllocation.FieldNo("Dimension Set ID"),
          FAAllocation.FieldNo("Global Dimension 1 Code"), FAAllocation.FieldNo("Global Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, FAJournalLine, FAJournalLine.FieldNo("Dimension Set ID"),
          FAJournalLine.FieldNo("Shortcut Dimension 1 Code"), FAJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, InsuranceJournalLine, InsuranceJournalLine.FieldNo("Dimension Set ID"),
          InsuranceJournalLine.FieldNo("Shortcut Dimension 1 Code"), InsuranceJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, TransferHeader, TransferHeader.FieldNo("Dimension Set ID"),
          TransferHeader.FieldNo("Shortcut Dimension 1 Code"), TransferHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, TransferLine, TransferLine.FieldNo("Dimension Set ID"),
          TransferLine.FieldNo("Shortcut Dimension 1 Code"), TransferLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ServiceHeader, ServiceHeader.FieldNo("Dimension Set ID"),
          ServiceHeader.FieldNo("Shortcut Dimension 1 Code"), ServiceHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ServiceItemLine, ServiceItemLine.FieldNo("Dimension Set ID"),
          ServiceItemLine.FieldNo("Shortcut Dimension 1 Code"), ServiceItemLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ServiceLine, ServiceLine.FieldNo("Dimension Set ID"),
          ServiceLine.FieldNo("Shortcut Dimension 1 Code"), ServiceLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ServiceContractHeader, ServiceContractHeader.FieldNo("Dimension Set ID"),
          ServiceContractHeader.FieldNo("Shortcut Dimension 1 Code"), ServiceContractHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, StandardServiceLine, StandardServiceLine.FieldNo("Dimension Set ID"),
          StandardServiceLine.FieldNo("Shortcut Dimension 1 Code"), StandardServiceLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, StandardGeneralJournalLine, StandardGeneralJournalLine.FieldNo("Dimension Set ID"),
          StandardGeneralJournalLine.FieldNo("Shortcut Dimension 1 Code"),
          StandardGeneralJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, StandardItemJournalLine, StandardItemJournalLine.FieldNo("Dimension Set ID"),
          StandardItemJournalLine.FieldNo("Shortcut Dimension 1 Code"), StandardItemJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, GenJournalLine, GenJournalLine.FieldNo("Dimension Set ID"),
          GenJournalLine.FieldNo("Shortcut Dimension 1 Code"), GenJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, ItemJournalLine, ItemJournalLine.FieldNo("Dimension Set ID"),
          ItemJournalLine.FieldNo("Shortcut Dimension 1 Code"), ItemJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, CashFlowWorksheetLine, CashFlowWorksheetLine.FieldNo("Dimension Set ID"),
          CashFlowWorksheetLine.FieldNo("Shortcut Dimension 1 Code"), CashFlowWorksheetLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, AssemblyHeader, AssemblyHeader.FieldNo("Dimension Set ID"),
          AssemblyHeader.FieldNo("Shortcut Dimension 1 Code"), AssemblyHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, AssemblyLine, AssemblyLine.FieldNo("Dimension Set ID"),
          AssemblyLine.FieldNo("Shortcut Dimension 1 Code"), AssemblyLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PlanningComponent, PlanningComponent.FieldNo("Dimension Set ID"),
          PlanningComponent.FieldNo("Shortcut Dimension 1 Code"), PlanningComponent.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PhysInvtOrderHeader, PhysInvtOrderHeader.FieldNo("Dimension Set ID"),
          PhysInvtOrderHeader.FieldNo("Shortcut Dimension 1 Code"), PhysInvtOrderHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PhysInvtOrderLine, PhysInvtOrderLine.FieldNo("Dimension Set ID"),
          PhysInvtOrderLine.FieldNo("Shortcut Dimension 1 Code"), PhysInvtOrderLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);

        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, InvtDocumentHeader, InvtDocumentHeader.FieldNo("Dimension Set ID"),
          InvtDocumentHeader.FieldNo("Shortcut Dimension 1 Code"), InvtDocumentHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, InvtDocumentLine, InvtDocumentLine.FieldNo("Dimension Set ID"),
          InvtDocumentLine.FieldNo("Shortcut Dimension 1 Code"), InvtDocumentLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);

        // Calls LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation for local tables through an exposed event OnVerifyShorcutDimCodesUpdatedOnDimSetIDValidationLocal and adds local tables to TempAllObj variable
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidationLocal(
          TempAllObj, DimSetID, DimensionValue[1].Code, DimensionValue[2].Code);

        // [THEN] "Shortcut Dimension 1 Code" is "ADM" and "Shortcut Dimension 2 Code" is "TOYOTA" in 35 tables (120 total - 69 W1 ignored - 16 local ignored)
        TempAllObj.Reset();
        Assert.RecordCount(
          TempAllObj, CountOfTablesWithFieldRelatedToDimSetEntryTable - CountOfTablesIgnored - CountOfLocalTablesIgnored);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToAssignBlockedDimensionToShortcutDimCode()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 221094] Not possible to assign blocked dimension to "Shortcut Dimension Code" field

        Initialize();
        LibraryDim.CreateDimension(Dimension);
        LibraryDim.BlockDimension(Dimension);
        LibraryDim.CreateDimensionValue(DimensionValue, Dimension.Code);

        VerifyDimValueCodeCannotBeAssignedToField(
          GenJournalLine, GenJournalLine.FieldNo("Shortcut Dimension 1 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          GenJournalLine, GenJournalLine.FieldNo("Shortcut Dimension 2 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          ServiceLine, ServiceLine.FieldNo("Shortcut Dimension 1 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          ServiceLine, ServiceLine.FieldNo("Shortcut Dimension 2 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          ServiceItemLine, ServiceItemLine.FieldNo("Shortcut Dimension 1 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          ServiceItemLine, ServiceItemLine.FieldNo("Shortcut Dimension 2 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          ServiceHeader, ServiceHeader.FieldNo("Shortcut Dimension 1 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          ServiceHeader, ServiceHeader.FieldNo("Shortcut Dimension 2 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          PurchaseLine, PurchaseLine.FieldNo("Shortcut Dimension 1 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          PurchaseLine, PurchaseLine.FieldNo("Shortcut Dimension 2 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          SalesLine, SalesLine.FieldNo("Shortcut Dimension 1 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          SalesLine, SalesLine.FieldNo("Shortcut Dimension 2 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          SalesHeader, SalesHeader.FieldNo("Shortcut Dimension 1 Code"), DimensionValue.Code);
        VerifyDimValueCodeCannotBeAssignedToField(
          SalesHeader, SalesHeader.FieldNo("Shortcut Dimension 2 Code"), DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionValueListCaptionUT()
    var
        DimensionValueList: TestPage "Dimension Value List";
        I: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254098] PAGE 560 "Dimension Value List" caption must contain Dimension Code

        Initialize();

        DimensionValueList.OpenNew();

        for I := 1 to 6 do begin
            DimensionValueList.FILTER.SetFilter("Global Dimension No.", Format(I));
            Assert.ExpectedMessage(GetShortcutDimCode(I), DimensionValueList.Caption);
        end;
        DimensionValueList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnGetCountOfLocalTablesUpdatesValue()
    var
        ERMDimension: Codeunit "ERM Dimension";
        Counter: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 304714] Local subscribers to OnGetLocalTablesWithDimSetIDValidationIgnored don't overwrite value, but add to it
        Initialize();

        Counter[1] := 0;
        Counter[2] := 1;

        BindSubscription(ERMDimension);
        LibraryDim.GetLocalTablesWithDimSetIDValidationIgnored(Counter[1]);
        LibraryDim.GetLocalTablesWithDimSetIDValidationIgnored(Counter[2]);

        Assert.AreEqual(Counter[1], Counter[2] - 1, StrSubstNo(CountOfLocalTablesErr, Counter[1] + 1, Counter[2]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimSelectionBufferGetDimSelectionTextReturnsCorrectValue()
    var
        SelectedDimension: Record "Selected Dimension";
        AnalysisView: Record "Analysis View";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
        DimSelectionText: Text[250];
    begin
        // [UT]
        // [SCENARIO 376135] "Dimension Selection Buffer".GetDimSelectionText returns correct value when "Dimension Code" has max length.
        Initialize();

        // [GIVEN] "Analysis View" and
        // [GIVEN] "Selection Dimension"."Dimension Code" with max length
        LibraryERM.CreateAnalysisView(AnalysisView);
        SelectedDimension.Init();
        SelectedDimension."User ID" := UserId();
        SelectedDimension."Object Type" := 1;
        SelectedDimension."Object ID" := 1;
        SelectedDimension."Dimension Code" :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(SelectedDimension."Dimension Code"), 0),
            1,
            MaxStrLen(SelectedDimension."Dimension Code"));
        SelectedDimension."Analysis View Code" := AnalysisView.Code;
        SelectedDimension.Insert();

        // [WHEN] Invoke "Dimension Selection Buffer".GetDimSelectionText
        DimSelectionText := DimensionSelectionBuffer.GetDimSelectionText(1, 1, AnalysisView.Code);

        // [THEN] Returned value must be equal "Selected Dimension"."Dimension Code"
        SelectedDimension.TestField("Dimension Code", DimSelectionText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimensionValueTestAutomaticCreation()
    var
        DimensionManagement: Codeunit DimensionManagement;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        NewDimSetID: Integer;
        DimensionCode: Code[20];
        DimensionValueCode: Code[20];
    begin
        // [Given] Dimension and Dimension Value Code
        DimensionCode := LibraryRandom.RandText(20);
        DimensionValueCode := LibraryRandom.RandText(20);

        // [When] SetDimensionValue is called 
        NewDimSetID := DimensionManagement.SetDimensionValue(0, DimensionCode, DimensionValueCode, true, true);

        // [Then] New Dimension Set is created
        Assert.AreNotEqual(0, NewDimSetID, 'New Dimension Set did not get created');

        // [Then] Dimension gets created
        Dimension.SetRange(Code, DimensionCode);
        Assert.RecordIsNotEmpty(Dimension);

        // [Then] Dimension Value gets created
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange("Code", DimensionValueCode);
        Assert.RecordIsNotEmpty(DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimensionValueTestErrorOnMissingDimension()
    var
        DimensionManagement: Codeunit DimensionManagement;
        NewDimSetID: Integer;
        DimensionCode: Code[20];
        DimensionValueCode: Code[20];
    begin
        // [Given] Dimension and Dimension Value Code
        DimensionCode := LibraryRandom.RandText(20);
        DimensionValueCode := LibraryRandom.RandText(20);

        // [When] SetDimensionValue is called without auto create of dimension
        asserterror NewDimSetID := DimensionManagement.SetDimensionValue(0, DimensionCode, DimensionValueCode, false, true);

        Assert.ExpectedError(StrSubstNo('The field Dimension Code of table Dimension Value contains a value (%1) that cannot be found in the related table (Dimension).', DimensionCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimensionValueTestErrorOnMissingDimensionValue()
    var
        DimensionManagement: Codeunit DimensionManagement;
        NewDimSetID: Integer;
        DimensionCode: Code[20];
        DimensionValueCode: Code[20];
    begin
        // [Given] Dimension and Dimension Value Code
        DimensionCode := LibraryRandom.RandText(20);
        DimensionValueCode := LibraryRandom.RandText(20);

        // [When] SetDimensionValue is called without auto create of dimension value
        asserterror NewDimSetID := DimensionManagement.SetDimensionValue(0, DimensionCode, DimensionValueCode, true, false);

        Assert.ExpectedError(StrSubstNo('The field Dimension Value Code of table Dimension Set Entry contains a value (%1) that cannot be found in the related table (Dimension Value).', DimensionValueCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimensionValueTestAutomaticCreationWithNames()
    var
        DimensionManagement: Codeunit DimensionManagement;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        NewDimSetID: Integer;
        DimensionCode: Code[20];
        DimensionValueCode: Code[20];
        DimensionName: Text[30];
        DimensionValueName: Text[30];
    begin
        // [Given] Dimension and Dimension Value Code
        DimensionCode := LibraryRandom.RandText(20);
        DimensionValueCode := LibraryRandom.RandText(20);
        DimensionName := LibraryRandom.RandText(30);
        DimensionValueName := LibraryRandom.RandText(30);

        // [When] SetDimensionValue is called 
        NewDimSetID := DimensionManagement.SetDimensionValue(0, DimensionCode, DimensionName, DimensionValueCode, DimensionValueName, true, true);

        // [Then] New Dimension Set is created
        Assert.AreNotEqual(0, NewDimSetID, 'New Dimension Set did not get created');

        // [Then] Dimension gets Created with name assigned
        Dimension.Get(DimensionCode);
        Assert.AreEqual(DimensionName, Dimension.Name, 'Dimension Name did not get set correctly');

        // [Then] Dimension Value gets Created
        DimensionValue.Get(DimensionCode, DimensionValueCode);
        Assert.AreEqual(DimensionValueName, DimensionValue.Name, 'Dimension value Name did not get set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimensionValueTestEmptyDimensionCode()
    var
        DimensionManagement: Codeunit DimensionManagement;
        NewDimSetID: Integer;
        DimensionCode: Code[20];
        DimensionValueCode: Code[20];
    begin
        // [Given] Empty Dimension and Dimension Value Code
        DimensionCode := '';
        DimensionValueCode := LibraryRandom.RandText(20);

        // [When] SetDimensionValue is called 
        NewDimSetID := DimensionManagement.SetDimensionValue(0, DimensionCode, DimensionValueCode, true, true);

        // [Then] Dimension Set ID did not get changed
        Assert.AreEqual(0, NewDimSetID, 'Dimension Set did not get changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimensionValueTestEmptyDimensionValueCode()
    var
        DimensionManagement: Codeunit DimensionManagement;
        NewDimSetID: Integer;
        DimensionCode: Code[20];
        DimensionValueCode: Code[20];
    begin
        // [Given] Dimension and Empty Dimension Value Code
        DimensionCode := LibraryRandom.RandText(20);
        DimensionValueCode := '';

        // [When] SetDimensionValue is called 
        NewDimSetID := DimensionManagement.SetDimensionValue(0, DimensionCode, DimensionValueCode, true, true);

        // [Then] Dimension Set ID did not get changed
        Assert.AreEqual(0, NewDimSetID, 'Dimension Set did not get changed');
    end;

    [Test]
    procedure GetDimSetFiltersChunksWhenLimitOfDimensionSetIdsReached()
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        Filters: List of [Text];
        SecondFilter: Text;
        i: Integer;
    begin
        for i := 1 to 1002 do begin
            TempDimensionSetEntry."Dimension Set ID" := i;
            TempDimensionSetEntry."Dimension Code" := 'TEST';
            TempDimensionSetEntry.Insert();
        end;
        Filters := LibraryDim.ChunkDimSetFilters(TempDimensionSetEntry);
        SecondFilter := Filters.Get(2);
        Assert.AreEqual(2, Filters.Count, 'Dimension Set Ids should be chunked when threshold of parameters (1001) is reached.');
        Assert.AreEqual('1002', SecondFilter, 'The second filter should be the last Dimension Set Id.');
    end;

    [Test]
    procedure GetDimSetFiltersDoesNotChunksWhenLimitOfDimensionSetIdsNotReached()
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        Filters: List of [Text];
    begin
        TempDimensionSetEntry."Dimension Set ID" := 1;
        TempDimensionSetEntry."Dimension Code" := 'DIM1';
        TempDimensionSetEntry.Insert();
        TempDimensionSetEntry."Dimension Set ID" := 2;
        TempDimensionSetEntry."Dimension Code" := 'DIM2';
        TempDimensionSetEntry.Insert();
        Filters := LibraryDim.ChunkDimSetFilters(TempDimensionSetEntry);
        Assert.AreEqual(1, Filters.Count, 'Dimension Set Ids should not be chunked for only two dimension set entries.');
        Assert.AreEqual('1|2', Filters.Get(1), 'The filter should contain all Dimension Set Ids.');
    end;

    local procedure Initialize()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GenJnlBatch: Record "Gen. Journal Batch";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension");
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension");

        // Create test dimensions
        LibraryDim.CreateDimension(Dimension);
        TestDim := Dimension.Code;
        LibraryDim.CreateDimensionValue(DimensionValue, Dimension.Code);
        TestDimValue := DimensionValue.Code;
        LibraryDim.CreateDimensionValue(DimensionValue, Dimension.Code);
        TestDimValue2 := DimensionValue.Code;

        LibraryDim.CreateDimension(Dimension);
        TestDim2 := Dimension.Code;
        LibraryDim.CreateDimensionValue(DimensionValue, Dimension.Code);
        TestDim2Value := DimensionValue.Code;

        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        JournalTemplate := GenJnlBatch."Journal Template Name";
        JournalBatch := GenJnlBatch.Name;
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension");
    end;

    local procedure ModifyJnlDimSetID(var GenJnlLine: Record "Gen. Journal Line"; DimSetID: Integer)
    begin
        GenJnlLine.Validate("Dimension Set ID", DimSetID);
        GenJnlLine.Modify(true);
    end;

    local procedure ValPosting_Setup(var GLAccount: Record "G/L Account"; var Customer: Record Customer; var DefaultDimension: Record "Default Dimension"; var GenJnlLine: Record "Gen. Journal Line"; ValuePosting: Enum "Default Dimension Value Posting Type")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibrarySales.CreateCustomer(Customer);
        if ValuePosting = DefaultDimension."Value Posting"::"No Code" then
            CreateDefaultDimCustomer(DefaultDimension, Customer."No.", TestDim, '', ValuePosting)
        else
            CreateDefaultDimCustomer(DefaultDimension, Customer."No.", TestDim, TestDimValue, ValuePosting);

        CreateJournalLine(GenJnlLine, JournalTemplate, JournalBatch, GenJnlLine."Account Type"::Customer, Customer."No.",
          GenJnlLine."Document Type"::Invoice, 100, GenJnlLine."Bal. Account Type"::"G/L Account", GLAccount."No.");
    end;

    local procedure NegativeTest(var GenJnlLine: Record "Gen. Journal Line"; ExpectError: Text[250])
    begin
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
        Assert.AreEqual(ExpectError, GetLastErrorText, UnknownError);
    end;

    local procedure PossitiveTest(var GenJnlLine: Record "Gen. Journal Line"; DimSetID: Integer)
    begin
        GenJnlLine.Validate("Dimension Set ID", DimSetID);
        GenJnlLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
    end;

    local procedure CreateJournalLine(var GenJnlLine: Record "Gen. Journal Line"; JnlTemplate: Code[10]; JnlBatch: Code[10]; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; Amount: Decimal; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(GenJnlLine, JnlTemplate, JnlBatch, DocType, AccType, AccNo, Amount);
        GenJnlLine.Validate("Bal. Account Type", BalAccType);
        GenJnlLine.Validate("Bal. Account No.", BalAccNo);
        GenJnlLine.Modify(true);
    end;

    local procedure CreateJournalLineByGeneralJournalPage() DocumentNo: Code[20]
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        GenJournalBatch.Get(JournalTemplate, JournalBatch);
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Account Type".SetValue(GenJournalLine."Account Type"::Vendor);
        LibraryPurchase.CreateVendor(Vendor);
        GeneralJournal."Account No.".SetValue(Vendor."No.");
        DocumentNo := GeneralJournal."Document No.".Value();
        GeneralJournal.Close();

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100, 2));  // Use Random Amount because value is not important.
        GenJournalLine.Modify(true);
    end;

    local procedure CreateDefaultDimCustomer(var DefaultDimension: Record "Default Dimension"; CustomerNo: Code[20]; DimCode: Code[20]; DimValue: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type")
    begin
        LibraryDim.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimCode, DimValue);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateInitialSetupForVendorAccountTypeDefaultDimension(var DefaultDimension: Record "Default Dimension"; var GLAccountNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
    begin
        LibraryDim.CreateAccTypeDefaultDimension(
          DefaultDimension, DATABASE::Vendor, TestDim, TestDimValue, DefaultDimension."Value Posting"::"Same Code");
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccountNo := GLAccount."No.";
        exit(Vendor."No.");
    end;

    local procedure CreateDimSet(DimensionValue: Record "Dimension Value"): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimSetEntry.Insert();

        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure CreateTwoDimValuesWithLongNames(var DimensionValue: array[2] of Record "Dimension Value")
    begin
        LibraryDim.CreateDimWithDimValue(DimensionValue[1]);
        UpdateDimensionValueName(DimensionValue[1]);

        LibraryDim.CreateDimensionValue(DimensionValue[2], DimensionValue[1]."Dimension Code");
        UpdateDimensionValueName(DimensionValue[2]);
    end;

    local procedure BlockedDimensionShortcutScenario(Level: Option)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
        DimSetId: Integer;
    begin
        // Scenario verifies usage of shortcut 1 dimension, but it is valid for other shourtcuts

        // Setup
        Initialize();

        Dimension.Get(LibraryERM.GetGlobalDimensionCode(1));
        LibraryDim.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimSetId := CreateDimSet(DimensionValue);
        MakeDimOrDimValueBlocked(Dimension, DimensionValue, Level);

        // Exercise
        asserterror DimMgt.ValidateShortcutDimValues(1, DimensionValue.Code, DimSetId);

        // Verify: error message should contain "is blocked"
        Assert.ExpectedError(BlockedErr);
    end;

    local procedure FindDimensionSetID(DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        exit(GLEntry."Dimension Set ID");
    end;

    local procedure MakeDimOrDimValueBlocked(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value"; Level: Option)
    begin
        case Level of
            BlockedLevel::Dimension:
                begin
                    Dimension.Validate(Blocked, true);
                    Dimension.Modify(true);
                end;
            BlockedLevel::"Dimension Value":
                begin
                    DimensionValue.Validate(Blocked, true);
                    DimensionValue.Modify(true);
                end;
        end;
    end;

    local procedure GetCountOfTablesWithFieldRelatedToDimSetEntryTable(): Integer
    var
        TempAllObj: Record AllObj temporary;
        "Field": Record "Field";
    begin
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(Enabled, true);
        Field.SetRange(RelationTableNo, DATABASE::"Dimension Set Entry");
        Field.SetFilter(TableNo, '<130000|>149999'); // excluding Test tables
        Field.FindSet();
        TempAllObj."Object Type" := TempAllObj."Object Type"::Table;
        repeat
            TempAllObj."Object ID" := Field.TableNo;
            if TempAllObj.Insert() then;
        until Field.Next() = 0;
        exit(TempAllObj.Count);
    end;

    local procedure GetShortcutDimCode(DimNo: Integer): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        case DimNo of
            1:
                exit(GeneralLedgerSetup."Global Dimension 1 Code");
            2:
                exit(GeneralLedgerSetup."Global Dimension 2 Code");
            3:
                exit(GeneralLedgerSetup."Shortcut Dimension 3 Code");
            4:
                exit(GeneralLedgerSetup."Shortcut Dimension 4 Code");
            5:
                exit(GeneralLedgerSetup."Shortcut Dimension 5 Code");
            6:
                exit(GeneralLedgerSetup."Shortcut Dimension 6 Code");
            7:
                exit(GeneralLedgerSetup."Shortcut Dimension 7 Code");
            8:
                exit(GeneralLedgerSetup."Shortcut Dimension 8 Code");
        end;
    end;

    local procedure UpdateDimensionValueCode(DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.Validate("Dimension Value Code", TestDimValue2);
        DimensionSetEntry.Modify(true);
    end;

    local procedure UpdateDimensionValueName(var DimensionValue: Record "Dimension Value")
    begin
        DimensionValue.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(DimensionValue.Name)));
        DimensionValue.Modify(true);
    end;

    local procedure VerifyPostedJournalLineDimensions(DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.SetRange("Dimension Value Code", DimensionValueCode);
        DimensionSetEntry.FindFirst();
    end;

    local procedure VerifyReclasDimSetBufferDimNames(ReclasDimensionSetBuffer: Record "Reclas. Dimension Set Buffer"; ExpectedDimValueName: Text[50]; ExpectedNewDimValueName: Text[50])
    begin
        ReclasDimensionSetBuffer.CalcFields("Dimension Value Name", "New Dimension Value Name");
        ReclasDimensionSetBuffer."Dimension Value Name" := CopyStr(ReclasDimensionSetBuffer."Dimension Value Name", 1, MaxStrLen(ReclasDimensionSetBuffer."Dimension Value Name"));
        ReclasDimensionSetBuffer."New Dimension Value Name" := CopyStr(ReclasDimensionSetBuffer."New Dimension Value Name", 1, MaxStrLen(ReclasDimensionSetBuffer."New Dimension Value Name"));
        Assert.AreEqual(ExpectedDimValueName, ReclasDimensionSetBuffer."Dimension Value Name", ReclasDimensionSetBuffer.FieldCaption("Dimension Value Name"));
        Assert.AreEqual(ExpectedNewDimValueName, ReclasDimensionSetBuffer."New Dimension Value Name", ReclasDimensionSetBuffer.FieldCaption("New Dimension Value Name"));
    end;

    local procedure VerifyDimValueCodeCannotBeAssignedToField("Record": Variant; FieldID: Integer; DimValueCode: Code[20])
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(Record);
        FieldRef := RecRef.Field(FieldID);
        asserterror FieldRef.Validate(DimValueCode);
        Assert.ExpectedError(StrSubstNo(DimValueNotFoundErr, DimValueCode));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries."Dimension Code".SetValue(TestDim);
        EditDimensionSetEntries.DimensionValueCode.SetValue(TestDimValue);
        EditDimensionSetEntries.New();
        EditDimensionSetEntries."Dimension Code".SetValue(TestDim2);
        EditDimensionSetEntries.DimensionValueCode.SetValue(TestDim2Value);
        EditDimensionSetEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectDimFromDimValueListModalPageHandler(var DimensionValueList: TestPage "Dimension Value List")
    begin
        DimensionValueList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        DimensionValueList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelSelectionFromDimValueListModalPageHandler(var DimensionValueList: TestPage "Dimension Value List")
    begin
        DimensionValueList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DefaultDimensionsMultipleModalPageHandler(var DefaultDimensionsMultiple: TestPage "Default Dimensions-Multiple")
    begin
        DefaultDimensionsMultiple."Dimension Code".AssertEquals(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple."Dimension Value Code".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Dimension", 'OnGetLocalTablesWithDimSetIDValidationIgnored', '', false, false)]
    local procedure AddToCountOfLocalTablesWithDimSetIDValidationIgnored(var CountOfTablesIgnored: Integer)
    begin
        CountOfTablesIgnored += 5;
    end;
}

