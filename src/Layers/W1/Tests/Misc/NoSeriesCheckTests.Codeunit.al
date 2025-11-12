namespace Microsoft.Test.Foundation.NoSeries;

using System.TestLibraries.Utilities;
using Microsoft.TestLibraries.Foundation.NoSeries;
using Microsoft.Foundation.NoSeries;

codeunit 134374 "No. Series Check Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryNoSeries: Codeunit "Library - No. Series";
        StartingNumberTxt: Label 'ABC00010D';
        EndingNumberTxt: Label 'ABC00090D';
        TestNoSeriesCodeTok: Label 'TEST', Locked = true;
        IsInitialized: Boolean;

    [Test]
    procedure NoSeriesWithoutNoSeriesLineFailsValidation()
    var
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();

        // Create no. series
        LibraryNoSeries.CreateNoSeries(TestNoSeriesCodeTok);

        // Invoke TestNoSeries action
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey(TestNoSeriesCodeTok);
        asserterror NoSeriesPage.TestNoSeries.Invoke();

        // Error is thrown
        LibraryAssert.ExpectedError('You cannot assign new numbers from the number series TEST');
    end;

    [Test]
    procedure NoSeriesWithNormalNoSeriesLineOnLaterStartingDateFailsValidation()
    var
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();

        // Create no. series with line with future starting date
        LibraryNoSeries.CreateNoSeries(TestNoSeriesCodeTok);
        LibraryNoSeries.CreateNormalNoSeriesLine(TestNoSeriesCodeTok, 1, StartingNumberTxt, EndingNumberTxt, CalcDate('<+1M>', WorkDate()));

        // Invoke TestNoSeries action
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey(TestNoSeriesCodeTok);
        asserterror NoSeriesPage.TestNoSeries.Invoke();

        // Error is thrown
        LibraryAssert.ExpectedError('You cannot assign new numbers from the number series TEST on ');
    end;

    [Test]
    procedure NormalNoSeriesThatCanGenerateNextNoSuceedsValidation()
    var
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();

        // Create no. series with line
        LibraryNoSeries.CreateNoSeries(TestNoSeriesCodeTok);
        LibraryNoSeries.CreateNormalNoSeriesLine(TestNoSeriesCodeTok, 1, StartingNumberTxt, EndingNumberTxt);

        // Invoke TestNoSeries action succeeds
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey(TestNoSeriesCodeTok);
        NoSeriesPage.TestNoSeries.Invoke();
    end;

    [Test]
    procedure NormalNoSeriesValidationDoesNotChangeTheNextNoGenerated()
    var
        NoSeries: Codeunit "No. Series";
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();

        // Create no. series with line
        LibraryNoSeries.CreateNoSeries(TestNoSeriesCodeTok);
        LibraryNoSeries.CreateNormalNoSeriesLine(TestNoSeriesCodeTok, 1, StartingNumberTxt, EndingNumberTxt);

        // Invoke TestNoSeries action succeeds
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey(TestNoSeriesCodeTok);
        NoSeriesPage.TestNoSeries.Invoke();

        // Ensure invoking TestNoSeries action does not modify the series
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(TestNoSeriesCodeTok, WorkDate(), true), 'GetNextNo does not get the first no in the no series');

        // Invoke TestNoSeries action again
        NoSeriesPage.TestNoSeries.Invoke();

        // Ensure invoking TestNoSeries action does not modify the series
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetNextNo(TestNoSeriesCodeTok, WorkDate(), true), 'GetNextNo does the get the second no in the no series');
    end;

    [Test]
    procedure NoSeriesWithSequenceNoSeriesLineOnLaterStartingDateFailsValidation()
    var
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();

        // Create no. series with line with future starting date
        LibraryNoSeries.CreateNoSeries(TestNoSeriesCodeTok);
        LibraryNoSeries.CreateSequenceNoSeriesLine(TestNoSeriesCodeTok, 1, StartingNumberTxt, EndingNumberTxt, CalcDate('<+1M>', WorkDate()));

        // Invoke TestNoSeries action
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey(TestNoSeriesCodeTok);
        asserterror NoSeriesPage.TestNoSeries.Invoke();

        // Error is thrown
        LibraryAssert.ExpectedError('You cannot assign new numbers from the number series TEST on ');
    end;

    [Test]
    procedure SequenceNoSeriesThatCanGenerateNextNoSuceedsValidation()
    var
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();

        // Create no. series with line
        LibraryNoSeries.CreateNoSeries(TestNoSeriesCodeTok);
        LibraryNoSeries.CreateSequenceNoSeriesLine(TestNoSeriesCodeTok, 1, StartingNumberTxt, EndingNumberTxt);

        // Invoke TestNoSeries action succeeds
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey(TestNoSeriesCodeTok);
        NoSeriesPage.TestNoSeries.Invoke();
    end;

    [Test]
    procedure SequenceNoSeriesValidationDoesNotChangeTheNextNoGenerated()
    var
        NoSeries: Codeunit "No. Series";
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();

        // Create no. series with line
        LibraryNoSeries.CreateNoSeries(TestNoSeriesCodeTok);
        LibraryNoSeries.CreateSequenceNoSeriesLine(TestNoSeriesCodeTok, 1, StartingNumberTxt, EndingNumberTxt);

        // Invoke TestNoSeries action succeeds
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey(TestNoSeriesCodeTok);
        NoSeriesPage.TestNoSeries.Invoke();

        // Ensure invoking TestNoSeries action does not modify the series
        LibraryAssert.AreEqual(StartingNumberTxt, NoSeries.GetNextNo(TestNoSeriesCodeTok, WorkDate(), true), 'GetNextNo does not get the first no in the no series');

        // Invoke TestNoSeries action again
        NoSeriesPage.TestNoSeries.Invoke();

        // Ensure invoking TestNoSeries action does not modify the series
        LibraryAssert.AreEqual(IncStr(StartingNumberTxt), NoSeries.GetNextNo(TestNoSeriesCodeTok, WorkDate(), true), 'GetNextNo does the get the second no in the no series');
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetRange(Code, TestNoSeriesCodeTok);
        NoSeries.DeleteAll(true);

        if IsInitialized then
            exit;
        IsInitialized := true;

        Commit();
    end;
}

