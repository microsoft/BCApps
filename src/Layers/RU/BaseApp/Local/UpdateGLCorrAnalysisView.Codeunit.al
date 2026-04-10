#pragma warning disable AA0247
codeunit 14940 "Update G/L Corr. Analysis View"
{
    Permissions = TableData "Analysis View" = rm,
                  TableData "Analysis View Filter" = r,
                  TableData "Analysis View Entry" = rimd,
                  TableData "Analysis View Budget Entry" = rimd;
    TableNo = "G/L Corr. Analysis View";

    trigger OnRun()
    begin
        MaxNumber := 2147483647;
        if Rec.Code <> '' then
            if Confirm(Text000, true, Rec.TableCaption(), Rec.Code) then begin
                Rec.Modify();
                UpdateOne(Rec, true);
            end;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Do you want to update %1 %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'Analysis View     #1############################\\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'Updating table    #2############################\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'Speed: (Entries/s)#4########\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label 'Average Speed     #5########';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrEntry: Record "G/L Correspondence Entry";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        TempGLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry" temporary;
        GLCorrAnalysisViewFilter: Record "G/L Corr. Analysis View Filter";
        DimSetEntry: Record "Dimension Set Entry";
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimEntryBuffer: Record "Dimension Entry Buffer" temporary;
        FilterIsInitialized: Boolean;
        FiltersExist: Boolean;
        MaxNumber: Integer;
        LedgEntryDimEntryNo: Integer;
        PrevPostingDate: Date;
        PrevCalculatedPostingDate: Date;
        NoOfEntries: Integer;
        Window: Dialog;
        ShowProgressWindow: Boolean;
        WinLastEntryNo: Integer;
        WinPrevEntryNo: Integer;
        WinUpdateCounter: Integer;
        WinTotalCounter: Integer;
        WinTime0: Time;
        WinTime1: Time;
        WinTime2: Time;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text009: Label '#6############### @3@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text010: Label 'Summarizing';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text011: Label 'Updating Database';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure UpdateAll(DirectlyFromPosting: Boolean)
    var
        GLCorrAnalysisView2: Record "G/L Corr. Analysis View";
    begin
        MaxNumber := 2147483647;
        GLCorrAnalysisView2.SetRange(Blocked, false);
        if DirectlyFromPosting then
            GLCorrAnalysisView2.SetRange("Update on G/L Corr. Creation", true);

        if GLCorrAnalysisView2.IsEmpty() then
            exit;

        GLCorrAnalysisView2.LockTable();
        if GLCorrAnalysisView2.FindSet() then
            repeat
                UpdateOne(GLCorrAnalysisView2, not DirectlyFromPosting);
            until GLCorrAnalysisView2.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Update(var NewGLCorrAnalysisView: Record "G/L Corr. Analysis View"; ShowWindow: Boolean)
    begin
        MaxNumber := 2147483647;
        NewGLCorrAnalysisView.TestField(Blocked, false);
        UpdateOne(NewGLCorrAnalysisView, ShowWindow);
    end;

    local procedure UpdateOne(var NewGLCorrAnalysisView: Record "G/L Corr. Analysis View"; ShowWindow: Boolean)
    var
        LastEntryNo: Integer;
    begin
        GLCorrAnalysisView := NewGLCorrAnalysisView;
        GLCorrAnalysisView.TestField(Blocked, false);
        ShowProgressWindow := ShowWindow;
        if ShowProgressWindow then
            InitWindow();

        GLCorrEntry.Reset();
        GLCorrEntry.SetRange("Entry No.", GLCorrAnalysisView."Last Entry No." + 1, MaxNumber);
        if GLCorrEntry.FindLast() then begin
            LastEntryNo := GLCorrEntry."Entry No.";
            if ShowProgressWindow then
                UpdateWindowHeader(DATABASE::"G/L Corr. Analysis View Entry", GLCorrEntry."Entry No.");
            GLCorrEntry.SetRange("Entry No.", GLCorrAnalysisView."Last Entry No." + 1, LastEntryNo);
            UpdateEntries();
            GLCorrAnalysisView."Last Entry No." := LastEntryNo;
        end;

        GLCorrAnalysisView."Last Date Updated" := Today;
        GLCorrAnalysisView.Modify();

        if ShowProgressWindow then
            Window.Close();
    end;

    local procedure UpdateEntries()
    begin
        FilterIsInitialized := false;
        LedgEntryDimEntryNo := 0;
        GLCorrEntry.FilterGroup(2);
        GLCorrEntry.SetFilter("Debit Account No.", '<>%1', '');
        GLCorrEntry.SetFilter("Credit Account No.", '<>%1', '');
        GLCorrEntry.FilterGroup(0);
        if GLCorrAnalysisView."Debit Account Filter" <> '' then
            GLCorrEntry.SetFilter("Debit Account No.", GLCorrAnalysisView."Debit Account Filter");
        if GLCorrAnalysisView."Credit Account Filter" <> '' then
            GLCorrEntry.SetFilter("Credit Account No.", GLCorrAnalysisView."Credit Account Filter");
        if GLCorrAnalysisView."Business Unit Filter" <> '' then
            GLCorrEntry.SetFilter("Business Unit Code", GLCorrAnalysisView."Business Unit Filter");
        if not GLCorrEntry.FindSet(true) then
            exit;

        repeat
            if CheckDimFilters() then
                UpdateAnalysisViewEntry(
                  GetDimValue(GLCorrEntry."Debit Dimension Set ID", GLCorrAnalysisView."Debit Dimension 1 Code"),
                  GetDimValue(GLCorrEntry."Debit Dimension Set ID", GLCorrAnalysisView."Debit Dimension 2 Code"),
                  GetDimValue(GLCorrEntry."Debit Dimension Set ID", GLCorrAnalysisView."Debit Dimension 3 Code"),
                  GetDimValue(GLCorrEntry."Credit Dimension Set ID", GLCorrAnalysisView."Credit Dimension 1 Code"),
                  GetDimValue(GLCorrEntry."Credit Dimension Set ID", GLCorrAnalysisView."Credit Dimension 2 Code"),
                  GetDimValue(GLCorrEntry."Credit Dimension Set ID", GLCorrAnalysisView."Credit Dimension 3 Code"));
            if ShowProgressWindow then
                UpdateWindowCounter(GLCorrEntry."Entry No.");
        until GLCorrEntry.Next() = 0;

        if ShowProgressWindow then
            UpdateWindowCounter(GLCorrEntry."Entry No.");
        FlushAnalysisViewEntry();
    end;

    local procedure UpdateAnalysisViewEntry(DebitDimValue1: Code[20]; DebitDimValue2: Code[20]; DebitDimValue3: Code[20]; CreditDimValue1: Code[20]; CreditDimValue2: Code[20]; CreditDimValue3: Code[20])
    var
        PostingDate: Date;
        EntryNo: Integer;
    begin
        PostingDate := GLCorrEntry."Posting Date";
        if PostingDate < GLCorrAnalysisView."Starting Date" then begin
            PostingDate := GLCorrAnalysisView."Starting Date" - 1;
            EntryNo := 0;
        end else begin
            PostingDate := CalculatePeriodStart(PostingDate, GLCorrAnalysisView."Date Compression");
            if PostingDate < GLCorrAnalysisView."Starting Date" then
                PostingDate := GLCorrAnalysisView."Starting Date";
            if GLCorrAnalysisView."Date Compression" = GLCorrAnalysisView."Date Compression"::None then
                EntryNo := GLCorrEntry."Entry No."
            else
                EntryNo := 0;
        end;

        TempGLCorrAnalysisViewEntry."G/L Corr. Analysis View Code" := GLCorrAnalysisView.Code;
        TempGLCorrAnalysisViewEntry."Business Unit Code" := GLCorrEntry."Business Unit Code";
        TempGLCorrAnalysisViewEntry."Debit Account No." := GLCorrEntry."Debit Account No.";
        TempGLCorrAnalysisViewEntry."Credit Account No." := GLCorrEntry."Credit Account No.";
        TempGLCorrAnalysisViewEntry."Posting Date" := PostingDate;
        TempGLCorrAnalysisViewEntry."Debit Dimension 1 Value Code" := DebitDimValue1;
        TempGLCorrAnalysisViewEntry."Debit Dimension 2 Value Code" := DebitDimValue2;
        TempGLCorrAnalysisViewEntry."Debit Dimension 3 Value Code" := DebitDimValue3;
        TempGLCorrAnalysisViewEntry."Credit Dimension 1 Value Code" := CreditDimValue1;
        TempGLCorrAnalysisViewEntry."Credit Dimension 2 Value Code" := CreditDimValue2;
        TempGLCorrAnalysisViewEntry."Credit Dimension 3 Value Code" := CreditDimValue3;
        TempGLCorrAnalysisViewEntry."Entry No." := EntryNo;

        if TempGLCorrAnalysisViewEntry.Find() then begin
            TempGLCorrAnalysisViewEntry.Amount := TempGLCorrAnalysisViewEntry.Amount + GLCorrEntry.Amount;
            TempGLCorrAnalysisViewEntry."Amount (ACY)" := TempGLCorrAnalysisViewEntry."Amount (ACY)" + GLCorrEntry."Amount (ACY)";
            TempGLCorrAnalysisViewEntry.Modify();
        end else begin
            TempGLCorrAnalysisViewEntry.Amount := GLCorrEntry.Amount;
            TempGLCorrAnalysisViewEntry."Amount (ACY)" := GLCorrEntry."Amount (ACY)";
            TempGLCorrAnalysisViewEntry.Insert();
            NoOfEntries := NoOfEntries + 1;
        end;
        if NoOfEntries >= 10000 then
            FlushAnalysisViewEntry();
    end;

    local procedure FlushAnalysisViewEntry()
    begin
        if ShowProgressWindow then
            Window.Update(6, Text011);
        if TempGLCorrAnalysisViewEntry.FindSet() then
            repeat
                GLCorrAnalysisViewEntry.Init();
                GLCorrAnalysisViewEntry := TempGLCorrAnalysisViewEntry;
                if not GLCorrAnalysisViewEntry.Insert() then begin
                    GLCorrAnalysisViewEntry.Find();
                    GLCorrAnalysisViewEntry.Amount :=
                      GLCorrAnalysisViewEntry.Amount + TempGLCorrAnalysisViewEntry.Amount;
                    GLCorrAnalysisViewEntry."Amount (ACY)" :=
                      GLCorrAnalysisViewEntry."Amount (ACY)" + TempGLCorrAnalysisViewEntry."Amount (ACY)";
                    GLCorrAnalysisViewEntry.Modify();
                end;
            until TempGLCorrAnalysisViewEntry.Next() = 0;
        TempGLCorrAnalysisViewEntry.DeleteAll();
        NoOfEntries := 0;
        if ShowProgressWindow then
            Window.Update(6, Text010);
    end;

    local procedure GetDimValue(DimSetID: Integer; DimCode: Code[20]): Code[20]
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if DimSetEntry.Get(DimSetID, DimCode) then
            exit(DimSetEntry."Dimension Value Code");

        exit('');
    end;

    local procedure InitWindow()
    begin
        Window.Open(
          Text005 +
          Text006 +
          Text009 +
          Text007 +
          Text008);
        Window.Update(6, Text010);
    end;

    local procedure UpdateWindowCounter(EntryNo: Integer)
    begin
        WinUpdateCounter := WinUpdateCounter + 1;
        WinTime2 := Time;
        if (WinTime2 > WinTime1 + 1000) or (EntryNo = WinLastEntryNo) then begin
            if WinLastEntryNo <> 0 then
                Window.Update(3, Round(EntryNo / WinLastEntryNo * 10000, 1));
            WinPrevEntryNo := EntryNo;
            WinTotalCounter := WinTotalCounter + WinUpdateCounter;
            if WinTime2 <> WinTime1 then
                Window.Update(4, Round(WinUpdateCounter * (1000 / (WinTime2 - WinTime1)), 1));
            if WinTime2 <> WinTime0 then
                Window.Update(5, Round(WinTotalCounter * (1000 / (WinTime2 - WinTime0)), 1));
            WinTime1 := WinTime2;
            WinUpdateCounter := 0;
        end;
    end;

    local procedure UpdateWindowHeader(TableID: Integer; EntryNo: Integer)
    var
        AllObj: Record AllObj;
    begin
        WinLastEntryNo := EntryNo;
        WinPrevEntryNo := 0;
        WinTotalCounter := 0;
        AllObj.Get(AllObj."Object Type"::Table, TableID);
        Window.Update(1, GLCorrAnalysisView.Code);
        Window.Update(2, AllObj."Object Name");
        Window.Update(3, 0);
        Window.Update(4, 0);
        Window.Update(5, 0);
        WinTime0 := Time;
        WinTime1 := WinTime0;
        WinTime2 := WinTime0;
    end;

    [Scope('OnPrem')]
    procedure CheckDimFilters(): Boolean
    var
        GLCorrAnalysisViewFilter: Record "G/L Corr. Analysis View Filter";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        GLCorrAnalysisViewFilter.SetRange("G/L Corr. Analysis View Code", GLCorrAnalysisView.Code);
        if GLCorrAnalysisViewFilter.IsEmpty() then
            exit(true);

        GLCorrAnalysisViewFilter.SetRange("Filter Group", GLCorrAnalysisViewFilter."Filter Group"::Debit);
        if GLCorrAnalysisViewFilter.FindSet() then
            repeat
                DimSetEntry.SetRange("Dimension Set ID", GLCorrEntry."Debit Dimension Set ID");
                DimSetEntry.SetRange("Dimension Code", GLCorrAnalysisViewFilter."Dimension Code");
                DimSetEntry.SetRange("Dimension Value Code", GLCorrAnalysisViewFilter."Dimension Value Filter");
                if DimSetEntry.IsEmpty() then
                    exit(false);
            until GLCorrAnalysisViewFilter.Next() = 0;

        GLCorrAnalysisViewFilter.SetRange("Filter Group", GLCorrAnalysisViewFilter."Filter Group"::Credit);
        if GLCorrAnalysisViewFilter.FindSet() then
            repeat
                DimSetEntry.SetRange("Dimension Set ID", GLCorrEntry."Credit Dimension Set ID");
                DimSetEntry.SetRange("Dimension Code", GLCorrAnalysisViewFilter."Dimension Code");
                DimSetEntry.SetRange("Dimension Value Code", GLCorrAnalysisViewFilter."Dimension Value Filter");
                if DimSetEntry.IsEmpty() then
                    exit(false);
            until GLCorrAnalysisViewFilter.Next() = 0;

        exit(true);
    end;

    local procedure CalculatePeriodStart(PostingDate: Date; DateCompression: Integer): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if PostingDate = ClosingDate(PostingDate) then
            exit(PostingDate);

        case DateCompression of
            GLCorrAnalysisView."Date Compression"::Week:
                PostingDate := CalcDate('<CW+1D-1W>', PostingDate);
            GLCorrAnalysisView."Date Compression"::Month:
                PostingDate := CalcDate('<CM+1D-1M>', PostingDate);
            GLCorrAnalysisView."Date Compression"::Quarter:
                PostingDate := CalcDate('<CQ+1D-1Q>', PostingDate);
            GLCorrAnalysisView."Date Compression"::Year:
                PostingDate := CalcDate('<CY+1D-1Y>', PostingDate);
            GLCorrAnalysisView."Date Compression"::Period:
                begin
                    if PostingDate <> PrevPostingDate then begin
                        PrevPostingDate := PostingDate;
                        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
                        if AccountingPeriod.FindLast() then
                            PrevCalculatedPostingDate := AccountingPeriod."Starting Date"
                        else
                            PrevCalculatedPostingDate := PostingDate;
                    end;
                    PostingDate := PrevCalculatedPostingDate;
                end;
        end;
        exit(PostingDate);
    end;

    local procedure IsValueIncludedInFilter(DimValue: Code[20]; DimFilter: Code[250]): Boolean
    begin
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        TempDimBuf.Init();
        TempDimBuf."Dimension Value Code" := DimValue;
        TempDimBuf.Insert();
        TempDimBuf.SetFilter("Dimension Value Code", DimFilter);
        exit(TempDimBuf.FindFirst());
    end;

    [Scope('OnPrem')]
    procedure DimSetIDInFilter(DimSetID: Integer; var GLCorrAnalysisView: Record "G/L Corr. Analysis View"): Boolean
    var
        InFilters: Boolean;
    begin
        if not FilterIsInitialized then begin
            TempDimEntryBuffer.DeleteAll();
            FilterIsInitialized := true;
            GLCorrAnalysisViewFilter.SetRange("G/L Corr. Analysis View Code", GLCorrAnalysisView.Code);
            FiltersExist := not GLCorrAnalysisViewFilter.IsEmpty();
        end;
        if not FiltersExist then
            exit(true);

        if TempDimEntryBuffer.Get(DimSetID) then
            exit(TempDimEntryBuffer."Dimension Entry No." <> 0);

        InFilters := true;
        if GLCorrAnalysisViewFilter.FindSet() then
            repeat
                if DimSetEntry.Get(DimSetID, GLCorrAnalysisViewFilter."Dimension Code") then
                    InFilters :=
                      InFilters and IsValueIncludedInFilter(DimSetEntry."Dimension Value Code", GLCorrAnalysisViewFilter."Dimension Value Filter")
                else
                    InFilters :=
                      InFilters and IsValueIncludedInFilter('', GLCorrAnalysisViewFilter."Dimension Value Filter");
            until (GLCorrAnalysisViewFilter.Next() = 0) or not InFilters;
        TempDimEntryBuffer."No." := DimSetID;
        if InFilters then
            TempDimEntryBuffer."Dimension Entry No." := 1
        else
            TempDimEntryBuffer."Dimension Entry No." := 0;
        TempDimEntryBuffer.Insert();
        exit(InFilters);
    end;
}

