codeunit 134477 "ERM Dimension General Part-1"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ExistError: Label '%1 for %2 %3 must not exist.';
        WrongValueErr: Label 'Wrong value of field %1 in table %2.';
        WrongCaptionErr: Label 'Wrong Caption %1.';
        InvalidColumnIndexErr: Label 'The ColumnNo param is outside the permitted range.';
        PKRangeMsg: Label '%1..%2', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoicePaymentForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Dimension on G/L Entry after Apply Invoice on Payment for Customer.

        // 1. Setup: Create Customer with Default Dimension, Create and Post General Journal Line with Document Type Invoice and Payment.
        Initialize();
        CreateCustomerWithDimension(DefaultDimension);

        // Use Random because value is not important.
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Customer, DefaultDimension."No.", LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Apply Invoice on Payment.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", -GenJournalLine.Amount);

        // 3. Verify: Verify Dimension on created G/L Entries.
        VerifyAppliedEntriesDimension(GenJournalLine."Document No.", GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoicePaymentForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Dimension on G/L Entry after Apply Invoice on Payment for Vendor.

        // 1. Setup: Create Vendor with Default Dimension, Create and Post General Journal Line with Document Type Invoice and Payment.
        Initialize();

        // Use Random because value is not important.
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendorWithDimension(), -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Apply Invoice on Payment.
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", -GenJournalLine.Amount);

        // 3. Verify: Verify Dimension on created G/L Entries.
        VerifyAppliedEntriesDimension(GenJournalLine."Document No.", GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeGlobalDimensionOnItem()
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // [FEATURE] [Change Global Dimensions]
        // [SCENARIO] Global Dimension on Item after Change the Global Dimension.

        // [GIVEN] Create Item, Dimension, Dimension Value and attach Dimension on Item.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryInventory.CreateItem(Item);
        CreateItemWithDimension(DefaultDimension, Item."No.");

        // [WHEN] Change "Global Dimension 2 Code" to 'X' on General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensions(GeneralLedgerSetup."Global Dimension 1 Code", DefaultDimension."Dimension Code");

        // [THEN] "Global Dimension 2 Code" is 'X' on Item.
        Item.Get(Item."No.");
        Item.TestField("Global Dimension 2 Code", DefaultDimension."Dimension Value Code");

        // 4. Teardown: Rollback the Default Global Dimension 2 Code on General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensions(
          GeneralLedgerSetup."Global Dimension 1 Code", GeneralLedgerSetup."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateDefaultDimension()
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Default Dimension creation with new Dimension.

        // 1. Setup: Create Dimension.
        Initialize();
        CreateDimensionWithValue(DimensionValue);

        // 2. Exercise: Create Default Dimension for G/L Account.
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, '', DimensionValue."Dimension Code", DimensionValue.Code);

        // 3. Verify: Verify Default Dimension created for G/L Account.
        DefaultDimension.SetRange("Dimension Code", DimensionValue."Dimension Code");
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", '');
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimension()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Default Dimension deleted on deletion of Dimension.

        // 1. Setup: Create Dimension and Default Dimension for G/L Account.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, '', Dimension.Code, '');

        // 2. Exercise: Delete Dimension.
        Dimension.Delete(true);

        // 3. Verify: Verify Default Dimension successfully deleted.
        Assert.IsFalse(
          DefaultDimension.Get(DATABASE::"G/L Account", '', Dimension.Code),
          StrSubstNo(ExistError, DefaultDimension.TableCaption(), DefaultDimension.FieldCaption("Dimension Code"), Dimension.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeShortcutDimensionBlocked()
    var
        Dimension: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Change Global Dimensions]
        // [SCENARIO] Shortcut Dimension 2 Code successfully updated after Changing Global Dimension 2 Code on General Ledger Setup with Blocked Dimension.

        // [GIVEN] Create Dimension and Blocked it.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.BlockDimension(Dimension);

        // [WHEN] Change "Global Dimension 2 Code" to 'X' on General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensions(GeneralLedgerSetup."Global Dimension 1 Code", Dimension.Code);

        // [THEN] "Shortcut Dimension 2 Code" is 'X' on General Ledger Setup.
        VerifyShortcutDimension(GeneralLedgerSetup."Global Dimension 1 Code", Dimension.Code);

        // 4. Teardown: Rollback the Default Global Dimension 2 Code on General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensions(
          GeneralLedgerSetup."Global Dimension 1 Code", GeneralLedgerSetup."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeGlobalDimensionWithBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
    begin
        // [FEATURE] [Change Global Dimensions]
        // [SCENARIO] Shortcut Dimension 1 Code and Shortcut Dimension 2 Code successfully updated after Changing Global Dimension 1 Code and
        // [SCENARIO] Global Dimension 2 code to Blank value on General Ledger Setup.

        // [GIVEN] Create Dimension.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);

        // [WHEN] Change "Global Dimension 1 Code" to 'X' and "Global Dimension 2 Code" to <Blank> on General Ledger Setup.
        GeneralLedgerSetup.Get();
        LibraryDimension.RunChangeGlobalDimensions(Dimension.Code, '');

        // [THEN] "Shortcut Dimension 1 Code" is 'X' and "Shortcut Dimension 2 Code" is <blank> on General Ledger Setup.
        VerifyShortcutDimension(Dimension.Code, '');

        // 4. Teardown: Rollback the Default Global Dimension 1 Code and Global Dimension 2 Code on General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensions(
          GeneralLedgerSetup."Global Dimension 1 Code", GeneralLedgerSetup."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeShortcutDimension()
    var
        Dimension: Record Dimension;
        Dimension2: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Test Shortcut Dimension 3 Code and Shortcut Dimension 4 Code successfully updated on General Ledger Setup.

        // 1. Setup: Create 2 Dimensions.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimension(Dimension2);

        // 2. Exercise: Change Shortcut Dimension 3 Code and Shortcut Dimension 4 Code successfully updated on General Ledger Setup.
        LibraryERM.SetShortcutDimensionCode(3, Dimension.Code);
        LibraryERM.SetShortcutDimensionCode(4, Dimension2.Code);

        // 3. Verify: Verify Shortcut Dimension 3 Code and Shortcut Dimension 4 Code on General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.TestField("Shortcut Dimension 4 Code", Dimension2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShortcutDimensionSameGlobal()
    begin
        // Test error occurs on updating Shortcut Dimension 3 Code same as Global Dimension 1 Code on General Ledger Setup.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Change Shortcut Dimension 3 Code on General Ledger Setup.
        asserterror LibraryERM.SetShortcutDimensionCode(3, LibraryERM.GetGlobalDimensionCode(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShortcutDimensionSameShortcut()
    var
        Dimension: Record Dimension;
    begin
        // Test error occurs on updating Shortcut Dimension 3 Code same as Shortcut Dimension 4 Code on General Ledger Setup.

        // 1. Setup: Create Dimension and attach as Shortcut Dimension 4 Code on General Ledger Setup.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.SetShortcutDimensionCode(3, '');
        LibraryERM.SetShortcutDimensionCode(4, Dimension.Code);

        // 2. Exercise: Change Shortcut Dimension 3 Code on General Ledger Setup.
        asserterror LibraryERM.SetShortcutDimensionCode(3, LibraryERM.GetShortcutDimensionCode(4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteShortcutDimension()
    var
        Dimension: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Test Shortcut Dimension 7 Code on General Ledger Setup after Deleting Dimension.

        // 1. Setup: Create Dimension and attach on General Ledger Setup as Shortcut Dimension 7 Code.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.SetShortcutDimensionCode(7, Dimension.Code);

        // 2. Exercise: Delete Dimension.
        Dimension.Delete(true);

        // 3. Verify: Verify Shortcut Dimension 7 Code on General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Shortcut Dimension 7 Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithGLBudgetName()
    var
        Dimension: Record Dimension;
    begin
        // Test error Occurs on deleting Dimension attached on G/L Budget Name.

        // 1. Setup: Create Dimension, attach on General Ledger Setup as Shortcut Dimension 7 Code and Create New G/L Budget Name, update
        // Dimension as Budget Dimension 1 Code on it.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.SetShortcutDimensionCode(7, Dimension.Code);
        CreateGLBudgetNameDimension(Dimension.Code);

        // 2. Exercise: Delete Dimension.
        asserterror Dimension.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithAnalysisView()
    var
        Dimension: Record Dimension;
    begin
        // Test error Occurs on deleting Dimension attached on Analysis View.

        // 1. Setup: Create Dimension, attach on General Ledger Setup as Shortcut Dimension 7 Code and Create New Analysis View, update
        // Dimension as Dimension 1 Code on it.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.SetShortcutDimensionCode(7, Dimension.Code);
        CreateAnalysisViewDimension(Dimension.Code);

        // 2. Exercise: Delete Dimension.
        asserterror Dimension.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DimensionValueWithExistingCode()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // Test error occurs on creating Dimension Value with same code previously exist Dimension value Code.

        // 1. Setup: Create Dimension Value for any Dimension.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode := DimensionValue.Code;

        // 2. Exercise: Create Dimension Value and Rename to already exist Dimension Value code.
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        asserterror DimensionValue.Rename(Dimension.Code, DimensionValueCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DimensionValueWithConflict()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occurs on creating Dimension Value with Conflict keyword as Code.

        // 1. Setup: Find Dimension.
        Initialize();
        LibraryDimension.FindDimension(Dimension);

        // 2. Exercise: Create Dimension value and validate Code as Conflict keyword.
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        asserterror DimensionValue.Validate(Code, '(conflict)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameDimensionValueAndCode()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        // Test Dimension on Customer Ledger Entry after Posting General Journal with Same value as Code and Dimension Code on Dimension
        // Value.

        // 1. Setup: Create Customer, Dimension, Dimension Value with Same Code as Dimension Code, General Journal with Document
        // Type Invoice for Customer and Create Dimension for General Journal Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionWithValue(DimensionValue);
        DimensionValue.Rename(DimensionValue."Dimension Code", DimensionValue."Dimension Code");
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.");
        DimensionSetID := GenJournalLine."Dimension Set ID";

        // 2. Exercise: Post the General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Dimension on Customer Ledger Entry.
        VerifyCustomerLedgerDimension(Customer."No.", DimensionSetID);
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, DimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedDimensionTypeStandard()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Dimension Set Entry with Blocked Dimension Value having Dimension Value Type Standard.
        JournalLineBlockedDimension(DimensionValue."Dimension Value Type"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedDimensionTypeHeading()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Dimension Set Entry with Blocked Dimension Value having Dimension Value Type Heading.
        JournalLineBlockedDimension(DimensionValue."Dimension Value Type"::Heading);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedDimensionTypeTotal()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Dimension Set Entry with Blocked Dimension Value having Dimension Value Type Total.
        JournalLineBlockedDimension(DimensionValue."Dimension Value Type"::Total);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedDimensionTypeBeginTotal()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Dimension Set Entry with Blocked Dimension Value having Dimension Value Type Begin-Total.
        JournalLineBlockedDimension(DimensionValue."Dimension Value Type"::"Begin-Total");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedDimensionTypeEndTotal()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Dimension Set Entry with Blocked Dimension Value having Dimension Value Type End-Total.
        JournalLineBlockedDimension(DimensionValue."Dimension Value Type"::"End-Total");
    end;

    local procedure JournalLineBlockedDimension(DimensionValueType: Option)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
    begin
        // 1. Setup: Create Customer, Dimension, Dimension Value, update Dimension Value Type as per parameter and Blocked it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionWithValue(DimensionValue);
        UpdateDimensionValueWithBlock(DimensionValue, DimensionValueType);

        // 2. Exercise: Create General Journal with Dimension.
        asserterror CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionForCustomer()
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Default Dimension for customer with blocked Dimension Value.

        // 1. Setup: Create Customer, Dimension, Dimension Value and Blocked it
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionWithValue(DimensionValue);
        UpdateDimensionValueWithBlock(DimensionValue, DimensionValue."Dimension Value Type"::Standard);

        // 2. Exercise: Create Default Dimension for Customer.
        asserterror LibraryDimension.CreateDefaultDimensionCustomer(
            DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvalidDimensionValueType()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on updating wrong Dimension Value Type on Dimension Value.

        // 1. Setup: Create Dimension and Dimension Value.
        Initialize();
        CreateDimensionWithValue(DimensionValue);

        // 2. Exercise: Update Dimension Value Type as Dimension Code.
        asserterror Evaluate(DimensionValue."Dimension Value Type", DimensionValue."Dimension Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineValueTypeHeading()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Dimension Set Entry with Dimension Value having Dimension Value Type as Heading.
        JournalLineWithValueType(DimensionValue."Dimension Value Type"::Heading);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineValueTypeTotal()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Dimension Set Entry with Dimension Value having Dimension Value Type as Total.
        JournalLineWithValueType(DimensionValue."Dimension Value Type"::Total);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineValueTypeEndTotal()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Dimension Set Entry with Dimension Value having Dimension Value Type as End-Total.
        JournalLineWithValueType(DimensionValue."Dimension Value Type"::"End-Total");
    end;

    local procedure JournalLineWithValueType(DimensionValueType: Option)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
    begin
        // 1. Setup: Create Customer, Dimension, Dimension Value and update Dimension Value Type as per parameter.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionWithValue(DimensionValue);
        UpdateDimensionValueType(DimensionValue, DimensionValueType);

        // 2. Exercise: Create General Journal with Dimension.
        asserterror CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnCustomerLedgerEntry()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        // Test Dimension on Customer Ledger Entry after Posting General Journal with Dimension Value having Dimension Value Type as
        // Begin-Total.

        // 1. Setup: Create Customer, Dimension, Dimension Value, update Dimension Value Type as Begin-Total, General Journal with
        // Document Type Invoice for Customer and Create Dimension for General Journal Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionWithValue(DimensionValue);
        UpdateDimensionValueType(DimensionValue, DimensionValue."Dimension Value Type"::"Begin-Total");
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.");
        DimensionSetID := GenJournalLine."Dimension Set ID";

        // 2. Exercise: Post the General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Dimension on Customer Ledger Entry.
        VerifyCustomerLedgerDimension(Customer."No.", DimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionWithHeading()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Default Dimension for customer with Dimension Value having Dimension Value Type as Heading.
        DefaultDimensionWithValueType(DimensionValue."Dimension Value Type"::Heading);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionWithTotal()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Default Dimension for customer with Dimension Value having Dimension Value Type as Total.
        DefaultDimensionWithValueType(DimensionValue."Dimension Value Type"::Total);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionWithEndTotal()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occur on creating Default Dimension for customer with Dimension Value having Dimension Value Type as End-Total.
        DefaultDimensionWithValueType(DimensionValue."Dimension Value Type"::"End-Total");
    end;

    local procedure DefaultDimensionWithValueType(DimensionValueType: Option)
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        // 1. Setup: Create Customer, Dimension, Dimension Value and update Dimension Value Type as per parameter.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionWithValue(DimensionValue);
        UpdateDimensionValueType(DimensionValue, DimensionValueType);

        // 2. Exercise: Create Default Dimension for Customer.
        asserterror LibraryDimension.CreateDefaultDimensionCustomer(
            DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyValueTypeAfterPosting()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occurs on updating Dimension Value Type as Heading on Dimension Value after Posting General Journal.

        // 1. Setup: Create Customer, Dimension, Dimension Value, Create and Post General Journal with Dimension.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionWithValue(DimensionValue);
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Update Dimension Value Type as Heading on Dimension Value.
        asserterror DimensionValue.Validate("Dimension Value Type", DimensionValue."Dimension Value Type"::Heading);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure RenameDimensionValueCode()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // Test Dimension Value Code successfully renamed.

        // 1. Setup: Create Dimension Value for any Dimension.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Dimension Value", DimensionValue.FieldNo(Code)));

        // 2. Exercise: Rename Dimension Value Code.
        DimensionValue.Rename(Dimension.Code, DimensionValueCode);

        // 3. Verify: Verify renamed Dimension Value Code.
        DimensionValue.TestField(Code, DimensionValueCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure RenameDimensionValueName()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValueName: Text[50];
    begin
        // Test Dimension Value Name successfully Modify.

        // 1. Setup: Create Dimension Value for any Dimension.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueName :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Name), DATABASE::"Dimension Value"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Dimension Value", DimensionValue.FieldNo(Name)));

        // 2. Exercise: Update Dimension Value Name.
        DimensionValue.Validate(Name, DimensionValueName);
        DimensionValue.Modify(true);

        // 3. Verify: Verify Dimension Value Name.
        DimensionValue.Get(Dimension.Code, DimensionValue.Code);
        DimensionValue.TestField(Name, DimensionValueName);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure RenameBlockDimensionValueCode()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // Test Dimension Value Code successfully renamed for Blocked Dimension Value.

        // 1. Setup: Create Dimension Value for any Dimension and Block it.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        UpdateDimensionValue(DimensionValue, DimensionValue."Dimension Value Type"::Standard);
        DimensionValueCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Dimension Value", DimensionValue.FieldNo(Code)));

        // 2. Exercise: Rename the Dimension Value Code.
        DimensionValue.Rename(Dimension.Code, DimensionValueCode);

        // 3. Verify: Verify renamed Dimension Value.
        DimensionValue.TestField(Code, DimensionValueCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure BlankDimensionValueCode()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occurs on rename Dimension Value Code to Blank.

        // 1. Setup: Create Dimension Value for any Dimension.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        // 2. Exercise: Rename Dimension Value Code.
        asserterror DimensionValue.Rename(Dimension.Code, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionValueAfterPosting()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValueCode: Code[20];
        DimensionSetID: Integer;
    begin
        // Test Dimension Value Code successfully renamed the after Posting General Journal.

        // 1. Setup: Create Customer, Dimension Value, Create and Post General Journal with Dimension.
        Initialize();
        GeneralLedgerSetup.Get();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.");
        DimensionSetID := GenJournalLine."Dimension Set ID";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DimensionValueCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Dimension Value", DimensionValue.FieldNo(Code)));

        // 2. Exercise: Rename Dimension Value Code.
        DimensionValue.Rename(GeneralLedgerSetup."Global Dimension 1 Code", DimensionValueCode);

        // 3. Verify: Verify Dimension Value Code on Dimension Set Entry.
        DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimensionValue()
    var
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        // Test deletion of Dimension Value.

        // 1. Setup: Create Dimension and Dimension Value.
        Initialize();
        CreateDimensionWithValue(DimensionValue);

        // 2. Exercise: Delete Dimension Value.
        DimensionValue2.Get(DimensionValue."Dimension Code", DimensionValue.Code);
        DimensionValue2.Delete(true);

        // 3. Verify: Verify Dimension Value deleted.
        Assert.IsFalse(
          DimensionValue2.Get(DimensionValue."Dimension Code", DimensionValue.Code),
          StrSubstNo(ExistError, DimensionValue.TableCaption(), DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDefaultDimensionValue()
    var
        DimensionValue: Record "Dimension Value";
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        DimensionCode: Code[20];
    begin
        // Test Default Dimension deleted on deletion of Dimension Value.

        // 1. Setup: Create Dimension, Dimension Value, Customer with Default Dimension.
        Initialize();
        CreateDimensionWithValue(DimensionValue);
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DimensionCode := DimensionValue."Dimension Code";

        // 2. Exercise: Delete Dimension Value.
        DimensionValue.Delete(true);

        // 3. Verify: Verify Default Dimension deleted.
        Assert.IsFalse(
          DefaultDimension.Get(DATABASE::Customer, Customer."No.", DimensionCode),
          StrSubstNo(ExistError, DefaultDimension.TableCaption(), DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimensionValueWithEntry()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
    begin
        // Test error occurs on deletion of Dimension Value after posting General Journal.

        // 1. Setup: Create Customer, Dimension, Dimension Value, Create and Post General Journal with Dimension.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionWithValue(DimensionValue);
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Delete Dimension Value.
        asserterror DimensionValue.Delete(true);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisDimMatrixForItemsColumnName()
    var
        ShowAsColumn: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
    begin
        // Check Sales Analysis by Dimensions shows correct Catpion values when Show Cloumn Name TRUE and Show as Column is Item.
        Initialize();
        EnqueueDetailAnalysisDimMatrixItem();
        CreateAndRunSalesAnalysisMatrix(ShowAsColumn::Item);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisDimMatrixForLocationsColumnName()
    var
        ShowAsColumn: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
    begin
        // Check Sales Analysis by Dimensions shows correct Catpion values when Show Cloumn Name TRUE and Show as Column is Location.
        Initialize();
        EnqueueDetailAnalysisDimMatrixLocation();
        CreateAndRunSalesAnalysisMatrix(ShowAsColumn::Location);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisDimMatrixForDimension1ColumnName()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check Sales Analysis by Dimensions shows correct Catpion values when Show Cloumn Name is TRUE and Column Dim. Code is Dimension 1.
        Initialize();
        GeneralLedgerSetup.Get();
        EnqueueDetailAnalysisDimMatrixDimensions(GeneralLedgerSetup."Global Dimension 1 Code");
        CreateAndRunSalesAnalysisMatrixForDimensions(GeneralLedgerSetup."Global Dimension 1 Code", 1);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisDimMatrixForDimension2ColumnName()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check Sales Analysis by Dimensions shows correct Catpion values when Show Cloumn Name is TRUE and Column Dim. Code is Dimension 2.
        Initialize();
        GeneralLedgerSetup.Get();
        EnqueueDetailAnalysisDimMatrixDimensions(GeneralLedgerSetup."Global Dimension 2 Code");
        CreateAndRunSalesAnalysisMatrixForDimensions(GeneralLedgerSetup."Global Dimension 2 Code", 2);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisDimMatrixForDimension3ColumnName()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check Sales Analysis by Dimensions shows correct Catpion values when Show Cloumn Name is TRUE and Column Dim. Code is Dimension 3.
        Initialize();
        GeneralLedgerSetup.Get();
        EnqueueDetailAnalysisDimMatrixDimensions(GeneralLedgerSetup."Shortcut Dimension 1 Code");
        CreateAndRunSalesAnalysisMatrixForDimensions(GeneralLedgerSetup."Shortcut Dimension 1 Code", 3);
    end;

    [Test]
    [HandlerFunctions('PurchaseAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisDimMatrixForItemsColumnName()
    var
        ShowAsColumn: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
    begin
        // Check Purchase Analysis by Dimensions shows correct Catpion values when Show Cloumn Name TRUE and Show as Column is Item.
        Initialize();
        EnqueueDetailAnalysisDimMatrixItem();
        CreateAndRunPurchaseAnalysisMatrix(ShowAsColumn::Item);
    end;

    [Test]
    [HandlerFunctions('PurchaseAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisDimMatrixForLocationsColumnName()
    var
        ShowAsColumn: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
    begin
        // Check Purchase Analysis by Dimensions shows correct Catpion values when Show Cloumn Name TRUE and Show as Column is Location.
        Initialize();
        EnqueueDetailAnalysisDimMatrixLocation();
        CreateAndRunPurchaseAnalysisMatrix(ShowAsColumn::Location);
    end;

    [Test]
    [HandlerFunctions('PurchaseAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisDimMatrixForDimension1ColumnName()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check Purchase Analysis by Dimensions shows correct Catpion values when Show Cloumn Name is TRUE and Column Dim. Code is Dimension 1.
        Initialize();
        GeneralLedgerSetup.Get();
        EnqueueDetailAnalysisDimMatrixDimensions(GeneralLedgerSetup."Global Dimension 1 Code");
        CreateAndRunPurchaseAnalysisMatrixForDimensions(GeneralLedgerSetup."Global Dimension 1 Code", 1);
    end;

    [Test]
    [HandlerFunctions('PurchaseAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisDimMatrixForDimension2ColumnName()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check Purchase Analysis by Dimensions shows correct Catpion values when Show Cloumn Name is TRUE and Column Dim. Code is Dimension 2.
        Initialize();
        GeneralLedgerSetup.Get();
        EnqueueDetailAnalysisDimMatrixDimensions(GeneralLedgerSetup."Global Dimension 2 Code");
        CreateAndRunPurchaseAnalysisMatrixForDimensions(GeneralLedgerSetup."Global Dimension 2 Code", 2);
    end;

    [Test]
    [HandlerFunctions('PurchaseAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisDimMatrixForDimension3ColumnName()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check Purchase Analysis by Dimensions shows correct Catpion values when Show Cloumn Name is TRUE and Column Dim. Code is Dimension 3.
        Initialize();
        GeneralLedgerSetup.Get();
        EnqueueDetailAnalysisDimMatrixDimensions(GeneralLedgerSetup."Shortcut Dimension 1 Code");
        CreateAndRunPurchaseAnalysisMatrixForDimensions(GeneralLedgerSetup."Shortcut Dimension 1 Code", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PKRangeWhenMatrixCurrentSetLengthGreaterThanOne()
    var
        Item: Record Item;
        MatrixManagement: Codeunit "Matrix Management";
        RecRef: RecordRef;
        PkRange: Text[100];
        LastItemCounter: Integer;
        ItemNo: Code[20];
    begin
        // Verify PKRange when Matrix Current Set Length Greater than one.

        // Setup: Create Multiple Items.
        Initialize();
        LastItemCounter := LibraryRandom.RandIntInRange(3, 5);
        ItemNo := CreateMultipleItems(Item, LastItemCounter);
        RecRef.GetTable(Item);

        // Exercise: Get Pk Range from MatrixManagement.
        PkRange := MatrixManagement.GetPKRange(RecRef, Item.FieldNo("No."), ReturnPkFirst(ItemNo), LastItemCounter - 1);

        // Verify: Verify PKRange when Matrix Current Set Length Greater than one.
        Assert.IsTrue(PkRange = StrSubstNo(PKRangeMsg, ItemNo, Item."No."), 'NotCorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PKRangeWhenMatrixCurrentSetLengthIsOne()
    var
        Item: Record Item;
        MatrixManagement: Codeunit "Matrix Management";
        RecRef: RecordRef;
        PkRange: Text[100];
        ItemNo: Code[20];
    begin
        // Verify PKRange when Matrix Current Set Length is one.

        // Setup: Create Multiple Items.
        Initialize();
        ItemNo := CreateMultipleItems(Item, LibraryRandom.RandIntInRange(3, 5));
        RecRef.GetTable(Item);

        // Exercise: Get Pk Range from MatrixManagement.
        PkRange := MatrixManagement.GetPKRange(RecRef, Item.FieldNo("No."), ReturnPkFirst(ItemNo), 1);

        // Verify: Verify PKRange when Matrix Current Set Length is one.
        Assert.IsTrue(PkRange = ItemNo, 'NotCorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PKRangeWhenMatrixCurrentSetLengthIsZero()
    var
        Item: Record Item;
        MatrixManagement: Codeunit "Matrix Management";
        RecRef: RecordRef;
        PkRange: Text[100];
        ItemNo: Code[20];
    begin
        // Verify PKRange when Matrix Current Set Length is Zero.

        // Setup: Create Multiple Items.
        Initialize();
        ItemNo := CreateMultipleItems(Item, LibraryRandom.RandIntInRange(3, 5));
        RecRef.GetTable(Item);

        // Exercise: Get Pk Range from MatrixManagement.
        PkRange := MatrixManagement.GetPKRange(RecRef, Item.FieldNo("No."), ReturnPkFirst(ItemNo), 0);

        // Verify: Verify PKRange when Matrix Current Set Length Zero.
        Assert.IsTrue(PkRange = StrSubstNo(PKRangeMsg, ItemNo, ItemNo), 'NotCorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeGlobalDimensionOnItemBudgetEntry()
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemBudgetName: Record "Item Budget Name";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Change Global Dimensions]
        // [SCENARIO] changing of the global dimensions on ItemBudgetEntry.

        // [GIVEN] Find an item, valid budget name and valid dimension value 'X' for Global Dimension 2.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateItemWithDimension(DefaultDimension, Item."No.");
        ItemBudgetName.SetRange("Analysis Area", ItemBudgetName."Analysis Area"::Sales);
        ItemBudgetName.FindFirst();
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");

        // [GIVEN] Create a budget item entry
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, ItemBudgetName.Name, WorkDate(), Item."No.");
        ItemBudgetEntry.Validate("Global Dimension 2 Code", DimensionValue.Code);
        ItemBudgetEntry.Modify(true);

        // [WHEN] Change "Global Dimension 2 Code" to 'X' on General Ledger Setup.
        GeneralLedgerSetup.Get();
        LibraryDimension.RunChangeGlobalDimensions(GeneralLedgerSetup."Global Dimension 1 Code", DefaultDimension."Dimension Code");

        // [THEN] "Global Dimension 2 Code" on Item Budget is <blank>.
        ItemBudgetEntry.Get(ItemBudgetEntry."Entry No.");
        ItemBudgetEntry.TestField("Global Dimension 2 Code", '');

        // 5. Teardown: Rollback the Default Global Dimension 2 Code on General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensions(
          GeneralLedgerSetup."Global Dimension 1 Code", GeneralLedgerSetup."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeGlobalDimensionOnCustLedgEntry()
    var
        NewDimValue: Record "Dimension Value";
        OldDimValue: Record "Dimension Value";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Change Global Dimensions]
        // [SCENARIO] changing of the global dimensions on Customer Ledger Entry.

        // [GIVEN] Create a customer ledger entry with old a new Global Dimension 1 Code.
        Initialize();
        InitExistingAndNewDimensions(OldDimValue, NewDimValue, LibraryERM.GetGlobalDimensionCode(1));
        CreateCustLedgEntry(CustLedgEntry, OldDimValue, NewDimValue);

        // [WHEN] Change "Global Dimension 1 Code" to 'X' on General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensionsParallel(NewDimValue."Dimension Code", LibraryERM.GetGlobalDimensionCode(2));

        // [THEN] "Global Dimension 1 Code" is 'X' on Customer Ledger Entry.
        CustLedgEntry.Find();
        Assert.AreEqual(
          NewDimValue.Code, CustLedgEntry."Global Dimension 1 Code",
          StrSubstNo(WrongValueErr, CustLedgEntry.FieldCaption("Global Dimension 1 Code"), CustLedgEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeGlobalDimensionOnVendLedgEntry()
    var
        NewDimValue: Record "Dimension Value";
        OldDimValue: Record "Dimension Value";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Change Global Dimensions]
        // [SCENARIO] changing of the global dimensions on Vendor Ledger Entry.

        // [GIVEN] Create a vendor ledger entry with old a new Global Dimension 1 Code.
        Initialize();
        InitExistingAndNewDimensions(OldDimValue, NewDimValue, LibraryERM.GetGlobalDimensionCode(1));
        CreateVendLedgEntry(VendLedgEntry, OldDimValue, NewDimValue);

        // [WHEN] Change "Global Dimension 1 Code" to 'X' on General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensionsParallel(NewDimValue."Dimension Code", LibraryERM.GetGlobalDimensionCode(2));

        // [THEN] "Global Dimension 1 Code" is 'X' on Vendor Ledger Entry.
        VendLedgEntry.Find();
        Assert.AreEqual(
          NewDimValue.Code, VendLedgEntry."Global Dimension 1 Code",
          StrSubstNo(WrongValueErr, VendLedgEntry.FieldCaption("Global Dimension 1 Code"), VendLedgEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionChangeDimensionCode()
    var
        DefaultDimension: Record "Default Dimension";
        Customer: Record Customer;
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [FEATURE] [Default Dimensions]
        // [SCENARIO 289222] Changing "Dimension Code" on Default Dimension resets "Dimension Value Code"

        // [GIVEN] Created Dimension "DIM01" with Value "DV01"
        // [GIVEN] Created Dimension "DIM02" with Value "DV02"
        CreateDimensionWithValue(DimensionValue[1]);
        CreateDimensionWithValue(DimensionValue[2]);

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] New Default Dimension for the Customer
        // [GIVEN] "Dimension Code" = "DIM01", "Dimension Value Code" = "DV01"
        DefaultDimension.Init();
        DefaultDimension.Validate("Table ID", DATABASE::Customer);
        DefaultDimension.Validate("No.", Customer."No.");
        DefaultDimension.Validate("Dimension Code", DimensionValue[1]."Dimension Code");
        DefaultDimension.Validate("Dimension Value Code", DimensionValue[1].Code);
        Assert.IsFalse(IsNullGuid(DefaultDimension.DimensionValueId), 'Dimension Value Id should not be null.');

        // [WHEN] Set "Dimension Code" = "DIM02" with validation
        DefaultDimension.Validate("Dimension Code", DimensionValue[2]."Dimension Code");

        // [THEN] "Dimension Value Code" and DimensionValueId fields are cleared
        DefaultDimension.TestField("Dimension Value Code", '');
        Assert.IsTrue(IsNullGuid(DefaultDimension.DimensionValueId), 'Dimension Value Id should be null.');
    end;

    [Test]
    procedure RealizedGainLossEntryDimensionsAreAppliedFromSourceEntryOnApplyInvoiceToPaymentWithDifferentDates()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        Currency: Record Currency;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrExchRateAmount, PaymentAmt : Decimal;
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        InvoiceDocNo: Code[20];
    begin
        // [SCENARIO 307817] Realized Gain\Loss Entry Dimensions are applied from Source Entry on Apply Invoice to Payment with different dates 
        Initialize();

        // [GIVEN] Set Dimension Posting to "Source Entry Dimensions"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."App. Dimension Posting" := Enum::"Exch. Rate Adjmt. Dimensions"::"Source Entry Dimensions";
        GeneralLedgerSetup.Modify();

        // [GIVEN] Create Currency
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Add Realized Gain\Loss Account to Currency
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);

        // [GIVEN] Create Currency Exchange Rates
        CurrExchRateAmount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1 / CurrExchRateAmount, 1 / CurrExchRateAmount);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate() - 1, 1 / (CurrExchRateAmount - 1), 1 / (CurrExchRateAmount - 1));

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Default Dimension for Vendor
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, Vendor."No.", DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [GIVEN] Return amount from Purchase Invoice
        PurchaseHeader.CalcFields("Amount Including VAT");
        PaymentAmt := PurchaseHeader."Amount Including VAT";

        // [GIVEN] Post Purchase Invoice
        InvoiceDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Payment
        CreateGenJnlLine(GenJournalLine, WorkDate() - 1, GenJournalLine."Document Type"::Payment, PaymentAmt, Vendor."No.", Currency.Code);

        // [GIVEN] Post Payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Apply and Post Payment to Invoice
        LibraryERM.ApplyVendorLedgerEntries(GenJournalDocumentType::Payment, GenJournalDocumentType::Invoice, GenJournalLine."Document No.", InvoiceDocNo);

        // [GIVEN] Find Realized Gain\Loss Entry
        GLEntry.SetFilter("G/L Account No.", '%1|%2', Currency."Realized Gains Acc.", Currency."Realized Losses Acc.");
        GLEntry.FindFirst();

        // [THEN] Verify result
        Assert.AreEqual(GLEntry."Global Dimension 1 Code", DimensionValue.Code, 'Dimension Value Code should be equal to dimension on Realized Gain\Loss Entry.');
    end;

    [Test]
    procedure RealizedGainLossEntryIsCreatedWithoutDimensionForNoDimensionsOptionOnApplyInvoiceToPaymentWithDifferentDates()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        Currency: Record Currency;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrExchRateAmount, PaymentAmt : Decimal;
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        InvoiceDocNo: Code[20];
    begin
        // [SCENARIO 307817] Realized Gain\Loss Entry is created without Dimension for "No Dimensions" option on Apply Invoice to Payment with different dates
        Initialize();

        // [GIVEN] Set Dimension Posting to "Source Entry Dimensions"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."App. Dimension Posting" := Enum::"Exch. Rate Adjmt. Dimensions"::"No Dimensions";
        GeneralLedgerSetup.Modify();

        // [GIVEN] Create Currency
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Add Realized Gain\Loss Account to Currency
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);

        // [GIVEN] Create Currency Exchange Rates
        CurrExchRateAmount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1 / CurrExchRateAmount, 1 / CurrExchRateAmount);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate() - 1, 1 / (CurrExchRateAmount - 1), 1 / (CurrExchRateAmount - 1));

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Default Dimension for Vendor
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, Vendor."No.", DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [GIVEN] Return amount from Purchase Invoice
        PurchaseHeader.CalcFields("Amount Including VAT");
        PaymentAmt := PurchaseHeader."Amount Including VAT";

        // [GIVEN] Post Purchase Invoice
        InvoiceDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Payment
        CreateGenJnlLine(GenJournalLine, WorkDate() - 1, GenJournalLine."Document Type"::Payment, PaymentAmt, Vendor."No.", Currency.Code);

        // [GIVEN] Post Payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Apply and Post Payment to Invoice
        LibraryERM.ApplyVendorLedgerEntries(GenJournalDocumentType::Payment, GenJournalDocumentType::Invoice, GenJournalLine."Document No.", InvoiceDocNo);

        // [GIVEN] Find Realized Gain\Loss Entry
        GLEntry.SetFilter("G/L Account No.", '%1|%2', Currency."Realized Gains Acc.", Currency."Realized Losses Acc.");
        GLEntry.FindFirst();

        // [THEN] Verify result
        Assert.AreEqual(GLEntry."Global Dimension 1 Code", '', 'Dimension on Realized Gain\Loss Entry should be empty.');
    end;

    [Test]
    procedure RealizedGainLossEntryIsCreatedWithDimFromGLAccountrForGLAccountDimensionsOptionOnApplyInvoiceToPaymentWithDifferentDates()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        Currency: Record Currency;
        DefaultDimension: Record "Default Dimension";
        DimensionValues: array[3] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrExchRateAmount, PaymentAmt : Decimal;
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        InvoiceDocNo, GainGLAccountNo, LossGLAccountNo : Code[20];
    begin
        // [SCENARIO 307817] Realized Gain\Loss Entry is created with Dimension from G/L Account for "G/L Account Dimensions" option on Apply Invoice to Payment with different dates
        Initialize();

        // [GIVEN] Set Dimension Posting to "Source Entry Dimensions"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."App. Dimension Posting" := Enum::"Exch. Rate Adjmt. Dimensions"::"G/L Account Dimensions";
        GeneralLedgerSetup.Modify();

        // [GIVEN] Create Currency
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Create G\L Accounts with Default Dimension
        CreateDefaultDimensionForGLAccount(GainGLAccountNo, DimensionValues[1]);
        CreateDefaultDimensionForGLAccount(LossGLAccountNo, DimensionValues[2]);

        // [GIVEN] Add Realized Gain\Loss Accounts to Currency
        Currency.Validate("Realized Gains Acc.", GainGLAccountNo);
        Currency.Validate("Realized Losses Acc.", LossGLAccountNo);
        Currency.Modify(true);

        // [GIVEN] Create Currency Exchange Rates
        CurrExchRateAmount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1 / CurrExchRateAmount, 1 / CurrExchRateAmount);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate() - 1, 1 / (CurrExchRateAmount - 1), 1 / (CurrExchRateAmount - 1));

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Default Dimension for Vendor
        LibraryDimension.CreateDimensionValue(DimensionValues[3], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, Vendor."No.", DimensionValues[3]."Dimension Code", DimensionValues[3].Code);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [GIVEN] Return amount from Purchase Invoice
        PurchaseHeader.CalcFields("Amount Including VAT");
        PaymentAmt := PurchaseHeader."Amount Including VAT";

        // [GIVEN] Post Purchase Invoice
        InvoiceDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Payment
        CreateGenJnlLine(GenJournalLine, WorkDate() - 1, GenJournalLine."Document Type"::Payment, PaymentAmt, Vendor."No.", Currency.Code);

        // [GIVEN] Post Payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Apply and Post Payment to Invoice
        LibraryERM.ApplyVendorLedgerEntries(GenJournalDocumentType::Payment, GenJournalDocumentType::Invoice, GenJournalLine."Document No.", InvoiceDocNo);

        // [GIVEN] Find Realized Gain\Loss G\L Entry
        GLEntry.SetFilter("G/L Account No.", '%1|%2', Currency."Realized Gains Acc.", Currency."Realized Losses Acc.");
        GLEntry.FindFirst();

        // [THEN] Verify result
        if GLEntry."G/L Account No." = Currency."Realized Gains Acc." then
            Assert.AreEqual(GLEntry."Global Dimension 1 Code", DimensionValues[1].Code, 'Dimension Value Code should be equal to dimension on Realized Gain\Loss Entry.');

        if GLEntry."G/L Account No." = Currency."Realized Losses Acc." then
            Assert.AreEqual(GLEntry."Global Dimension 1 Code", DimensionValues[2].Code, 'Dimension Value Code should be equal to dimension on Realized Gain\Loss Entry.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension General Part-1");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        LibraryDimension.InitGlobalDimChange();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension General Part-1");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension General Part-1");
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, CustLedgerEntry2."Document Type"::Payment, DocumentNo);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, VendorLedgerEntry2."Document Type"::Payment, DocumentNo);
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);

        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure InitExistingAndNewDimensions(var OldDimValue: Record "Dimension Value"; var NewDimValue: Record "Dimension Value"; OldDimensionCode: Code[20])
    var
        NewDimension: Record Dimension;
    begin
        LibraryDimension.FindDimensionValue(OldDimValue, OldDimensionCode);
        LibraryDimension.CreateDimension(NewDimension);
        LibraryDimension.CreateDimensionValue(NewDimValue, NewDimension.Code);
    end;

    local procedure CreateMultipleItems(var Item: Record Item; CounterLoop: Integer) ItemNo: Code[20]
    var
        LibraryInventory: Codeunit "Library - Inventory";
        Counter: Integer;
    begin
        for Counter := 1 to CounterLoop do begin
            LibraryInventory.CreateItem(Item);
            if Counter = 1 then
                ItemNo := Item."No.";
        end;
        exit(ItemNo);
    end;

    local procedure CreateAndRunSalesAnalysisMatrix(ShowAsColumn: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3")
    var
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
    begin
        CreateSalesItemAnalysisView(SalesAnalysisbyDimensions, '', 0);
        SetParameterForSalesAnalysisDimension(SalesAnalysisbyDimensions, ShowAsColumn);
        SalesAnalysisbyDimensions.ShowColumnName.SetValue(true);
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();
    end;

    local procedure CreateAndRunSalesAnalysisMatrixForDimensions(DimensionValue: Code[20]; DimCode: Integer)
    var
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
        ShowAsColumn: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
    begin
        CreateSalesItemAnalysisView(SalesAnalysisbyDimensions, DimensionValue, DimCode);
        SalesAnalysisbyDimensions.LineDimCode.SetValue(ShowAsColumn::Location);
        SalesAnalysisbyDimensions.ColumnDimCode.SetValue(DimensionValue);
        SalesAnalysisbyDimensions.ShowColumnName.SetValue(true);
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();
    end;

    local procedure CreateAndRunPurchaseAnalysisMatrix(ShowAsColumn: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3")
    var
        PurchaseAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions";
    begin
        CreatePurchaseItemAnalysisView(PurchaseAnalysisbyDimensions, '', 0);
        SetParameterForPurchaseAnalysisDimension(PurchaseAnalysisbyDimensions, ShowAsColumn);
        PurchaseAnalysisbyDimensions.ShowColumnName.SetValue(true);
        PurchaseAnalysisbyDimensions.ShowMatrix.Invoke();
    end;

    local procedure CreateAndRunPurchaseAnalysisMatrixForDimensions(DimensionValue: Code[20]; DimCode: Integer)
    var
        PurchaseAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions";
        ShowAsColumn: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
    begin
        CreatePurchaseItemAnalysisView(PurchaseAnalysisbyDimensions, DimensionValue, DimCode);
        PurchaseAnalysisbyDimensions.LineDimCode.SetValue(ShowAsColumn::Location);
        PurchaseAnalysisbyDimensions.ColumnDimCode.SetValue(DimensionValue);
        PurchaseAnalysisbyDimensions.ShowColumnName.SetValue(true);
        PurchaseAnalysisbyDimensions.ShowMatrix.Invoke();
    end;

    local procedure CreateAnalysisViewDimension(Dimension1Code: Code[20])
    var
        AnalysisView: Record "Analysis View";
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Dimension 1 Code", Dimension1Code);
        AnalysisView.Modify(true);
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

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateGLBudgetNameDimension(BudgetDimension1Code: Code[20])
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        GLBudgetName.Validate("Budget Dimension 1 Code", BudgetDimension1Code);
        GLBudgetName.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
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

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindJournalBatchAndTemplate(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, Amount);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, -Amount);
    end;

    local procedure CreateItemWithDimension(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateJournalLineWithDimension(var GenJournalLine: Record "Gen. Journal Line"; DimensionValue: Record "Dimension Value"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindJournalBatchAndTemplate(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, AccountNo,
          LibraryRandom.RandDec(100, 2));  // Use Random because value is not important.
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateSalesItemAnalysisView(var SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions"; DimensionCode: Code[20]; DimCode: Integer)
    var
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        UpdateDimensionCodeOnItemAnalysisView(ItemAnalysisView, DimCode, DimensionCode);
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        SalesAnalysisbyDimensions.Trap();
        AnalysisViewListSales.EditAnalysisView.Invoke();
    end;

    local procedure CreatePurchaseItemAnalysisView(var PurchaseAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions"; DimensionCode: Code[20]; DimCode: Integer)
    var
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisViewListPurchase: TestPage "Analysis View List Purchase";
    begin
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        UpdateDimensionCodeOnItemAnalysisView(ItemAnalysisView, DimCode, DimensionCode);
        AnalysisViewListPurchase.OpenEdit();
        AnalysisViewListPurchase.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        PurchaseAnalysisbyDimensions.Trap();
        AnalysisViewListPurchase.EditAnalysisView.Invoke();
    end;

    local procedure CreateVendorWithDimension(): Code[20]
    var
        Vendor: Record Vendor;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension.Code, DimensionValue.Code);
        exit(Vendor."No.");
    end;

    local procedure CreateCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; OldDimValue: Record "Dimension Value"; NewDimValue: Record "Dimension Value")
    var
        RecRef: RecordRef;
    begin
        CustLedgEntry.Init();
        RecRef.GetTable(CustLedgEntry);
        CustLedgEntry."Entry No." :=
          LibraryUtility.GetNewLineNo(RecRef, CustLedgEntry.FieldNo("Entry No."));
        CustLedgEntry."Global Dimension 1 Code" := OldDimValue.Code;
        CustLedgEntry."Dimension Set ID" :=
          LibraryDimension.CreateDimSet(
            LibraryDimension.CreateDimSet(0, OldDimValue."Dimension Code", OldDimValue.Code),
            NewDimValue."Dimension Code", NewDimValue.Code);
        CustLedgEntry.Insert();
    end;

    local procedure CreateVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; OldDimValue: Record "Dimension Value"; NewDimValue: Record "Dimension Value")
    var
        RecRef: RecordRef;
    begin
        VendLedgEntry.Init();
        RecRef.GetTable(VendLedgEntry);
        VendLedgEntry."Entry No." :=
          LibraryUtility.GetNewLineNo(RecRef, VendLedgEntry.FieldNo("Entry No."));
        VendLedgEntry."Global Dimension 1 Code" := OldDimValue.Code;
        VendLedgEntry."Dimension Set ID" :=
          LibraryDimension.CreateDimSet(
            LibraryDimension.CreateDimSet(0, OldDimValue."Dimension Code", OldDimValue.Code),
            NewDimValue."Dimension Code", NewDimValue.Code);
        VendLedgEntry.Insert();
    end;

    local procedure EnqueueDetailAnalysisDimMatrixItem()
    var
        Item: Record Item;
        TableCounter: Integer;
        Counter: Integer;
    begin
        Item.FindSet();
        if Item.Count > 12 then
            TableCounter := LibraryRandom.RandInt(12)
        else
            TableCounter := Item.Count();
        LibraryVariableStorage.Enqueue(TableCounter);
        for Counter := 1 to TableCounter do begin
            LibraryVariableStorage.Enqueue(Counter);
            LibraryVariableStorage.Enqueue(Item.Description);
            Item.Next();
        end;
    end;

    local procedure EnqueueDetailAnalysisDimMatrixLocation()
    var
        Location: Record Location;
        TableCounter: Integer;
        Counter: Integer;
    begin
        Location.FindSet();
        if Location.Count > 12 then
            TableCounter := LibraryRandom.RandInt(12)
        else
            TableCounter := Location.Count();
        LibraryVariableStorage.Enqueue(TableCounter);
        for Counter := 1 to TableCounter do begin
            LibraryVariableStorage.Enqueue(Counter);
            LibraryVariableStorage.Enqueue(Location.Name);
            Location.Next();
        end;
    end;

    local procedure EnqueueDetailAnalysisDimMatrixDimensions(DimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        TableCounter: Integer;
        Counter: Integer;
    begin
        DimensionValue.SetFilter("Dimension Code", DimensionCode);
        DimensionValue.FindSet();
        if DimensionValue.Count > 12 then
            TableCounter := LibraryRandom.RandInt(12)
        else
            TableCounter := DimensionValue.Count();
        LibraryVariableStorage.Enqueue(TableCounter);
        for Counter := 1 to TableCounter do begin
            LibraryVariableStorage.Enqueue(Counter);
            LibraryVariableStorage.Enqueue(DimensionValue.Name);
            DimensionValue.Next();
        end;
    end;

    local procedure FindJournalBatchAndTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure ReturnPkFirst(ItemNo: Code[20]) PkFirst: Text[100]
    var
        Item: Record Item;
        RecRef: RecordRef;
    begin
        Item.Get(ItemNo);
        RecRef.GetTable(Item);
        RecRef.Get(RecRef.RecordId);
        PkFirst := RecRef.GetPosition();
        exit(PkFirst);
    end;

    local procedure SetParameterForSalesAnalysisDimension(var SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions"; LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3")
    begin
        if LineDimOption = LineDimOption::Item then begin
            SalesAnalysisbyDimensions.LineDimCode.SetValue(LineDimOption::Location);
            SalesAnalysisbyDimensions.ColumnDimCode.SetValue(LineDimOption::Item);
        end else
            if LineDimOption = LineDimOption::Location then begin
                SalesAnalysisbyDimensions.LineDimCode.SetValue(LineDimOption::Item);
                SalesAnalysisbyDimensions.ColumnDimCode.SetValue(LineDimOption::Location);
            end;
    end;

    local procedure SetParameterForPurchaseAnalysisDimension(var PurchaseAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions"; LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3")
    begin
        if LineDimOption = LineDimOption::Item then begin
            PurchaseAnalysisbyDimensions.LineDimCode.SetValue(LineDimOption::Location);
            PurchaseAnalysisbyDimensions.ColumnDimCode.SetValue(LineDimOption::Item);
        end else
            if LineDimOption = LineDimOption::Location then begin
                PurchaseAnalysisbyDimensions.LineDimCode.SetValue(LineDimOption::Item);
                PurchaseAnalysisbyDimensions.ColumnDimCode.SetValue(LineDimOption::Location);
            end;
    end;

    local procedure UpdateDimensionValue(var DimensionValue: Record "Dimension Value"; DimensionValueType: Option)
    begin
        DimensionValue.Validate("Dimension Value Type", DimensionValueType);
        LibraryDimension.BlockDimensionValue(DimensionValue);
    end;

    local procedure UpdateDimensionValueType(var DimensionValue: Record "Dimension Value"; DimensionValueType: Option)
    begin
        DimensionValue.Validate("Dimension Value Type", DimensionValueType);
        DimensionValue.Modify(true);
    end;

    local procedure UpdateDimensionValueWithBlock(var DimensionValue: Record "Dimension Value"; DimensionValueType: Option)
    begin
        DimensionValue.Validate("Dimension Value Type", DimensionValueType);
        LibraryDimension.BlockDimensionValue(DimensionValue);
    end;

    local procedure UpdateDimensionCodeOnItemAnalysisView(var ItemAnalysisView: Record "Item Analysis View"; DimCode: Integer; DimensionCode: Code[20])
    begin
        case DimCode of
            1:
                begin
                    ItemAnalysisView.Validate("Dimension 1 Code", DimensionCode);
                    ItemAnalysisView.Modify(true);
                end;
            2:
                begin
                    ItemAnalysisView.Validate("Dimension 2 Code", DimensionCode);
                    ItemAnalysisView.Modify(true);
                end;
            3:
                begin
                    ItemAnalysisView.Validate("Dimension 3 Code", DimensionCode);
                    ItemAnalysisView.Modify(true);
                end;
        end;
    end;

    local procedure VerifyAppliedEntriesDimension(DocumentNo: Code[20]; DimensionSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Dimension Set ID", DimensionSetID);
        until GLEntry.Next() = 0;
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

    local procedure VerifyShortcutDimension(ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        GeneralLedgerSetup.TestField("Shortcut Dimension 2 Code", ShortcutDimension2Code);
    end;

    local procedure CreateDefaultDimensionForGLAccount(var GLAccountNo: Code[20]; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;


    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimMatrixPageHandler(var SalesAnalysisbyDimMatrix: TestPage "Sales Analysis by Dim Matrix")
    var
        ColumnNo: array[12] of Variant;
        Caption: array[12] of Variant;
        RecCounter: Variant;
        ColumnNoInt: array[12] of Integer;
        CounterInt: Integer;
        Counter: Integer;
    begin
        LibraryVariableStorage.Dequeue(RecCounter);
        CounterInt := RecCounter;
        for Counter := 1 to CounterInt do begin
            LibraryVariableStorage.Dequeue(ColumnNo[Counter]);
            LibraryVariableStorage.Dequeue(Caption[Counter]);
            ColumnNoInt[Counter] := ColumnNo[Counter];
        end;
        case ColumnNoInt[Counter] of
            1:
                Assert.AreEqual(Caption[1], SalesAnalysisbyDimMatrix.Field1.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[1]));
            2:
                Assert.AreEqual(Caption[2], SalesAnalysisbyDimMatrix.Field2.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[2]));
            3:
                Assert.AreEqual(Caption[3], SalesAnalysisbyDimMatrix.Field3.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[3]));
            4:
                Assert.AreEqual(Caption[4], SalesAnalysisbyDimMatrix.Field4.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[4]));
            5:
                Assert.AreEqual(Caption[5], SalesAnalysisbyDimMatrix.Field5.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[5]));
            6:
                Assert.AreEqual(Caption[6], SalesAnalysisbyDimMatrix.Field6.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[6]));
            7:
                Assert.AreEqual(Caption[7], SalesAnalysisbyDimMatrix.Field7.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[7]));
            8:
                Assert.AreEqual(Caption[8], SalesAnalysisbyDimMatrix.Field8.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[8]));
            9:
                Assert.AreEqual(Caption[9], SalesAnalysisbyDimMatrix.Field9.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[9]));
            10:
                Assert.AreEqual(Caption[10], SalesAnalysisbyDimMatrix.Field10.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[10]));
            11:
                Assert.AreEqual(Caption[11], SalesAnalysisbyDimMatrix.Field11.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[11]));
            12:
                Assert.AreEqual(Caption[12], SalesAnalysisbyDimMatrix.Field12.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[12]));
            else
                Error(InvalidColumnIndexErr)
        end
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisbyDimMatrixPageHandler(var PurchAnalysisbyDimMatrix: TestPage "Purch. Analysis by Dim Matrix")
    var
        ColumnNo: array[12] of Variant;
        Caption: array[12] of Variant;
        RecCounter: Variant;
        ColumnNoInt: array[12] of Integer;
        CounterInt: Integer;
        Counter: Integer;
    begin
        LibraryVariableStorage.Dequeue(RecCounter);
        CounterInt := RecCounter;
        for Counter := 1 to CounterInt do begin
            LibraryVariableStorage.Dequeue(ColumnNo[Counter]);
            LibraryVariableStorage.Dequeue(Caption[Counter]);
            ColumnNoInt[Counter] := ColumnNo[Counter];
        end;
        case ColumnNoInt[Counter] of
            1:
                Assert.AreEqual(Caption[1], PurchAnalysisbyDimMatrix.Field1.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[1]));
            2:
                Assert.AreEqual(Caption[2], PurchAnalysisbyDimMatrix.Field2.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[2]));
            3:
                Assert.AreEqual(Caption[3], PurchAnalysisbyDimMatrix.Field3.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[3]));
            4:
                Assert.AreEqual(Caption[4], PurchAnalysisbyDimMatrix.Field4.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[4]));
            5:
                Assert.AreEqual(Caption[5], PurchAnalysisbyDimMatrix.Field5.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[5]));
            6:
                Assert.AreEqual(Caption[6], PurchAnalysisbyDimMatrix.Field6.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[6]));
            7:
                Assert.AreEqual(Caption[7], PurchAnalysisbyDimMatrix.Field7.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[7]));
            8:
                Assert.AreEqual(Caption[8], PurchAnalysisbyDimMatrix.Field8.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[8]));
            9:
                Assert.AreEqual(Caption[9], PurchAnalysisbyDimMatrix.Field9.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[9]));
            10:
                Assert.AreEqual(Caption[10], PurchAnalysisbyDimMatrix.Field10.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[10]));
            11:
                Assert.AreEqual(Caption[11], PurchAnalysisbyDimMatrix.Field11.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[11]));
            12:
                Assert.AreEqual(Caption[12], PurchAnalysisbyDimMatrix.Field12.Caption, StrSubstNo(WrongCaptionErr, ColumnNoInt[12]));
            else
                Error(InvalidColumnIndexErr)
        end
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

