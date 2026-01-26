// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 2000041 "CODA Write Statements"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Gen. Journal Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label '%1 %2 %3 already exists. Replace?';
        Text001: Label '%1 cannot be %2.';
        Text002: Label 'Expected line with sequence number %1, detail number %2.\Returned sequence number %3, detail number %4\on line %5 %6 %7.', Comment = 'Parameters 1-4 are integer numbers, 5 - bank account number, 6 - statement number, 7 - line number.';
        Text005: Label 'Did not expect line with Sequence no. %1, detail number %2\on line %3 %4 %5', Comment = 'Parameters 1 and 2 are integer numbers, 3 - bank account number, 4 - statement number, 5 - line number.';
        Text007: Label '%1 was expected, got %2 on %3 %4 %5.', Comment = 'Parameters 1 and 2 are integer numbers, 3 - bank account number, 4 - statement number, 5 - line number.';
        Text008: Label 'Could not find %1 %2 %3.', Comment = 'Parameter 1 - bank account number, 2 - statement number, 3 - line number.';
        BankAcc: Record "Bank Account";
        Currency: Record Currency;
        CodBankStmtSrcLine: Record "CODA Statement Source Line";
        LastCodBankStmtSrcLine: Record "CODA Statement Source Line";
        CodBankStmtLine: Record "CODA Statement Line";
        LastCodBankStmtLine: Record "CODA Statement Line";
        ArticleIsContinued: Boolean;
        ApplEntryWasSelected: Boolean;
        NextID: Option ,,,Information,"Free Message";
        RefLineNo: Integer;
        DetailCounter: Integer;

    [Scope('OnPrem')]
    procedure SetBankAcc(CodedBankStmtSrcLine: Record "CODA Statement Source Line")
    begin
        BankAcc.Get(CodedBankStmtSrcLine."Bank Account No.");
        if BankAcc."Currency Code" <> '' then
            Currency.Get(BankAcc."Currency Code")
    end;

    [Scope('OnPrem')]
    procedure UpdateBankStatement(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"; var CodedBankStnt: Record "CODA Statement"): Boolean
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        case CodBankStmtSrcLine.ID of
            CodBankStmtSrcLine.ID::"Old Balance":
                begin
                    CodedBankStnt."Balance Last Statement" := CodBankStmtSrcLine.Amount;
                    CodedBankStnt."CODA Statement No." := CodBankStmtSrcLine."CODA Statement No.";
                    CodedBankStnt.Modify(true);
                end;
            CodBankStmtSrcLine.ID::"New Balance":
                begin
                    RefLineNo := 0;
                    CodedBankStnt."Statement Ending Balance" := CodBankStmtSrcLine.Amount;
                    CodedBankStnt.Modify(true);
                end;
            CodBankStmtSrcLine.ID::Header:
                begin
                    CodedBankStnt."Bank Account No." := CodBankStmtSrcLine."Bank Account No.";
                    CodedBankStnt."Statement No." := CodBankStmtSrcLine."Statement No.";
                    CodedBankStnt."Statement Date" := CodBankStmtSrcLine."Transaction Date";
                    if not CodedBankStnt.Insert(true) then
                        if GuiAllowed then begin
                            if Confirm(
                                StrSubstNo(Text000,
                                CodedBankStnt.TableCaption(), CodBankStmtSrcLine."Bank Account No.", CodBankStmtSrcLine."Statement No."))
                            then begin
                                CodBankStmtLine.Reset();
                                CodBankStmtLine.SetRange("Bank Account No.", CodBankStmtSrcLine."Bank Account No.");
                                CodBankStmtLine.SetRange("Statement No.", CodBankStmtSrcLine."Statement No.");
                                CodBankStmtLine.DeleteAll(true);
                                CodedBankStnt.Modify(true);
                            end else
                                exit(false);
                        end else
                            exit(false);
                    Clear(LastCodBankStmtSrcLine);
                    Clear(LastCodBankStmtLine);
                end;
            else
                Error(Text001, CodBankStmtSrcLine.FieldCaption(ID), CodBankStmtSrcLine.ID);
        end;
        CodBankStmtSrcLine.Transferred := true;
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure InsertBankStatementLine(var CodedBankStmtSrcLine: Record "CODA Statement Source Line"; var CodedBankStmtLine: Record "CODA Statement Line")
    begin
        CodBankStmtSrcLine := CodedBankStmtSrcLine;
        InitCBStmtLine();
        case CodBankStmtSrcLine.ID of
            CodBankStmtSrcLine.ID::Movement:
                UpdateMovement();
            CodBankStmtSrcLine.ID::Information:
                UpdateInformation();
            CodBankStmtSrcLine.ID::"Free Message":
                UpdateFreeMessage();
        end;
        CodBankStmtLine.Modify();
        CodBankStmtSrcLine.Transferred := true;
        LastCodBankStmtSrcLine := CodBankStmtSrcLine;
        LastCodBankStmtLine := CodBankStmtLine;
        CodedBankStmtSrcLine := CodBankStmtSrcLine;
        CodedBankStmtLine := CodBankStmtLine;
    end;

    local procedure InitCBStmtLine()
    begin
        if (LastCodBankStmtSrcLine.ID = LastCodBankStmtSrcLine.ID::"New Balance") and
           (CodBankStmtSrcLine.ID in [CodBankStmtSrcLine.ID::Movement, CodBankStmtSrcLine.ID::Information, CodBankStmtSrcLine.ID::"Free Message"])
        then begin
            if (ArticleIsContinued and
                (LastCodBankStmtSrcLine."Sequence No." <> CodBankStmtSrcLine."Sequence No.") and
                (LastCodBankStmtSrcLine."Detail No." <> CodBankStmtSrcLine."Detail No."))
            then
                Error(
                  Text002,
                  LastCodBankStmtSrcLine."Sequence No.", LastCodBankStmtSrcLine."Detail No.",
                  CodBankStmtSrcLine."Sequence No.", CodBankStmtSrcLine."Detail No.",
                  CodBankStmtSrcLine."Bank Account No.", CodBankStmtSrcLine."Statement No.", CodBankStmtSrcLine."Line No.");

            if (not ArticleIsContinued and
                (LastCodBankStmtSrcLine."Sequence No." = CodBankStmtSrcLine."Sequence No.") and
                (LastCodBankStmtSrcLine."Detail No." = CodBankStmtSrcLine."Detail No."))
            then
                Error(
                  Text005,
                  CodBankStmtSrcLine."Sequence No.", CodBankStmtSrcLine."Detail No.",
                  CodBankStmtSrcLine."Bank Account No.", CodBankStmtSrcLine."Statement No.", CodBankStmtSrcLine."Line No.");

            if (NextID <> 0) and (NextID <> CodBankStmtSrcLine.ID) then
                Error(Text007,
                  NextID, CodBankStmtSrcLine.ID, CodBankStmtSrcLine."Bank Account No.", CodBankStmtSrcLine."Statement No.", CodBankStmtSrcLine."Line No.");
        end;

        CodBankStmtLine.Init();
        CodBankStmtLine."Bank Account No." := CodBankStmtSrcLine."Bank Account No.";
        CodBankStmtLine."Statement No." := CodBankStmtSrcLine."Statement No.";
        if (CodBankStmtSrcLine.ID = CodBankStmtSrcLine.ID::"Free Message") or (CodBankStmtSrcLine."Item Code" = '1') then begin
            CodBankStmtLine.ID := CodBankStmtSrcLine.ID;
            CodBankStmtLine."Statement Line No." := LastCodBankStmtLine."Statement Line No." + 10000;
            CodBankStmtLine."Document No." := StrSubstNo('%1/%2', CopyStr(CodBankStmtSrcLine.Data, 122, 3), CodBankStmtSrcLine."Sequence No.");
            CodBankStmtLine."Currency Code" := BankAcc."Currency Code";
            OnBeforeCodBankStmtLineInsert(CodBankStmtSrcLine, CodBankStmtLine);
            CodBankStmtLine.Insert();
        end else
            CodBankStmtLine."Statement Line No." := LastCodBankStmtLine."Statement Line No.";
        if not CodBankStmtLine.Find() then
            Error(Text008,
              CodBankStmtSrcLine."Bank Account No.", CodBankStmtSrcLine."Statement No.", CodBankStmtLine."Statement Line No.");
        // Link codes only with Type 2, 3, 4.
        if CodBankStmtSrcLine.ID in [CodBankStmtSrcLine.ID::Movement, CodBankStmtSrcLine.ID::Information, CodBankStmtSrcLine.ID::"Free Message"] then begin
            ArticleIsContinued := CodBankStmtSrcLine."Sequence Code" = 1;
            if CodBankStmtSrcLine."Binding Code" = 0 then
                NextID := 0
            else
                NextID := CodBankStmtSrcLine."Binding Code" + 2
        end
    end;

    local procedure UpdateMovement()
    begin
        case CodBankStmtSrcLine."Item Code" of
            '1':
                begin
                    if CodBankStmtSrcLine."Detail No." = 0 then begin
                        CodBankStmtLine.Type := CodBankStmtLine.Type::Global;
                        RefLineNo := CodBankStmtLine."Statement Line No.";
                        DetailCounter := -1
                    end else begin
                        CodBankStmtLine.Type := CodBankStmtLine.Type::Detail;
                        CodBankStmtLine."Attached to Line No." := RefLineNo;
                        CodBankStmtLine."Document No." := CodBankStmtLine."Document No." + Format(DetailCounter);
                        DetailCounter := DetailCounter - 1;
                        OnUpdateMovementOnAfterDetailCounterChange(CodBankStmtLine, DetailCounter);
                    end;
                    CodBankStmtLine."Bank Reference No." := CodBankStmtSrcLine."Bank Reference No.";
                    CodBankStmtLine."Ext. Reference No." := CodBankStmtSrcLine."Ext. Reference No.";
                    CodBankStmtLine."Statement Amount" := CodBankStmtSrcLine.Amount;
                    CodBankStmtLine."Unapplied Amount" := CodBankStmtSrcLine.Amount;
                    CodBankStmtLine."Transaction Date" := CodBankStmtSrcLine."Transaction Date";
                    CodBankStmtLine."Posting Date" := CodBankStmtSrcLine."Posting Date";
                    CodBankStmtLine."Transaction Type" := CodBankStmtSrcLine."Transaction Type";
                    CodBankStmtLine."Transaction Family" := CodBankStmtSrcLine."Transaction Family";
                    CodBankStmtLine.Transaction := CodBankStmtSrcLine.Transaction;
                    CodBankStmtLine."Transaction Category" := CodBankStmtSrcLine."Transaction Category";
                    CodBankStmtLine."Message Type" := CodBankStmtSrcLine."Message Type";
                    CodBankStmtLine."Type Standard Format Message" := CodBankStmtSrcLine."Type Standard Format Message";
                    CodBankStmtLine."Statement Message" := CodBankStmtSrcLine."Statement Message";
                end;
            '2':
                begin
                    CodBankStmtLine."Statement Message" := CodBankStmtLine."Statement Message" + CodBankStmtSrcLine."Statement Message";
                    CodBankStmtLine."Customer Reference" := DelChr(CodBankStmtSrcLine."Customer Reference", '>', ' ');
                    CodBankStmtLine."SWIFT Address" := CodBankStmtSrcLine."SWIFT Address";
                    CodBankStmtLine."Original Transaction Currency" := CodBankStmtSrcLine."Original Transaction Currency";
                    CodBankStmtLine."Original Transaction Amount" := CodBankStmtSrcLine."Original Transaction Amount"
                end;
            '3':
                begin
                    CodBankStmtLine."Statement Message" := CodBankStmtLine."Statement Message" + CodBankStmtSrcLine."Statement Message";
                    CodBankStmtLine."Bank Account No. Other Party" := CodBankStmtSrcLine."Bank Account No. Other Party";
                    CodBankStmtLine."Internal Codes Other Party" := CodBankStmtSrcLine."Internal Codes Other Party";
                    CodBankStmtLine."Ext. Acc. No. Other Party" := CodBankStmtSrcLine."Ext. Acc. No. Other Party";
                    CodBankStmtLine."Name Other Party" := DelChr(CodBankStmtSrcLine."Name Other Party", '>', ' ');
                    CodBankStmtLine."Address Other Party" := DelChr(CodBankStmtSrcLine."Address Other Party", '>', ' ');
                    CodBankStmtLine."City Other Party" := DelChr(CodBankStmtSrcLine."City Other Party", '>', ' ');
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateInformation()
    var
        CodBankStmtLine2: Record "CODA Statement Line";
        Overflow: Integer;
    begin
        case CodBankStmtSrcLine."Item Code" of
            '1':
                begin
                    CodBankStmtLine."Bank Reference No." := CodBankStmtSrcLine."Bank Reference No.";
                    CodBankStmtLine."Ext. Reference No." := CodBankStmtSrcLine."Ext. Reference No.";
                    CodBankStmtLine."Transaction Type" := CodBankStmtSrcLine."Transaction Type";
                    CodBankStmtLine."Transaction Family" := CodBankStmtSrcLine."Transaction Family";
                    CodBankStmtLine.Transaction := CodBankStmtSrcLine.Transaction;
                    CodBankStmtLine."Transaction Category" := CodBankStmtSrcLine."Transaction Category";
                    CodBankStmtLine."Message Type" := CodBankStmtSrcLine."Message Type";
                    CodBankStmtLine."Type Standard Format Message" := CodBankStmtSrcLine."Type Standard Format Message";
                    CodBankStmtLine."Statement Message" := CodBankStmtSrcLine."Statement Message";
                    // Max. Length = 73
                end;
            '2':
                begin
                    CodBankStmtLine."Statement Message" := CodBankStmtLine."Statement Message" + CodBankStmtSrcLine."Statement Message";
                    // Max. Length = 105
                    SetBankAcc(CodBankStmtSrcLine);
                    if BankAcc."Version Code" = '2' then begin
                        CodBankStmtLine2.Get(CodBankStmtSrcLine."Bank Account No.", CodBankStmtSrcLine."Statement No.", CodBankStmtLine."Statement Line No.");
                        CodBankStmtLine2.Find('<');
                        CodBankStmtLine2."Address Other Party" := CodBankStmtSrcLine."Address Other Party";
                        CodBankStmtLine2."City Other Party" := CodBankStmtSrcLine."City Other Party";
                        CodBankStmtLine2.Modify();
                    end;
                end;
            '3':
                begin
                    Overflow :=
                      StrLen(CodBankStmtLine."Statement Message" + CodBankStmtSrcLine."Statement Message") -
                      MaxStrLen(CodBankStmtLine."Statement Message");
                    CodBankStmtLine."Statement Message" :=
                      CopyStr(CodBankStmtLine."Statement Message" + CodBankStmtSrcLine."Statement Message", 1, MaxStrLen(CodBankStmtLine."Statement Message"));
                    // Max. Length = 90
                    if Overflow > 0 then
                        CodBankStmtLine."Statement Message (cont.)" :=
                          CopyStr(CodBankStmtSrcLine."Statement Message", StrLen(CodBankStmtSrcLine."Statement Message") + 1 - Overflow);
                end;
        end;

        CodBankStmtLine."Attached to Line No." := RefLineNo;
    end;

    [Scope('OnPrem')]
    procedure UpdateFreeMessage()
    begin
        CodBankStmtLine."Bank Reference No." := CodBankStmtSrcLine."Bank Reference No.";
        CodBankStmtLine."Ext. Reference No." := CodBankStmtSrcLine."Ext. Reference No.";
        CodBankStmtLine."Transaction Family" := CodBankStmtSrcLine."Transaction Family";
        CodBankStmtLine.Transaction := CodBankStmtSrcLine.Transaction;
        CodBankStmtLine."Message Type" := CodBankStmtSrcLine."Message Type";
        CodBankStmtLine."Type Standard Format Message" := CodBankStmtSrcLine."Type Standard Format Message";
        CodBankStmtLine."Statement Message" := DelChr(CodBankStmtSrcLine."Statement Message", '>', ' ');
        CodBankStmtLine."Attached to Line No." := RefLineNo;
    end;

    [Scope('OnPrem')]
    procedure Apply(var CodedBankStmtLine: Record "CODA Statement Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        CODAWriteStatements: Codeunit "CODA Write Statements";
        Applied: Boolean;
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", CodedBankStmtLine."Posting Date");
        GenJnlLine.Validate("Document No.", CodedBankStmtLine."Document No.");
        GenJnlLine.Validate("Account Type", CodedBankStmtLine."Account Type");
        GenJnlLine.Validate("Account No.", CodedBankStmtLine."Account No.");
        GenJnlLine.Validate(Amount, -CodedBankStmtLine."Statement Amount");
        OnApplyOnBeforeGenJnlLineInsert(GenJnlLine, CodedBankStmtLine);
        if not GenJnlLine.Insert() then
            GenJnlLine.Modify();
        Commit();
        // show error message when Account Type is G/L Account
        BindSubscription(CODAWriteStatements);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJnlLine);
        UnbindSubscription(CODAWriteStatements);
        Applied := IsApplied(GenJnlLine, CodedBankStmtLine."Applies-to ID", CODAWriteStatements.WasEntrySelected());
        // Make sure that "Applies-to ID" value for the CODA Statement Line is zero if the overall result is not applied
        if not Applied then
            GenJnlLine."Applies-to ID" := '';
        if Applied then begin
            if CodedBankStmtLine."Account No." = '' then
                CodedBankStmtLine.Validate("Account No.", GenJnlLine."Account No.");
            CodedBankStmtLine."Applies-to ID" := GenJnlLine."Applies-to ID";
            CodedBankStmtLine.Validate("Unapplied Amount", CodedBankStmtLine."Unapplied Amount" - CodedBankStmtLine.Amount);
        end else begin
            CodedBankStmtLine.Validate("Applies-to ID", GenJnlLine."Applies-to ID");
            CodedBankStmtLine.Validate("Unapplied Amount");
        end;
        CodedBankStmtLine.Modify(true);
        GenJnlLine.Get('', '', 0);
        GenJnlLine.Delete();
    end;

    procedure RunApply(var CodedBankStmtLine: Record "CODA Statement Line")
    begin
        Apply(CodedBankStmtLine);
    end;

    [Scope('OnPrem')]
    procedure WasEntrySelected(): Boolean
    begin
        exit(ApplEntryWasSelected);
    end;

    local procedure IsApplied(var GenJnlLine: Record "Gen. Journal Line"; StatementLineAppliesToID: Code[50]; WasEntrySelected: Boolean): Boolean
    begin
        if (GenJnlLine."Applies-to ID" <> '') and WasEntrySelected then
            // If user set applies-to ID and press OK in the Apply Customer/Vendor Ledger Entries page then application is successfull
            exit(true);

        // User has cancelled the application process by closing the "Apply Customer/Vendor Ledger Entries page" or pressing cancel
        if (StatementLineAppliesToID <> '') and (GenJnlLine."Applies-to ID" <> '') then
            // If User previously made an application (first condition) and hasn't blanked the "Applies-to ID" (second condition during the existing application
            // then check if there are still some entries applied to keep the CODA statement lined applied
            exit(IsEntryApplied(GenJnlLine));
        exit(false);
    end;

    local procedure IsEntryApplied(GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        case GenJournalLine."Account Type" of
            GenJournalLine."Account Type"::Customer:
                exit(IsAnyCustLedgEntryApplied(GenJournalLine));
            GenJournalLine."Account Type"::Vendor:
                exit(IsAnyVendLedgEntryApplied(GenJournalLine));
            else begin
                GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
                exit(GenJournalLine."Applies-to ID" <> '');
            end;
        end
    end;

    local procedure IsAnyCustLedgEntryApplied(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
        exit(not CustLedgerEntry.IsEmpty());
    end;

    local procedure IsAnyVendLedgEntryApplied(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
        exit(not VendorLedgerEntry.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCodBankStmtLineInsert(var CODAStatementSourceLine: Record "CODA Statement Source Line"; var CODAStatementLine: Record "CODA Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateMovementOnAfterDetailCounterChange(var CODAStatementLine: Record "CODA Statement Line"; var DetailCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyOnBeforeGenJnlLineInsert(var GenJnlLine: Record "Gen. Journal Line"; CodedBankStmtLine: Record "CODA Statement Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Apply", 'OnAfterSelectCustLedgEntry', '', false, false)]
    local procedure OnAfterSelectCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean)
    begin
        ApplEntryWasSelected := Selected;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Apply", 'OnAfterSelectVendLedgEntry', '', false, false)]
    local procedure OnAfterSelectVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean)
    begin
        ApplEntryWasSelected := Selected;
    end;
}

