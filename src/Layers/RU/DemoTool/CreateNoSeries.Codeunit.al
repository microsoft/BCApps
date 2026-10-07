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
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Init();
        NoSeries.Code := Code;
        NoSeries.Description := Description;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := "Manual Nos.";
        if not NoSeries.Insert() then
            NoSeries.Modify();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine.Validate("Starting No.", "Starting No.");
        NoSeriesLine.Validate("Ending No.", "Ending No.");
        NoSeriesLine.Validate("Last No. Used", "Last Number Used");
        if "Warning No." <> '' then
            NoSeriesLine.Validate("Warning No.", "Warning No.");
        NoSeriesLine.Validate("Increment-by No.", "Increment-by No.");
        NoSeriesLine.Validate(Implementation, Implementation);
        NoSeriesLine."Line No." := 10000;
        if not NoSeriesLine.Insert() then
            NoSeriesLine.Modify();

        SeriesCode := Code;
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

    procedure InsertSeriesOnly(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[50]; "Manual Nos.": Boolean; "Default Nos.": Boolean; "Date Order": Boolean)
    var
        NoSeries2: Record "No. Series";
    begin
        NoSeries2.Init();
        NoSeries2.Code := Code;
        NoSeries2.Description := Description;
        NoSeries2."Default Nos." := true;
        NoSeries2."Manual Nos." := "Manual Nos.";
        NoSeries2."Date Order" := false; // TODO
        NoSeries2.Insert();

        SeriesCode := Code;
    end;

    procedure InsertSeriesLine(var SeriesCode: Code[20]; "Code": Code[20]; LineNo: Integer; "Starting Date": Date; "Increment-by No.": Integer)
    var
        NoSeriesLine: Record "No. Series Line";
        MakeAdjustments: Codeunit "Make Adjustments";
        YearNo: Code[2];
    begin
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := LineNo;
        NoSeriesLine."Starting Date" := MakeAdjustments.AdjustDate("Starting Date");
        if "Starting Date" <> 0D then begin
            YearNo := CopyStr(Format(Date2DMY(NoSeriesLine."Starting Date", 3)), 3, 2);
            NoSeriesLine."Starting No." := CopyStr(Code, 1, 10) + '-' + YearNo + '-00001';
            NoSeriesLine."Ending No." := CopyStr(Code, 1, 10) + '-' + YearNo + '-99999';
            NoSeriesLine."Warning No." := CopyStr(Code, 1, 10) + '-' + YearNo + '-99995';
        end else begin
            NoSeriesLine."Starting No." := CopyStr(Code, 1, 10) + '-00001';
            NoSeriesLine."Ending No." := CopyStr(Code, 1, 10) + '-99999';
            NoSeriesLine."Warning No." := CopyStr(Code, 1, 10) + '-99995';
        end;
        NoSeriesLine."Increment-by No." := "Increment-by No.";
        NoSeriesLine.Insert(true);
    end;
}

