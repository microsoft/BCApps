codeunit 131321 "Library - ERM Employee Watch"
{

    trigger OnRun()
    begin
    end;

    var
        WatchEmployee: Record "Watch Employee";
        WatchEmployeeLedgerEntry: Record "Watch Employee Ledger Entry";
        Assert: Codeunit Assert;
        Tolerance: Decimal;

    [Scope('OnPrem')]
    procedure Init()
    begin
        Tolerance := 0.0;
        WatchEmployee.Reset();
        WatchEmployee.DeleteAll();
        WatchEmployeeLedgerEntry.Reset();
        WatchEmployeeLedgerEntry.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SetTolerance(Tol: Decimal)
    begin
        Tolerance := Tol;
    end;

    local procedure WatchEmployeeEntry(EmployeeNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean; LECompareMethod: Option; DtldLECompareMethod: Option)
    begin
        WatchEmployee.Init();
        WatchEmployee."Line No." := NextLineNo();
        WatchEmployee."Employee No." := EmployeeNo;

        WatchEmployee."Original LE Count" := LedgerEntryTotal(EmployeeNo);
        WatchEmployee."Original Dtld. LE Count" := DtldLedgerEntryTotal(EmployeeNo);
        WatchEmployee."Watch LE" := WatchLETotal;
        WatchEmployee."Watch Dtld. LE" := WatchDtldLETotal;
        WatchEmployee."LE Comparison Method" := LECompareMethod;
        WatchEmployee."Dtld. LE Comparison Method" := DtldLECompareMethod;

        WatchEmployee.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure EmployeeEqual(EmployeeNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchEmployeeEntry(EmployeeNo, WatchLETotal, WatchDtldLETotal,
          WatchEmployee."LE Comparison Method"::Equal,
          WatchEmployee."Dtld. LE Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure EmployeeGreaterThan(EmployeeNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchEmployeeEntry(EmployeeNo, WatchLETotal, WatchDtldLETotal,
          WatchEmployee."LE Comparison Method"::"Greater Than",
          WatchEmployee."Dtld. LE Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure EmployeeLessThan(EmployeeNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchEmployeeEntry(EmployeeNo, WatchLETotal, WatchDtldLETotal,
          WatchEmployee."LE Comparison Method"::"Less Than",
          WatchEmployee."Dtld. LE Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchLedgerEntries(EmployeeNo: Code[20]; EntryType: Option; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        WatchEmployeeLedgerEntry.Init();
        WatchEmployeeLedgerEntry."Line No." := NextLELineNo();
        WatchEmployeeLedgerEntry."Employee No." := EmployeeNo;
        WatchEmployeeLedgerEntry."Line Level" := WatchEmployeeLedgerEntry."Line Level"::"Ledger Entry";
        WatchEmployeeLedgerEntry."Line Type" := EntryType;

        WatchEmployeeLedgerEntry."Original Count" := LedgerEntryCount(EmployeeNo, EntryType);
        WatchEmployeeLedgerEntry."Delta Count" := DeltaCount;
        WatchEmployeeLedgerEntry."Original Sum" := LedgerEntrySum(EmployeeNo, EntryType);
        WatchEmployeeLedgerEntry."Delta Sum" := DeltaSum;
        WatchEmployeeLedgerEntry."Count Comparison Method" := CountCompareMethod;
        WatchEmployeeLedgerEntry."Sum Comparison Method" := SumCompareMethod;

        WatchEmployeeLedgerEntry.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure EntriesEqual(EmployeeNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(EmployeeNo, EntryType, 1, DeltaSum,
          WatchEmployeeLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchEmployeeLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure EntriesGreaterThan(EmployeeNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(EmployeeNo, EntryType, 1, DeltaSum,
          WatchEmployeeLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchEmployeeLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure EntriesLessThan(EmployeeNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(EmployeeNo, EntryType, 1, DeltaSum,
          WatchEmployeeLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchEmployeeLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchDtldLedgerEntries(EmployeeNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        WatchEmployeeLedgerEntry.Init();
        WatchEmployeeLedgerEntry."Line No." := NextLELineNo();
        WatchEmployeeLedgerEntry."Employee No." := EmployeeNo;
        WatchEmployeeLedgerEntry."Line Level" := WatchEmployeeLedgerEntry."Line Level"::"Detailed Ledger Entry";
        WatchEmployeeLedgerEntry."Line Type" := EntryType.AsInteger();

        WatchEmployeeLedgerEntry."Original Count" := DtldLedgerEntryCount(EmployeeNo, EntryType);
        WatchEmployeeLedgerEntry."Delta Count" := DeltaCount;
        WatchEmployeeLedgerEntry."Original Sum" := DtldLedgerEntrySum(EmployeeNo, EntryType);
        WatchEmployeeLedgerEntry."Delta Sum" := DeltaSum;
        WatchEmployeeLedgerEntry."Count Comparison Method" := CountCompareMethod;
        WatchEmployeeLedgerEntry."Sum Comparison Method" := SumCompareMethod;

        WatchEmployeeLedgerEntry.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesSigned(Sign: Decimal; EmployeeNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        if Sign = 0 then
            DtldEntriesEqual(EmployeeNo, EntryType, DeltaSum)
        else
            if Sign > 0 then
                DtldEntriesGreaterThan(EmployeeNo, EntryType, DeltaSum)
            else
                DtldEntriesLessThan(EmployeeNo, EntryType, DeltaSum);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesEqual(EmployeeNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(EmployeeNo, EntryType, 1, DeltaSum,
          WatchEmployeeLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchEmployeeLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesGreaterThan(EmployeeNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(EmployeeNo, EntryType, 1, DeltaSum,
          WatchEmployeeLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchEmployeeLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesLessThan(EmployeeNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(EmployeeNo, EntryType, 1, DeltaSum,
          WatchEmployeeLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchEmployeeLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    local procedure AssertLedgerEntry(WatchEmployeeLedgerEntry2: Record "Watch Employee Ledger Entry")
    begin
        DeltaCompareCount(
            WatchEmployeeLedgerEntry2."Original Count",
            WatchEmployeeLedgerEntry2."Delta Count",
            LedgerEntryCount(WatchEmployeeLedgerEntry2."Employee No.", WatchEmployeeLedgerEntry2."Line Type"),
            WatchEmployeeLedgerEntry2."Count Comparison Method",
            'Incorrect ledger entry count, Employee: ' + WatchEmployeeLedgerEntry2."Employee No." + ', line type: ' + Format(WatchEmployeeLedgerEntry2."Line Type"));

        DeltaCompareSum(
          WatchEmployeeLedgerEntry2."Original Sum",
          WatchEmployeeLedgerEntry2."Delta Sum",
          LedgerEntrySum(WatchEmployeeLedgerEntry2."Employee No.", WatchEmployeeLedgerEntry2."Line Type"),
          WatchEmployeeLedgerEntry2."Sum Comparison Method",
          'Incorrect ledger entry sum, Employee: ' + WatchEmployeeLedgerEntry2."Employee No." + ', line type: ' + Format(WatchEmployeeLedgerEntry2."Line Type"));
    end;

    local procedure AssertDtldLedgerEntry(WatchEmployeeLedgerEntry2: Record "Watch Employee Ledger Entry")
    begin
        DeltaCompareCount(
            WatchEmployeeLedgerEntry2."Original Count",
            WatchEmployeeLedgerEntry2."Delta Count",
            DtldLedgerEntryCount(WatchEmployeeLedgerEntry2."Employee No.", "Detailed CV Ledger Entry Type".FromInteger(WatchEmployeeLedgerEntry2."Line Type")),
            WatchEmployeeLedgerEntry2."Count Comparison Method",
            'Incorrect detailed ledger entry count, Employee: ' + WatchEmployeeLedgerEntry2."Employee No." + ', line type: ' + Format(WatchEmployeeLedgerEntry2."Line Type"));

        DeltaCompareSum(
          WatchEmployeeLedgerEntry2."Original Sum",
          WatchEmployeeLedgerEntry2."Delta Sum",
          DtldLedgerEntrySum(WatchEmployeeLedgerEntry2."Employee No.", "Detailed CV Ledger Entry Type".FromInteger(WatchEmployeeLedgerEntry2."Line Type")),
          WatchEmployeeLedgerEntry2."Sum Comparison Method",
          'Incorrect detailed ledger entry sum, Employee: ' + WatchEmployeeLedgerEntry2."Employee No." + ', line type: ' + Format(WatchEmployeeLedgerEntry2."Line Type"));
    end;

    [Scope('OnPrem')]
    procedure AssertEmployee()
    var
        TotalLEDelta: Integer;
        TotalDtldLEDelta: Integer;
    begin
        TotalLEDelta := 0;
        TotalDtldLEDelta := 0;

        WatchEmployeeLedgerEntry.Reset();

        if WatchEmployeeLedgerEntry.FindSet() then
            repeat
                if WatchEmployeeLedgerEntry."Line Level" = WatchEmployeeLedgerEntry."Line Level"::"Ledger Entry" then begin
                    TotalLEDelta += WatchEmployeeLedgerEntry."Delta Count";
                    AssertLedgerEntry(WatchEmployeeLedgerEntry)
                end else begin
                    TotalDtldLEDelta += WatchEmployeeLedgerEntry."Delta Count";
                    AssertDtldLedgerEntry(WatchEmployeeLedgerEntry);
                end;
            until WatchEmployeeLedgerEntry.Next() = 0;

        WatchEmployee.Reset();
        if WatchEmployee.FindFirst() then begin
            // Check that all ledger entries are accounted for
            if WatchEmployee."Watch LE" then
                DeltaCompareCount(WatchEmployee."Original LE Count", TotalLEDelta, LedgerEntryTotal(WatchEmployee."Employee No."), WatchEmployee."LE Comparison Method",
                  'There are unaccounted for ledger entries');
            // Check that all detailed ledger entries are accounted for
            if WatchEmployee."Watch Dtld. LE" then
                DeltaCompareCount(
                  WatchEmployee."Original Dtld. LE Count", TotalDtldLEDelta, DtldLedgerEntryTotal(WatchEmployee."Employee No."), WatchEmployee."Dtld. LE Comparison Method"
                  , 'There are unaccounted for detailed ledger entries');
        end;
    end;

    local procedure DeltaCompareCount(Original: Integer; Delta: Integer; Total: Integer; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
        case ComparisonMethod of
            WatchEmployeeLedgerEntry."Count Comparison Method"::Equal:
                Assert.AreEqual(Original + Delta, Total, ErrorMsg);
            WatchEmployeeLedgerEntry."Count Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchEmployeeLedgerEntry."Count Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure DeltaCompareSum(Original: Decimal; Delta: Decimal; Total: Decimal; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
        case ComparisonMethod of
            WatchEmployeeLedgerEntry."Sum Comparison Method"::Equal:
                Assert.AreNearlyEqual(Original + Delta, Total, Tolerance, ErrorMsg);
            WatchEmployeeLedgerEntry."Sum Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchEmployeeLedgerEntry."Sum Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure LedgerEntryTotal(EmployeeNo: Code[20]): Integer
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.Reset();
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        if EmployeeLedgerEntry.FindFirst() then
            exit(EmployeeLedgerEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntryTotal(EmployeeNo: Code[20]): Integer
    var
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        DtldEmployeeLedgEntry.Reset();
        DtldEmployeeLedgEntry.SetRange("Employee No.", EmployeeNo);
        if DtldEmployeeLedgEntry.FindFirst() then
            exit(DtldEmployeeLedgEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntryCount(EmployeeNo: Code[20]; LineType: Option): Integer
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetRange("Document Type", LineType);
        if EmployeeLedgerEntry.FindFirst() then
            exit(EmployeeLedgerEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntrySum(EmployeeNo: Code[20]; LineType: Option) "Sum": Decimal
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetRange("Document Type", LineType);
        if EmployeeLedgerEntry.FindSet() then
            repeat
                EmployeeLedgerEntry.CalcFields(Amount);
                Sum += EmployeeLedgerEntry.Amount;
            until EmployeeLedgerEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure DtldLedgerEntryCount(EmployeeNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type"): Integer
    var
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        DtldEmployeeLedgEntry.Reset();
        DtldEmployeeLedgEntry.SetRange("Employee No.", EmployeeNo);
        DtldEmployeeLedgEntry.SetRange("Entry Type", LineType);
        if DtldEmployeeLedgEntry.FindFirst() then
            exit(DtldEmployeeLedgEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntrySum(EmployeeNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type") "Sum": Decimal
    var
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        DtldEmployeeLedgEntry.Reset();
        DtldEmployeeLedgEntry.SetRange("Employee No.", EmployeeNo);
        DtldEmployeeLedgEntry.SetRange("Entry Type", LineType);
        if DtldEmployeeLedgEntry.FindSet() then
            repeat
                Sum += DtldEmployeeLedgEntry.Amount;
            until DtldEmployeeLedgEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure NextLineNo(): Integer
    var
        WatchEmployee2: Record "Watch Employee";
    begin
        if WatchEmployee2.FindLast() then
            exit(WatchEmployee2."Line No." + 1);
        exit(1);
    end;

    local procedure NextLELineNo(): Integer
    var
        WatchEmployeeLedgerEntry2: Record "Watch Employee Ledger Entry";
    begin
        if WatchEmployeeLedgerEntry2.FindLast() then
            exit(WatchEmployeeLedgerEntry2."Line No." + 1);
        exit(1);
    end;
}

