namespace Microsoft.TestLibraries.Foundation.NoSeries;

using Microsoft.Foundation.NoSeries;

codeunit 134510 "Library - No. Series"
{
    procedure CreateNoSeries(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := NoSeriesCode;
        NoSeries.Description := NoSeriesCode;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();
    end;

    procedure CreateNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20])
    begin
        CreateNormalNoSeriesLine(NoSeriesCode, IncrementBy, StartingNo, EndingNo);
    end;

    procedure CreateNormalNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20])
    begin
        CreateNormalNoSeriesLine(NoSeriesCode, IncrementBy, StartingNo, EndingNo, 0D);
    end;

    procedure CreateNormalNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20]; StartingDate: Date)
    begin
        CreateNormalNoSeriesLine(NoSeriesCode, IncrementBy, StartingNo, EndingNo, '', StartingDate);
    end;

    procedure CreateNormalNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20]; LastNoUsed: Text[20]; StartingDate: Date)
    begin
        CreateNoSeriesLine(NoSeriesCode, IncrementBy, StartingNo, EndingNo, LastNoUsed, StartingDate, Enum::"No. Series Implementation"::Normal);
    end;

    procedure CreateSequenceNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20])
    begin
        CreateSequenceNoSeriesLine(NoSeriesCode, IncrementBy, StartingNo, EndingNo, 0D);
    end;

    procedure CreateSequenceNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20]; StartingDate: Date)
    begin
        CreateSequenceNoSeriesLine(NoSeriesCode, IncrementBy, StartingNo, EndingNo, '', StartingDate);
    end;

    procedure CreateSequenceNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20]; LastNoUsed: Text[20]; StartingDate: Date)
    begin
        CreateNoSeriesLine(NoSeriesCode, IncrementBy, StartingNo, EndingNo, LastNoUsed, StartingDate, Enum::"No. Series Implementation"::Sequence);
    end;

    procedure CreateNoSeriesLine(NoSeriesCode: Code[20]; IncrementBy: Integer; StartingNo: Text[20]; EndingNo: Text[20]; LastNoUsed: Text[20]; StartingDate: Date; Implementation: Enum "No. Series Implementation")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        if NoSeriesLine.FindFirst() then;
        NoSeriesLine."Series Code" := NoSeriesCode;
        NoSeriesLine."Line No." += 10000;
        NoSeriesLine.Init();
        NoSeriesLine.Validate("Increment-by No.", IncrementBy);
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        if LastNoUsed <> '' then
            NoSeriesLine.Validate("Last No. Used", LastNoUsed);
        NoSeriesLine.Validate("Starting Date", StartingDate);
        NoSeriesLine.Validate(Implementation, Implementation);
        NoSeriesLine.Insert(true);
    end;
}