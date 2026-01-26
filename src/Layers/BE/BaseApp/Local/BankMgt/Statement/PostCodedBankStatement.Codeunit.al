// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 2000042 "Post Coded Bank Statement"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Gen. Journal Template" = r,
                  TableData "Gen. Journal Line" = rimd,
                  TableData "Gen. Journal Batch" = ri;
    TableNo = "CODA Statement Line";

    trigger OnRun()
    begin
        EBSetup.Get();
        CodBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", "Statement Line No.");
        CodBankStmtLine.CopyFilters(Rec);
        Code();
        Rec.Copy(CodBankStmtLine);
    end;

    var
        Text000: Label 'There are unapplied Statement lines.';
        Text001: Label 'Do you want to transfer the statement lines to the General Ledger ?';
        Text002: Label 'There is no general journal template for bank account number %1.';
        Text003: Label 'Line                  #2###### @3@@@@@@@@@@@@@';
        Text004: Label '%1 %2 is transferring to journal %3...', Comment = 'Parameter 1 - bank account number, 2 - statement number, 3 - general journal template name.';
        Text005: Label 'CODA statement line %1 has already been transferred to the general ledger.';
        Text006: Label 'Internal error: recursive call of Default Posting.';
        Text007: Label 'CV', Locked = true;
        Text008: Label 'VC', Locked = true;
        Text009: Label 'C', Locked = true;
        Text010: Label 'V', Locked = true;
        Text011: Label 'Type standard format message %1 was not found.';
        Text012: Label 'Error in %1 %2 on line number %3.', Comment = 'Parameter 1 - message type (Non standard format,Standard format), 2 - statement message (text), 3 - statement line number (integer).';
        Text013: Label 'The Open field in customer ledger entry is %1.';
        Text014: Label '%1 is partially applied.';
        Text015: Label '%1 was not found.';
        EBSetup: Record "Electronic Banking Setup";
        CodBankStmtLine: Record "CODA Statement Line";
        CodedTrans: Record "Transaction Coding";
        BankAcc: Record "Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLAcc: Record "G/L Account";
        CurrExchRate: Record "Currency Exchange Rate";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        GenJnlManagement: Codeunit GenJnlManagement;
        CodeFound: Boolean;
        ProcessingDefaultPosting: Boolean;
        Testing: Boolean;
        DefaultApplication: Boolean;
        ErrorMsg: Text[250];
        BatchName: Code[10];

    [Scope('OnPrem')]
    procedure "Code"()
    var
        CodedBankStmtLine: Record "CODA Statement Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        CodedBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", "Statement Line No.");
        CodedBankStmtLine.CopyFilters(CodBankStmtLine);
        CodedBankStmtLine.SetRange(ID, CodBankStmtLine.ID::Movement);
        CodedBankStmtLine.SetRange("Application Status", CodBankStmtLine."Application Status"::" ");
        if not CodedBankStmtLine.IsEmpty() then
            Error(Text000);

        if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
            exit;

        CodedBankStmtLine.Reset();

        CodBankStmtLine.SetFilter("Application Status", '%1|%2', CodBankStmtLine."Application Status"::Applied, CodBankStmtLine."Application Status"::"Partly applied");
        CodBankStmtLine.FindFirst();
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Financial);
        GenJnlTemplate.SetRange("Bal. Account Type", GenJnlTemplate."Bal. Account Type"::"Bank Account");
        GenJnlTemplate.SetRange("Bal. Account No.", CodBankStmtLine."Bank Account No.");
        if not GenJnlTemplate.FindFirst() then
            Error(Text002, CodBankStmtLine."Bank Account No.");
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlManagement.OpenJnl(BatchName, GenJnlLine);
        OnCodeOnBeforeTransferCodBankStmtLines(CodedBankStmtLine, CodBankStmtLine);
        CheckAccountType(CodBankStmtLine."Bank Account No.", CodBankStmtLine."Statement No.");
        TransferCodBankStmtLines();
    end;

    [Scope('OnPrem')]
    procedure TransferCodBankStmtLines()
    var
        Window: Dialog;
        LineNo: Integer;
        TotLines: Integer;
        LineCounter: Integer;
    begin
        Window.Open(
          '#1#################################\\' +
          Text003);

        if GenJnlLine.FindLast() then;
        LineNo := GenJnlLine."Line No.";
        TotLines := CodBankStmtLine.Count;
        LineCounter := 0;
        Window.Update(1, StrSubstNo(Text004, CodBankStmtLine."Bank Account No.", CodBankStmtLine."Statement No.", GenJnlTemplate.Name));
        CodBankStmtLine.FindSet();
        repeat
            // Test if Coded Bank statement line has been posted yet
            if (CodBankStmtLine."Journal Template Name" <> '') or
               (CodBankStmtLine."Journal Batch Name" <> '') or
               (CodBankStmtLine."Line No." <> 0)
            then
                Error(Text005, CodBankStmtLine."Document No.");

            if CodBankStmtLine."Statement Amount" <> 0 then begin
                OnTransferCodBankStmtLinesOnBeforeInitGenJnlLine(CodBankStmtLine);
                LineCounter := LineCounter + 1;
                GenJnlLine.Init();
                LineNo := LineNo + 10000;
                GenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
                GenJnlLine."Journal Batch Name" := BatchName;
                GenJnlLine."Line No." := LineNo;
                GenJnlLine."Posting Date" := CodBankStmtLine."Posting Date";
                // 463983 - Because CODA is only used in BE and in BE the posting date is always the VAT date.
                GenJnlLine."VAT Reporting Date" := CodBankStmtLine."Posting Date";
                GenJnlLine."Source Code" := GenJnlTemplate."Source Code";
                GenJnlLine.Validate("Bal. Account Type", GenJnlTemplate."Bal. Account Type");
                GenJnlLine.Validate("Bal. Account No.", GenJnlTemplate."Bal. Account No.");
                GenJnlLine."Account Type" := CodBankStmtLine."Account Type";
                GenJnlLine."Document Type" := CodBankStmtLine."Document Type";
                GenJnlLine."Document No." := CodBankStmtLine."Document No.";
                if CodBankStmtLine.Description <> '' then
                    GenJnlLine.Description := CopyStr(CodBankStmtLine.Description, 1, MaxStrLen(GenJnlLine.Description));
                // Bank account is Balancing Account, hence Statement Amount takes the opposite sign
                BankAcc.Get(CodBankStmtLine."Bank Account No.");
                if BankAcc."Currency Code" = '' then begin
                    GenJnlLine."Currency Factor" := CodBankStmtLine."Currency Factor";
                    GenJnlLine."Currency Code" := CodBankStmtLine."Currency Code";
                end;
                GenJnlLine.Validate("Account No.", CodBankStmtLine."Account No.");
                GenJnlLine."Applies-to ID" := CodBankStmtLine."Applies-to ID";
                if ((BankAcc."Currency Code" = '') and (GenJnlLine."Currency Code" <> '')) then begin
                    GenJnlLine."Amount (LCY)" := -CodBankStmtLine."Statement Amount";
                    GenJnlLine.Amount := Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine."Amount (LCY)", GenJnlLine."Currency Factor"));
                end else
                    GenJnlLine.Validate(Amount, -CodBankStmtLine."Statement Amount");
                GenJnlLine."System-Created Entry" := true;
                OnTransferCodBankStmtLinesOnBeforeGenJnlLineInsert(GenJnlLine, CodBankStmtLine);
                GenJnlLine.Insert();
                // Link Coded Bank Statement line to Gen. Jnl. Line
                CodBankStmtLine."Journal Template Name" := GenJnlLine."Journal Template Name";
                CodBankStmtLine."Journal Batch Name" := GenJnlLine."Journal Batch Name";
                CodBankStmtLine."Line No." := GenJnlLine."Line No.";
                CodBankStmtLine.Modify();

                Window.Update(2, LineNo);
                Window.Update(3, Round(LineCounter / TotLines * 10000, 1));
            end;
        until CodBankStmtLine.Next() = 0;
        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure ProcessCodBankStmtLine(var CodedBankStmtLine: Record "CODA Statement Line")
    var
        CodBankStmtLine: Record "CODA Statement Line";
        AppliedAmount: Decimal;
        UnappliedAmtInclPartial: Decimal;
    begin
        if FetchCodedTransaction(CodedBankStmtLine) then
            // Type 0 lines don't have details.
            if (CodedTrans."Globalisation Code" = CodedTrans."Globalisation Code"::Global) or
               (CodedBankStmtLine."Transaction Type" = 0)
            then begin
                ApplyCodedTransaction(CodedBankStmtLine);

                if CodedBankStmtLine.Type = CodedBankStmtLine.Type::Global then begin
                    CodBankStmtLine.Reset();
                    CodBankStmtLine.SetRange("Bank Account No.", CodedBankStmtLine."Bank Account No.");
                    CodBankStmtLine.SetRange("Statement No.", CodedBankStmtLine."Statement No.");
                    CodBankStmtLine.SetRange(ID, CodedBankStmtLine.ID);
                    CodBankStmtLine.SetRange("Attached to Line No.", CodedBankStmtLine."Statement Line No.");
                    if CodBankStmtLine.FindSet() then
                        repeat
                            CodBankStmtLine."Unapplied Amount" := 0;
                            CodBankStmtLine."Application Status" := CodedBankStmtLine."Application Status"::"Indirectly applied";
                            CodBankStmtLine.Modify();
                        until CodBankStmtLine.Next() = 0;
                end;
            end else begin
                CodBankStmtLine.Reset();
                CodBankStmtLine.SetRange("Bank Account No.", CodedBankStmtLine."Bank Account No.");
                CodBankStmtLine.SetRange("Statement No.", CodedBankStmtLine."Statement No.");
                CodBankStmtLine.SetRange(ID, CodedBankStmtLine.ID);
                CodBankStmtLine.SetRange("Attached to Line No.", CodedBankStmtLine."Statement Line No.");
                if CodBankStmtLine.FindSet() then begin
                    UnappliedAmtInclPartial := CodedBankStmtLine."Unapplied Amount";
                    repeat
                        ProcessCodBankStmtLine(CodBankStmtLine);

                        if CodBankStmtLine."Application Status" = CodBankStmtLine."Application Status"::"Partly applied" then
                            AppliedAmount := CodBankStmtLine."Statement Amount"
                        else
                            AppliedAmount := CodBankStmtLine.Amount;
                        UnappliedAmtInclPartial -= AppliedAmount;
                        CodedBankStmtLine."Unapplied Amount" := CodedBankStmtLine."Unapplied Amount" - CodBankStmtLine.Amount;
                    until CodBankStmtLine.Next() = 0;
                    if UnappliedAmtInclPartial = 0 then
                        CodedBankStmtLine."Application Status" := CodedBankStmtLine."Application Status"::"Indirectly applied";
                end else
                    ApplyCodedTransaction(CodedBankStmtLine)
            end;
        CodedBankStmtLine."System-Created Entry" := true;
        CodedBankStmtLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure FetchCodedTransaction(var CodedBankStmtLine: Record "CODA Statement Line"): Boolean
    var
        TransactionFound: Boolean;
    begin
        if ProcessingDefaultPosting then begin
            CodedTrans."Bank Account No." := '';
            CodedTrans."Transaction Family" := 0;
            CodedTrans.Transaction := 0;
            CodedTrans."Transaction Category" := 0;

            // Error if default posting entry is not found
            CodedTrans.Find();
            TransactionFound := true;
        end else begin
            CodedTrans."Bank Account No." := CodedBankStmtLine."Bank Account No.";
            CodedTrans."Transaction Family" := CodedBankStmtLine."Transaction Family";
            CodedTrans.Transaction := CodedBankStmtLine.Transaction;
            CodedTrans."Transaction Category" := CodedBankStmtLine."Transaction Category";
            TransactionFound := CodedTrans.Find();
            if not TransactionFound then begin
                CodedTrans."Bank Account No." := '';
                TransactionFound := CodedTrans.Find();
            end;
            if not TransactionFound then begin
                CodedTrans."Transaction Family" := 0;
                CodedTrans.Transaction := 0;
                TransactionFound := CodedTrans.Find();
            end;
            if not (Testing or TransactionFound) then begin
                CodedTrans."Transaction Category" := 0;
                TransactionFound := CodedTrans.Find();
            end;
        end;
        exit(TransactionFound);
    end;

    [Scope('OnPrem')]
    procedure ApplyCodedTransaction(var CodedBankStmtLine: Record "CODA Statement Line")
    begin
        CodBankStmtLine := CodedBankStmtLine;
        if CodBankStmtLine."Message Type" = CodBankStmtLine."Message Type"::"Standard format" then
            InterpretStandardFormat(CodBankStmtLine);
        // Post line according to Coded Transaction definition
        if CodBankStmtLine."Application Status" in [CodBankStmtLine."Application Status"::" ", CodBankStmtLine."Application Status"::"Partly applied"] then begin
            if (CodBankStmtLine."Message Type" = CodBankStmtLine."Message Type"::"Non standard format") and (CodBankStmtLine."Statement Message" <> '') then
                CodBankStmtLine.Description := CopyStr(DelChr(CodBankStmtLine."Statement Message", '>', ' '), 1, MaxStrLen(CodBankStmtLine.Description));
            case CodedTrans."Account Type" of
                CodedTrans."Account Type"::" ":
                    NotCodedPosting();
                CodedTrans."Account Type"::"G/L Account", CodedTrans."Account Type"::"Bank Account":
                    begin
                        CodedTrans.TestField("Account No.");
                        InitCodBankStmtLine(CodedTrans."Account Type" - 1, false);
                        if (CodBankStmtLine."Message Type" = CodBankStmtLine."Message Type"::"Non standard format") and (CodBankStmtLine."Statement Message" = '') then
                            CodBankStmtLine.Description := CodedTrans.Description;
                    end;
                CodedTrans."Account Type"::Customer:
                    begin
                        SearchCustLedgEntry();
                        if CodedTrans."Account No." <> '' then
                            InitCodBankStmtLine(CodedTrans."Account Type" - 1, true);
                    end;
                CodedTrans."Account Type"::Vendor:
                    begin
                        SearchVendLedgEntry();
                        if CodedTrans."Account No." <> '' then
                            InitCodBankStmtLine(CodedTrans."Account Type" - 1, true);
                    end;
            end;
        end;
        if CodBankStmtLine."Message Type" = CodBankStmtLine."Message Type"::"Non standard format" then
            if CodBankStmtLine."Statement Message" <> '' then
                CodBankStmtLine.Description := CopyStr(DelChr(CodBankStmtLine."Statement Message", '>', ' '), 1, MaxStrLen(CodBankStmtLine.Description));
        // Everything else failed
        if (CodBankStmtLine."Application Status" = CodBankStmtLine."Application Status"::" ") and DefaultApplication then
            DefaultPosting(CodBankStmtLine);
        CodedBankStmtLine := CodBankStmtLine;
    end;

    [Scope('OnPrem')]
    procedure DefaultPosting(var CodedBankStmtLine: Record "CODA Statement Line")
    begin
        OnBeforeDefaultPosting(CodedBankStmtLine, CodedTrans);
        if ProcessingDefaultPosting then
            Error(Text006);
        ProcessingDefaultPosting := true;
        ProcessCodBankStmtLine(CodedBankStmtLine);
        ProcessingDefaultPosting := false
    end;

    [Scope('OnPrem')]
    procedure NotCodedPosting()
    var
        Sequence: Text[30];
        i: Integer;
    begin
        if CodBankStmtLine."Statement Amount" > 0 then
            Sequence := Text007
        else
            Sequence := Text008;
        for i := 1 to StrLen(Sequence) do begin
            case Format(Sequence[i]) of
                Text009:
                    SearchCustLedgEntry();
                Text010:
                    SearchVendLedgEntry();
            end;
            if CodBankStmtLine."Application Status" = CodBankStmtLine."Application Status"::Applied then
                exit;
        end;
    end;

    [Scope('OnPrem')]
    procedure InterpretStandardFormat(var CodedBankStmtLine: Record "CODA Statement Line"): Text[250]
    begin
        ErrorMsg := '';
        CodBankStmtLine := CodedBankStmtLine;
        if CodBankStmtLine."Message Type" = CodBankStmtLine."Message Type"::"Non standard format" then
            exit;
        CodeFound := false;
        case CodBankStmtLine."Type Standard Format Message" of
            10:
                CodeFound := true;
            11:
                CodeFound := true;
            101, 102:
                begin
                    DecodeOGM();
                    CodeFound := true;
                end;
            103:
                begin
                    DecodeNumber();
                    CodeFound := true
                end;
            104:
                begin
                    DecodeEquivalent();
                    CodeFound := true
                end;
            105:
                begin
                    DecodeOriginalAmount();
                    CodeFound := true
                end;
            106:
                begin
                    DecodeMethodOfCalculation();
                    CodeFound := true
                end;
            107:
                begin
                    DecodeDomiciliation();
                    CodeFound := true
                end;
            126:
                begin
                    TermInvestment();
                    CodeFound := true
                end;
            else
                CodeFound := true;
        end;
        if not CodeFound then
            ErrorMsg := StrSubstNo(Text011, CodBankStmtLine."Type Standard Format Message");
        CodedBankStmtLine := CodBankStmtLine;
        if Testing then
            exit(ErrorMsg);

        if ErrorMsg <> '' then
            Error(ErrorMsg);
    end;

    [Scope('OnPrem')]
    procedure InitCodeunit(NewTesting: Boolean; DefaultPosting: Boolean)
    begin
        Testing := NewTesting;
        DefaultApplication := DefaultPosting
    end;

    local procedure DecodeOGM()
    begin
        if not PaymJnlManagement.Mod97Test(CodBankStmtLine."Statement Message") then
            ErrorMsg :=
              StrSubstNo(Text012,
                CodBankStmtLine."Message Type", CodBankStmtLine."Statement Message", CodBankStmtLine."Statement Line No.")
        else
            if CodBankStmtLine."Statement Amount" > 0 then begin
                DecodeCustLedgEntry();
                if CodBankStmtLine."Application Status" = CodBankStmtLine."Application Status"::" " then
                    SearchCustLedgEntry();
            end else begin
                DecodeVendLedgEntry();
                if CodBankStmtLine."Application Status" = CodBankStmtLine."Application Status"::" " then
                    SearchVendLedgEntry();
            end;
    end;

    [Scope('OnPrem')]
    procedure DecodeNumber()
    begin
        // 103
        CodBankStmtLine.Description := CopyStr(CodBankStmtLine."Statement Message", 1, 12)
    end;

    [Scope('OnPrem')]
    procedure DecodeEquivalent()
    begin
        // 104
        Evaluate(CodBankStmtLine."Amount (LCY)", CopyStr(CodBankStmtLine."Statement Message", 1, 15));
    end;

    [Scope('OnPrem')]
    procedure DecodeOriginalAmount()
    begin
    end;

    local procedure DecodeCustLedgEntry()
    var
        DocNo: Code[20];
    begin
        Clear(CustLedgEntry);
        if CodBankStmtLine."Type Standard Format Message" = 107 then begin
            if CodBankStmtLine.Type = CodBankStmtLine.Type::Global then
                DocNo := DelChr(CopyStr(CodBankStmtLine."Customer Reference", 1, 10), '<', '0')
            else
                DocNo := DelChr(CopyStr(CodBankStmtLine."Customer Reference", 14, 11), '<', '0');
        end else
            DocNo := DelChr(CopyStr(CodBankStmtLine."Statement Message", 1, 10), '<', '0');

        CustLedgEntry.SetCurrentKey("Document No.");
        if CodBankStmtLine."Statement Amount" > 0 then
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", DocNo);
        OnDecodeCustLedgEntryOnBeforePost(CustLedgEntry, CodBankStmtLine, DocNo);
        if CustLedgEntry.FindFirst() then
            PostCustLedgEntry();
    end;

    local procedure SearchCustomer(): Boolean
    var
        CustBankAcc: Record "Customer Bank Account";
        DomiciliationNo: Text[12];
        BankAccNo: Text[30];
    begin
        Clear(Cust);
        if CodBankStmtLine."Type Standard Format Message" = 107 then begin
            if Cust.SetCurrentKey("Domiciliation No.") then;
            DomiciliationNo := CopyStr(CodBankStmtLine."Statement Message", 1, 12);
            Cust.SetRange("Domiciliation No.", DomiciliationNo);
            exit(Cust.FindFirst());
        end;
        if CodBankStmtLine."Bank Account No. Other Party" <> '' then begin
            CustBankAcc.SetRange(IBAN, CodBankStmtLine."Bank Account No. Other Party");
            if not CustBankAcc.FindFirst() then begin
                CustBankAcc.SetRange(IBAN);
                if StrLen(CodBankStmtLine."Bank Account No. Other Party") <= MaxStrLen(CustBankAcc."Bank Account No.") then
                    CustBankAcc.SetRange("Bank Account No.", CodBankStmtLine."Bank Account No. Other Party");
                if not CustBankAcc.FindFirst() then begin
                    BankAccNo :=
                      // try format xxx-xxxxxxx-xx
                      CopyStr(CodBankStmtLine."Bank Account No. Other Party", 1, 3) +
                      '-' + CopyStr(CodBankStmtLine."Bank Account No. Other Party", 4, 7) +
                      '-' + CopyStr(CodBankStmtLine."Bank Account No. Other Party", 11, 2);
                    CustBankAcc.SetRange("Bank Account No.", BankAccNo);
                    if not CustBankAcc.FindFirst() then
                        if CodedTrans."Account Type" = CodedTrans."Account Type"::Customer then
                            CustBankAcc."Customer No." := CodedTrans."Account No.";
                end;
            end;
            exit(Cust.Get(CustBankAcc."Customer No."));
        end
    end;

    local procedure SearchCustLedgEntry()
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
        Found: Integer;
    begin
        Clear(CustLedgEntry);
        if SearchCustomer() then begin
            CustLedgEntry2.SetCurrentKey("Customer No.", Open, Positive);
            CustLedgEntry2.SetRange("Customer No.", Cust."No.");
            CustLedgEntry2.SetRange(Open, true);
            CustLedgEntry2.SetRange(Positive, CodBankStmtLine."Statement Amount" > 0);
            OnSearchCustLedgEntryOnAfterCustLedgEntry2SetFilters(CustLedgEntry2, CodBankStmtLine);
            if CustLedgEntry2.FindSet() then
                repeat
                    CustLedgEntry2.CalcFields("Remaining Amount");
                    if CustLedgEntry2."Remaining Amount" = CodBankStmtLine."Statement Amount" then begin
                        Found := Found + 1;
                        if CheckCustLedgEntry(CustLedgEntry2, Found) then
                            CustLedgEntry := CustLedgEntry2;
                    end;
                until CustLedgEntry2.Next() = 0;
            // Multiple Entries with Same Amount: Do Not Assign
            if (Found = 0) or ((Found > 1) and (CustLedgEntry."Payment Reference" = '')) then
                Clear(CustLedgEntry);
            CustLedgEntry."Customer No." := Cust."No.";

            PostCustLedgEntry();
        end;
        Clear(Cust)
    end;

    [Scope('OnPrem')]
    procedure PostCustLedgEntry()
    begin
        CodBankStmtLine."Application Status" := CodBankStmtLine."Application Status"::Applied;
        Cust.Get(CustLedgEntry."Customer No.");
        if CodBankStmtLine."Statement Amount" > 0 then
            CodBankStmtLine."Document Type" := CodBankStmtLine."Document Type"::Payment
        else
            CodBankStmtLine."Document Type" := CodBankStmtLine."Document Type"::Refund;
        CodBankStmtLine."Account Type" := CodBankStmtLine."Account Type"::Customer;
        CodBankStmtLine."Account No." := CustLedgEntry."Customer No.";
        CodBankStmtLine.Amount := CodBankStmtLine."Statement Amount";
        CodBankStmtLine."Unapplied Amount" := CodBankStmtLine."Unapplied Amount" - CodBankStmtLine.Amount;
        CodBankStmtLine.Validate("Account Name", Cust.Name);
        if CustLedgEntry."Entry No." > 0 then
            if not CustLedgEntry.Open then begin
                CodBankStmtLine."Application Status" := CodBankStmtLine."Application Status"::"Partly applied";
                CodBankStmtLine."Application Information" :=
                  StrSubstNo(Text013, CustLedgEntry.Open);
            end else begin
                if CodBankStmtLine."Unapplied Amount" <> 0 then begin
                    CodBankStmtLine."Application Information" := StrSubstNo(Text014, CustLedgEntry.TableCaption());
                    CodBankStmtLine."Application Status" := CodBankStmtLine."Application Status"::"Partly applied";
                end;
                CodBankStmtLine."Applies-to ID" := CodBankStmtLine."Document No.";
                CustLedgEntry."Applies-to ID" := CodBankStmtLine."Document No.";
                CustLedgEntry.CalcFields("Remaining Amount");
                CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
                CustLedgEntry.Modify();
            end
        else begin
            CodBankStmtLine."Application Status" := CodBankStmtLine."Application Status"::"Partly applied";
            CodBankStmtLine."Application Information" := StrSubstNo(Text015, CustLedgEntry.TableCaption());
        end;
        Clear(CustLedgEntry)
    end;

    local procedure DecodeVendLedgEntry()
    var
        Message: Text[50];
    begin
        Clear(VendLedgEntry);
        if CodBankStmtLine."Type Standard Format Message" = 107 then
            Message := DelChr(CopyStr(CodBankStmtLine."Statement Message", 19, 15), '<', '0')
        else
            Message := DelChr(CopyStr(CodBankStmtLine."Statement Message", 1, 50), '<', '0');
        VendLedgEntry.SetCurrentKey(Open);
        if CodBankStmtLine."Statement Amount" > 0 then
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo")
        else
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);

        VendLedgEntry.SetRange(Description, Message);
        OnDecodeVendLedgEntryOnAfterVendLedgEntrySetFilters(VendLedgEntry, CodBankStmtLine, Message);
        if VendLedgEntry.FindFirst() then
            PostVendLedgEntry();
    end;

    local procedure SearchVendor(): Boolean
    var
        VendBankAcc: Record "Vendor Bank Account";
        BankAccNo: Text[30];
    begin
        Clear(Vend);
        if CodBankStmtLine."Bank Account No. Other Party" <> '' then begin
            VendBankAcc.SetRange(IBAN, CodBankStmtLine."Bank Account No. Other Party");
            if not VendBankAcc.FindFirst() then begin
                VendBankAcc.SetRange(IBAN);
                if StrLen(CodBankStmtLine."Bank Account No. Other Party") <= MaxStrLen(VendBankAcc."Bank Account No.") then
                    VendBankAcc.SetRange("Bank Account No.", CodBankStmtLine."Bank Account No. Other Party");
                if not VendBankAcc.FindFirst() then begin
                    BankAccNo :=
                      // try format xxx-xxxxxxx-xx
                      CopyStr(CodBankStmtLine."Bank Account No. Other Party", 1, 3) +
                      '-' + CopyStr(CodBankStmtLine."Bank Account No. Other Party", 4, 7) +
                      '-' + CopyStr(CodBankStmtLine."Bank Account No. Other Party", 11, 2);
                    VendBankAcc.SetRange("Bank Account No.", BankAccNo);
                    if not VendBankAcc.FindFirst() then
                        if CodedTrans."Account Type" = CodedTrans."Account Type"::Vendor then
                            VendBankAcc."Vendor No." := CodedTrans."Account No.";
                end;
            end;
            OnAfterSearchVendor(Vend, VendBankAcc, CodBankStmtLine);
            exit(Vend.Get(VendBankAcc."Vendor No."));
        end;
    end;

    local procedure SearchVendLedgEntry()
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
        Found: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSearchVendorLedgerEntry(CodBankStmtLine, IsHandled);
        if IsHandled then
            exit;

        Clear(VendLedgEntry);
        if SearchVendor() then begin
            VendLedgEntry2.SetAutoCalcFields("Remaining Amount");
            VendLedgEntry2.SetCurrentKey("Vendor No.", Open, Positive);
            VendLedgEntry2.SetRange("Vendor No.", Vend."No.");
            VendLedgEntry2.SetRange(Open, true);
            VendLedgEntry2.SetRange(Positive, CodBankStmtLine."Statement Amount" > 0);
            if VendLedgEntry2.FindSet() then
                repeat
                    if VendLedgEntry2."Remaining Amount" = CodBankStmtLine."Statement Amount" then begin
                        Found := Found + 1;
                        VendLedgEntry := VendLedgEntry2;
                    end;
                until VendLedgEntry2.Next() = 0;
            // Multiple Entries with Same Amount: Do Not Assign
            if Found <> 1 then
                Clear(VendLedgEntry);
            VendLedgEntry."Vendor No." := Vend."No.";

            PostVendLedgEntry();
        end;
        Clear(Vend);
    end;

    [Scope('OnPrem')]
    procedure PostVendLedgEntry()
    begin
        Vend.Get(VendLedgEntry."Vendor No.");
        CodBankStmtLine."Application Status" := CodBankStmtLine."Application Status"::Applied;
        if CodBankStmtLine."Statement Amount" < 0 then
            CodBankStmtLine."Document Type" := CodBankStmtLine."Document Type"::Payment
        else
            CodBankStmtLine."Document Type" := CodBankStmtLine."Document Type"::Refund;
        CodBankStmtLine."Account Type" := CodBankStmtLine."Account Type"::Vendor;
        CodBankStmtLine."Account No." := VendLedgEntry."Vendor No.";
        CodBankStmtLine.Validate("Account Name", Vend.Name);
        if VendLedgEntry."Entry No." > 0 then begin
            CodBankStmtLine.Amount := CodBankStmtLine."Statement Amount";
            CodBankStmtLine."Unapplied Amount" := CodBankStmtLine."Unapplied Amount" - CodBankStmtLine.Amount;
            if CodBankStmtLine."Unapplied Amount" <> 0 then begin
                CodBankStmtLine."Application Information" := StrSubstNo(Text014, VendLedgEntry.TableCaption());
                CodBankStmtLine."Application Status" := CodBankStmtLine."Application Status"::"Partly applied"
            end;
            CodBankStmtLine."Applies-to ID" := CodBankStmtLine."Document No.";
            VendLedgEntry."Applies-to ID" := CodBankStmtLine."Document No.";
            VendLedgEntry.CalcFields("Remaining Amount");
            VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
            VendLedgEntry.Modify();
        end else begin
            CodBankStmtLine."Application Information" := StrSubstNo(Text015, VendLedgEntry.TableCaption());
            CodBankStmtLine."Application Status" := CodBankStmtLine."Application Status"::"Partly applied"
        end;
        Clear(VendLedgEntry)
    end;

    [Scope('OnPrem')]
    procedure DecodeMethodOfCalculation()
    begin
        // 106
        // Not implemented
    end;

    [Scope('OnPrem')]
    procedure DecodeDomiciliation()
    var
        Sequence: Text[30];
        i: Integer;
    begin
        // 107
        if CodedTrans."Account Type" <> CodedTrans."Account Type"::"G/L Account" then begin
            if CodedTrans."Account Type" = CodedTrans."Account Type"::Customer then
                Sequence := Text009
            else
                if CodedTrans."Account Type" = CodedTrans."Account Type"::Vendor then
                    Sequence := Text010
                else
                    if CodBankStmtLine."Statement Amount" > 0 then
                        Sequence := Text007
                    else
                        Sequence := Text008;
            for i := 1 to StrLen(Sequence) do begin
                case Format(Sequence[i]) of
                    Text009:
                        begin
                            DecodeCustLedgEntry();
                            if CodBankStmtLine."Application Status" = CodBankStmtLine."Application Status"::" " then
                                SearchCustLedgEntry();
                        end;
                    Text010:
                        begin
                            DecodeVendLedgEntry();
                            if CodBankStmtLine."Application Status" = CodBankStmtLine."Application Status"::" " then
                                SearchVendLedgEntry();
                        end
                end;
                if CodBankStmtLine."Application Status" = CodBankStmtLine."Application Status"::Applied then
                    exit;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure TermInvestment()
    begin
        // 126
        // Not implemented
    end;

    local procedure InitCodBankStmtLine(AccountType: Integer; UpdateApplicationAmounts: Boolean)
    begin
        CodBankStmtLine."Application Status" := CodBankStmtLine."Application Status"::"Partly applied";
        CodBankStmtLine."Application Information" := CodedTrans.Description;
        CodBankStmtLine."Account Type" := "Gen. Journal Account Type".FromInteger(AccountType);
        CodBankStmtLine."Account No." := CodedTrans."Account No.";
        case CodBankStmtLine."Account Type" of
            CodBankStmtLine."Account Type"::Customer:
                begin
                    if Cust.Get(CodBankStmtLine."Account No.") then
                        CodBankStmtLine.Description := Cust.Name;
                    CodBankStmtLine."Document Type" := CodBankStmtLine."Document Type"::Payment;
                end;
            CodBankStmtLine."Account Type"::Vendor:
                begin
                    if Vend.Get(CodBankStmtLine."Account No.") then
                        CodBankStmtLine.Description := Vend.Name;
                    CodBankStmtLine."Document Type" := CodBankStmtLine."Document Type"::Payment;
                end;
            CodBankStmtLine."Account Type"::"G/L Account":
                if GLAcc.Get(CodBankStmtLine."Account No.") then
                    CodBankStmtLine.Description := GLAcc.Name;
        end;
        if UpdateApplicationAmounts then begin
            CodBankStmtLine.Amount := CodBankStmtLine."Statement Amount";
            if CodBankStmtLine."Currency Code" = '' then
                CodBankStmtLine."Amount (LCY)" := CodBankStmtLine."Statement Amount"
            else
                CodBankStmtLine."Amount (LCY)" := Round(CodBankStmtLine.Amount * CodBankStmtLine."Currency Factor" / 100);
            CodBankStmtLine."Unapplied Amount" := CodBankStmtLine."Unapplied Amount" - CodBankStmtLine.Amount;
        end;
        OnAfterInitCodBankStmtLine(CodBankStmtLine, CodedTrans, AccountType, UpdateApplicationAmounts);
    end;

    local procedure CheckAccountType(BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.SetRange("Bank Account No.", BankAccountNo);
        CODAStatementLine.SetRange("Statement No.", StatementNo);
        CODAStatementLine.SetFilter("Application Status", '%1|%2', CODAStatementLine."Application Status"::Applied, CODAStatementLine."Application Status"::"Partly applied");
        CodBankStmtLine.SetFilter("Statement Amount", '<>%1', 0);
        if CODAStatementLine.FindSet() then
            repeat
                case CODAStatementLine."Account Type" of
                    CODAStatementLine."Account Type"::"G/L Account":
                        GetGLAccount(CODAStatementLine."Account No.");
                    CODAStatementLine."Account Type"::Customer:
                        GetCustomerAccount(CODAStatementLine."Account No.");
                    CODAStatementLine."Account Type"::Vendor:
                        GetVendorAccount(CODAStatementLine."Account No.");
                end;
            until CODAStatementLine.Next() = 0;
    end;

    local procedure GetGLAccount(AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        GLAccount.CheckGLAcc();
    end;

    local procedure GetCustomerAccount(AccountNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(AccountNo);
        if Customer.Blocked <> Customer.Blocked::All then
            exit;

        Customer.CustBlockedErrorMessage(Customer, true)
    end;

    local procedure GetVendorAccount(AccountNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(AccountNo);
        if Vendor.Blocked = Vendor.Blocked::" " then
            exit;

        Vendor.VendBlockedErrorMessage(Vendor, true)
    end;

    local procedure CheckCustLedgEntry(CustLedgEntry2: Record "Cust. Ledger Entry"; Found: Integer): Boolean
    var
        StatementMessage: Text;
    begin
        if Found = 1 then
            exit(true);

        if CustLedgEntry2."Payment Reference" = '' then
            exit(false);

        StatementMessage := CopyStr(CodBankStmtLine."Statement Message", 1, StrLen(CustLedgEntry2."Payment Reference"));
        if StatementMessage = '' then
            exit(false);

        if CustLedgEntry2."Payment Reference" = StatementMessage then
            exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCodBankStmtLine(var CodBankStmtLine: Record "CODA Statement Line"; TransactionCoding: Record "Transaction Coding"; AccountType: Integer; UpdateApplicationAmounts: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSearchVendor(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; var CODAStatementLine: Record "CODA Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDefaultPosting(var CODAStatementLine: Record "CODA Statement Line"; TransactionCoding: Record "Transaction Coding")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeTransferCodBankStmtLines(var CODAStatementLine: Record "CODA Statement Line"; var CODAStatementLine2: Record "CODA Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDecodeCustLedgEntryOnBeforePost(var CustLedgerEntry: Record "Cust. Ledger Entry"; var CODAStatementLine: Record "CODA Statement Line"; var DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDecodeVendLedgEntryOnAfterVendLedgEntrySetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; var CODAStatementLine: Record "CODA Statement Line"; var Message: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchCustLedgEntryOnAfterCustLedgEntry2SetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var CODAStatementLine: Record "CODA Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCodBankStmtLinesOnBeforeInitGenJnlLine(var CODAStatementLine: Record "CODA Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCodBankStmtLinesOnBeforeGenJnlLineInsert(var GenJnlLine: Record "Gen. Journal Line"; CodBankStmtLine: Record "CODA Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSearchVendorLedgerEntry(var CODAStatementLine: Record "CODA Statement Line"; var IsHandled: Boolean)
    begin
    end;
}

