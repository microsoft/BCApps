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

    procedure InitFinalSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; No: Integer; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; VATRegPrintPriority: Integer; ReverseSalesVATNoSeries: Code[20]; DateOrder: Boolean)
    var
        StartingNo: Code[20];
        EndingNo: Code[20];
    begin
        StartingNo := '10' + Format(No);
        EndingNo := '10' + Format(No + 1);
        InsertSeries(SeriesCode, Code, Description, CopyStr(StartingNo + '001', 1, 20), CopyStr(EndingNo + '999', 1, 20), '', CopyStr(EndingNo + '995', 1, 20), 1, false,
            NoSeriesType, VATRegister, VATRegPrintPriority, ReverseSalesVATNoSeries, DateOrder); // IT
    end;

    procedure InitTempSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; VATRegPrintPriority: Integer; ReverseSalesVATNoSeries: Code[20]; DateOrder: Boolean)
    begin
        InitTempSeries(SeriesCode, Code, Description, 1,
                         NoSeriesType, VATRegister, VATRegPrintPriority, ReverseSalesVATNoSeries, DateOrder);//IT
    end;

    procedure InitTempSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; No: Integer; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; VATRegPrintPriority: Integer; ReverseSalesVATNoSeries: Code[20]; DateOrder: Boolean)
    var
        StartingNo: Code[20];
        EndingNo: Code[20];
    begin
        StartingNo := Format(No);
        EndingNo := Format(No + 1);
        InsertSeries(SeriesCode, Code, Description, CopyStr(StartingNo + '001', 1, 20), CopyStr(EndingNo + '999', 1, 20), '', Copystr(EndingNo + '995', 1, 20), 1, false,
            NoSeriesType, VATRegister, VATRegPrintPriority, ReverseSalesVATNoSeries, DateOrder, Enum::"No. Series Implementation"::Normal); // IT
    end;

    procedure InitBaseSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning at No.": Code[20]; "Increment-by No.": Integer; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; VATRegPrintPriority: Integer; ReverseSalesVATNoSeries: Code[20]; DateOrder: Boolean)
    begin
        InitBaseSeries(SeriesCode, "Code", Description, "Starting No.", "Ending No.", "Last Number Used", "Warning at No.", "Increment-by No.", NoSeriesType, VATRegister, VATRegPrintPriority, ReverseSalesVATNoSeries, DateOrder, Enum::"No. Series Implementation"::Normal);
    end;

    internal procedure InitBaseSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning at No.": Code[20]; "Increment-by No.": Integer; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; VATRegPrintPriority: Integer; ReverseSalesVATNoSeries: Code[20]; DateOrder: Boolean; Implementation: Enum "No. Series Implementation")
    begin
        InsertSeries(
          SeriesCode, Code, Description,
          "Starting No.", "Ending No.", "Last Number Used", "Warning at No.", "Increment-by No.", true,
          NoSeriesType, VATRegister, VATRegPrintPriority, ReverseSalesVATNoSeries, DateOrder, Implementation);//IT
    end;

    procedure InsertSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning No.": Code[20]; "Increment-by No.": Integer; "Manual Nos.": Boolean; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; VATRegPrintPriority: Integer; ReverseSalesVATNoSeries: Code[20]; DateOrder: Boolean)
    begin
        InsertSeries(SeriesCode, "Code", Description, "Starting No.", "Ending No.", "Last Number Used", "Warning No.", "Increment-by No.", "Manual Nos.", NoSeriesType, VATRegister, VATRegPrintPriority, ReverseSalesVATNoSeries, DateOrder, Enum::"No. Series Implementation"::Normal);
    end;

    internal procedure InsertSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning No.": Code[20]; "Increment-by No.": Integer; "Manual Nos.": Boolean; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; VATRegPrintPriority: Integer; ReverseSalesVATNoSeries: Code[20]; DateOrder: Boolean; Implementation: Enum "No. Series Implementation")
    begin
        InsertSeries(SeriesCode, "Code", Description, "Starting No.", "Ending No.", "Last Number Used", "Warning No.", "Increment-by No.", "Manual Nos.", NoSeriesType, VATRegister, VATRegPrintPriority, ReverseSalesVATNoSeries, DateOrder, Implementation, false);
    end;

    internal procedure InsertSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[100]; "Starting No.": Code[20]; "Ending No.": Code[20]; "Last Number Used": Code[20]; "Warning No.": Code[20]; "Increment-by No.": Integer; "Manual Nos.": Boolean; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; VATRegPrintPriority: Integer; ReverseSalesVATNoSeries: Code[20]; DateOrder: Boolean; Implementation: Enum "No. Series Implementation"; SkipInsertLine: Boolean)
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Init();
        NoSeries.Code := Code;
        NoSeries.Description := Description;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := "Manual Nos.";
        //IT
        NoSeries."No. Series Type" := NoSeriesType;
        NoSeries."VAT Register" := VATRegister;
        NoSeries."VAT Reg. Print Priority" := VATRegPrintPriority;
        NoSeries."Reverse Sales VAT No. Series" := ReverseSalesVATNoSeries;
        NoSeries."Date Order" := DateOrder;
        //END IT

        NoSeries.Insert();

        if not SkipInsertLine then
            InsertSeriesLine(NoSeries.Code, 0D, "Starting No.", "Ending No.", "Last Number Used", "Warning No.", "Increment-by No.", Implementation, 1000);

        SeriesCode := Code;
    end;

    internal procedure InsertSeriesLine(SeriesCode: Code[20]; StartingDate: Date; StartingNo: Code[20]; EndingNo: Code[20]; LastNumberUsed: Code[20]; WarningNo: Code[20]; IncrementByNo: Integer; Implementation: Enum "No. Series Implementation"; LineNo: Integer)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine.Validate("Starting Date", StartingDate);
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate("Last No. Used", LastNumberUsed);
        if WarningNo <> '' then
            NoSeriesLine.Validate("Warning No.", WarningNo);
        NoSeriesLine.Validate("Increment-by No.", IncrementByNo);
        NoSeriesLine.Validate(Implementation, Implementation);
        NoSeriesLine."Line No." := LineNo;
        NoSeriesLine.Insert(true);
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
}

