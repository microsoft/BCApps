codeunit 131310 "Library - ERM Customer Watch"
{

    trigger OnRun()
    begin
    end;

    var
        WatchCustomer: Record "Watch Customer";
        WatchCustLedgerEntry: Record "Watch Customer Ledger Entry";
        Assert: Codeunit Assert;
        Tolerance: Decimal;

    [Scope('OnPrem')]
    procedure Init()
    begin
        Tolerance := 0.0;
        WatchCustomer.Reset();
        WatchCustomer.DeleteAll();
        WatchCustLedgerEntry.Reset();
        WatchCustLedgerEntry.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SetTolerance(Tol: Decimal)
    begin
        Tolerance := Tol;
    end;

    local procedure WatchCustomerEntry(CustomerNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean; LECompareMethod: Option; DtldLECompareMethod: Option)
    begin
        WatchCustomer.Init();
        WatchCustomer."Line No." := NextLineNo();
        WatchCustomer."Customer No." := CustomerNo;

        WatchCustomer."Original LE Count" := LedgerEntryTotal(CustomerNo);
        WatchCustomer."Original Dtld. LE Count" := DtldLedgerEntryTotal(CustomerNo);
        WatchCustomer."Watch LE" := WatchLETotal;
        WatchCustomer."Watch Dtld. LE" := WatchDtldLETotal;
        WatchCustomer."LE Comparison Method" := LECompareMethod;
        WatchCustomer."Dtld. LE Comparison Method" := DtldLECompareMethod;

        WatchCustomer.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CustomerEqual(CustomerNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchCustomerEntry(CustomerNo, WatchLETotal, WatchDtldLETotal,
          WatchCustomer."LE Comparison Method"::Equal,
          WatchCustomer."Dtld. LE Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure CustomerGreaterThan(CustomerNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchCustomerEntry(CustomerNo, WatchLETotal, WatchDtldLETotal,
          WatchCustomer."LE Comparison Method"::"Greater Than",
          WatchCustomer."Dtld. LE Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure CustomerLessThan(CustomerNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchCustomerEntry(CustomerNo, WatchLETotal, WatchDtldLETotal,
          WatchCustomer."LE Comparison Method"::"Less Than",
          WatchCustomer."Dtld. LE Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchLedgerEntries(CustomerNo: Code[20]; EntryType: Option; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        WatchCustLedgerEntry.Init();
        WatchCustLedgerEntry."Line No." := NextLELineNo();
        WatchCustLedgerEntry."Customer No." := CustomerNo;
        WatchCustLedgerEntry."Line Level" := WatchCustLedgerEntry."Line Level"::"Ledger Entry";
        WatchCustLedgerEntry."Line Type" := EntryType;

        WatchCustLedgerEntry."Original Count" := LedgerEntryCount(CustomerNo, EntryType);
        WatchCustLedgerEntry."Delta Count" := DeltaCount;
        WatchCustLedgerEntry."Original Sum" := LedgerEntrySum(CustomerNo, EntryType);
        WatchCustLedgerEntry."Delta Sum" := DeltaSum;
        WatchCustLedgerEntry."Count Comparison Method" := CountCompareMethod;
        WatchCustLedgerEntry."Sum Comparison Method" := SumCompareMethod;

        WatchCustLedgerEntry.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure EntriesEqual(CustomerNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure EntriesGreaterThan(CustomerNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure EntriesLessThan(CustomerNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchDtldLedgerEntries(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        WatchCustLedgerEntry.Init();
        WatchCustLedgerEntry."Line No." := NextLELineNo();
        WatchCustLedgerEntry."Customer No." := CustomerNo;
        WatchCustLedgerEntry."Line Level" := WatchCustLedgerEntry."Line Level"::"Detailed Ledger Entry";
        WatchCustLedgerEntry."Line Type" := EntryType.AsInteger();

        WatchCustLedgerEntry."Original Count" := DtldLedgerEntryCount(CustomerNo, EntryType);
        WatchCustLedgerEntry."Delta Count" := DeltaCount;
        WatchCustLedgerEntry."Original Sum" := DtldLedgerEntrySum(CustomerNo, EntryType);
        WatchCustLedgerEntry."Delta Sum" := DeltaSum;
        WatchCustLedgerEntry."Count Comparison Method" := CountCompareMethod;
        WatchCustLedgerEntry."Sum Comparison Method" := SumCompareMethod;

        WatchCustLedgerEntry.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesSigned(Sign: Decimal; CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        if Sign = 0 then
            DtldEntriesEqual(CustomerNo, EntryType, DeltaSum)
        else
            if Sign > 0 then
                DtldEntriesGreaterThan(CustomerNo, EntryType, DeltaSum)
            else
                DtldEntriesLessThan(CustomerNo, EntryType, DeltaSum);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesEqual(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesGreaterThan(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesLessThan(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    local procedure AssertLedgerEntry(WatchCustLedgerEntry2: Record "Watch Customer Ledger Entry")
    begin
        DeltaCompareCount(
            WatchCustLedgerEntry2."Original Count",
            WatchCustLedgerEntry2."Delta Count",
            LedgerEntryCount(WatchCustLedgerEntry2."Customer No.", WatchCustLedgerEntry2."Line Type"),
            WatchCustLedgerEntry2."Count Comparison Method",
            'Incorrect ledger entry count, Customer: ' + WatchCustLedgerEntry2."Customer No." + ', line type: ' + Format(WatchCustLedgerEntry2."Line Type"));

        DeltaCompareSum(
          WatchCustLedgerEntry2."Original Sum",
          WatchCustLedgerEntry2."Delta Sum",
          LedgerEntrySum(WatchCustLedgerEntry2."Customer No.", WatchCustLedgerEntry2."Line Type"),
          WatchCustLedgerEntry2."Sum Comparison Method",
          'Incorrect ledger entry sum, Customer: ' + WatchCustLedgerEntry2."Customer No." + ', line type: ' + Format(WatchCustLedgerEntry2."Line Type"));
    end;

    local procedure AssertDtldLedgerEntry(WatchCustLedgerEntry2: Record "Watch Customer Ledger Entry")
    begin
        DeltaCompareCount(
            WatchCustLedgerEntry2."Original Count",
            WatchCustLedgerEntry2."Delta Count",
            DtldLedgerEntryCount(WatchCustLedgerEntry2."Customer No.", "Detailed CV Ledger Entry Type".FromInteger(WatchCustLedgerEntry2."Line Type")),
            WatchCustLedgerEntry2."Count Comparison Method",
            'Incorrect detailed ledger entry count, Customer: ' + WatchCustLedgerEntry2."Customer No." + ', line type: ' + Format(WatchCustLedgerEntry2."Line Type"));

        DeltaCompareSum(
          WatchCustLedgerEntry2."Original Sum",
          WatchCustLedgerEntry2."Delta Sum",
          DtldLedgerEntrySum(WatchCustLedgerEntry2."Customer No.", "Detailed CV Ledger Entry Type".FromInteger(WatchCustLedgerEntry2."Line Type")),
          WatchCustLedgerEntry2."Sum Comparison Method",
          'Incorrect detailed ledger entry sum, Customer: ' + WatchCustLedgerEntry2."Customer No." + ', line type: ' + Format(WatchCustLedgerEntry2."Line Type"));
    end;

    [Scope('OnPrem')]
    procedure AssertCustomer()
    var
        TotalLEDelta: Integer;
        TotalDtldLEDelta: Integer;
    begin
        TotalLEDelta := 0;
        TotalDtldLEDelta := 0;

        WatchCustLedgerEntry.Reset();

        if WatchCustLedgerEntry.FindSet() then
            repeat
                if WatchCustLedgerEntry."Line Level" = WatchCustLedgerEntry."Line Level"::"Ledger Entry" then begin
                    TotalLEDelta += WatchCustLedgerEntry."Delta Count";
                    AssertLedgerEntry(WatchCustLedgerEntry)
                end else begin
                    TotalDtldLEDelta += WatchCustLedgerEntry."Delta Count";
                    AssertDtldLedgerEntry(WatchCustLedgerEntry);
                end;
            until WatchCustLedgerEntry.Next() = 0;

        WatchCustomer.Reset();
        if WatchCustomer.FindFirst() then begin
            // Check that all ledger entries are accounted for
            if WatchCustomer."Watch LE" then
                DeltaCompareCount(WatchCustomer."Original LE Count", TotalLEDelta, LedgerEntryTotal(WatchCustomer."Customer No."), WatchCustomer."LE Comparison Method",
                  'There are unaccounted for ledger entries');
            // Check that all detailed ledger entries are accounted for
            if WatchCustomer."Watch Dtld. LE" then
                DeltaCompareCount(
                  WatchCustomer."Original Dtld. LE Count", TotalDtldLEDelta, DtldLedgerEntryTotal(WatchCustomer."Customer No."), WatchCustomer."Dtld. LE Comparison Method"
                  , 'There are unaccounted for detailed ledger entries');
        end;
    end;

    local procedure DeltaCompareCount(Original: Integer; Delta: Integer; Total: Integer; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
        case ComparisonMethod of
            WatchCustLedgerEntry."Count Comparison Method"::Equal:
                Assert.AreEqual(Original + Delta, Total, ErrorMsg);
            WatchCustLedgerEntry."Count Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchCustLedgerEntry."Count Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure DeltaCompareSum(Original: Decimal; Delta: Decimal; Total: Decimal; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
        case ComparisonMethod of
            WatchCustLedgerEntry."Sum Comparison Method"::Equal:
                Assert.AreNearlyEqual(Original + Delta, Total, Tolerance, ErrorMsg);
            WatchCustLedgerEntry."Sum Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchCustLedgerEntry."Sum Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure LedgerEntryTotal(CustomerNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if CustLedgerEntry.FindFirst() then
            exit(CustLedgerEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntryTotal(CustomerNo: Code[20]): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetRange("Customer No.", CustomerNo);
        if DtldCustLedgEntry.FindFirst() then
            exit(DtldCustLedgEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntryCount(CustomerNo: Code[20]; LineType: Option): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", LineType);
        if CustLedgerEntry.FindFirst() then
            exit(CustLedgerEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntrySum(CustomerNo: Code[20]; LineType: Option) "Sum": Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", LineType);
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.CalcFields(Amount);
                Sum += CustLedgerEntry.Amount;
            until CustLedgerEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure DtldLedgerEntryCount(CustomerNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type"): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DtldCustLedgEntry.SetRange("Entry Type", LineType);
        if DtldCustLedgEntry.FindFirst() then
            exit(DtldCustLedgEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntrySum(CustomerNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type") "Sum": Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DtldCustLedgEntry.SetRange("Entry Type", LineType);
        if DtldCustLedgEntry.FindSet() then
            repeat
                Sum += DtldCustLedgEntry.Amount;
            until DtldCustLedgEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure NextLineNo(): Integer
    var
        WatchCustomer2: Record "Watch Customer";
    begin
        if WatchCustomer2.FindLast() then
            exit(WatchCustomer2."Line No." + 1);
        exit(1);
    end;

    local procedure NextLELineNo(): Integer
    var
        WatchCustLedgerEntry2: Record "Watch Customer Ledger Entry";
    begin
        if WatchCustLedgerEntry2.FindLast() then
            exit(WatchCustLedgerEntry2."Line No." + 1);
        exit(1);
    end;
}

