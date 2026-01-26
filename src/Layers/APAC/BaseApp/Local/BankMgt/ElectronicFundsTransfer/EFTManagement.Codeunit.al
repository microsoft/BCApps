// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.IO;

codeunit 11603 "EFT Management"
{
    Permissions = TableData "Vendor Ledger Entry" = rim;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        VendBankAcc: Record "Vendor Bank Account";
        Vend: Record Vendor;
        CompanyInfo: Record "Company Information";
        RBMgt: Codeunit "File Management";
        FileVar: File;
        NoOfLines: Integer;
        TypeOfLine: Code[2];
        ServerFileName: Text;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        Text11000: Label 'The value for the parameter is too long for the function. The value is %1.';
        Text11001: Label 'The length for %1 is %2 long, %3 characters are maximum.';
        Text11002: Label 'File EFT Payment created with Amount=%1.', Comment = '%1 - amount';
        Text11003: Label 'The value for the parameter is too long for the function %1. The value is %2.';
        ConfirmCancelExportQst: Label 'Do you want to cancel the EFT Payment export?';
        EFTRegisterExportCanceledMsg: Label 'EFT register number %1 has been canceled.', Comment = '%1 - register number';
        InvalidWHTRealizedTypeErr: Label 'Line number %3 in journal template name %1, journal batch name %2 cannot be exported because it must be applied to an invoice when the WHT Realized Type field contains Payment.', Comment = '%1 - journal template name, %2 - journal batch name, %3 - line number';

    [Scope('OnPrem')]
    procedure CleanUpEFTRegister()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        EFTRegister: Record "EFT Register";
    begin
        EFTRegister.Reset();
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("EFT Register No.");
        if EFTRegister.FindSet() then
            repeat
                VendLedgEntry.SetRange("EFT Register No.", EFTRegister."No.");
                if not VendLedgEntry.FindFirst() then
                    EFTRegister.Delete();
            until EFTRegister.Next() = 0;
    end;

    procedure Date2Text(Date: Date; Length: Integer): Text[6]
    begin
        if (Length < 1) or (Length > 6) then
            Error(Text11000, Length);
        if Date <> 0D then
            exit(CopyStr(Format(Date, 0, '<Day,2><Month,2><Year,2>'), 1, Length));
        exit(PadStr('', Length));
    end;

    procedure ClearText(Text: Text[250]): Text[250]
    begin
        exit(DelChr(Text, '=', DelChr(Text, '=', '0123456789')));
    end;

    procedure NFL(Text: Text[250]; Length: Integer): Text[250]
    begin
        Text := DelChr(Text, '<>');
        if (Length < 1) or (Length > 250) then
            Error(Text11003, 'NFL', Length);
        if StrLen(Text) > Length then
            Text := CopyStr(Text, StrLen(Text) - Length + 1);
        exit(PadStr('', Length - StrLen(Text), '0') + Text);
    end;

    procedure TFL(Text: Text[250]; Length: Integer): Text[250]
    begin
        Text := DelChr(Text, '<>');
        if (Length < 1) or (Length > 250) then
            Error(Text11003, 'TFL', Length);
        Text := CopyStr(Text, 1, Length);
        exit(PadStr('', Length - StrLen(Text), ' ') + Text);
    end;

    procedure TFR(Text: Text[250]; Length: Integer): Text[250]
    begin
        Text := DelChr(Text, '<>');
        if (Length < 1) or (Length > 250) then
            Error(Text11003, 'TFR', Length);
        exit(UpperCase(PadStr(Text, Length)));
    end;

    procedure BLK(Length: Integer): Text[250]
    begin
        if (Length < 1) or (Length > 250) then
            Error(Text11003, 'BLK', Length);
        exit(PadStr('', Length));
    end;

    procedure Value1(Dec: Decimal; Length: Integer): Text[250]
    begin
        exit(NFL(ClearText(Format(Round(Dec, 1.0))), Length));
    end;

    procedure Value100(Dec: Decimal; Length: Integer): Text[250]
    begin
        if Dec = 0 then
            exit(NFL('000', Length));
        exit(NFL(ClearText(Format(Round(Dec) * 100)), Length));
    end;

    [Scope('OnPrem')]
    procedure GetSetup()
    begin
        CompanyInfo.Get();
        GLSetup.Get();
    end;

    [Scope('OnPrem')]
    procedure OpenFile()
    begin
        FileVar.TextMode(true);
        FileVar.WriteMode(true);
        ServerFileName := RBMgt.ServerTempFileName('.txt');
        FileVar.Create(ServerFileName);
        Clear(TotalAmount);
        Clear(NoOfLines);
        Clear(TotalAmountLCY);
    end;

    procedure WriteFile(Length: Integer; Text: Text)
    begin
        if StrLen(Text) > Length then
            Error(Text11001, Text, StrLen(Text), Length);
        FileVar.Write(PadStr(Text, Length));
    end;

    [Scope('OnPrem')]
    procedure CloseFile(EFTRegister: Record "EFT Register"; FileDescription: Text[12]; BankAccount: Record "Bank Account")
    var
        EFTFileName: Text;
        EFTFileExtension: Text;
    begin
        EFTRegister.LockTable();
        EFTRegister.Find();
        EFTRegister."Total Amount (LCY)" := TotalAmountLCY;
        EFTRegister."File Created" := Today;
        EFTRegister.Time := Time;
        EFTRegister."File Description" := FileDescription;
        EFTRegister."Bank Account Code" := BankAccount."No.";
        EFTRegister.Modify();
        FileVar.Close();

        if CanDownloadFile() then begin
            EFTFileExtension := '.txt';
            EFTFileName := FileDescription;
            OnCloseFileBeforeDownloadFile(EFTRegister, EFTFileName, EFTFileExtension);
            if RBMgt.DownloadHandler(ServerFileName, '', '', '', EFTFileName + EFTFileExtension) then
                Message(Text11002, TotalAmountLCY);
        end;
    end;

    procedure CreateFileFromEFTRegister(var EFTRegister: Record "EFT Register"; FileDescription: Text[12]; var BankAcc: Record "Bank Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFileFromEFTRegister(EFTRegister, FileDescription, BankAcc, IsHandled);
        if IsHandled then
            exit;

        GetSetup();
        if EFTRegister."EFT Payment" then begin
            EFTRegister.TestField(Canceled, false);
            OpenFile();
            CreateFileEFTPayment(EFTRegister, FileDescription, BankAcc);
            CloseFile(EFTRegister, FileDescription, BankAcc);
        end;
    end;

    procedure CreateFileEFTPayment(var EFTRegister: Record "EFT Register"; FileDescription: Text[12]; var BankAccount: Record "Bank Account")
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        WHTManagement: Codeunit WHTManagement;
        LodgementReference: Text[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFileEFTPayment(EFTRegister, FileDescription, BankAccount, IsHandled);
        if IsHandled then
            exit;

        PreparePaymentBuffer(EFTRegister, TempGenJournalLine);
        if not TempGenJournalLine.Find('-') then
            exit;
        WriteFile(
          120, '0' + BLK(17) + '01' + TFR(FormatBankAccount(BankAccount."EFT Bank Code"), 10) +
          TFR(BankAccount."EFT Security Name", 26) + NFL(BankAccount."EFT Security No.", 6) +
          TFR(FileDescription, 12) + Date2Text(Today, 6) + BLK(40));
        repeat
            Vend.Get(TempGenJournalLine."Account No.");
            VendBankAcc.Get(Vend."No.", TempGenJournalLine."EFT Bank Account No.");
            if TempGenJournalLine.Amount > 0 then
                TypeOfLine := '50'
            else
                TypeOfLine := '53';
            if GLSetup."Round Amount for WHT Calc" then
                TempGenJournalLine."WHT Absorb Base" := WHTManagement.RoundWHTAmount(TempGenJournalLine."WHT Absorb Base");
            TotalAmountLCY += TempGenJournalLine.Amount - TempGenJournalLine."WHT Absorb Base";
            NoOfLines += 1;
            VendBankAcc.Get(Vend."No.", TempGenJournalLine."EFT Bank Account No.");
            LodgementReference := GetPmtRefOrDocNoFromGenJnlLine(TempGenJournalLine);
            WriteFile(
              120, '1' + TFR(FormatBranchNumber(VendBankAcc."EFT BSB No."), 7) + TFL(VendBankAcc."Bank Account No.", 9) +
              BLK(1) + TypeOfLine + NFL(Value100(TempGenJournalLine.Amount - TempGenJournalLine."WHT Absorb Base", 10), 10) + TFR(Vend.Name, 32) +
              TFR(LodgementReference, 18) + TFR(FormatBranchNumber(BankAccount."EFT BSB No."), 7) + TFL(
                BankAccount."Bank Account No.", 9) +
              TFR(BankAccount."EFT Security Name", 16) + NFL(Value100(TempGenJournalLine."WHT Absorb Base", 8), 8));
        until TempGenJournalLine.Next() = 0;
        if BankAccount."EFT Balancing Record Required" then begin
            WriteFile(
              120, '1' + TFR(FormatBranchNumber(BankAccount."EFT BSB No."), 7) + TFL(BankAccount."Bank Account No.", 9) + BLK(1) +
              '13' + NFL(Value100(TotalAmountLCY, 10), 10) +
              TFR(BankAccount."EFT Security Name", 32) + TFR(LodgementReference, 18) +
              TFR(FormatBranchNumber(BankAccount."EFT BSB No."), 7) + TFL(BankAccount."Bank Account No.", 9) +
              TFR(BankAccount."EFT Security Name", 16) + NFL(Value100(0, 8), 8));
            NoOfLines += 1;
        end;
        if BankAccount."EFT Balancing Record Required" then
            WriteFile(
              120, '7' + TFR('999-999', 7) + BLK(12) + NFL(Value100(0, 10), 10) +
              NFL(Value100(TotalAmountLCY, 10), 10) +
              NFL(Value100(TotalAmountLCY, 10), 10) +
              BLK(24) + NFL(Value1(NoOfLines, 6), 6) + BLK(40))
        else
            WriteFile(
              120, '7' + TFR('999-999', 7) + BLK(12) + NFL(Value100(TotalAmountLCY, 10), 10) +
              NFL(Value100(TotalAmountLCY, 10), 10) +
              NFL(Value100(0, 10), 10) +
              BLK(24) + NFL(Value1(NoOfLines, 6), 6) + BLK(40))
    end;

    [Scope('OnPrem')]
    procedure CalcAmountToPay(VendLedgEntry: Record "Vendor Ledger Entry"): Decimal
    begin
        VendLedgEntry.CalcFields("Remaining Amount");
        if (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice) and
           (VendLedgEntry."Due Date" <= VendLedgEntry."Pmt. Discount Date")
        then
            exit(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible");
        exit(VendLedgEntry."Remaining Amount");
    end;

    [Scope('OnPrem')]
    procedure CalcAmountToPayLCY(VendLedgEntry: Record "Vendor Ledger Entry"): Decimal
    begin
        if VendLedgEntry."Adjusted Currency Factor" <> 1 then
            exit(Round(VendLedgEntry."EFT Amount Transferred" / VendLedgEntry."Adjusted Currency Factor", GLSetup."Inv. Rounding Precision (LCY)"));
        exit(Round(VendLedgEntry."EFT Amount Transferred", GLSetup."Inv. Rounding Precision (LCY)"))
    end;

    procedure FormatBranchNumber(BranchNo: Text[10]): Text[7]
    begin
        if BranchNo = ' ' then
            exit(BLK(7));
        if StrPos(BranchNo, '-') <> 0 then
            exit(CopyStr(BranchNo, 1, 7));
        exit(Format(CopyStr(BranchNo, 1, 3) + '-' + CopyStr(BranchNo, 4, 3)));
    end;

    procedure FormatBankAccount(BankAcc: Code[10]): Text[3]
    begin
        if BankAcc = ' ' then
            exit(BLK(3));
        exit(CopyStr(BankAcc, 1, 3));
    end;

    [Scope('OnPrem')]
    procedure WithHoldingTaxAmountLCY(VendLedgEntry: Record "Vendor Ledger Entry"): Decimal
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        WHTSetup: Record "WHT Posting Setup";
        WHTManagement: Codeunit WHTManagement;
        WHTAmount: Decimal;
    begin
        TempGenJnlLine.DeleteAll();
        GLSetup.Get();
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." += 10000;
        TempGenJnlLine.Validate("Posting Date", VendLedgEntry."Posting Date");
        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::Vendor);
        TempGenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
        TempGenJnlLine.Validate("Document Type", VendLedgEntry."Document Type"::Payment);
        TempGenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
        TempGenJnlLine.Validate(Amount, VendLedgEntry."EFT Amount Transferred");
        TempGenJnlLine.Validate("Applies-to Doc. Type", VendLedgEntry."Document Type");
        TempGenJnlLine.Validate("Applies-to Doc. No.", VendLedgEntry."Document No.");
        TempGenJnlLine.Insert();
        if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Vendor then
            if WHTSetup.Get(TempGenJnlLine."WHT Business Posting Group", TempGenJnlLine."WHT Product Posting Group") then
                if WHTSetup."Realized WHT Type" <> WHTSetup."Realized WHT Type"::Earliest then
                    WHTAmount := WHTAmount + WHTManagement.WHTAmountJournal(TempGenJnlLine, false)
                else
                    WHTAmount := WHTAmount + Abs(WHTManagement.CalcVendExtraWHTForEarliest(TempGenJnlLine));

        WHTAmount := Round(WHTAmount, GLSetup."Inv. Rounding Precision (LCY)");

        if VendLedgEntry."Adjusted Currency Factor" <> 1 then
            exit(Round(WHTAmount / VendLedgEntry."Adjusted Currency Factor", GLSetup."Inv. Rounding Precision (LCY)"));
        exit(Round(WHTAmount, GLSetup."Inv. Rounding Precision (LCY)"));
    end;

    [Scope('OnPrem')]
    procedure CalcAmountToPayGJLrec(GenJournalLine: Record "Gen. Journal Line"): Decimal
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GenJournalLine.TestField("EFT Ledger Entry No.");
        VendLedgerEntry.Get(GenJournalLine."EFT Ledger Entry No.");
        VendLedgerEntry."Due Date" := GenJournalLine."Due Date";
        exit(-CalcAmountToPay(VendLedgerEntry));
    end;

    [Scope('OnPrem')]
    procedure GetServerFileName(): Text
    begin
        exit(ServerFileName);
    end;

    procedure PreparePaymentBuffer(EFTRegister: Record "EFT Register"; var PaymentBufferGenJournalLine: Record "Gen. Journal Line")
    begin
        FillBufferFromNonPostedPayments(EFTRegister, PaymentBufferGenJournalLine);
        FillBufferFromPostedPayments(EFTRegister, PaymentBufferGenJournalLine);
    end;

    local procedure FillBufferFromNonPostedPayments(EFTRegister: Record "EFT Register"; var PaymentBufferGenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("EFT Register No.", EFTRegister."No.");
        if GenJournalLine.FindSet() then
            repeat
                if (GenJournalLine."Applies-to Doc. Type" = GenJournalLine."Applies-to Doc. Type"::Invoice) and
                   (GenJournalLine."Applies-to Doc. No." <> '')
                then
                    FillBufferFromAppliedDoc(PaymentBufferGenJournalLine, GenJournalLine)
                else
                    if GenJournalLine."Applies-to ID" <> '' then
                        FillBufferFromAppliedEntries(PaymentBufferGenJournalLine, GenJournalLine)
                    else
                        FillBufferFromPaymentLine(PaymentBufferGenJournalLine, GenJournalLine);
            until GenJournalLine.Next() = 0;
    end;

    local procedure FillBufferFromPostedPayments(EFTRegister: Record "EFT Register"; var PaymentBufferGenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
    begin
        VendorLedgerEntry.SetRange("EFT Register No.", EFTRegister."No.");
        if VendorLedgerEntry.FindSet() then
            repeat
                FindAppliedEntries(VendorLedgerEntry, TempVendorLedgerEntry);
                if TempVendorLedgerEntry.FindSet() then begin
                    VendorLedgerEntry.CalcFields(Amount);
                    InitPaymentBuffer(
                        PaymentBufferGenJournalLine,
                        VendorLedgerEntry."Vendor No.",
                        VendorLedgerEntry."EFT Bank Account No.",
                        VendorLedgerEntry."Document No.",
                        VendorLedgerEntry."Payment Reference",
                        VendorLedgerEntry.Amount,
                        true);
                    repeat
                        UpdatePaymentBufferAmounts(PaymentBufferGenJournalLine, TempVendorLedgerEntry, true);
                    until TempVendorLedgerEntry.Next() = 0;
                    OnFillBufferFromPostedPaymentsBeforeInsertPaymentBufferGenJournalLine(PaymentBufferGenJournalLine, VendorLedgerEntry);
                    PaymentBufferGenJournalLine.Insert();
                end;
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure FillBufferFromAppliedDoc(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
        VendorLedgerEntry.FindFirst();
        InitPaymentBuffer(
            PaymentBufferGenJournalLine,
            VendorLedgerEntry."Vendor No.",
            GenJournalLine."EFT Bank Account No.",
            GenJournalLine."Document No.",
            GenJournalLine."Payment Reference",
            GenJournalLine.Amount,
            GenJournalLine."Skip WHT");
        UpdatePaymentBufferAmounts(PaymentBufferGenJournalLine, VendorLedgerEntry, false);
        OnFillBufferFromAppliedDocBeforeInsertPaymentBufferGenJournalLine(PaymentBufferGenJournalLine, VendorLedgerEntry, GenJournalLine);        
        PaymentBufferGenJournalLine.Insert();
    end;

    local procedure FillBufferFromAppliedEntries(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetFilter("Document Type", '<>%1&<>%2',
          VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::Refund);
        if VendorLedgerEntry.FindSet() then begin
            InitPaymentBuffer(
                PaymentBufferGenJournalLine,
                VendorLedgerEntry."Vendor No.",
                GenJournalLine."EFT Bank Account No.",
                GenJournalLine."Document No.",
                GenJournalLine."Payment Reference",
                GenJournalLine.Amount,
                GenJournalLine."Skip WHT");
            repeat
                UpdatePaymentBufferAmounts(PaymentBufferGenJournalLine, VendorLedgerEntry, false);
            until VendorLedgerEntry.Next() = 0;
            OnFillBufferFromAppliedEntriesBeforeInsertPaymentBufferGenJournalLine(PaymentBufferGenJournalLine, VendorLedgerEntry, GenJournalLine);            
            PaymentBufferGenJournalLine.Insert();
        end;
    end;

    local procedure FillBufferFromPaymentLine(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GLSetup.Get();
        if GLSetup."Enable WHT" and not GenJournalLine."Skip WHT" then
            CheckRealizedWHTType(GenJournalLine);
        InitPaymentBuffer(
            PaymentBufferGenJournalLine,
            GenJournalLine."Account No.",
            GenJournalLine."EFT Bank Account No.",
            GenJournalLine."Document No.",
            GenJournalLine."Payment Reference",
            GenJournalLine.Amount,
            GenJournalLine."Skip WHT");
        PaymentBufferGenJournalLine."WHT Absorb Base" := 0;
        OnFillBufferFromPaymentLineBeforeInsertPaymentBufferGenJournalLine(PaymentBufferGenJournalLine, GenJournalLine);
        PaymentBufferGenJournalLine.Insert();
    end;

    local procedure CheckRealizedWHTType(GenJournalLine: Record "Gen. Journal Line")
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        if WHTPostingSetup.Get(GenJournalLine."WHT Business Posting Group", GenJournalLine."WHT Product Posting Group") then
            if WHTPostingSetup."Realized WHT Type" = WHTPostingSetup."Realized WHT Type"::Payment then
                Error(
                  InvalidWHTRealizedTypeErr,
                  GenJournalLine."Journal Template Name",
                  GenJournalLine."Journal Batch Name",
                  GenJournalLine."Line No.");
    end;

    local procedure FindAppliedEntries(PaymentVendorLedgerEntry: Record "Vendor Ledger Entry"; var AppliedVendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry1.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry1.SetRange("Vendor Ledger Entry No.", PaymentVendorLedgerEntry."Entry No.");
        DtldVendLedgEntry1.SetRange("Entry Type", DtldVendLedgEntry1."Entry Type"::Application);
        DtldVendLedgEntry1.SetRange(Unapplied, false);
        if DtldVendLedgEntry1.FindSet() then
            repeat
                if DtldVendLedgEntry1."Vendor Ledger Entry No." =
                   DtldVendLedgEntry1."Applied Vend. Ledger Entry No."
                then begin
                    DtldVendLedgEntry2.Init();
                    DtldVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DtldVendLedgEntry2.SetRange(
                      "Applied Vend. Ledger Entry No.", DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
                    DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
                    DtldVendLedgEntry2.SetRange(Unapplied, false);
                    if DtldVendLedgEntry2.FindSet() then
                        repeat
                            if DtldVendLedgEntry2."Vendor Ledger Entry No." <>
                               DtldVendLedgEntry2."Applied Vend. Ledger Entry No."
                            then begin
                                VendorLedgerEntry.Get(DtldVendLedgEntry2."Vendor Ledger Entry No.");
                                AddAppliedEntryToBuffer(VendorLedgerEntry, AppliedVendorLedgerEntry);
                            end;
                        until DtldVendLedgEntry2.Next() = 0;
                end else begin
                    VendorLedgerEntry.Get(DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
                    AddAppliedEntryToBuffer(VendorLedgerEntry, AppliedVendorLedgerEntry);
                end;
            until DtldVendLedgEntry1.Next() = 0;
    end;

    local procedure AddAppliedEntryToBuffer(VendorLedgerEntry: Record "Vendor Ledger Entry"; var ApliedVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        if not ApliedVendorLedgerEntry.Get(VendorLedgerEntry."Entry No.") then begin
            ApliedVendorLedgerEntry := VendorLedgerEntry;
            ApliedVendorLedgerEntry.Insert();
        end;
    end;

    local procedure UpdatePaymentBufferAmounts(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; PaymentIsPosted: Boolean)
    var
        WHTAmount: Decimal;
    begin
        if PaymentIsPosted then
            PaymentBufferGenJournalLine.Amount += -VendorLedgerEntry."Amount to Apply";
        VendorLedgerEntry."EFT Amount Transferred" := PaymentBufferGenJournalLine.Amount;
        if PaymentBufferGenJournalLine."Skip WHT" then
            exit;
        WHTAmount := WithHoldingTaxAmountLCY(VendorLedgerEntry);
        if PaymentBufferGenJournalLine.Amount > 0 then
            PaymentBufferGenJournalLine."WHT Absorb Base" += WHTAmount
        else
            PaymentBufferGenJournalLine."WHT Absorb Base" -= WHTAmount;
    end;

    local procedure InitPaymentBuffer(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; EFTBankAccountNo: Code[20]; DocumentNo: Code[20]; PaymentReference: Code[50]; Amount: Decimal; SkipWHT: Boolean)
    begin
        PaymentBufferGenJournalLine.Init();

        OnBeforeInitPaymentBufferWithPaymentReference(PaymentBufferGenJournalLine, VendorNo, EFTBankAccountNo, DocumentNo, PaymentReference, Amount);
        if PaymentReference = '' then
            PaymentReference := DocumentNo;

        PaymentBufferGenJournalLine."Line No." += 10000;
        PaymentBufferGenJournalLine."Account No." := VendorNo;
        PaymentBufferGenJournalLine."Document No." := DocumentNo;
        PaymentBufferGenJournalLine."Payment Reference" := PaymentReference;
        PaymentBufferGenJournalLine."EFT Bank Account No." := EFTBankAccountNo;
        PaymentBufferGenJournalLine.Amount := Amount;
        PaymentBufferGenJournalLine."Skip WHT" := SkipWHT;
    end;

    local procedure CanDownloadFile(): Boolean
    var
        DoNotDownloadFile: Boolean;
    begin
        OnBeforeDownloadFile(DoNotDownloadFile);
        exit(not DoNotDownloadFile);
    end;

    procedure CancelExport(var EFTRegister: Record "EFT Register")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if not Confirm(ConfirmCancelExportQst) then
            exit;

        EFTRegister.Canceled := true;
        EFTRegister.Modify(true);

        GenJournalLine.SetRange("EFT Register No.", EFTRegister."No.");
        GenJournalLine.ModifyAll("EFT Register No.", 0);

        Message(EFTRegisterExportCanceledMsg, EFTRegister."No.");
    end;

    local procedure GetPmtRefOrDocNoFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line"): Text[50]
    begin
        if GenJnlLine."Payment Reference" = '' then
            exit(GenJnlLine."Document No.");
        exit(GenJnlLine."Payment Reference");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFileEFTPayment(var EFTRegister: Record "EFT Register"; FileDescription: Text[12]; var BankAccount: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFileFromEFTRegister(var EFTRegister: Record "EFT Register"; FileDescription: Text[12]; var BankAcc: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadFile(var DoNotDownloadFile: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPaymentBufferWithPaymentReference(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; var VendorNo: Code[20]; var EFTBankAccountNo: Code[20]; var DocumentNo: Code[20]; var PaymentReference: Code[50]; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseFileBeforeDownloadFile(EFTRegister: Record "EFT Register"; var EFTFileName: Text; var EFTFileExtension: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillBufferFromPostedPaymentsBeforeInsertPaymentBufferGenJournalLine(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillBufferFromAppliedDocBeforeInsertPaymentBufferGenJournalLine(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillBufferFromAppliedEntriesBeforeInsertPaymentBufferGenJournalLine(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillBufferFromPaymentLineBeforeInsertPaymentBufferGenJournalLine(var PaymentBufferGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;    
}

