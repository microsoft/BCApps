codeunit 101308 "Create No. Series"
{

    trigger OnRun()
    begin
        exit;
    end;

    var
        NoSeriesRelationship: Record "No. Series Relationship";

    procedure AddPrefix(SeriesCode: Code[20]; Prefix: Code[10])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        NoSeriesLine.FindSet();
        repeat
            NoSeriesLine.Validate("Starting No.", Prefix + NoSeriesLine."Starting No.");
            NoSeriesLine.Modify();
        until NoSeriesLine.Next() = 0;
    end;

    procedure InitFinalSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; No: Integer)
    var
        StartingNo: Code[20];
        EndingNo: Code[20];
    begin
        StartingNo := '10' + Format(No);
        EndingNo := '10' + Format(No + 1);
        InsertSeries(SeriesCode, Code, Description, CopyStr(StartingNo + '001', 1, 20), CopyStr(EndingNo + '999', 1, 20), '', CopyStr(EndingNo + '995', 1, 20), 1, false);
    end;

    procedure InitTempSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100])
    begin
        InitTempSeries(SeriesCode, Code, Description, 1);
    end;

    procedure InitTempSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; No: Integer)
    var
        StartingNo: Code[20];
        EndingNo: Code[20];
    begin
        StartingNo := Format(No);
        EndingNo := Format(No + 1);
        InsertSeries(SeriesCode, Code, Description, CopyStr(StartingNo + '001', 1, 20), CopyStr(EndingNo + '999', 1, 20), '', Copystr(EndingNo + '995', 1, 20), 1, false, Enum::"No. Series Implementation"::Normal);
    end;

    procedure InitBaseSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning at No.": Code[20]; "Increment-by No.": Integer)
    begin
        InitBaseSeries(SeriesCode, "Code", Description, "Starting No.", "Ending No.", "Last Number Used", "Warning at No.", "Increment-by No.", Enum::"No. Series Implementation"::Normal);
    end;

    internal procedure InitBaseSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning at No.": Code[20]; "Increment-by No.": Integer; Implementation: Enum "No. Series Implementation")
    begin
        InsertSeries(
          SeriesCode, Code, Description,
          "Starting No.", "Ending No.", "Last Number Used", "Warning at No.", "Increment-by No.", true, Implementation);
    end;

    procedure InsertSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning No.": Code[20]; "Increment-by No.": Integer; "Manual Nos.": Boolean)
    begin
        InsertSeries(SeriesCode, "Code", Description, "Starting No.", "Ending No.", "Last Number Used", "Warning No.", "Increment-by No.", "Manual Nos.", Enum::"No. Series Implementation"::Normal);
    end;

    internal procedure InsertSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning No.": Code[20]; "Increment-by No.": Integer; "Manual Nos.": Boolean; Implementation: Enum "No. Series Implementation")
    begin
        InsertSeries(Code, Description, "Manual Nos.");
        InsertSeriesLine(Code, 10000, 0D, "Starting No.", "Ending No.", "Last Number Used", "Warning No.", "Increment-by No.", Implementation);

        SeriesCode := Code;
    end;

    internal procedure InsertSeries(Code: Code[20]; Description: Text[100]; ManualNos: Boolean)
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Init();
        NoSeries.Code := Code;
        NoSeries.Description := Description;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := ManualNos;
        if not NoSeries.Insert() then
            NoSeries.Modify();
    end;

    internal procedure InsertSeriesLine(SeriesCode: Code[20]; LineNo: Integer; StartingDate: Date; StartingNo: Code[20]; EndingNo: Code[20]; LastNumberUsed: Code[20]; WarningNo: Code[20]; IncrementByNo: Integer; Implementation: Enum "No. Series Implementation")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Starting Date" := StartingDate;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate("Last No. Used", LastNumberUsed);
        if WarningNo <> '' then
            NoSeriesLine.Validate("Warning No.", WarningNo);
        NoSeriesLine.Validate("Increment-by No.", IncrementByNo);
        NoSeriesLine.Validate(Implementation, Implementation);
        NoSeriesLine."Line No." := LineNo;
        if not NoSeriesLine.Insert() then
            NoSeriesLine.Modify();
    end;

    procedure InsertRelation("Code": Code[20]; "Series Code": Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        NoSeriesRelationship.Init();
        NoSeriesRelationship.Code := Code;
        NoSeriesRelationship."Series Code" := "Series Code";
        NoSeriesRelationship.Insert();

        NoSeries.Get("Series Code");
        NoSeries."Default Nos." := false;
        NoSeries.Modify();
    end;

    procedure InitBaseSeries2(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning at No.": Code[20]; "Increment-by No.": Integer)
    begin
        // NAVCZ
        InsertSeries(
          SeriesCode, Code, Description,
          "Starting No.", "Ending No.", "Last Number Used", "Warning at No.", "Increment-by No.", false);
    end;
}

