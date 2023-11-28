namespace Microsoft.Test.Foundation.NoSeries;

using System.TestLibraries.Utilities;
using Microsoft.Foundation.NoSeries;

codeunit 134371 "Stateless No. Series Tests"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        NoSeries: Codeunit "No. Series";
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';

    [Test]
    procedure TestGetNextNoDefaultRunOut()
    var
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        CreateNoSeries(NoSeriesCode);
        CreateNoSeriesLine(NoSeriesCode, 1, '1', '10');
        for i := 1 to 10 do
            LibraryAssert.AreEqual(Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNo()
    var
        NoSeriesCode: Code[20];
    begin
        CreateNoSeries(NoSeriesCode);
        CreateNoSeriesLine(NoSeriesCode, 7, '1', '10');
        LibraryAssert.AreEqual('1', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('8', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoDefaultOverFlow()
    var
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        CreateNoSeries(NoSeriesCode);
        CreateNoSeriesLine(NoSeriesCode, 1, 'A1', 'A5');
        CreateNoSeriesLine(NoSeriesCode, 1, 'B1', 'B5');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('A' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        for i := 1 to 5 do
            LibraryAssert.AreEqual('B' + Format(i), NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    [Test]
    procedure TestGetNextNoAdvancedOverFlow()
    var
        NoSeriesCode: Code[20];
    begin
        CreateNoSeries(NoSeriesCode);
        CreateNoSeriesLine(NoSeriesCode, 7, 'A1', 'A10');
        CreateNoSeriesLine(NoSeriesCode, 7, 'B1', 'B10');
        LibraryAssert.AreEqual('A01', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('A08', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B01', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        LibraryAssert.AreEqual('B08', NoSeries.GetNextNo(NoSeriesCode), 'Number was not as expected');
        asserterror NoSeries.GetNextNo(NoSeriesCode);
        LibraryAssert.ExpectedError(StrSubstNo(CannotAssignNewErr, NoSeriesCode));
    end;

    local procedure CreateNoSeries(var NoSeriesCode: Code[20])
    var
        NoSeriesRecord: Record "No. Series";
    begin
        NoSeriesCode := CopyStr(Any.AlphabeticText(20), 1, 20);
        NoSeriesRecord.Code := NoSeriesCode;
        NoSeriesRecord.Description := NoSeriesCode;
        NoSeriesRecord."Default Nos." := true;
        NoSeriesRecord.Insert();
    end;

    local procedure CreateNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        if NoSeriesLine.FindFirst() then;
        NoSeriesLine."Series Code" := NoSeriesCode;
        NoSeriesLine."Line No." += 10000;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine."Increment-by No." := IncrementBy;
        NoSeriesLine.Validate("Allow Gaps in Nos.", false);
        NoSeriesLine.Insert(true);
    end;
}