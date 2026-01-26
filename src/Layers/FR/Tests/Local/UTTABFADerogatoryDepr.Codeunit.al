codeunit 144025 "UT TAB FA Derogatory Depr."
{
    // Test for feature FADD - Fixed Asset Derogatory Depreciation.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        DialogErr: Label 'Dialog';
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcDerogatoryDeprBookExistsError()
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Setup: Create multiple Depreciation Books with one Depreciation Book is assigned to multiple Depreciation Books as Derogatory Calculation.
        CreateDepreciationBook(DepreciationBook);
        UpdateGLIntegrationDepreciationBook(DepreciationBook);
        CreateDepreciationBook(DepreciationBook2);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook2, DepreciationBook.Code);
        CreateDepreciationBook(DepreciationBook3);
        UpdateGLIntegrationDepreciationBook(DepreciationBook3);

        // Exercise: Validate already used Depreciation Book as Derogatory Calculation of another Depreciation Book.
        asserterror DepreciationBook3.Validate("Derogatory Calculation", DepreciationBook.Code);

        // Verify: Verify expected error code, actual error: The depreciation book is already set up in combination with derogatory depreciation book.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcSameDerogatoryDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Setup: Create Depreciation Book.
        CreateDepreciationBook(DepreciationBook);

        // Exercise: Validate Derogatory Calculation to same Depreciation Book.
        asserterror DepreciationBook.Validate("Derogatory Calculation", DepreciationBook.Code);

        // Verify: Verify expected error code, actual error: The depreciation book cannot be set up as derogatory for depreciation book.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcDerogatoryDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Setup: Create multiple Depreciation Books with one Derogatory Depreciation Book is assigned to another Depreciation Book as Derogatory Calculation.
        CreateDepreciationBook(DepreciationBook);
        UpdateGLIntegrationDepreciationBook(DepreciationBook);
        CreateDepreciationBook(DepreciationBook2);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook2, DepreciationBook.Code);
        CreateDepreciationBook(DepreciationBook3);

        // Exercise: Validate Derogatory Depreciation Book is assigned to another Depreciation Book as Derogatory Calculation.
        asserterror DepreciationBook3.Validate("Derogatory Calculation", DepreciationBook2.Code);

        // Verify: Verify expected error code, actual error: The depreciation book is a derogatory depreciation book.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcDerogatoryAccountingDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Setup: Create multiple Depreciation Books with one Accounting Depreciation Book is assigned to a Depreciation Book as Derogatory Calculation.
        CreateDepreciationBook(DepreciationBook);
        CreateDepreciationBook(DepreciationBook2);
        CreateDepreciationBook(DepreciationBook3);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook3, DepreciationBook.Code);
        DepreciationBook.CalcFields("Used with Derogatory Book");

        // Exercise: Validate Accounting Depreciation Book as Derogatory Calculation to a Depreciation Book.
        asserterror DepreciationBook.Validate("Derogatory Calculation", DepreciationBook2.Code);

        // Verify: Verify expected error code, actual error: The depreciation book is an accounting book and cannot be set up as a derogatory depreciation book.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcAcqCostDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error, Derogatory depreciation books cannot be integrated with the general ledger for the field G/L Integration - Acq. Cost.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Acq. Cost"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcGLIntegrationDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error, Derogatory depreciation books cannot be integrated with the general ledger for the field G/L Integration - Depreciation.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Depreciation"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcWriteDownDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error, Derogatory depreciation books cannot be integrated with the general ledger for the field G/L Integration - Write-Down.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Write-Down"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcAppreciationDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error Derogatory depreciation books cannot be integrated with the general ledger for the field G/L Integration - Appreciation.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Appreciation"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcCustom1DeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error, Derogatory depreciation books cannot be integrated with the general ledger for the field G/L Integration - Custom 1.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Custom 1"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcCustom2DeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error, Derogatory depreciation books cannot be integrated with the general ledger for the field G/L Integration - Custom2.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Custom 2"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcDisposalDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error, Derogatory depreciation books cannot be integrated with the general ledger for the field G/L Integration - Disposal.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Disposal"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcMaintenanceDeprBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is, to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error, Derogatory depreciation books cannot be integrated with the general ledger, for the field G/L Integration - Maintenance.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Maintenance"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateGLIntegrationDerogatoryCalDepreBookError()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Test to verify error, Derogatory depreciation books cannot be integrated with the general ledger, for the field G/L Integration - Derogatory.
        OnValidateDerogatoryCalculationDepreciationBook(DepreciationBook.FieldNo("G/L Integration - Derogatory"));
    end;

    local procedure OnValidateDerogatoryCalculationDepreciationBook(FieldNo: Integer)
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup: Create multiple Depreciation Books and Validate multiple fields related to GL Integration.
        CreateDepreciationBook(DepreciationBook);
        DepreciationBook2.Code := LibraryUTUtility.GetNewCode10();
        RecRef.GetTable(DepreciationBook2);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(true);
        RecRef.SetTable(DepreciationBook2);

        // Exercise.
        asserterror DepreciationBook2.Validate("Derogatory Calculation", DepreciationBook.Code);

        // Verify: Verify expected error code, actual error: Derogatory depreciation books cannot be integrated with the general ledger. Please make sure that none of the fields on the Integration tab are checked.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDerogatoryCalcDeprecBookZeroDerogatoryError()
    var
        DepreciationBook: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of the test is to validate Derogatory Calculation - OnValidate trigger of Table ID - 5611 Depreciation Book.

        // Setup: Create multiple Depreciation Books with one Derogatory Depreciation Book is assigned to another Depreciation Book as Derogatory Calculation.
        CreateDepreciationBook(DepreciationBook);
        CreateDepreciationBook(DepreciationBook2);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook, DepreciationBook2.Code);
        CreateDepreciationBook(DepreciationBook3);
        UpdateDerogatoryCalculationDepreciationBook(DepreciationBook3, LibraryUTUtility.GetNewCode10());  // Derogatory Calculation.
        CreateFADepreciationBook(FADepreciationBook, DepreciationBook3."Derogatory Calculation");
        CreateFALegerEntry(FADepreciationBook);

        // Exercise.
        asserterror DepreciationBook3.Validate("Derogatory Calculation", DepreciationBook."Derogatory Calculation");

        // Verify: Verify expected error code, Actual error: Derogatory must be equal to '0'  in FA Depreciation Book.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateTypesFADateType()
    var
        FADateType: Record "FA Date Type";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of the test is to validate CreateTypes function of Table ID - 5645 FA Date Type.
        // Setup.
        FADateType."Entry No." := 11;  // Required on the basis of CreateTypes function of Table ID - 5645 FA Date Type for Derogatory.

        // Exercise.
        FADateType.CreateTypes();

        // Verify: Verify FA Date Type No. as Field No of Last Derogatory Date and FA Date Type Name as Field Caption of Last Derogatory Date of FA Depreciation Book.
        FADateType.TestField("FA Date Type No.", FADepreciationBook.FieldNo("Last Derogatory Date"));
        FADateType.TestField("FA Date Type Name", FADepreciationBook.FieldCaption("Last Derogatory Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateTypesFAMatrixPostingType()
    var
        FAMatrixPostingType: Record "FA Matrix Posting Type";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of the test is to validate CreateTypes function of Table ID - 5647 FA Matrix Posting Type.
        // Setup.
        FAMatrixPostingType."Entry No." := 12;  // Required on the basis of CreateTypes function of Table ID - 5647 FA Matrix Posting Type for Derogatory.

        // Exercise.
        FAMatrixPostingType.CreateTypes();

        // Verify: Verify FA Posting Type Name as Field Caption of Derogatory of FA Depreciation Book.
        FAMatrixPostingType.TestField("FA Posting Type Name", FADepreciationBook.FieldCaption(Derogatory));
    end;

    local procedure CreateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        DepreciationBook.Insert();
    end;

    local procedure CreateFALegerEntry(FADepreciationBook: Record "FA Depreciation Book")
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
    begin
        FALedgerEntry."Entry No." := 1;
        if FALedgerEntry2.FindLast() then
            FALedgerEntry."Entry No." := FALedgerEntry2."Entry No." + 1;
        FALedgerEntry."FA No." := FADepreciationBook."FA No.";
        FALedgerEntry."Depreciation Book Code" := FADepreciationBook."Depreciation Book Code";
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Derogatory;
        FALedgerEntry."Exclude Derogatory" := false;
        FALedgerEntry.Amount := LibraryRandom.RandDec(10, 2);
        FALedgerEntry.Insert();
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10])
    begin
        FADepreciationBook."FA No." := LibraryUTUtility.GetNewCode();
        FADepreciationBook."Depreciation Book Code" := DepreciationBookCode;
        FADepreciationBook.Insert();
    end;

    local procedure UpdateGLIntegrationDepreciationBook(DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook."G/L Integration - Depreciation" := true;
        DepreciationBook."G/L Integration - Write-Down" := true;
        DepreciationBook."G/L Integration - Appreciation" := true;
        DepreciationBook."G/L Integration - Custom 1" := true;
        DepreciationBook."G/L Integration - Custom 2" := true;
        DepreciationBook."G/L Integration - Disposal" := true;
        DepreciationBook."G/L Integration - Maintenance" := true;
        DepreciationBook."G/L Integration - Derogatory" := true;
        DepreciationBook.Modify();
    end;

    local procedure UpdateDerogatoryCalculationDepreciationBook(var DepreciationBook: Record "Depreciation Book"; DerogatoryCalculation: Code[10])
    begin
        DepreciationBook."Derogatory Calculation" := DerogatoryCalculation;
        DepreciationBook.Modify();
    end;
}

