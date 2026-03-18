codeunit 134234 "ERM Dimension Allowed by Acc."
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Allowed Dimension Values]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;
        DimValueNotAllowedForAccountErr: Label 'Dimension value %1, %2 is not allowed for %3, %4.', Comment = '%1 = Dim Code, %2 = Dim Value, %3 - table caption, %4 - account number.';
        DimValueNotAllowedForAccountTypeErr: Label 'Dimension value %1 %2 is not allowed for account type %3.', Comment = '%1 = Dim Code, %2 = Dim Value, %3 - table caption.';
        DefaultDimValueErr: Label 'You cannot block dimension value %1 because it is a default value for %2, %3.', Comment = '%1 = dimension value code and %2- table name, %3 - account number';
        InvalidAllowedValuesFilterErr: Label 'There are no dimension values for allowed values filter %1.', Comment = '%1 - allowed values filter';
        NoAllowedValuesSelectedErr: Label 'There are no allowed dimension values selected.';
        GLAccountFilter: Text;
        DefDimensionIsNotAllowedMsg: Label 'Default Dimension is not allowed by default.';
        FilterLbl: Label '..';

    [Test]
    [Scope('OnPrem')]
    procedure PostingBlockedIfDimensionValueDisallowed()
    var
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 356543] User is not able to post gen. journal line with dimension value not allowed for account
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Dimension Value Code" = "DV01" not allowed for G/L Account "A"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);

        // [GIVEN] Create gen. journal line with G/L Account "A" with dimension "DIM01" "DV01"
        CreateGeneralJnlLine(GenJournalLine, "Gen. Journal Account Type"::"G/L Account", GLAccount."No.");
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue[1]."Dimension Code", DimensionValue[1].Code));
        GenJournalLine.Modify(true);
        // [WHEN] Gen. journal line is being posted
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error "Dimension value DIM01 DV01 is not allowed for G/L Account A"
        Assert.ExpectedError(
            StrSubstNo(
                DimValueNotAllowedForAccountErr, DimensionValue[1]."Dimension Code", DimensionValue[1].Code, GLAccount.TableCaption(), GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDefaultDimension()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 356543] Delete default dimension leads to delete apropriate allowed dimension by account
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Dimension Value Code" = "DV01" not allowed for G/L Account "A"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);

        // [WHEN] Default dimension is being deleted
        DefaultDimension.Delete(true);

        // [THEN] Allowed dimension values for account "A" deleted
        VerifyDimValuePerAccountEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimensionValue()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [SCENARIO 356543] Delete dimension value leads to delete apropriate allowed dimension by account
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01", "DV02" and "DV03"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Dimension Value Code" = "DV01" not allowed for G/L Account "A"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);

        // [WHEN] Dimension value "DV01" is being deleted
        DimensionValue[1].Delete(true);

        // [THEN] Allowed dimension for account deleted
        Assert.IsFalse(
            DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code),
            'Dim. Value per Account must be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimensionValueToMakeAllowedValuesFilterEmpty()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 356543] Delete dimension value which makes allowed values filter empyt leads to delete all allowed dimension values by account
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Allowed Values Filter" = "DV02"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);
        DefaultDimension.Modify();

        // [WHEN] Dimension value "DV01" is being deleted
        DimensionValue[1].Delete(true);

        // [THEN] Allowed dimension values for account "A" deleted
        VerifyDimValuePerAccountEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDefaultDimensionPostingType()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 356543] Change default dimension posting type from "Code Mandatory" leads to delete apropriate allowed dimension by account
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Allowed Values Filter" = "DV02"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);

        // [WHEN] Default dimension is being deleted
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::" ");

        // [THEN] Allowed dimension values for account "A" deleted
        VerifyDimValuePerAccountEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAllowedValuesFilterForWrongPostingType()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 356543] Change default dimension "Allowed Values Filter" for posting type " " leads to error
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01"
        CreateDimensionWithValue(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01" with Posting Type = " "
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimensionValue."Dimension Code", '');

        // [WHEN] Change "Allowed Values Filter" to "DV01"
        asserterror DefaultDimension.Validate("Allowed Values Filter", DimensionValue.Code);

        // [THEN] Error Value Posting must be equal to 'Code Mandatory'
        Assert.ExpectedTestFieldError(DefaultDimension.FieldCaption("Value Posting"), Format(DefaultDimension."Value Posting"::"Code Mandatory"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNewDimValueAllValuesAllowed()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 356543] New dimension value for default dimension which has all values allowed does not create record "Dim. Value per Account"
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01"
        CreateDimensionWithValue(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue."Dimension Code");

        // [WHEN] New dimension value "DV02" is being created
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");

        // [THEN] Still no records "Dim. Value per Account" for default dimension
        VerifyDimValuePerAccountEmpty(DefaultDimension);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CreateNewDimValue()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [SCENARIO 407861] New dimension value for default dimension with nonempty "Allowed Values Filter" does not change existent "Allowed Values Filter"
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Dimension Value Code" = "DV01" not allowed for G/L Account "A"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);
        DefaultDimension.Modify();

        // [WHEN] New dimension value "DV03" is being created
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[2]."Dimension Code");

        // [THEN] Allowed dimension for account "DV03" creaetd with "Allowed" = "No"
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        DimValuePerAccount.TestField(Allowed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowedValuesAllValuesAllowed()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 356543] New dimension value became allowed for default dimension with code mandatory
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01"
        CreateDimensionWithValue(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [WHEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01" is being created
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue."Dimension Code");

        // [THEN] Default Dimension has "Allowed Values Filter" = ''
        DefaultDimension.TestField("Allowed Values Filter", '');
        // [THEN] By default no records "Dim. Value per Account" created
        VerifyDimValuePerAccountEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowedValuesAllValuesDisallowed()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 356543] New dimension value became allowed for default dimension with code mandatory
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Mock set both dim value per account not allowed for G/L Account "A"
        CreateDimValuePerAccount(DimensionValue[1], Database::"G/L Account", GLAccount."No.", false);
        CreateDimValuePerAccount(DimensionValue[2], Database::"G/L Account", GLAccount."No.", false);

        // [WHEN] "Allowed Values Filter" is being recalculated
        asserterror DefaultDimension.UpdateDefaultDimensionAllowedValuesFilter();

        // [THEN] Error "There are no allowed values for the dimension"
        Assert.ExpectedError(NoAllowedValuesSelectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAllowedFilterAfterDisallowedValueDefined()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 356543] User get error when already defined default dimension value is out of allowed values filter
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");
        // [GIVEN] Set defalult dimension value "DV01" for G/L Account "A"
        DefaultDimension."Dimension Value Code" := DimensionValue[1].Code;
        DefaultDimension.Modify();

        // [WHEN] Set "Dimension Value Code" = "DV01" not allowed for G/L Account "A"
        asserterror DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);

        // [THEN] Error "You cannot set dimension value DIM01 disallowed because it is a default value for G/L Account A"
        Assert.ExpectedError(StrSubstNo(DefaultDimValueErr, DimensionValue[1].Code, GLAccount.TableCaption(), GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDefaultDimensionDimensionValueCodeAsAllowedValuesFilter()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [SCENARIO 387098] User can update "Allowed Values Filter" with DefaultDimension."Dimension Value Code"
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");
        // [GIVEN] Set defalult dimension value "DV01" for G/L Account "A"
        DefaultDimension."Dimension Value Code" := DimensionValue[1].Code;
        DefaultDimension.Modify();

        // [WHEN] Set "Dimension Value Code" = "DV01" not allowed for G/L Account "A"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[1].Code);

        // [THEN] No error for "DV01". "Dim. Value per Account" for "DV02" became disallowed
        DimValuePerAccount.Get(DefaultDimension."Table ID", DefaultDimension."No.", DefaultDimension."Dimension Code", DimensionValue[2].Code);
        DimValuePerAccount.TestField(Allowed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountDefault()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 356543] User is able to define disallowed dimension value for default account type
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for account type G/L Account - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", '', DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Dimension Value Code" = "DV01" not allowed for G/L Account "A"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);

        // [GIVEN] Create gen. journal line with G/L Account "A" with dimension "DIM01" "DV01"
        CreateGeneralJnlLine(GenJournalLine, "Gen. Journal Account Type"::"G/L Account", GLAccount."No.");
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue[1]."Dimension Code", DimensionValue[1].Code));
        GenJournalLine.Modify(true);
        // [WHEN] Gen. journal line is being posted
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error "Dimension value DIM01 DV01 is not allowed for account type G/L Account"
        Assert.ExpectedError(
            StrSubstNo(
                DimValueNotAllowedForAccountTypeErr, DimensionValue[1]."Dimension Code", DimensionValue[1].Code, GLAccount.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultDimensionMultipleOpen()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: array[2] of Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 356543] Page "Default Dimension Multiple" shows several dimension values per account created before 
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV0101" and "DV0102"
        CreateDimensionWithValue(DimensionValue[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], DimensionValue[1]."Dimension Code");

        // [GIVEN] Created Dimension "DIM02" with Value "DV0201" and "DV0202"
        CreateDimensionWithValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[2]."Dimension Code");

        // [GIVEN] Create G/L Account "A1"
        LibraryERM.CreateGLAccount(GLAccount[1]);
        // [GIVEN] Create G/L Account "A2"
        LibraryERM.CreateGLAccount(GLAccount[2]);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A1" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount[1]."No.", DimensionValue[1]."Dimension Code");
        // [GIVEN] Set "Dimension Value Code" = "DV0101" not allowed for G/L Account "A1"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[1].Code);
        DefaultDimension.Modify();

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A2" - "Dimension Code" = "DIM02"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount[2]."No.", DimensionValue[2]."Dimension Code");
        // [GIVEN] Set "Dimension Value Code" = "DV0201" not allowed for G/L Account "A2"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);
        DefaultDimension.Modify();

        // [WHEN] Action Dimension-Multiple for selected accounts "A1" and "A2" from page Chart of Accouts
        MockGLAccountsDimensionMultiple(GLAccount);

        // [THEN] Both dimensions "DIM01" and "DIM02" shown on the page with "Allowed Value Filter" "DV0102" and "DV0202"
        Assert.AreEqual(DimensionValue[1]."Dimension Code", LibraryVariableStorage.DequeueText(), 'Unexpected dimension value');
        Assert.AreEqual(DimensionValue[1].Code, LibraryVariableStorage.DequeueText(), 'Unexpected allowed values filter');
        Assert.AreEqual(DimensionValue[2]."Dimension Code", LibraryVariableStorage.DequeueText(), 'Unexpected dimension value');
        Assert.AreEqual(DimensionValue[2].Code, LibraryVariableStorage.DequeueText(), 'Unexpected allowed values filter');
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandlerCreateNew')]
    [Scope('OnPrem')]
    procedure DefaultDimensionMultipleCreateNew()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: array[2] of Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 356543] User set up dimension values per account with page "Default Dimension Multiple"
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV0101" and "DV0102"
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");

        // [GIVEN] Create G/L Account "A1"
        LibraryERM.CreateGLAccount(GLAccount[1]);
        // [GIVEN] Create G/L Account "A2"
        LibraryERM.CreateGLAccount(GLAccount[2]);

        // [WHEN] Action Dimension-Multiple for selected accounts "A1" and "A2" from page Chart of Accouts and created new default dimension DV0101 with Code Mandatory
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        MockGLAccountsDimensionMultiple(GLAccount);

        // [THEN] Default dimension DV0101 with Code Mandatory created for both accounts
        DefaultDimension.Get(Database::"G/L Account", GLAccount[1]."No.", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Value Posting", "Default Dimension Value Posting Type"::"Code Mandatory");
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount[1]."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DimValuePerAccount.TestField(Allowed, true);

        DefaultDimension.Get(Database::"G/L Account", GLAccount[2]."No.", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Value Posting", "Default Dimension Value Posting Type"::"Code Mandatory");
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount[2]."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DimValuePerAccount.TestField(Allowed, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowedValuesFilterSetAllAllowed()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 356543] Manual update "Allowed Values Filter" to '' deletes all "Dim. Value per Account" records for current default dimension
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithValue(DimensionValue[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[1]."Dimension Code");

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Dimension Value Code" = "DV01" not allowed for G/L Account "A"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);

        // [WHEN] Set "Allowed Values Filter" to ''
        DefaultDimension.Validate("Allowed Values Filter", '');

        // [THEN] All records "Dim. Value per Account" for default dimension G/L Account, "A", "DIM01" "DV01" deleted
        VerifyDimValuePerAccountEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowedValuesFilterSetValidFilter()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [SCENARIO 356543] Manual update "Allowed Values Filter" to valid value makes appropriate "Dim. Value per Account" allowed
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV01" and "DV02"
        CreateDimensionWithValue(DimensionValue[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[1]."Dimension Code");

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [WHEN] Set "Allowed Values Filter" to "DV01"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[1].Code);

        // [THEN] Allowed = true for "Dim. Value per Account" "DV01"
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        DimValuePerAccount.TestField(Allowed, true);
        // [THEN] Allowed = false for "Dim. Value per Account" "DV02"
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        DimValuePerAccount.TestField(Allowed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowedValuesFilterSetUnsupportedFilter()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        InvalidFilter: Text;
    begin
        // [SCENARIO 356543] User enters manually incorrect "Allowed Values Filter" and don't confirm change
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Values "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Allowed Values Filter" = "DV02" 
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);
        DefaultDimension.Modify();

        // [WHEN] Set "Allowed Values Filter" to nonexistent value DV03
        Commit();
        InvalidFilter := IncStr(DimensionValue[2].Code);
        asserterror DefaultDimension.Validate("Allowed Values Filter", copystr(InvalidFilter, 1, MaxStrLen(DefaultDimension."Allowed Values Filter")));

        Assert.ExpectedError(StrSubstNo(InvalidAllowedValuesFilterErr, InvalidFilter));
    end;

    [Test]
    [HandlerFunctions('DimAllowedValuesPerAccModalPageHandler')]
    [Scope('OnPrem')]
    procedure BigAllowedValuesFilter()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[100] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        SavedDimValuePerAccount: Record "Dim. Value per Account" temporary;
        DefaultDimensions: TestPage "Default Dimensions";
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 356543] User can work with allowed dimension values making filter more than 250 symbols
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with 100 Values "DV001" .. "DV100"
        CreateDimensionWithValue(DimensionValue[1]);
        for i := 2 to 100 do
            LibraryDimension.CreateDimensionValue(DimensionValue[i], DimensionValue[1]."Dimension Code");

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set each odd dimension value disallowed for G/L Account "A" to get a long allowed values filter
        for i := 1 to 100 do
            CreateDimValuePerAccount(DimensionValue[i], Database::"G/L Account", GLAccount."No.", i mod 2 > 0);

        DimValuePerAccount.SetRange("Table ID", Database::"G/L Account");
        DimValuePerAccount.SetRange("No.", GLAccount."No.");
        DimValuePerAccount.SetRange("Dimension Code", DimensionValue[1]."Dimension Code");
        if DimValuePerAccount.FindSet() then
            repeat
                SavedDimValuePerAccount := DimValuePerAccount;
                SavedDimValuePerAccount.Insert();
            until DimValuePerAccount.Next() = 0;

        // [WHEN] Run assist edit for "Allowed Values Filter" from default dimension page for G/L Account "A" and press OK
        DefaultDimensions.OpenEdit();
        DefaultDimensions.Filter.SetFilter("Dimension Code", DimensionValue[1]."Dimension Code");
        DefaultDimensions.AllowedValuesFilter.AssistEdit();

        // [THEN] Allowed field has same value as before for all records  "Dim. Value per Account"
        SavedDimValuePerAccount.FindSet();
        repeat
            DimValuePerAccount.Get(SavedDimValuePerAccount."Table ID", SavedDimValuePerAccount."No.", SavedDimValuePerAccount."Dimension Code", SavedDimValuePerAccount."Dimension Value Code");
            DimValuePerAccount.TestField(Allowed, SavedDimValuePerAccount.Allowed);
        until SavedDimValuePerAccount.Next() = 0;
    end;


    [Test]
    [Scope('OnPrem')]
    procedure BigAllowedValuesFilterDeleteDimensionValue()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[100] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        SavedDimValuePerAccount: Record "Dim. Value per Account" temporary;
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 356543] Delete dimension value when "Allowed Values Filter" more than 250 symbols
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with 100 Values "DV001" .. "DV100"
        CreateDimensionWithValue(DimensionValue[1]);
        for i := 2 to 100 do
            LibraryDimension.CreateDimensionValue(DimensionValue[i], DimensionValue[1]."Dimension Code");

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set each odd dimension value disallowed for G/L Account "A" to get a long allowed values filter
        for i := 1 to 100 do
            CreateDimValuePerAccount(DimensionValue[i], Database::"G/L Account", GLAccount."No.", i mod 2 > 0);

        DimValuePerAccount.SetRange("Table ID", Database::"G/L Account");
        DimValuePerAccount.SetRange("No.", GLAccount."No.");
        DimValuePerAccount.SetRange("Dimension Code", DimensionValue[1]."Dimension Code");
        if DimValuePerAccount.FindSet() then
            repeat
                SavedDimValuePerAccount := DimValuePerAccount;
                SavedDimValuePerAccount.Insert();
            until DimValuePerAccount.Next() = 0;
        DefaultDimension.UpdateDefaultDimensionAllowedValuesFilter();

        // [WHEN] Delete last allowed dimension value "DV100" 
        DimValuePerAccount.SetRange(Allowed, false);
        DimValuePerAccount.FindLast();
        DimensionValue[1].Get(DimValuePerAccount."Dimension Code", DimValuePerAccount."Dimension Value Code");
        DimensionValue[1].Delete(true);

        // [THEN] Allowed field has same value as before for all records  "Dim. Value per Account" (except deleted "DV100")
        SavedDimValuePerAccount.SetFilter("Dimension Value Code", '<>%1', DimValuePerAccount."Dimension Value Code");
        SavedDimValuePerAccount.FindSet();
        repeat
            DimValuePerAccount.Get(SavedDimValuePerAccount."Table ID", SavedDimValuePerAccount."No.", SavedDimValuePerAccount."Dimension Code", SavedDimValuePerAccount."Dimension Value Code");
            DimValuePerAccount.TestField(Allowed, SavedDimValuePerAccount.Allowed);
        until SavedDimValuePerAccount.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('DimAllowedValuesPerAccSetValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetDimValueDisalowedUI()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 356543] User set dimension value disallowed with UI
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Values "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Run assist edit for "Allowed Values Filter" from default dimension page for G/L Account "A" 
        DefaultDimensions.OpenEdit();
        DefaultDimensions.Filter.SetFilter("Dimension Code", DimensionValue[1]."Dimension Code");

        // [WHEN] Set "DV01" value disallowed
        AssistEditAllowedValuesFilter(DefaultDimensions, DimensionValue[1].Code, false, true);

        // [THEN] "Dim. Value per Account" for "DV01" has Allowed = false
        DimValuePerAccount.Get(DefaultDimension."Table ID", DefaultDimension."No.", DefaultDimension."Dimension Code", DimensionValue[1].Code);
        DimValuePerAccount.TestField(Allowed, false);
    end;

    [Test]
    [HandlerFunctions('DimAllowedValuesPerAccSetValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetDimValueDisalowedUICancel()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 356543] Cancel button on "Dim. Allowed Values per Acc." allows user to cancel changes
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Values "DV01" and "DV02"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Allowed Values Filter" = "DV02" 
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[2].Code);
        DefaultDimension.Modify();

        // [GIVEN] Run assist edit for "Allowed Values Filter" from default dimension page for G/L Account "A" 
        DefaultDimensions.OpenEdit();
        DefaultDimensions.Filter.SetFilter("Dimension Code", DimensionValue[1]."Dimension Code");

        // [WHEN] Set "DV01" value allowed but press Cancel button on "Dim. Allowed Values per Acc." page
        AssistEditAllowedValuesFilter(DefaultDimensions, DimensionValue[1].Code, true, false);

        // [THEN] "Dim. Value per Account" for "DV01" has Allowed = false
        DimValuePerAccount.Get(DefaultDimension."Table ID", DefaultDimension."No.", DefaultDimension."Dimension Code", DimensionValue[1].Code);
        DimValuePerAccount.TestField(Allowed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowedValuesFilterNotEditableForEmptyValuePosting()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 387514] Field "Allowed Values Filter" is not editable if "Value Posting" <> "Code Mandatory"
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Values "DV01" and "DV02"
        CreateDimensionWithValue(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01" with "Value Posting" = empty
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue."Dimension Code", '');

        // [WHEN] Open Default Dimensions page
        DefaultDimensions.OpenEdit();
        DefaultDimensions.Filter.SetFilter("Dimension Code", DimensionValue."Dimension Code");

        // [THEN] Field "Allowed Values Filter" is not editable
        Assert.IsFalse(DefaultDimensions.AllowedValuesFilter.Editable(), 'Allowed Values Filter must be not editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowedValuesFilterNotEditableForCodeMandatoryValuePosting()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 387514] Field "Allowed Values Filter" is editable if "Value Posting" = "Code Mandatory"
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Values "DV01" and "DV02"
        CreateDimensionWithValue(DimensionValue);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01" with "Value Posting" = "Code Mandatory"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue."Dimension Code");

        // [WHEN] Open Default Dimensions page
        DefaultDimensions.OpenEdit();
        DefaultDimensions.Filter.SetFilter("Dimension Code", DimensionValue."Dimension Code");

        // [THEN] Field "Allowed Values Filter" is not editable
        Assert.IsTrue(DefaultDimensions.AllowedValuesFilter.Editable(), 'Allowed Values Filter must be editable');
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandlerCreateNew')]
    [Scope('OnPrem')]
    procedure DefaultDimensionMultipleForSeveralAccounts()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: array[2] of Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 388589] User can create default dimensions for several accounts twice
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV0101" and "DV0102"
        CreateDimensionWithValue(DimensionValue[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], DimensionValue[1]."Dimension Code");
        // [GIVEN] Created Dimension "DIM02" with Value "DV0201" and "DV0202"
        CreateDimensionWithValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[2]."Dimension Code");

        // [GIVEN] Create G/L Account "A1"
        LibraryERM.CreateGLAccount(GLAccount[1]);
        // [GIVEN] Create G/L Account "A2"
        LibraryERM.CreateGLAccount(GLAccount[2]);

        // [GIVEN] Action Dimension-Multiple for selected accounts "A1" and "A2" from page Chart of Accouts and created new default dimension DV0101 with Code Mandatory
        LibraryVariableStorage.Enqueue(DimensionValue[1]."Dimension Code");
        MockGLAccountsDimensionMultiple(GLAccount);

        // [WHEN] Run Action Dimension-Multiple again and create new default dimension DV0201 with Code Mandatory
        LibraryVariableStorage.Enqueue(DimensionValue[2]."Dimension Code");
        MockGLAccountsDimensionMultiple(GLAccount);

        // [THEN] Default dimension DV0201 with Code Mandatory created for both accounts
        DefaultDimension.Get(Database::"G/L Account", GLAccount[1]."No.", DimensionValue[2]."Dimension Code");
        DefaultDimension.TestField("Value Posting", "Default Dimension Value Posting Type"::"Code Mandatory");
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount[1]."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        DimValuePerAccount.TestField(Allowed, true);

        DefaultDimension.Get(Database::"G/L Account", GLAccount[2]."No.", DimensionValue[2]."Dimension Code");
        DefaultDimension.TestField("Value Posting", "Default Dimension Value Posting Type"::"Code Mandatory");
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount[2]."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        DimValuePerAccount.TestField(Allowed, true);
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandlerAssistEdit,DimAllowedValuesPerAccSetValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultDimensionMultipleForAllAllowedValues()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: array[2] of Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 388591] "Default Dimension Multiple" page shows list of dimension values when it called from accounts with all values allowed
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV0101" and "DV0102"
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");

        // [GIVEN] Create G/L Account "A1"
        LibraryERM.CreateGLAccount(GLAccount[1]);
        // [GIVEN] Create G/L Account "A2"
        LibraryERM.CreateGLAccount(GLAccount[2]);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A1" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount[1]."No.", DimensionValue."Dimension Code");
        // [GIVEN] New mandatory Default Dimension for the G/L Account "A2" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount[2]."No.", DimensionValue."Dimension Code");

        // [WHEN] Action Dimension-Multiple for selected accounts "A1" and "A2" from page Chart of Accouts, assist edit for "Allowed Values Filter", set Allowed = false for "DV0102"
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        EnqueueForDimAllowedValuesPerAccSetValueModalPageHandler(DimensionValue.Code, false, true);
        MockGLAccountsDimensionMultiple(GLAccount);

        // [THEN] "Dim. Value per Account" for DV0102 with Allowed = false create for both accounts
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount[1]."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DimValuePerAccount.TestField(Allowed, false);

        DimValuePerAccount.Get(Database::"G/L Account", GLAccount[2]."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DimValuePerAccount.TestField(Allowed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WildcardCharacters()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[4] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [SCENARIO 388596] Wildcard characters does not cause error when used in "Allowed Values Filter"
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Values "!", "?", "@", "|" 
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[1], '!', Dimension.Code);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[2], '?', Dimension.Code);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[3], '@', Dimension.Code);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[4], '|', Dimension.Code);

        // [GIVEN] Create G/L Account "A"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] Set "Allowed Values Filter" = "'!'..'@'" 
        DefaultDimension.Validate("Allowed Values Filter", StrSubstNo('''%1''..''%2''', DimensionValue[1].Code, DimensionValue[3].Code));
        DefaultDimension.Modify();

        // [WHEN] Dimension value "@" is being deleted (to recalculate "Allowed Values Filter")
        DimensionValue[3].Delete(true);

        // [THEN] No wildcard character error
        Assert.IsFalse(
            DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue[3]."Dimension Code", Dimension.Code),
            'Dim. Value per Account must be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameDimension()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        Dimension: Record Dimension;
        OldDimensionCode: Code[20];
    begin
        // [SCENARIO 434674] Rename dimension should update relevant dimension codes in "Dimension Value per Account" table
        Initialize();

        // [GIVEN] Dimension "D1" with dimension values "DV1" and "DV2"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] G/L Account "A" with mandatory allowed default dimension: "Dimension Code" = "D1", "Dimension Value Code" = "DV1"
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[1].Code);

        // [WHEN] Rename "D1"
        Dimension.Get(DimensionValue[1]."Dimension Code");
        OldDimensionCode := Dimension.Code;
        Dimension.Rename(LibraryUtility.GenerateRandomCode20(Dimension.FieldNo(Code), Database::Dimension));

        // [THEN] Allowed dimension codes for "A" updated
        DimValuePerAccount.SetRange("Dimension Code", OldDimensionCode);
        Assert.RecordIsEmpty(DimValuePerAccount);
        DimValuePerAccount.SetRange("Dimension Code", Dimension.Code);
        Assert.RecordCount(DimValuePerAccount, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameDimensionValue()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        OldDimensionValueCode: Code[20];
    begin
        // [SCENARIO 434674] Rename dimension value should update relevant dimension value codes in "Dimension Value per Account" table
        Initialize();

        // [GIVEN] Dimension "D1" with dimension values "DV1" and "DV2"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] G/L Account "A" with mandatory allowed default dimension: "Dimension Code" = "D1", "Dimension Value Code" = "DV1"
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[1].Code);

        // [WHEN] Rename "DV1"
        OldDimensionValueCode := DimensionValue[1].Code;
        DimensionValue[1].Rename(DimensionValue[1]."Dimension Code", LibraryUtility.GenerateRandomCode20(DimensionValue[1].FieldNo(Code), Database::"Dimension Value"));

        // [THEN] Allowed dimension value code for "A" updated
        Assert.IsFalse(DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code", OldDimensionValueCode), 'Dim. value per account entry should be renamed');
        Assert.IsTrue(DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code), 'Dim. value per account entry should be renamed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameGLAccountWithAllowedDimension()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        OldGLAccountNo: Code[20];
    begin
        // [SCENARIO 434674] Rename g/l account with allowed default dimension should update relevant "No." fields in "Dimension Value per Account" table
        Initialize();

        // [GIVEN] Dimension "D1" with dimension values "DV1" and "DV2"
        CreateDimensionWithTwoValues(DimensionValue);

        // [GIVEN] G/L Account "A" with mandatory allowed default dimension: "Dimension Code" = "D1", "Dimension Value Code" = "DV1"
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[1].Code);

        // [WHEN] Rename "A"
        OldGLAccountNo := GLAccount."No.";
        GLAccount.Rename(LibraryUtility.GenerateRandomCode20(GLAccount.FieldNo("No."), Database::"G/L Account"));

        // [THEN] Allowed "No." fields for "A" updated
        DimValuePerAccount.SetRange("Table ID", Database::"G/L Account");
        DimValuePerAccount.SetRange("No.", OldGLAccountNo);
        Assert.RecordIsEmpty(DimValuePerAccount);
        DimValuePerAccount.SetRange("No.", GLAccount."No.");
        Assert.RecordCount(DimValuePerAccount, 2);
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandlerAssistEdit,DimAllowedValuesPerAccSetValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDefaultMultipleDimension()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        // [SCENARIO 450783] Dimension values are mixed up when use dimension value filter
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV0101" and "DV0102"
        CreateDimensionWithValue(DimensionValue[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], DimensionValue[1]."Dimension Code");

        // [GIVEN] Created Dimension "DIM02" with Value "DV0201" and "DV0202"
        CreateDimensionWithValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[2]."Dimension Code");

        // [GIVEN] Create G/L Account "A1"
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A1" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A1" - "Dimension Code" = "DIM02"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue[2]."Dimension Code");

        // [WHEN] Action Dimension-Multiple for selected accounts "A1" from page Chart of Accouts, assist edit for "Allowed Values Filter", set Allowed = false for "DV0202"
        LibraryVariableStorage.Enqueue(DimensionValue[2]."Dimension Code");
        EnqueueForDimAllowedValuesPerAccSetValueModalPageHandler(DimensionValue[2].Code, false, true);
        MockGLAccountDimensionMultiple(GLAccount."No.");

        // [VERIFY] "Dim. Value per Account" for DIM02, doesn't have the value from DIM01
        asserterror DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue[2]."Dimension Code", DimensionValue[1].Code);
        Assert.ExpectedErrorCannotFind(Database::"Dim. Value per Account");
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandlerAssistEdit,DimAllowedValuesPerAccSetValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDefaultMultipleDimensionWhenMultipleGLSelected()
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: array[2] of Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        GLAccountText: Text[100];
    begin
        // [SCENARIO 456453] Dimension values are not saving the changes after editing from multiple dimensions
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV0101" and "DV0102"
        CreateDimensionWithValue(DimensionValue[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], DimensionValue[1]."Dimension Code");

        // [GIVEN] Created Dimension "DIM02" with Value "DV0201" and "DV0202"
        CreateDimensionWithValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], DimensionValue[2]."Dimension Code");

        // [GIVEN] Create G/L Account "A1" and A2
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        GLAccountText := GLAccount[1]."No." + '|' + GLAccount[2]."No.";

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A1" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount[1]."No.", DimensionValue[1]."Dimension Code");
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount[2]."No.", DimensionValue[1]."Dimension Code");

        // [GIVEN] New mandatory Default Dimension for the G/L Account "A1" - "Dimension Code" = "DIM02"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount[1]."No.", DimensionValue[2]."Dimension Code");
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount[2]."No.", DimensionValue[2]."Dimension Code");

        // [WHEN] Action Dimension-Multiple for selected accounts "A1" from page Chart of Accouts, assist edit for "Allowed Values Filter", set Allowed = false for "DV0202"
        LibraryVariableStorage.Enqueue(DimensionValue[2]."Dimension Code");
        EnqueueForDimAllowedValuesPerAccSetValueModalPageHandler(DimensionValue[2].Code, false, true);
        MockGLAccountDimensionMultiple(GLAccountText);

        // [VERIFY] Verify Allowed on dim value per account.
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount[1]."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        assert.AreEqual(false, DimValuePerAccount.Allowed, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure VerifyNewDimensionValueIsAllowedForDefDimensioIfItsIncludedInAllowedValuesFilter()
    var
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 460671] Verify New Dimension Value is allowed for Default Dimension if it's included in "Allowed Values Filter" 
        Initialize();

        // [GIVEN] Create G/L Account
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Created Dimension with Value
        CreateDimensionWithValue(DimensionValue);

        // [GIVEN] New mandatory Default Dimension for the G/L Account
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", GLAccount."No.", DimensionValue."Dimension Code");

        // [GIVEN] Add "Allowed Values Filter" on Default Dimension
        DefaultDimension.Validate("Allowed Values Filter", 'GU*');
        DefaultDimension.Modify(true);

        // [WHEN] Create new Dimension Value
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionValue."Dimension Code");

        // [GIVEN] Mock set for dim value per account allowed for G/L Account "A"
        CreateDimValuePerAccount(DimensionValue, Database::"G/L Account", GLAccount."No.", true);

        // [THEN] Verify new Dimension Value is allowed
        VerifyNewDimensionValueIsAllowed(GLAccount, DimensionValue);
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandlerCreateNew2')]
    [Scope('OnPrem')]
    procedure AllowedValueFilterShouldUpdateDimAllowedValuesPerAccEvenWithoutAssitEdit()
    var
        Dimension: Record Dimension;
        GLAccount: Record "G/L Account";
        DimensionValue: array[3] of Record "Dimension Value";
        ChartOfAccountsPage: TestPage "Chart of Accounts";
    begin
        // [SCENARIO 490153] Dimension-Multiple rules - set up not working.
        Initialize();

        // [GIVEN] Create a Dimension.
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Create three Dimension Values.
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[3], Dimension.Code);

        // [GIVEN] Create a GL Account.
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Open Chart Of Accounts Page.
        ChartOfAccountsPage.OpenEdit();
        ChartOfAccountsPage.GoToRecord(GLAccount);

        // [WHEN] Run Dimensions Multiple action & Validate Allowed Values Filter field.
        LibraryVariableStorage.Enqueue(Dimension.Code);
        LibraryVariableStorage.Enqueue(Format(DimensionValue[2].Code) + FilterLbl + Format(DimensionValue[3].Code));
        ChartOfAccountsPage."Dimensions-&Multiple".Invoke();
        ChartOfAccountsPage.Close();

        // [VERIFY] Verify Dimension Values set on Allowed Values Filter field
        // are applied as Allowed in DimValuePerAccount for GL Account.
        VerifyNewDimensionValueIsAllowed(GLAccount, DimensionValue[2]);
        VerifyNewDimensionValueIsAllowed(GLAccount, DimensionValue[3]);

        // [VERIFY] Verify Dimension Values not set on Allowed Values Filter field 
        // are not applied as Allowed in DimValuePerAccount for GL Account.
        asserterror VerifyNewDimensionValueIsAllowed(GLAccount, DimensionValue[1]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure NewDimValueAddedToAllowedDimensionValuesPerAccountAtomatically()
    var
        Customer: Record "Customer";
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: array[4] of Record "Dimension Value";
        DimValuePerAccount: Record "Dim. Value per Account";
        Dimensions: TestPage "Dimensions";
        DimensionValues: TestPage "Dimension Values";
    begin
        // [SCENARIO 565211] New Dimension Value is not added to the Allowed Dimension Values per Account automatically
        Initialize();

        // [GIVEN] Created Dimension "DIM01" with Value "DV1", "DV2" and "DV3"
        CreateDimensionWithThreeValues(
            Dimension, DimensionValue,
            Format(LibraryRandom.RandIntInRange(1, 1)),
            Format(LibraryRandom.RandIntInRange(3, 3)),
            Format(LibraryRandom.RandIntInRange(4, 4)));

        // [GIVEN] Create Customer "C"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] New mandatory Default Dimension for the Customer "C" - "Dimension Code" = "DIM01"
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::Customer, Customer."No.", Dimension.Code);

        // [GIVEN] Mock set both dim value per account allowed for Customer "C"
        CreateDimValuePerAccount(DimensionValue[1], Database::Customer, Customer."No.", true);
        CreateDimValuePerAccount(DimensionValue[2], Database::Customer, Customer."No.", true);

        // [GIVEN] Set "Allowed Values Filter" = "DV1" .. "DV3" for Customer "C"
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue[1].Code + '..' + DimensionValue[2].Code);
        DefaultDimension.Modify(true);

        // [WHEN] New dimension value "DV4" is being created using Page "Dimension Values"
        Dimensions.OpenEdit();
        DimensionValues.Trap();
        Dimensions.GoToRecord(Dimension);
        Dimensions."Dimension &Values".Invoke();
        DimensionValues.New();
        DimensionValues.Code.SetValue(Format(LibraryRandom.RandIntInRange(2, 2)));
        DimensionValue[4].Code := DimensionValues.Code.Value;
        DimensionValues.OK().Invoke();
        Dimensions.OK().Invoke();

        // [THEN] Verify Allowed dimension for account "DV4" creaetd with "Allowed" = "Yes"
        DimValuePerAccount.Get(Database::Customer, Customer."No.", Dimension.Code, DimensionValue[4].Code);
        Assert.IsTrue(DimValuePerAccount.Allowed, DefDimensionIsNotAllowedMsg);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Dimension Allowed by Acc.");
        LibraryVariableStorage.Clear();
        LibraryDimension.InitGlobalDimChange();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Dimension Allowed by Acc.");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Dimension Allowed by Acc.");
    end;

    local procedure VerifyNewDimensionValueIsAllowed(GLAccount: Record "G/L Account"; DimensionValue: Record "Dimension Value")
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.Get(Database::"G/L Account", GLAccount."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        Assert.IsTrue(DimValuePerAccount.Allowed, DefDimensionIsNotAllowedMsg);
    end;

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDimensionWithTwoValues(var DimensionValue: array[2] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);
    end;

    local procedure CreateDefaultDimensionCodeMandatory(var DefaultDimension: Record "Default Dimension"; TableId: Integer; No: Code[20]; DimensionCode: Code[20])
    begin
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableId, No, DimensionCode, '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify();
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        PrepareGeneralJournal(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
            AccountType, AccountNo, LibraryRandom.RandInt(1000));
    end;

    local procedure AssistEditAllowedValuesFilter(var DefaultDimensions: TestPage "Default Dimensions"; DimValueCode: Code[20]; Allowed: Boolean; PressOk: Boolean)
    begin
        EnqueueForDimAllowedValuesPerAccSetValueModalPageHandler(DimValueCode, Allowed, PressOk);
        DefaultDimensions.AllowedValuesFilter.AssistEdit();
    end;

    local procedure EnqueueForDimAllowedValuesPerAccSetValueModalPageHandler(DimValueCode: Code[20]; Allowed: Boolean; PressOk: Boolean)
    begin
        LibraryVariableStorage.Enqueue(DimValueCode);
        LibraryVariableStorage.Enqueue(Allowed);
        LibraryVariableStorage.Enqueue(PressOk);
    end;

    local procedure MockGLAccountsDimensionMultiple(SelectedGLAccount: array[2] of Record "G/L Account")
    var
        ChartOfAccounts: TestPage "Chart of Accounts";
        ERMDimensionAllowedByAcc: Codeunit "ERM Dimension Allowed by Acc.";
    begin
        BindSubscription(ERMDimensionAllowedByAcc);
        ERMDimensionAllowedByAcc.SetGLAccountFilter(StrSubstNo('%1|%2', SelectedGLAccount[1]."No.", SelectedGLAccount[2]."No."));
        ChartOfAccounts.OpenEdit();
        ChartOfAccounts."Dimensions-&Multiple".Invoke();
    end;

    local procedure CreateDimValuePerAccount(DimensionValue: Record "Dimension Value"; TableID: Integer; No: Code[20]; Allowed: Boolean)
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.Init();
        DimValuePerAccount."Table ID" := TableID;
        DimValuePerAccount."No." := No;
        DimValuePerAccount."Dimension Code" := DimensionValue."Dimension Code";
        DimValuePerAccount."Dimension Value Code" := DimensionValue.Code;
        DimValuePerAccount.Allowed := Allowed;
        DimValuePerAccount.Insert();
    end;

    local procedure PrepareGeneralJournal(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure MockGLAccountDimensionMultiple(SelectedGLAccount: Text)
    var
        ChartOfAccounts: TestPage "Chart of Accounts";
        ERMDimensionAllowedByAcc: Codeunit "ERM Dimension Allowed by Acc.";
    begin
        BindSubscription(ERMDimensionAllowedByAcc);
        ERMDimensionAllowedByAcc.SetGLAccountFilter(SelectedGLAccount);
        ChartOfAccounts.OpenView();
        ChartOfAccounts."Dimensions-&Multiple".Invoke();
    end;

    local procedure VerifyDimValuePerAccountEmpty(DefaultDimension: Record "Default Dimension")
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.SetRange("Table ID", DefaultDimension."Table ID");
        DimValuePerAccount.SetRange("No.", DefaultDimension."No.");
        DimValuePerAccount.SetRange("Dimension Code", DefaultDimension."Dimension Code");
        Assert.RecordIsEmpty(DimValuePerAccount);
    end;

    local procedure CreateDimensionWithThreeValues(
        var Dimension: Record Dimension;
        var DimensionValue: array[2] of Record "Dimension Value";
        DimensionValueCode1: Code[20];
        DimensionValueCode2: Code[20];
        DimensionValueCode3: Code[20])
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[1], DimensionValueCode1, Dimension.Code);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[2], DimensionValueCode2, Dimension.Code);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[3], DimensionValueCode3, Dimension.Code);
    end;

    [Scope('OnPrem')]
    procedure SetGLAccountFilter(NewGLAccountFilter: Text)
    begin
        GLAccountFilter := NewGLAccountFilter;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Default Dimensions-Multiple", 'OnBeforeSetMultiRecord', '', false, false)]
    local procedure OnBeforeSetMultiRecord(var MasterRecord: Variant)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("No.", GLAccountFilter);
        MasterRecord := GLAccount;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DefaultDimensionsMultipleModalPageHandler(var DefaultDimensionsMultiple: TestPage "Default Dimensions-Multiple")
    begin
        DefaultDimensionsMultiple.First();
        LibraryVariableStorage.Enqueue(DefaultDimensionsMultiple."Dimension Code".Value);
        LibraryVariableStorage.Enqueue(DefaultDimensionsMultiple.AllowedValuesFilter.Value);
        DefaultDimensionsMultiple.Next();
        LibraryVariableStorage.Enqueue(DefaultDimensionsMultiple."Dimension Code".Value);
        LibraryVariableStorage.Enqueue(DefaultDimensionsMultiple.AllowedValuesFilter.Value);
        DefaultDimensionsMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DefaultDimensionsMultipleModalPageHandlerCreateNew(var DefaultDimensionsMultiple: TestPage "Default Dimensions-Multiple")
    begin
        DefaultDimensionsMultiple.New();
        DefaultDimensionsMultiple."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple."Value Posting".SetValue("Default Dimension Value Posting Type"::"Code Mandatory");
        DefaultDimensionsMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DefaultDimensionsMultipleModalPageHandlerAssistEdit(var DefaultDimensionsMultiple: TestPage "Default Dimensions-Multiple")
    begin
        DefaultDimensionsMultiple."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple."Value Posting".SetValue(1);
        DefaultDimensionsMultiple.AllowedValuesFilter.AssistEdit();
        DefaultDimensionsMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimAllowedValuesPerAccModalPageHandler(var DimAllowedValuesPerAcc: TestPage "Dim. Allowed Values per Acc.")
    begin
        DimAllowedValuesPerAcc.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimAllowedValuesPerAccSetValueModalPageHandler(var DimAllowedValuesPerAcc: TestPage "Dim. Allowed Values per Acc.")
    begin
        DimAllowedValuesPerAcc.Filter.SetFilter("Dimension Value Code", LibraryVariableStorage.DequeueText());
        DimAllowedValuesPerAcc.Allowed.SetValue(LibraryVariableStorage.DequeueBoolean());
        if LibraryVariableStorage.DequeueBoolean() then
            DimAllowedValuesPerAcc.OK().Invoke()
        else
            DimAllowedValuesPerAcc.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DefaultDimensionsMultipleModalPageHandlerCreateNew2(var DefaultDimensionsMultiple: TestPage "Default Dimensions-Multiple")
    begin
        DefaultDimensionsMultiple.New();
        DefaultDimensionsMultiple."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple."Value Posting".SetValue("Default Dimension Value Posting Type"::"Code Mandatory");
        DefaultDimensionsMultiple.AllowedValuesFilter.SetValue(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}