codeunit 131320 "Library - ERM Vendor Watch"
{

    trigger OnRun()
    begin
    end;

    var
        WatchVendor: Record "Watch Vendor";
        WatchVendorLedgerEntry: Record "Watch Vendor Ledger Entry";
        Assert: Codeunit Assert;
        Tolerance: Decimal;

    [Scope('OnPrem')]
    procedure Init()
    begin
        Tolerance := 0.0;
        WatchVendor.Reset();
        WatchVendor.DeleteAll();
        WatchVendorLedgerEntry.Reset();
        WatchVendorLedgerEntry.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SetTolerance(Tol: Decimal)
    begin
        Tolerance := Tol;
    end;

    local procedure WatchVendorEntry(VendorNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean; LECompareMethod: Option; DtldLECompareMethod: Option)
    begin
        WatchVendor.Init();
        WatchVendor."Line No." := NextLineNo();
        WatchVendor."Vendor No." := VendorNo;

        WatchVendor."Original LE Count" := LedgerEntryTotal(VendorNo);
        WatchVendor."Original Dtld. LE Count" := DtldLedgerEntryTotal(VendorNo);
        WatchVendor."Watch LE" := WatchLETotal;
        WatchVendor."Watch Dtld. LE" := WatchDtldLETotal;
        WatchVendor."LE Comparison Method" := LECompareMethod;
        WatchVendor."Dtld. LE Comparison Method" := DtldLECompareMethod;

        WatchVendor.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure VendorEqual(VendorNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchVendorEntry(VendorNo, WatchLETotal, WatchDtldLETotal,
          WatchVendor."LE Comparison Method"::Equal,
          WatchVendor."Dtld. LE Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure VendorGreaterThan(VendorNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchVendorEntry(VendorNo, WatchLETotal, WatchDtldLETotal,
          WatchVendor."LE Comparison Method"::"Greater Than",
          WatchVendor."Dtld. LE Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure VendorLessThan(VendorNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchVendorEntry(VendorNo, WatchLETotal, WatchDtldLETotal,
          WatchVendor."LE Comparison Method"::"Less Than",
          WatchVendor."Dtld. LE Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchLedgerEntries(VendorNo: Code[20]; EntryType: Option; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        WatchVendorLedgerEntry.Init();
        WatchVendorLedgerEntry."Line No." := NextLELineNo();
        WatchVendorLedgerEntry."Vendor No." := VendorNo;
        WatchVendorLedgerEntry."Line Level" := WatchVendorLedgerEntry."Line Level"::"Ledger Entry";
        WatchVendorLedgerEntry."Line Type" := EntryType;

        WatchVendorLedgerEntry."Original Count" := LedgerEntryCount(VendorNo, EntryType);
        WatchVendorLedgerEntry."Delta Count" := DeltaCount;
        WatchVendorLedgerEntry."Original Sum" := LedgerEntrySum(VendorNo, EntryType);
        WatchVendorLedgerEntry."Delta Sum" := DeltaSum;
        WatchVendorLedgerEntry."Count Comparison Method" := CountCompareMethod;
        WatchVendorLedgerEntry."Sum Comparison Method" := SumCompareMethod;

        WatchVendorLedgerEntry.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure EntriesEqual(VendorNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure EntriesGreaterThan(VendorNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure EntriesLessThan(VendorNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchDtldLedgerEntries(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        WatchVendorLedgerEntry.Init();
        WatchVendorLedgerEntry."Line No." := NextLELineNo();
        WatchVendorLedgerEntry."Vendor No." := VendorNo;
        WatchVendorLedgerEntry."Line Level" := WatchVendorLedgerEntry."Line Level"::"Detailed Ledger Entry";
        WatchVendorLedgerEntry."Line Type" := EntryType.AsInteger();

        WatchVendorLedgerEntry."Original Count" := DtldLedgerEntryCount(VendorNo, EntryType);
        WatchVendorLedgerEntry."Delta Count" := DeltaCount;
        WatchVendorLedgerEntry."Original Sum" := DtldLedgerEntrySum(VendorNo, EntryType);
        WatchVendorLedgerEntry."Delta Sum" := DeltaSum;
        WatchVendorLedgerEntry."Count Comparison Method" := CountCompareMethod;
        WatchVendorLedgerEntry."Sum Comparison Method" := SumCompareMethod;

        WatchVendorLedgerEntry.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesSigned(Sign: Decimal; VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        if Sign = 0 then
            DtldEntriesEqual(VendorNo, EntryType, DeltaSum)
        else
            if Sign > 0 then
                DtldEntriesGreaterThan(VendorNo, EntryType, DeltaSum)
            else
                DtldEntriesLessThan(VendorNo, EntryType, DeltaSum);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesEqual(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesGreaterThan(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesLessThan(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    local procedure AssertLedgerEntry(WatchVendorLedgerEntry2: Record "Watch Vendor Ledger Entry")
    begin
        DeltaCompareCount(
            WatchVendorLedgerEntry2."Original Count",
            WatchVendorLedgerEntry2."Delta Count",
            LedgerEntryCount(WatchVendorLedgerEntry2."Vendor No.", WatchVendorLedgerEntry2."Line Type"),
            WatchVendorLedgerEntry2."Count Comparison Method",
            'Incorrect ledger entry count, vendor: ' + WatchVendorLedgerEntry2."Vendor No." + ', line type: ' + Format(WatchVendorLedgerEntry2."Line Type"));

        DeltaCompareSum(
          WatchVendorLedgerEntry2."Original Sum",
          WatchVendorLedgerEntry2."Delta Sum",
          LedgerEntrySum(WatchVendorLedgerEntry2."Vendor No.", WatchVendorLedgerEntry2."Line Type"),
          WatchVendorLedgerEntry2."Sum Comparison Method",
          'Incorrect ledger entry sum, vendor: ' + WatchVendorLedgerEntry2."Vendor No." + ', line type: ' + Format(WatchVendorLedgerEntry2."Line Type"));
    end;

    local procedure AssertDtldLedgerEntry(WatchVendorLedgerEntry2: Record "Watch Vendor Ledger Entry")
    begin
        DeltaCompareCount(
            WatchVendorLedgerEntry2."Original Count",
            WatchVendorLedgerEntry2."Delta Count",
            DtldLedgerEntryCount(WatchVendorLedgerEntry2."Vendor No.", "Detailed CV Ledger Entry Type".FromInteger(WatchVendorLedgerEntry2."Line Type")),
            WatchVendorLedgerEntry2."Count Comparison Method",
            'Incorrect detailed ledger entry count, vendor: ' + WatchVendorLedgerEntry2."Vendor No." + ', line type: ' + Format(WatchVendorLedgerEntry2."Line Type"));

        DeltaCompareSum(
          WatchVendorLedgerEntry2."Original Sum",
          WatchVendorLedgerEntry2."Delta Sum",
          DtldLedgerEntrySum(WatchVendorLedgerEntry2."Vendor No.", "Detailed CV Ledger Entry Type".FromInteger(WatchVendorLedgerEntry2."Line Type")),
          WatchVendorLedgerEntry2."Sum Comparison Method",
          'Incorrect detailed ledger entry sum, vendor: ' + WatchVendorLedgerEntry2."Vendor No." + ', line type: ' + Format(WatchVendorLedgerEntry2."Line Type"));
    end;

    [Scope('OnPrem')]
    procedure AssertVendor()
    var
        TotalLEDelta: Integer;
        TotalDtldLEDelta: Integer;
    begin
        TotalLEDelta := 0;
        TotalDtldLEDelta := 0;

        WatchVendorLedgerEntry.Reset();

        if WatchVendorLedgerEntry.FindSet() then
            repeat
                if WatchVendorLedgerEntry."Line Level" = WatchVendorLedgerEntry."Line Level"::"Ledger Entry" then begin
                    TotalLEDelta += WatchVendorLedgerEntry."Delta Count";
                    AssertLedgerEntry(WatchVendorLedgerEntry)
                end else begin
                    TotalDtldLEDelta += WatchVendorLedgerEntry."Delta Count";
                    AssertDtldLedgerEntry(WatchVendorLedgerEntry);
                end;
            until WatchVendorLedgerEntry.Next() = 0;

        WatchVendor.Reset();
        if WatchVendor.FindFirst() then begin
            // Check that all ledger entries are accounted for
            if WatchVendor."Watch LE" then
                DeltaCompareCount(WatchVendor."Original LE Count", TotalLEDelta, LedgerEntryTotal(WatchVendor."Vendor No."), WatchVendor."LE Comparison Method",
                  'There are unaccounted for ledger entries');
            // Check that all detailed ledger entries are accounted for
            if WatchVendor."Watch Dtld. LE" then
                DeltaCompareCount(
                  WatchVendor."Original Dtld. LE Count", TotalDtldLEDelta, DtldLedgerEntryTotal(WatchVendor."Vendor No."), WatchVendor."Dtld. LE Comparison Method"
                  , 'There are unaccounted for detailed ledger entries');
        end;
    end;

    local procedure DeltaCompareCount(Original: Integer; Delta: Integer; Total: Integer; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
#pragma warning disable AA0139
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
#pragma warning restore AA0139
        case ComparisonMethod of
            WatchVendorLedgerEntry."Count Comparison Method"::Equal:
                Assert.AreEqual(Original + Delta, Total, ErrorMsg);
            WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchVendorLedgerEntry."Count Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure DeltaCompareSum(Original: Decimal; Delta: Decimal; Total: Decimal; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
#pragma warning disable AA0139
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
#pragma warning restore AA0139
        case ComparisonMethod of
            WatchVendorLedgerEntry."Sum Comparison Method"::Equal:
                Assert.AreNearlyEqual(Original + Delta, Total, Tolerance, ErrorMsg);
            WatchVendorLedgerEntry."Sum Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchVendorLedgerEntry."Sum Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure LedgerEntryTotal(VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        if VendorLedgerEntry.FindFirst() then
            exit(VendorLedgerEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntryTotal(VendorNo: Code[20]): Integer
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendorLedgEntry.Reset();
        DtldVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        if DtldVendorLedgEntry.FindFirst() then
            exit(DtldVendorLedgEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntryCount(VendorNo: Code[20]; LineType: Option): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", LineType);
        if VendorLedgerEntry.FindFirst() then
            exit(VendorLedgerEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntrySum(VendorNo: Code[20]; LineType: Option) "Sum": Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", LineType);
        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields(Amount);
                Sum += VendorLedgerEntry.Amount;
            until VendorLedgerEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure DtldLedgerEntryCount(VendorNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type"): Integer
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendorLedgEntry.Reset();
        DtldVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DtldVendorLedgEntry.SetRange("Entry Type", LineType);
        if DtldVendorLedgEntry.FindFirst() then
            exit(DtldVendorLedgEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntrySum(VendorNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type") "Sum": Decimal
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendorLedgEntry.Reset();
        DtldVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DtldVendorLedgEntry.SetRange("Entry Type", LineType);
        if DtldVendorLedgEntry.FindSet() then
            repeat
                Sum += DtldVendorLedgEntry.Amount;
            until DtldVendorLedgEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure NextLineNo(): Integer
    var
        WatchVendor2: Record "Watch Vendor";
    begin
        if WatchVendor2.FindLast() then
            exit(WatchVendor2."Line No." + 1);
        exit(1);
    end;

    local procedure NextLELineNo(): Integer
    var
        WatchVendorLedgerEntry2: Record "Watch Vendor Ledger Entry";
    begin
        if WatchVendorLedgerEntry2.FindLast() then
            exit(WatchVendorLedgerEntry2."Line No." + 1);
        exit(1);
    end;
}

