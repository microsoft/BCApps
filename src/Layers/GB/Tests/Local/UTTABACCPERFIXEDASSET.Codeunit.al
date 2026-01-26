codeunit 144020 "UT TAB ACCPER - FIXED ASSET"
{
    // Unit Test Cases for ACCPER - FIXED ASSET Feature.
    // 
    // 1. Purpose of this test is to verify error on Validate of Depreciation Method in FA Depreciation Book Table.
    // 2. Purpose of this test is to verify error on Validate of Use Accounting Period in Depreciation Book Table.
    // 
    // Covers Test Cases for WI - 340446
    // ----------------------------------------------------------------------------------------
    // Test Function Name                                               TFS ID
    // ----------------------------------------------------------------------------------------
    // OnValidateDepreciationMethodFADepreciationBookError              159710,159714,159715
    // OnValidateUseAccountingPeriodDepreciationBookError               159711

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        DialogErr: Label 'Dialog';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDepreciationMethodFADepreciationBookError()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of this test is to verify error on Validate of Depreciation Method in FA Depreciation Book Table.

        // Setup: Create FA Depreciation Book with Use Accounting Period as True.
        FADepreciationBook."Depreciation Book Code" := CreateDepreciationBook(true);  // True - Use Accounting Period.

        // Exercise.
        asserterror FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Declining-Balance 1");

        // Verify:  Verify Actual Error - Depreciation Method must be Straight-Line if Use Accounting Period is Yes in Depreciation Book.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateUseAccountingPeriodDepreciationBookError()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Purpose of this test is to verify error on Validate of Use Accounting Period in Depreciation Book Table.

        // Setup: Create FA Depreciation Book with with Use Accounting Period as False and Depreciation Method as Declining-Balance 1.
        FADepreciationBook."Depreciation Book Code" := CreateDepreciationBook(false);  // False - Use Accounting Period.
        FADepreciationBook."Depreciation Method" := FADepreciationBook."Depreciation Method"::"Declining-Balance 1";
        FADepreciationBook.Insert();
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");

        // Exercise.
        asserterror DepreciationBook.Validate("Use Accounting Period", true);

        // Verify:  Verify Actual Error - You cannot set Use Accounting Period to Yes because some Fixed Assets associated with this book exists where Depreciation Method is other than Straight-Line.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    local procedure CreateDepreciationBook(UseAccountingPeriod: Boolean): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        DepreciationBook."Use Accounting Period" := UseAccountingPeriod;
        DepreciationBook.Insert();
        exit(DepreciationBook.Code);
    end;
}

