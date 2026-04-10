codeunit 139505 "FA Use Accounting Period Tests"
{
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
    procedure OnValidateUseAccountingPeriodDepreciationBookError()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [SCENARIO] Validating "Use Accounting Period" should raise an error when the Depreciation Method is not Straight-Line.

        // [GIVEN] Depreciation Book with "Use Accounting Period" = False
        // [GIVEN] FA Depreciation Book with "Depreciation Method" = Declining-Balance 1
        FADepreciationBook."Depreciation Book Code" := CreateDepreciationBook(false);
        FADepreciationBook."Depreciation Method" := FADepreciationBook."Depreciation Method"::"Declining-Balance 1";
        FADepreciationBook.Insert();
        DepreciationBook.Get(FADepreciationBook."Depreciation Book Code");

        // [WHEN] "Use Accounting Period" is validated as 'True'
        asserterror DepreciationBook.Validate("Use Accounting Period", true);

        // [THEN] Error: 'You cannot set Use Accounting Period to Yes because some Fixed Assets associated with this book exists where Depreciation Method is other than Straight-Line'
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