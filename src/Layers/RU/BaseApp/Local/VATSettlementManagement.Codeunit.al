#pragma warning disable AA0247
codeunit 12411 "VAT Settlement Management"
{
    Permissions = TableData "VAT Entry" = imd,
                  TableData "VAT Document Entry Buffer" = i;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text14701: Label 'VAT by Act - ';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text14705: Label 'Unrealized VAT had been already realized for %1 = %2, %3 = %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text14704: Label 'Unrealized VAT had been already realized in %1 for %2 = %3, %4 = %5.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text14706: Label '%1 %2 must not be more than %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text14707: Label '%1 %2: %3 must not be less than %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12403: Label 'FA No. %1 is not into operation.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12404: Label '%1 %2 cannot be less than %3 %4 for FA No. %5.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12405: Label '%1 %2: %3 %4 cannot be less than %5 %6.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text14711: Label '%1 must be %2 for %3 = %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text14713: Label 'must be positive';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text14714: Label 'must be negative';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text14715: Label 'Posted VAT Settlement entries exist. You should reverse these entries before unapply operation.';
#pragma warning restore AA0074
        VATDocEntryBuffer: Record "VAT Document Entry Buffer";
        DimMgt: Codeunit DimensionManagement;
        RecalculationDate: Date;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text14716: Label 'Dimension used in %1 %2, %3 has caused an error. %4';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text14717: Label 'Dimension used in %1 %2, %3, %4 has caused an error. %5';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CalcAmount(var GenJnlLine: Record "Gen. Journal Line") AppliedAmount: Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        AppliedAmount := 0;
        DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Transaction No.", GenJnlLine."VAT Transaction No.");
        DtldVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
        DtldVendLedgEntry.SetFilter("Entry Type", '%1|%2|%3', DtldVendLedgEntry."Entry Type"::Application,
          DtldVendLedgEntry."Entry Type"::"Realized Loss",
          DtldVendLedgEntry."Entry Type"::"Realized Gain");
        if DtldVendLedgEntry.FindSet() then
            repeat
                if not DtldVendLedgEntry.Unapplied then begin
                    VendLedgEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.");
                    if (VendLedgEntry."Document Type" = GenJnlLine."Document Type") and
                       (VendLedgEntry."Document No." = GenJnlLine."Document No.")
                    then
                        AppliedAmount += DtldVendLedgEntry."Amount (LCY)";
                end;
            until DtldVendLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure TransferVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; var CVLedgEntry: Record "CV Ledger Entry Buffer")
    begin
        CVLedgEntry."Posting Date" := VendLedgEntry."Posting Date";
        CVLedgEntry."Entry No." := VendLedgEntry."Entry No.";
        CVLedgEntry."CV No." := VendLedgEntry."Vendor No.";
        CVLedgEntry."Document Type" := VendLedgEntry."Document Type";
        CVLedgEntry."Document No." := VendLedgEntry."Document No.";
        CVLedgEntry.Description := VendLedgEntry.Description;
    end;

    [Scope('OnPrem')]
    procedure TransferCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var CVLedgEntry: Record "CV Ledger Entry Buffer")
    begin
        CVLedgEntry."Posting Date" := CustLedgEntry."Posting Date";
        CVLedgEntry."Entry No." := CustLedgEntry."Entry No.";
        CVLedgEntry."CV No." := CustLedgEntry."Customer No.";
        CVLedgEntry."Document Type" := CustLedgEntry."Document Type";
        CVLedgEntry."Document No." := CustLedgEntry."Document No.";
        CVLedgEntry.Description := CustLedgEntry.Description;
    end;

    [Scope('OnPrem')]
    procedure InsertLine(var GenJnlLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; CVLedgEntry: Record "CV Ledger Entry Buffer"; CVType: Enum "Gen. Journal Account Type"; VATSettlementPart: Option; PostingDate: Date; VATAmount: Decimal; BaseAmount: Decimal; NextTransactionNo: Integer)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine1: Record "Gen. Journal Line";
        Currency: Record Currency;
        VATDifference: Decimal;
        Prefix: Text[50];
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJnlBatch.TestField("No. Series", '');

        GenJnlLine1.Copy(GenJnlLine);
        GenJnlLine1.Reset();
        GenJnlLine1.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine1.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if GenJnlLine1.FindLast() then
            GenJnlLine1."Line No." := GenJnlLine1."Line No." + 10000
        else
            GenJnlLine1."Line No." := 10000;

        GenJnlLine1.Init();
        GenJnlLine1.SetUpNewLine(GenJnlLine, 0, true);
        GenJnlLine1."VAT Settlement Part" := VATSettlementPart;
        GenJnlLine1."Document Date" := CVLedgEntry."Posting Date";
        GenJnlLine1."Unrealized VAT Entry No." := VATEntry."Entry No.";
        GenJnlLine1."External Document No." := VATEntry."External Document No.";
        GenJnlLine1."Object Type" := VATEntry."Object Type".AsInteger();
        GenJnlLine1."Object No." := VATEntry."Object No.";
        GenJnlLine1.Correction := GenJnlLine.Correction;
        GenJnlLine1."Posting Date" := PostingDate;
        GenJnlLine1.Validate("Posting Date", PostingDate);
        GenJnlLine1."Account Type" := CVType;
        GenJnlLine1.Validate("Account No.", CVLedgEntry."CV No.");
        GenJnlLine1."VAT Transaction No." := NextTransactionNo;
        GenJnlLine1."Document Type" := CVLedgEntry."Document Type";
        GenJnlLine1."Document No." := CVLedgEntry."Document No.";
        Prefix := Text14701;
        GenJnlLine1."Paid Amount" := GenJnlLine."Paid Amount";
        GenJnlLine1."Currency Code" := '';
        GenJnlLine1.Validate(Amount, BaseAmount + VATAmount);
        GenJnlLine1.Description := CopyStr(Prefix + CVLedgEntry.Description, 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine1.Validate("VAT %", GetVATPercent(GenJnlLine1."Unrealized VAT Entry No."));
        GenJnlLine1."Additional VAT Ledger Sheet" := GenJnlLine."Additional VAT Ledger Sheet";
        GenJnlLine1."Corrected Document Date" := GenJnlLine."Corrected Document Date";
        GenJnlLine1."Prepmt. Diff." := VATEntry."Prepmt. Diff.";

        Currency.InitRoundingPrecision();

        VATDifference :=
          VATAmount -
          Round(
            GenJnlLine1.Amount * GenJnlLine1."VAT %" / (100 + GenJnlLine1."VAT %"),
            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());

        VATAmount := VATAmount - VATDifference;

        if VATAmount <> 0 then
            GenJnlLine1.Validate("VAT Amount", VATAmount);
        GenJnlLine1."Payment Date" := GenJnlLine."Posting Date";
        GenJnlLine1.UpdateLineBalance();
        CopyDimensions(GenJnlLine1, CVType.AsInteger(), NextTransactionNo);
        GenJnlLine1.Insert();

        GenJnlLine := GenJnlLine1;
    end;

    [Scope('OnPrem')]
    procedure CheckDuplicate(GenJnlLine: Record "Gen. Journal Line")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Reset();
        case GenJnlLine."VAT Settlement Part" of
            GenJnlLine."VAT Settlement Part"::" ":
                begin
                    VATEntry.SetCurrentKey("Transaction No.");
                    VATEntry.SetRange("Transaction No.", GenJnlLine."VAT Transaction No.");
                    if VATEntry.FindSet() then
                        repeat
                            if (not VATEntry.Reversed) and (VATEntry."Unrealized VAT Entry No." = GenJnlLine."Unrealized VAT Entry No.") and
                               (VATEntry."Object No." = GenJnlLine."Object No.")
                            then
                                Error(Text14705, GenJnlLine.FieldCaption("Object No."), GenJnlLine."Object No.",
                                  VATEntry.FieldCaption("Entry No."), VATEntry."Entry No.");
                        until VATEntry.Next() = 0;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure IsLastOperation(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        if GenJnlLine.Correction then
            exit(false);

        if GenJnlLine."VAT Settlement Part" = GenJnlLine."VAT Settlement Part"::" " then
            exit(IsLastApplication(GenJnlLine));
        exit(IsLastSettlement(GenJnlLine));
    end;

    [Scope('OnPrem')]
    procedure IsLastApplication(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        VATEntry: Record "VAT Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntryNo: Integer;
        FoundRealVAT: Boolean;
    begin
        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Transaction No.", GenJnlLine."VAT Transaction No.");
        DtldVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        if DtldVendLedgEntry.FindSet() then
            repeat
                if not DtldVendLedgEntry.Unapplied then begin
                    VendLedgEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.");
                    if VendLedgEntry."Document No." = GenJnlLine."Document No." then
                        VendLedgEntryNo := DtldVendLedgEntry."Vendor Ledger Entry No."
                end;
            until DtldVendLedgEntry.Next() = 0;

        VendLedgEntry.Get(VendLedgEntryNo);
        if VendLedgEntry.Open then
            exit(false);

        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        if DtldVendLedgEntry.FindSet() then
            repeat
                if not DtldVendLedgEntry.Unapplied then
                    if DtldVendLedgEntry."Transaction No." <> GenJnlLine."VAT Transaction No." then begin
                        FoundRealVAT := false;
                        VATEntry.SetCurrentKey("Transaction No.");
                        VATEntry.SetRange("Transaction No.", DtldVendLedgEntry."Transaction No.");
                        if VATEntry.FindSet() then
                            repeat
                                FoundRealVAT := FoundRealVAT or ((VATEntry."Object Type".AsInteger() = GenJnlLine."Object Type") and
                                                                 (VATEntry."Object No." = GenJnlLine."Object No.") and
                                                                 (not VATEntry.Reversed) and
                                                                 (VATEntry."Unrealized VAT Entry No." <> 0));
                            until VATEntry.Next() = 0;
                        if not FoundRealVAT then
                            exit(false);
                    end;
            until DtldVendLedgEntry.Next() = 0;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure IsLastSettlement(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        exit(GetPeriodCount(GenJnlLine."VAT Settlement Part") -
          GetLastPosted(GenJnlLine."Unrealized VAT Entry No.", GenJnlLine."VAT Settlement Part") = 1);
    end;

    [Scope('OnPrem')]
    procedure GetLastPosted(UnrealVATEntryNo: Integer; VATSettlementPart: Option " ",Full,"1/6","1/12","28FL") EntryCount: Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        EntryCount := 0;
        VATEntry.SetCurrentKey("Unrealized VAT Entry No.");
        VATEntry.SetRange("Unrealized VAT Entry No.", UnrealVATEntryNo);
        if VATEntry.FindSet() then
            repeat
                if (not VATEntry.Correction) and
                   (not VATEntry.Reversed) and (VATEntry."VAT Settlement Part" <> VATEntry."VAT Settlement Part"::" ")
                then
                    if VATEntry."VAT Settlement Part" = VATSettlementPart then
                        EntryCount := EntryCount + 1
                    else
                        Error(Text14711, VATEntry.FieldCaption("VAT Settlement Part"), VATEntry."VAT Settlement Part",
                          VATEntry.FieldCaption("Unrealized VAT Entry No."), VATEntry."Unrealized VAT Entry No.");
            until VATEntry.Next() = 0;
    end;

    local procedure GetPeriodCount(VATSettlementPart: Option " ",Full,"1/6","1/12","28FL") PeriodCount: Integer
    begin
        if VATSettlementPart = VATSettlementPart::" " then
            PeriodCount := 0;
    end;

    [Scope('OnPrem')]
    procedure CheckDate(GenJnlLine: Record "Gen. Journal Line")
    var
        VATEntry: Record "VAT Entry";
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        GLSetup: Record "General Ledger Setup";
    begin
        case GenJnlLine."VAT Settlement Part" of
            GenJnlLine."VAT Settlement Part"::Custom,
          GenJnlLine."VAT Settlement Part"::" ":
                if GenJnlLine."Object Type" = GenJnlLine."Object Type"::"Fixed Asset" then begin
                    if GenJnlLine."Posting Date" < GenJnlLine."Payment Date" then
                        Error(Text12405, GenJnlLine.FieldCaption("Document No."), GenJnlLine."Document No.",
                          GenJnlLine.FieldCaption("Posting Date"), GenJnlLine."Posting Date",
                          GenJnlLine.FieldCaption("Payment Date"), GenJnlLine."Payment Date");
                    if VATEntry.Get(GenJnlLine."Unrealized VAT Entry No.") then
                        if FA.Get(GenJnlLine."Object No.") then
                            if VATEntry."VAT Settlement Type" = VATEntry."VAT Settlement Type"::"Future Expenses" then begin
                                if GenJnlLine."FA Error Entry No." <> 0 then begin
                                    FALedgEntry.Get(GenJnlLine."FA Error Entry No.");
                                    if GenJnlLine."Posting Date" < FALedgEntry."Posting Date" then
                                        Error(Text14707, GenJnlLine.FieldCaption("Document No."), GenJnlLine."Document No.",
                                          GenJnlLine.FieldCaption("Posting Date"), FALedgEntry."Posting Date");
                                end;
                            end else begin
                                if AppliedToCrMemo(GenJnlLine) then
                                    exit;
                                GLSetup.Get();
                                if (FA."Initial Release Date" = 0D) and (not GLSetup."Allow VAT Set. before FA Rel.") then
                                    Error(Text12403, FA."No.");
                                if FA."Initial Release Date" > GenJnlLine."Posting Date" then
                                    Error(Text12404, GenJnlLine.FieldCaption("Posting Date"), GenJnlLine."Posting Date",
                                      FA.FieldCaption("Initial Release Date"), FA."Initial Release Date", FA."No.");
                            end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcUnrealVATPart(GenJnlLine: Record "Gen. Journal Line"): Decimal
    var
        VATEntry: Record "VAT Entry";
        FullAmount: Decimal;
        InitialAmount: Decimal;
        NewAmount: Decimal;
        PositiveNewAmount: Boolean;
        PositiveAmount: Boolean;
    begin
        FullAmount := GetRemUnrealVAT(GenJnlLine."Unrealized VAT Entry No.", 0D);
        if (not GenJnlLine.Correction) and (FullAmount = 0) then
            exit(0);

        VATEntry.Get(GenJnlLine."Unrealized VAT Entry No.");
        InitialAmount := VATEntry."Unrealized Base" + VATEntry."Unrealized Amount";
        PositiveAmount := InitialAmount > 0;
        NewAmount := FullAmount - GenJnlLine.Amount;
        PositiveNewAmount := (NewAmount > 0) or (NewAmount = 0) and PositiveAmount;
        if Abs(NewAmount) > Abs(InitialAmount) then
            Error(Text14707, GenJnlLine.FieldCaption("Document No."), GenJnlLine."Document No.",
              GenJnlLine.FieldCaption(Amount), FullAmount - InitialAmount);
        if PositiveAmount <> PositiveNewAmount then
            Error(Text14706, GenJnlLine.FieldCaption(Amount), GenJnlLine.Amount, FullAmount);

        if not GenJnlLine.Correction then
            if GenJnlLine.Amount / FullAmount < 0 then
                if GenJnlLine.Amount < 0 then
                    GenJnlLine.FieldError(Amount, Text14713)
                else
                    GenJnlLine.FieldError(Amount, Text14714);
        exit(GenJnlLine.Amount / FullAmount);
    end;

    [Scope('OnPrem')]
    procedure PartiallyRealized(UnrealVATEntryNo: Integer; VATSettlementPart: Option " ",Full,"1/6","1/12","28FL"): Boolean
    begin
        if VATSettlementPart <> VATSettlementPart::" " then
            exit(false);

        exit(GetPart(UnrealVATEntryNo) <> 0);
    end;

    [Scope('OnPrem')]
    procedure GetRemUnrealVAT(EntryNo: Integer; AtDate: Date) FullAmount: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        FullAmount := 0;
        if VATEntry.Get(EntryNo) then
            FullAmount := VATEntry."Remaining Unrealized Amount" + VATEntry."Remaining Unrealized Base";
        if AtDate <> 0D then begin
            VATEntry.SetCurrentKey("Unrealized VAT Entry No.");
            VATEntry.SetRange("Unrealized VAT Entry No.", EntryNo);
            if VATEntry.Find('+') then
                repeat
                    if not VATEntry.Reversed and (VATEntry."Posting Date" >= AtDate) then
                        FullAmount := FullAmount + (VATEntry.Amount + VATEntry.Base);
                until VATEntry.Next(-1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcPaidAmount(FromDate: Date; ToDate: Date; UnrealVATEntryNo: Integer; AddRealVAT: Option ,Add,Deduct,RealVATOnly,Correction) PaidAmount: Decimal
    var
        VATEntry: Record "VAT Entry";
        OriginalAmount: Decimal;
    begin
        if AddRealVAT < AddRealVAT::RealVATOnly then begin
            VATEntry.Get(UnrealVATEntryNo);
            case VATEntry.Type of
                VATEntry.Type::Sale:
                    PaidAmount := GetCustPaidAmount(VATEntry, FromDate, ToDate, OriginalAmount);
                VATEntry.Type::Purchase:
                    PaidAmount := GetVendPaidAmount(VATEntry, FromDate, ToDate, OriginalAmount);
            end;
            PaidAmount := Round(PaidAmount * (VATEntry."Unrealized Amount" + VATEntry."Unrealized Base") / OriginalAmount);
        end;

        if AddRealVAT = 0 then
            exit;

        VATEntry.SetCurrentKey("Unrealized VAT Entry No.");
        VATEntry.SetRange("Unrealized VAT Entry No.", UnrealVATEntryNo);
        VATEntry.SetRange("Posting Date", FromDate, ToDate);
        if VATEntry.FindSet() then
            repeat
                if not VATEntry.Reversed then
                    case AddRealVAT of
                        AddRealVAT::Add,
                      AddRealVAT::RealVATOnly:
                            PaidAmount -= VATEntry.Base + VATEntry.Amount;
                        AddRealVAT::Correction:
                            if VATEntry.Correction or
                               VATEntry."Additional VAT Ledger Sheet"
                            then
                                PaidAmount -= VATEntry.Base + VATEntry.Amount;
                        AddRealVAT::Deduct:
                            PaidAmount += VATEntry.Base + VATEntry.Amount;
                    end;
            until VATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetCustPaidAmount(VATEntry: Record "VAT Entry"; FromDate: Date; ToDate: Date; var OriginalAmount: Decimal) PaidAmount: Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LedgerEntryNo: Integer;
    begin
        LedgerEntryNo := 0;
        CustLedgEntry.SetCurrentKey("Transaction No.");
        CustLedgEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        if CustLedgEntry.FindSet() then
            repeat
                if CustLedgEntry."Document Type" = VATEntry."Document Type" then begin
                    LedgerEntryNo := CustLedgEntry."Entry No.";
                    CustLedgEntry.CalcFields("Original Amt. (LCY)");
                    OriginalAmount := CustLedgEntry."Original Amt. (LCY)";
                end;
            until (CustLedgEntry.Next() = 0) or (LedgerEntryNo <> 0);
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", LedgerEntryNo);
        if ToDate <> 0D then
            DtldCustLedgEntry.SetRange("Posting Date", FromDate, ToDate);
        DtldCustLedgEntry.SetFilter("Entry Type", '%1|%2|%3', DtldCustLedgEntry."Entry Type"::Application,
          DtldCustLedgEntry."Entry Type"::"Realized Loss",
          DtldCustLedgEntry."Entry Type"::"Realized Gain");
        if DtldCustLedgEntry.FindSet() then
            repeat
                if not DtldCustLedgEntry.Unapplied then
                    PaidAmount += DtldCustLedgEntry."Amount (LCY)";
            until DtldCustLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetVendPaidAmount(VATEntry: Record "VAT Entry"; FromDate: Date; ToDate: Date; var OriginalAmount: Decimal) PaidAmount: Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LedgerEntryNo: Integer;
    begin
        LedgerEntryNo := 0;
        VendLedgEntry.SetCurrentKey("Transaction No.");
        VendLedgEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        if VendLedgEntry.FindSet() then
            repeat
                if VendLedgEntry."Document Type" = VATEntry."Document Type" then begin
                    LedgerEntryNo := VendLedgEntry."Entry No.";
                    VendLedgEntry.CalcFields("Original Amt. (LCY)");
                    OriginalAmount := VendLedgEntry."Original Amt. (LCY)";
                end;
            until (VendLedgEntry.Next() = 0) or (LedgerEntryNo <> 0);
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", LedgerEntryNo);
        if ToDate <> 0D then
            DtldVendLedgEntry.SetRange("Posting Date", FromDate, ToDate);
        DtldVendLedgEntry.SetFilter("Entry Type", '%1|%2|%3', DtldVendLedgEntry."Entry Type"::Application,
          DtldVendLedgEntry."Entry Type"::"Realized Loss",
          DtldVendLedgEntry."Entry Type"::"Realized Gain");
        if DtldVendLedgEntry.FindSet() then
            repeat
                if not DtldVendLedgEntry.Unapplied then
                    PaidAmount += DtldVendLedgEntry."Amount (LCY)";
            until DtldVendLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure VATIsPostponed(VATEntry: Record "VAT Entry"; VATSettlementPart: Option " ",Full,"1/6","1/12","28FL"; PostingDate: Date): Boolean
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATSettlementPart <> 0 then
            exit(false);
        if VATBusPostingGroup.Get(VATEntry."VAT Bus. Posting Group") then
            if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then
                exit(VATPostingSetup."Manual VAT Settlement");
    end;

    [Scope('OnPrem')]
    procedure GetPart(UnrealVATEntryNo: Integer): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Unrealized VAT Entry No.");
        VATEntry.SetRange("Unrealized VAT Entry No.", UnrealVATEntryNo);
        if VATEntry.Find('+') then
            repeat
                if (not VATEntry.Reversed) and (VATEntry."VAT Settlement Part" > VATEntry."VAT Settlement Part"::" ") then
                    exit(VATEntry."VAT Settlement Part");
            until VATEntry.Next(-1) = 0;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetVATPercent(UnrealVATEntryNo: Integer): Decimal
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATEntry.Get(UnrealVATEntryNo) then
            if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then
                exit(VATPostingSetup."VAT %");
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure Recalculate(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    var
        PaidAmount: Decimal;
        Date1: Date;
        Amount: Decimal;
        I: Integer;
        PostedCorrection: Decimal;
    begin
        Date1 := CalcDate('<-CY-1D>', RecalculationDate);
        PaidAmount := CalcPaidAmount(0D, Date1, GenJnlLine."Unrealized VAT Entry No.", 2);
        repeat
            I := I + 1;
            Date1 := CalcDate('<+1M+CM>', Date1);
            PaidAmount := PaidAmount + CalcPaidAmount(CalcDate('<-CM>', Date1), Date1, GenJnlLine."Unrealized VAT Entry No.", 0);
            Amount := Amount + Round((PaidAmount - Amount) / (13 - I));
        until Date1 = CalcDate('<-1D+CM>', RecalculationDate);
        PostedCorrection := CalcPaidAmount(RecalculationDate, CalcDate('<CM>', RecalculationDate), GenJnlLine."Unrealized VAT Entry No.", 4);
        GenJnlLine.Correction := true;
        GenJnlLine.Amount :=
          CalcPaidAmount(CalcDate('<-CY>', Date1), Date1, GenJnlLine."Unrealized VAT Entry No.", 3) - Amount + PostedCorrection;
        VATEntry."Remaining Unrealized Amount" :=
          Round(GenJnlLine.Amount * VATEntry."Unrealized Amount" / (VATEntry."Unrealized Amount" + VATEntry."Unrealized Base"));
        VATEntry."Remaining Unrealized Base" := GenJnlLine.Amount - VATEntry."Remaining Unrealized Amount";
    end;

    [Scope('OnPrem')]
    procedure AppliedToCrMemo(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo" then
            exit(true);

        DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Transaction No.", GenJnlLine."VAT Transaction No.");
        DtldVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        if DtldVendLedgEntry.Find('-') then
            repeat
                if DtldVendLedgEntry."Document Type" = DtldVendLedgEntry."Document Type"::"Credit Memo" then
                    exit(true);
            until DtldVendLedgEntry.Next() = 0;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CheckForUnapplyByEntryNo(EntryNo: Integer; ContragentType: Option Customer,Vendor)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TransactionNo: Integer;
    begin
        case ContragentType of
            ContragentType::Customer:
                begin
                    CustLedgerEntry.Get(EntryNo);
                    TransactionNo := CustLedgerEntry."Transaction No.";
                end;
            ContragentType::Vendor:
                begin
                    VendorLedgerEntry.Get(EntryNo);
                    TransactionNo := VendorLedgerEntry."Transaction No.";
                end;
        end;
        CheckForUnapplyByTransNo(TransactionNo);
    end;

    [Scope('OnPrem')]
    procedure CheckForUnapplyByTransNo(TransactionNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Transaction No.", TransactionNo);
        if VATEntry.Find('-') then
            repeat
                VATEntry2.SetCurrentKey("Unrealized VAT Entry No.");
                VATEntry2.SetRange("Unrealized VAT Entry No.", VATEntry."Entry No.");
                if VATEntry2.Find('-') then
                    repeat
                        if not VATEntry2.Reversed then
                            if (VATEntry2."VAT Settlement Part" = VATEntry2."VAT Settlement Part"::Custom) and
                               not VATEntry2."Manual VAT Settlement"
                            then
                                Error(Text14715);
                    until VATEntry2.Next() = 0;
            until VATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CopyDimensions(var GenJournalLine: Record "Gen. Journal Line"; CVType: Option " ",Customer,Vendor; TransactionNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        case CVType of
            CVType::Customer:
                begin
                    CustLedgerEntry.SetCurrentKey("Transaction No.");
                    CustLedgerEntry.SetRange("Transaction No.", TransactionNo);
                    if CustLedgerEntry.FindFirst() then begin
                        GenJournalLine."Shortcut Dimension 1 Code" := CustLedgerEntry."Global Dimension 1 Code";
                        GenJournalLine."Shortcut Dimension 2 Code" := CustLedgerEntry."Global Dimension 2 Code";
                        GenJournalLine."Dimension Set ID" := CustLedgerEntry."Dimension Set ID";
                    end;
                end;
            CVType::Vendor:
                begin
                    VendLedgerEntry.SetCurrentKey("Transaction No.");
                    VendLedgerEntry.SetRange("Transaction No.", TransactionNo);
                    if VendLedgerEntry.FindFirst() then begin
                        GenJournalLine."Shortcut Dimension 1 Code" := VendLedgerEntry."Global Dimension 1 Code";
                        GenJournalLine."Shortcut Dimension 2 Code" := VendLedgerEntry."Global Dimension 2 Code";
                        GenJournalLine."Dimension Set ID" := VendLedgerEntry."Dimension Set ID";
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckForPDUnapply(CVLedgEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey(Type, "CV Ledg. Entry No.");
        VATEntry.SetRange("CV Ledg. Entry No.", CVLedgEntryNo);
        if VATEntry.FindSet() then
            repeat
                VATEntry2.SetCurrentKey("Unrealized VAT Entry No.");
                VATEntry2.SetRange("Unrealized VAT Entry No.", VATEntry."Entry No.");
                if VATEntry2.FindSet() then
                    repeat
                        if not VATEntry2.Reversed then
                            if VATEntry2."Prepmt. Diff." and (VATEntry2."VAT Settlement Part" > VATEntry2."VAT Settlement Part"::" ")
                            then
                                Error(Text14715);
                    until VATEntry2.Next() = 0;
            until VATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckFPE(var GenJnlLine: Record "Gen. Journal Line")
    var
        VATEntry: Record "VAT Entry";
        FALedgEntry: Record "FA Ledger Entry";
        VATAllocLine: Record "VAT Allocation Line";
        Mode: Option Any,Depreciation,General;
        RemVATAmount: Decimal;
        RemVATBase: Decimal;
    begin
        VATEntry.Get(GenJnlLine."Unrealized VAT Entry No.");
        VATAllocLine.SetRange("VAT Entry No.", GenJnlLine."Unrealized VAT Entry No.");
        VATAllocLine.FindFirst();
        GetFPEMode(GenJnlLine."Unrealized VAT Entry No.", Mode);
        if (Mode = Mode::Depreciation) or
           (Mode = Mode::Any) and (GenJnlLine."FA Error Entry No." <> 0)
        then begin
            GenJnlLine.TestField("FA Error Entry No.");
            FALedgEntry.Get(GenJnlLine."FA Error Entry No.");
            RemVATBase := FALedgEntry.GetAmountToRealize(GenJnlLine."Unrealized VAT Entry No.");
            if Mode = Mode::Depreciation then
                VATAllocLine.TestField(Base, VATAllocLine.Base::Depreciation);
            if VATAllocLine.Base = VATAllocLine.Base::Depreciation then begin
                if Abs(RemVATBase) < Abs(VATAllocLine."VAT Base Amount") then
                    VATAllocLine.FieldError("VAT Base Amount");
                RemVATAmount := VATEntry.GetAmountOnBase(RemVATBase);
                if Abs(GenJnlLine.Amount) > Abs(RemVATAmount) then
                    Error(Text14704, Format(FALedgEntry."Posting Date", 0, '<Month Text> <Year4>'),
                      FALedgEntry.TableCaption(), GenJnlLine."FA Error Entry No.",
                      VATEntry.FieldCaption("Remaining Unrealized Amount"), -RemVATAmount);
            end else
                GenJnlLine."FA Error Entry No." := 0
        end else begin
            if VATAllocLine.Base = VATAllocLine.Base::Depreciation then
                VATAllocLine.FieldError(Base);
            GenJnlLine."FA Error Entry No." := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateRealEntries(UnrealVAtEntryNo: Integer; CVEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Unrealized VAT Entry No.");
        VATEntry.SetRange("Unrealized VAT Entry No.", UnrealVAtEntryNo);
        VATEntry.ModifyAll("CV Ledg. Entry No.", CVEntryNo);
    end;

    [Scope('OnPrem')]
    procedure FillCVEntryNo(TransactionNo: Integer; CVEntryNo: Integer)
    var
        UnrealVATEntry: Record "VAT Entry";
    begin
        UnrealVATEntry.SetCurrentKey("Transaction No.");
        UnrealVATEntry.SetRange("Transaction No.", TransactionNo);
        if UnrealVATEntry.FindSet(true) then
            repeat
                if UnrealVATEntry."Unrealized Base" <> 0 then begin // Unreal. Amount may be 0 even for unrealized VAT entry
                    UnrealVATEntry."CV Ledg. Entry No." := CVEntryNo;
                    UnrealVATEntry.Modify();
                    UpdateRealEntries(UnrealVATEntry."Entry No.", CVEntryNo);
                end;
            until UnrealVATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Generate(var TempVATDocBuf: Record "VAT Document Entry Buffer" temporary; Type: Option ,Purchase,Sale,"Fixed Asset","Future Expense")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        Cust: Record Customer;
        Vend: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        Window: Dialog;
        VATCount: Integer;
        I: Integer;
        CVEntryNo: Integer;
        DimSetID: Integer;
        PostingDate: Date;
        CVEntryType: Option " ",Purchase,Sale;
    begin
        VATDocEntryBuffer.CopyFilters(TempVATDocBuf);
        TempVATDocBuf.DeleteAll();
        Window.Open('@1@@@@@@@@@@@@@@@');

        VATEntry.Reset();
        case Type of
            Type::Purchase:
                VATEntry.SetRange(Type, Type::Purchase);
            Type::Sale:
                VATEntry.SetRange(Type, Type::Sale);
            Type::"Fixed Asset":
                VATEntry.SetRange("VAT Settlement Type", VATEntry."VAT Settlement Type"::"by Act");
            Type::"Future Expense":
                VATEntry.SetRange("VAT Settlement Type", VATEntry."VAT Settlement Type"::"Future Expenses");
        end;
        if Type in [Type::"Fixed Asset", Type::"Future Expense"] then
            VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset")
        else
            VATEntry.SetFilter("Object Type", '<>%1', VATEntry."Object Type"::"Fixed Asset");
        VATEntry.SetRange(Reversed, false);
        VATEntry.SetRange("Unrealized VAT Entry No.", 0);
        VATEntry.SetFilter("Posting Date", TempVATDocBuf.GetFilter("Date Filter"));
        VATEntry.SetFilter("VAT Bus. Posting Group", TempVATDocBuf.GetFilter("VAT Bus. Posting Group Filter"));
        VATEntry.SetFilter("VAT Prod. Posting Group", TempVATDocBuf.GetFilter("VAT Prod. Posting Group Filter"));
        VATEntry.SetRange(Base, 0);
        VATEntry.SetFilter("Remaining Unrealized Amount", '<>%1', 0);
        VATEntry.SetRange("Manual VAT Settlement", true);
        I := 0;
        VATCount := VATEntry.Count();
        if VATEntry.FindSet() then
            repeat
                I += 1;
                Window.Update(1, Round(I / VATCount * 10000, 1));
                PostingDate := TempVATDocBuf.GetRangeMax("Date Filter");
                if CheckFixedAsset(VATEntry, PostingDate, Type) then
                    if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then
                        // IF VATPostingSetup."Manual VAT Settlement" THEN
                        if VATEntry.FindCVEntry(CVEntryType, CVEntryNo) then begin
                            case CVEntryType of
                                CVEntryType::Purchase:
                                    begin
                                        VendLedgEntry.Get(CVEntryNo);
                                        VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                                        TempVATDocBuf.TransferFields(VendLedgEntry);
                                        TempVATDocBuf."Amount (LCY)" := VendLedgEntry."Amount (LCY)";
                                        TempVATDocBuf."Remaining Amt. (LCY)" := VendLedgEntry."Remaining Amt. (LCY)";
                                        TempVATDocBuf."Table ID" := DATABASE::"Vendor Ledger Entry";
                                        Vend.Get(VendLedgEntry."Vendor No.");
                                        TempVATDocBuf."CV Name" := Vend.Name;
                                        DimSetID := VendLedgEntry."Dimension Set ID";
                                    end;
                                CVEntryType::Sale:
                                    begin
                                        CustLedgEntry.Get(CVEntryNo);
                                        CustLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                                        TempVATDocBuf.TransferFields(CustLedgEntry);
                                        TempVATDocBuf."Amount (LCY)" := CustLedgEntry."Amount (LCY)";
                                        TempVATDocBuf."Remaining Amt. (LCY)" := CustLedgEntry."Remaining Amt. (LCY)";
                                        TempVATDocBuf."Table ID" := DATABASE::"Cust. Ledger Entry";
                                        Cust.Get(CustLedgEntry."Customer No.");
                                        TempVATDocBuf."CV Name" := Cust.Name;
                                        DimSetID := CustLedgEntry."Dimension Set ID";
                                    end;
                            end;
                            TempVATDocBuf."Entry Type" := "General Posting Type".FromInteger(CVEntryType);
                            TempVATDocBuf."Document Date" := TempVATDocBuf."Posting Date";
                            if PostingDate > TempVATDocBuf."Posting Date" then
                                TempVATDocBuf."Posting Date" := PostingDate;
                            CreateAllocation(VATEntry."Entry No.");
                            RecalculateAllocation(VATEntry."Entry No.", TempVATDocBuf."Posting Date");
                            MergeEntryDimSetIDWithVATAllocationDim(VATEntry."Entry No.", DimSetID);
                            TempVATDocBuf.CalcFields("VAT Amount To Allocate");
                            TempVATDocBuf."Allocated VAT Amount" := TempVATDocBuf."VAT Amount To Allocate";
                            if TempVATDocBuf.Insert() then
                                FillCVEntryNo(TempVATDocBuf."Transaction No.", TempVATDocBuf."Entry No.");
                        end;
            until VATEntry.Next() = 0;
        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure CheckFixedAsset(var VATEntry: Record "VAT Entry"; var PostingDate: Date; Type: Option " ",Purchase,Sale,"Fixed Asset","Future Expense"): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
        Mode: Option Any,Depreciation,General;
        DeprEntryNo: Integer;
    begin
        if Type in [Type::Purchase, Type::Sale] then
            exit(true);

        if FA.Get(VATEntry."Object No.") then begin
            if FA.Blocked or FA.Inactive then
                exit(false);
        end else
            exit(false);

        case Type of
            Type::"Fixed Asset":
                if (FA.Status >= FA.Status::Operation) and (FA."Initial Release Date" <> 0D) then begin
                    if FA."Initial Release Date" <= PostingDate then begin
                        PostingDate := FA."Initial Release Date";
                        exit(true);
                    end;
                end else begin
                    GLSetup.Get();
                    exit(GLSetup."Allow VAT Set. before FA Rel.");
                end;
            Type::"Future Expense":
                begin
                    FA.SetFilter("Date Filter", VATEntry.GetFilter("Posting Date"));
                    DeprEntryNo :=
                      FAInsertLedgEntry.GetDeprEntryForVATSettlement(FA, PostingDate, VATEntry."Entry No.");
                    GetFPEMode(VATEntry."Entry No.", Mode);
                    if Mode <> Mode::Depreciation then
                        exit(true);
                    if DeprEntryNo = 0 then
                        exit(false);
                    if FALedgEntry.Get(DeprEntryNo) then
                        exit(FALedgEntry.GetAmountToRealize(VATEntry."Entry No.") <> 0);
                end;
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UpdateDocVATAlloc(var VATAmtToAlloc: Decimal; CVLedgEntryNo: Integer; var PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
        VATAmountRnded: Decimal;
        TotalVATAmount: Decimal;
        Factor: Decimal;
        AmtToAllocate: Decimal;
    begin
        VATEntry.SetCurrentKey(Type, "CV Ledg. Entry No.");
        VATEntry.SetRange("CV Ledg. Entry No.", CVLedgEntryNo);
        VATEntry.CalcSums("Remaining Unrealized Amount");
        case true of
            VATEntry."Remaining Unrealized Amount" > 0:
                if VATAmtToAlloc < 0 then
                    Error(Text14713);
            VATEntry."Remaining Unrealized Amount" < 0:
                if VATAmtToAlloc > 0 then
                    Error(Text14714);
            VATEntry."Remaining Unrealized Amount" = 0:
                exit;
        end;
        if Abs(VATAmtToAlloc) > Abs(VATEntry."Remaining Unrealized Amount") then
            VATAmtToAlloc := VATEntry."Remaining Unrealized Amount";
        Factor := VATAmtToAlloc / VATEntry."Remaining Unrealized Amount";
        if VATEntry.FindSet() then
            repeat
                if VATEntry."Remaining Unrealized Amount" <> 0 then begin
                    CreateAllocation(VATEntry."Entry No.");
                    TotalVATAmount := TotalVATAmount + VATEntry."Remaining Unrealized Amount" * Factor;
                    AmtToAllocate := Round(TotalVATAmount) - VATAmountRnded;
                    CalculateAllocation(VATEntry."Entry No.", -AmtToAllocate, PostingDate);
                    VATAmountRnded := VATAmountRnded + AmtToAllocate;
                end;
            until VATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateAllocation(VATEntryNo: Integer)
    var
        VATAllocLine: Record "VAT Allocation Line";
    begin
        VATAllocLine.SetRange("VAT Entry No.", VATEntryNo);
        if VATAllocLine.IsEmpty() then
            if not ApplyDefaultAllocation(VATEntryNo) then
                InsertInitEntry(VATEntryNo);
    end;

    [Scope('OnPrem')]
    procedure InsertInitEntry(VATEntryNo: Integer)
    var
        VATAllocLine: Record "VAT Allocation Line";
        VATEntry: Record "VAT Entry";
        Mode: Option Any,Depreciation,General;
    begin
        VATEntry.Get(VATEntryNo);
        VATAllocLine.SetFilter("Posting Date Filter", VATDocEntryBuffer.GetFilter("Date Filter"));
        VATAllocLine.Init();
        VATAllocLine."Line No." := 10000;
        VATAllocLine.Validate("VAT Entry No.", VATEntryNo);
        VATAllocLine."Allocation %" := 100;
        VATAllocLine.Base := VATAllocLine.Base::Remaining;
        if VATEntry."Object Type" = VATEntry."Object Type"::"Fixed Asset" then begin
            VATAllocLine."VAT Settlement Type" := VATEntry."VAT Settlement Type";
            if VATAllocLine."VAT Settlement Type" = VATAllocLine."VAT Settlement Type"::"Future Expenses" then begin
                GetFPEMode(VATEntryNo, Mode);
                if Mode <> Mode::General then
                    VATAllocLine.Base := VATAllocLine.Base::Depreciation;
            end;
        end;
        VATAllocLine.Validate(Base);
        VATAllocLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure ApplyDefaultAllocation(VATEntryNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
        DefaultVATAlloc: Record "Default VAT Allocation Line";
    begin
        VATEntry.Get(VATEntryNo);
        DefaultVATAlloc.SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
        DefaultVATAlloc.SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
        if DefaultVATAlloc.IsEmpty() then
            exit(false);

        InsertVATAlloc(DefaultVATAlloc, VATEntry);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure InsertVATAlloc(var DefaultVATAlloc: Record "Default VAT Allocation Line"; VATEntry: Record "VAT Entry")
    var
        VATAllocLine: Record "VAT Allocation Line";
        LineNo: Integer;
    begin
        VATAllocLine.SetFilter("Posting Date Filter", VATDocEntryBuffer.GetFilter("Date Filter"));
        LineNo := 0;
        DefaultVATAlloc.FindSet();
        repeat
            LineNo := LineNo + 10000;
            VATAllocLine.Init();
            VATAllocLine."Line No." := LineNo;
            VATAllocLine.Validate("VAT Entry No.", VATEntry."Entry No.");
            VATAllocLine."CV Ledger Entry No." := VATEntry."CV Ledg. Entry No.";
            VATAllocLine.Type := DefaultVATAlloc.Type;
            VATAllocLine."Account No." := DefaultVATAlloc."Account No.";
            if VATAllocLine."Account No." = '' then
                VATAllocLine.Validate(Type);
            if DefaultVATAlloc.Description <> '' then
                VATAllocLine.Description := DefaultVATAlloc.Description;
            VATAllocLine."Recurring Frequency" := DefaultVATAlloc."Recurring Frequency";
            VATAllocLine."Shortcut Dimension 1 Code" := DefaultVATAlloc."Shortcut Dimension 1 Code";
            VATAllocLine."Shortcut Dimension 2 Code" := DefaultVATAlloc."Shortcut Dimension 2 Code";
            VATAllocLine."Dimension Set ID" := DefaultVATAlloc."Dimension Set ID";
            VATAllocLine."Allocation %" := DefaultVATAlloc."Allocation %";
            VATAllocLine.Amount := DefaultVATAlloc.Amount;
            VATAllocLine.Validate(Base, DefaultVATAlloc.Base);
            if VATEntry."Object Type" = VATEntry."Object Type"::"Fixed Asset" then
                VATAllocLine."VAT Settlement Type" := VATEntry."VAT Settlement Type";
            VATAllocLine.Insert();
        until DefaultVATAlloc.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalculateAllocation(VATEntryNo: Integer; Amount: Decimal; var PostingDate: Date)
    var
        VATAllocLine: Record "VAT Allocation Line";
        TotalAmount: Decimal;
        Factor: Decimal;
        TotalAmountRnded: Decimal;
        MinDateFormula: DateFormula;
        NewAmount: Decimal;
    begin
        VATAllocLine.SetFilter("Posting Date Filter", VATDocEntryBuffer.GetFilter("Date Filter"));
        VATAllocLine.SetRange("VAT Entry No.", VATEntryNo);
        VATAllocLine.LockTable();
        VATAllocLine.CalcSums(Amount);
        if VATAllocLine.Amount = 0 then begin
            VATAllocLine.FindFirst();
            VATAllocLine.Validate(Base);
            VATAllocLine.Validate(Amount, -Amount);
            VATAllocLine.Modify();
        end;
        Factor := 0;
        if VATAllocLine.Amount <> 0 then
            Factor := -Amount / VATAllocLine.Amount;

        TotalAmount := 0;
        if VATAllocLine.FindSet(true) then
            repeat
                VATAllocLine."Allocation %" := 0;
                NewAmount := VATAllocLine.Amount * Factor;
                if Abs(NewAmount) > Abs(VATAllocLine."VAT Amount") then
                    NewAmount := VATAllocLine."VAT Amount";
                TotalAmount := TotalAmount + NewAmount;
                VATAllocLine.Amount := Round(TotalAmount) - TotalAmountRnded;
                TotalAmountRnded := TotalAmountRnded + VATAllocLine.Amount;
                VATAllocLine.Modify();
                VATAllocLine.CheckVATAllocation();
                SetDateFormula(MinDateFormula, VATAllocLine."Recurring Frequency");
            until VATAllocLine.Next() = 0;
        if Format(MinDateFormula) <> '' then
            GetLastRealVATEntryDate(PostingDate, VATEntryNo, MinDateFormula);
    end;

    [Scope('OnPrem')]
    procedure RecalculateAllocation(VATEntryNo: Integer; var PostingDate: Date)
    var
        VATAllocLine: Record "VAT Allocation Line";
        MinDateFormula: DateFormula;
        TotalAmount: Decimal;
        ControlTotal: Boolean;
        TotalAmountRnded: Decimal;
    begin
        VATAllocLine.SetFilter("Posting Date Filter", VATDocEntryBuffer.GetFilter("Date Filter"));
        VATAllocLine.SetRange("VAT Entry No.", VATEntryNo);
        if VATAllocLine.FindFirst() then begin
            VATAllocLine.SetFilter(Base, '<>%1', VATAllocLine.Base);
            ControlTotal := VATAllocLine.IsEmpty();
            VATAllocLine.SetRange(Base);
        end;
        if VATAllocLine.FindSet(true) then
            repeat
                VATAllocLine.SetTotalCheck(false);
                VATAllocLine.Validate(Base);
                if ControlTotal then begin
                    if VATAllocLine."Allocation %" <> 0 then
                        TotalAmount := TotalAmount + VATAllocLine."VAT Amount" * VATAllocLine."Allocation %" / 100
                    else begin
                        if Abs(VATAllocLine.Amount) > Abs(VATAllocLine."VAT Amount") then
                            VATAllocLine.Amount := VATAllocLine."VAT Amount";
                        TotalAmount := TotalAmount + VATAllocLine.Amount;
                    end;
                    VATAllocLine.Amount := Round(TotalAmount) - TotalAmountRnded;
                    TotalAmountRnded := TotalAmountRnded + VATAllocLine.Amount;
                end;
                VATAllocLine.Modify();
                SetDateFormula(MinDateFormula, VATAllocLine."Recurring Frequency");
            until VATAllocLine.Next() = 0;
        if Format(MinDateFormula) <> '' then
            GetLastRealVATEntryDate(PostingDate, VATEntryNo, MinDateFormula);
    end;

    [Scope('OnPrem')]
    procedure SetDateFormula(var MinDateFormula: DateFormula; DateFormula: DateFormula)
    var
        ClearDateFormula: DateFormula;
    begin
        Clear(ClearDateFormula);
        if DateFormula <> ClearDateFormula then
            if (MinDateFormula = ClearDateFormula) or
               (CalcDate(MinDateFormula, WorkDate()) > CalcDate(DateFormula, WorkDate()))
            then
                MinDateFormula := DateFormula;
    end;

    [Scope('OnPrem')]
    procedure GetLastRealVATEntryDate(var LastPostingDate: Date; UnrealVATEntryNo: Integer; DateFormula: DateFormula)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Unrealized VAT Entry No.");
        VATEntry.SetRange("Unrealized VAT Entry No.", UnrealVATEntryNo);
        VATEntry.SetRange(Reversed, false);
        if VATEntry.FindLast() then
            LastPostingDate := CalcDate(DateFormula, VATEntry."Posting Date");
    end;

    [Scope('OnPrem')]
    procedure CopyToJnl(var EntryToPost: Record "VAT Document Entry Buffer" temporary; var VATEntry: Record "VAT Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        FA: Record "Fixed Asset";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
        Mode: Option Any,Depreciation,General;
        NextLineNo: Integer;
        InsertLine: Boolean;
        IsCorrection: Boolean;
    begin
        VATDocEntryBuffer.CopyFilters(EntryToPost);
        EntryToPost.FindSet();
        repeat
            IsCorrection := false;
            if EntryToPost."Document Type" = EntryToPost."Document Type"::"Credit Memo" then
                case EntryToPost."Entry Type" of
                    EntryToPost."Entry Type"::Purchase:
                        if PurchCrMemoHeader.Get(EntryToPost."Document No.") then
                            IsCorrection := PurchCrMemoHeader.Correction;
                    EntryToPost."Entry Type"::Sale:
                        if SalesCrMemoHeader.Get(EntryToPost."Document No.") then
                            IsCorrection := SalesCrMemoHeader.Correction;
                end;
            VATEntry.SetCurrentKey(Type, "CV Ledg. Entry No.");
            VATEntry.SetRange("CV Ledg. Entry No.", EntryToPost."Entry No.");
            VATEntry.SetRange("Unrealized VAT Entry No.", 0);
            VATEntry.SetFilter("Remaining Unrealized Amount", '<>0');
            VATEntry.SetFilter("VAT Settlement Type", EntryToPost.GetFilter("Type Filter"));
            VATEntry.SetRange("Manual VAT Settlement", true);
            if VATEntry.FindSet() then
                repeat
                    VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                    VATPostingSetup.TestField("VAT Settlement Template");
                    VATPostingSetup.TestField("VAT Settlement Batch");
                    RecalculateAllocation(VATEntry."Entry No.", EntryToPost."Posting Date");

                    NextLineNo := 0;
                    GenJnlLine.SetRange("Journal Template Name", VATPostingSetup."VAT Settlement Template");
                    GenJnlLine.SetRange("Journal Batch Name", VATPostingSetup."VAT Settlement Batch");
                    if GenJnlLine.FindLast() then
                        NextLineNo := GenJnlLine."Line No.";
                    NextLineNo := NextLineNo + 10000;

                    GenJnlLine.Init();
                    GenJnlLine."Journal Template Name" := VATPostingSetup."VAT Settlement Template";
                    GenJnlLine."Journal Batch Name" := VATPostingSetup."VAT Settlement Batch";
                    GenJnlLine."Line No." := NextLineNo;
                    GenJnlLine.Validate("Unrealized VAT Entry No.", VATEntry."Entry No.");
                    UpdateGenJnlLineDimSetID(GenJnlLine, VATEntry."Entry No.");
                    InsertLine := GenJnlLine.Amount <> 0;
                    GenJnlLine."Posting Date" := EntryToPost."Posting Date";
                    GenJnlLine.Correction := IsCorrection;
                    GenJnlLine."External Document No." := VATEntry."External Document No.";
                    if VATEntry."VAT Settlement Type" = VATEntry."VAT Settlement Type"::"Future Expenses" then begin
                        FA.Get(VATEntry."Object No.");
                        FA.SetFilter("Date Filter", EntryToPost.GetFilter("Date Filter"));
                        GenJnlLine."FA Error Entry No." :=
                          FAInsertLedgEntry.GetDeprEntryForVATSettlement(FA, GenJnlLine."Posting Date", VATEntry."Entry No.");
                        GetFPEMode(VATEntry."Entry No.", Mode);
                        if Mode = Mode::Depreciation then
                            InsertLine := GenJnlLine."FA Error Entry No." <> 0;
                    end;
                    if Abs(GenJnlLine.Amount) > Abs(GenJnlLine."Paid Amount") then
                        GenJnlLine.Validate(Amount, -GenJnlLine."Paid Amount");
                    if InsertLine then
                        GenJnlLine.Insert();
                until VATEntry.Next() = 0;
        until EntryToPost.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SetGroupVATAlloc(var VATEntry: Record "VAT Entry"; var EntryNo: Record "Integer"): Boolean
    var
        GroupVATAllocLine: Record "Default VAT Allocation Line" temporary;
        VATAllocLine: Record "VAT Allocation Line";
        PostingDate: Date;
    begin
        if EntryNo.FindSet() then
            if GetGroupVATAlloc(GroupVATAllocLine) then begin
                repeat
                    VATEntry.SetRange("CV Ledg. Entry No.", EntryNo.Number);
                    if VATEntry.FindSet() then
                        repeat
                            VATAllocLine.SetRange("VAT Entry No.", VATEntry."Entry No.");
                            VATAllocLine.DeleteAll(true);
                            InsertVATAlloc(GroupVATAllocLine, VATEntry);
                            RecalculateAllocation(VATEntry."Entry No.", PostingDate);
                        until VATEntry.Next() = 0;
                until EntryNo.Next() = 0;

                exit(true);
            end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetGroupVATAlloc(var GroupVATAllocLine: Record "Default VAT Allocation Line" temporary): Boolean
    var
        GroupVATAllocForm: Page "Group VAT Allocation";
    begin
        GroupVATAllocForm.LookupMode := true;
        if GroupVATAllocForm.RunModal() = ACTION::LookupOK then
            GroupVATAllocForm.GetRecords(GroupVATAllocLine);
        exit(not GroupVATAllocLine.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure CheckVATAllocation(GenJnlLine: Record "Gen. Journal Line")
    var
        VATAllocLine: Record "VAT Allocation Line";
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
    begin
        VATAllocLine.SetRange("VAT Entry No.", GenJnlLine."Unrealized VAT Entry No.");
        if VATAllocLine.FindSet() then
            repeat
                VATAllocLine.TestField("Account No.");
                VATAllocLine.TestField(Amount);
                TableID[1] := DATABASE::"G/L Account";
                AccNo[1] := VATAllocLine."Account No.";
                if not DimMgt.CheckDimValuePosting(TableID, AccNo, VATAllocLine."Dimension Set ID") then
                    Error(
                      Text14716,
                      VATAllocLine.TableCaption, VATAllocLine."VAT Entry No.", VATAllocLine."Line No.",
                      DimMgt.GetDimValuePostingErr());
                TableID[1] := DATABASE::"G/L Account";
                AccNo[1] := VATAllocLine."VAT Unreal. Account No.";
                if not DimMgt.CheckDimValuePosting(TableID, AccNo, VATAllocLine."Dimension Set ID") then
                    Error(
                      Text14717,
                      GenJnlLine.TableCaption(), GenJnlLine."Journal Template Name",
                      GenJnlLine."Journal Batch Name", GenJnlLine."Line No.",
                      DimMgt.GetDimValuePostingErr())
            until VATAllocLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetFPEMode(UnrealVATEntryNo: Integer; var Mode: Option Any,Depreciation,General)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Unrealized VAT Entry No.");
        VATEntry.SetRange("Unrealized VAT Entry No.", UnrealVATEntryNo);
        VATEntry.SetRange(Reversed, false);
        if VATEntry.FindLast() then begin
            if VATEntry."FA Ledger Entry No." = 0 then
                Mode := Mode::General
            else
                Mode := Mode::Depreciation;
        end else
            Mode := Mode::Any;
    end;

    local procedure MergeEntryDimSetIDWithVATAllocationDim(VATEntryNo: Integer; DimSetID: Integer)
    var
        VATAllocationLine: Record "VAT Allocation Line";
    begin
        VATAllocationLine.SetRange("VAT Entry No.", VATEntryNo);
        if VATAllocationLine.FindSet(true) then
            repeat
                VATAllocationLine."Dimension Set ID" := GetCombinedDimSetID(
                    VATAllocationLine."Shortcut Dimension 1 Code", VATAllocationLine."Shortcut Dimension 2 Code",
                    VATAllocationLine."Dimension Set ID", DimSetID, GetVATEntryDimSetID(VATEntryNo));
                VATAllocationLine.Modify(true);
            until VATAllocationLine.Next() = 0;
    end;

    local procedure UpdateGenJnlLineDimSetID(var GenJournalLine: Record "Gen. Journal Line"; VATEntryNo: Integer)
    begin
        GenJournalLine."Dimension Set ID" :=
            GetCombinedDimSetID(
                GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code",
                GenJournalLine."Dimension Set ID", GetVATEntryDimSetID(VATEntryNo), 0);
    end;

    local procedure GetCombinedDimSetID(var ShortcutDimensionCode1: Code[20]; var ShortcutDimensionCode2: Code[20]; DimSetID1: Integer; DimSetID2: Integer; DimSetID3: Integer): Integer
    var
        DimensionSetIDArr: array[10] of Integer;
    begin
        DimensionSetIDArr[1] := DimSetID1;
        DimensionSetIDArr[2] := DimSetID2;
        DimensionSetIDArr[3] := DimSetID3;
        exit(DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, ShortcutDimensionCode1, ShortcutDimensionCode2));
    end;

    local procedure GetVATEntryDimSetID(VATEntryNo: Integer): Integer
    var
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        GLEntry: Record "G/L Entry";
    begin
        GLEntryVATEntryLink.SetRange("VAT Entry No.", VATEntryNo);
        if GLEntryVATEntryLink.FindFirst() then begin
            GLEntry.Get(GLEntryVATEntryLink."G/L Entry No.");
            exit(GLEntry."Dimension Set ID");
        end;
        exit(0);
    end;
}

