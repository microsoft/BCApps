// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 2000002 "Check Domestic Payments"
{
    TableNo = "Payment Journal Line";

    trigger OnRun()
    begin
        TempBankAcc.DeleteAll();
        GLSetup.Get();
        CheckPaymJnlLine.ClearErrorLog();

        // Check if there is anything to export and exit if not
        if Rec.Count = 0 then begin
            CheckPaymJnlLine.InsertErrorLog(Text003);
            CheckPaymJnlLine.ShowErrorLog();
        end;

        if Rec.FindSet() then
            repeat
                CheckOwnBankAccount(Rec);
                CheckBenBankAccountNumber(Rec);
                CheckCurrencyEuro(Rec);
                if Rec."Bank Account" <> '' then
                    if not TempBankAcc.Get(Rec."Bank Account") then begin
                        TempBankAcc."No." := Rec."Bank Account";
                        TempBankAcc.Insert();
                    end;
            until Rec.Next() = 0;

        // Check if exactly one bank account is used
        CheckForOnlyOneBankAcc();

        CheckPaymJnlLine.ShowErrorLog();
    end;

    var
        Text000: Label 'Beneficiary bank account number %1 did not pass the MOD97 test in payment journal line number %2.';
        Text001: Label 'The beneficiary bank account number cannot be blank in payment journal line  number %1.';
        Text002: Label 'You can only specify one valid bank account in the filter for this export protocol.';
        TempBankAcc: Record "Bank Account" temporary;
        GLSetup: Record "General Ledger Setup";
        Text003: Label 'There are no payment records to be processed.';
        Text004: Label 'The currency is not euro in payment journal line number %1.';
        BankAcc: Record "Bank Account";
        CheckPaymJnlLine: Codeunit CheckPaymJnlLine;
        PmtJnlManagement: Codeunit PmtJrnlManagement;
        Text005: Label 'Bank account number %1 for bank account code %2 in payment journal line number %3 did not pass the MOD97 test.', Comment = 'Parameter 1 - bank account number, 2 - bank account code, 3 - integer number.';
        Text006: Label 'Bank Branch No. for Bank Account No. %1 needs to be filled in.';
        Text007: Label 'The bank account number cannot be blank in payment journal line number %1.';

    [Scope('OnPrem')]
    procedure CheckBenBankAccountNumber(var PmtJnlLine: Record "Payment Journal Line")
    begin
        // Check if BBAN is blank
        if PmtJnlLine."Beneficiary Bank Account No." = '' then
            CheckPaymJnlLine.InsertErrorLog(StrSubstNo(Text001, PmtJnlLine."Line No."))
        else
            // MOD97 test for BBAN
            if not PmtJnlManagement.Mod97Test(PmtJnlLine."Beneficiary Bank Account No.") then
                CheckPaymJnlLine.InsertErrorLog(
                  StrSubstNo(Text000, PmtJnlLine."Beneficiary Bank Account No.", PmtJnlLine."Line No."));
    end;

    [Scope('OnPrem')]
    procedure CheckOwnBankAccount(var PmtJnlLine: Record "Payment Journal Line")
    begin
        if PmtJnlLine."Bank Account" = '' then
            CheckPaymJnlLine.InsertErrorLog(StrSubstNo(Text007, PmtJnlLine."Line No."))
        else begin
            // MOD97 test for BAN
            GetBankAccount(PmtJnlLine."Bank Account");
            if not PmtJnlManagement.Mod97Test(BankAcc."Bank Account No.") then
                CheckPaymJnlLine.InsertErrorLog(
                  StrSubstNo(Text005, BankAcc."Bank Account No.", PmtJnlLine."Bank Account", PmtJnlLine."Line No."));
            if BankAcc."Bank Branch No." = '' then
                CheckPaymJnlLine.InsertErrorLog(StrSubstNo(Text006, BankAcc."No."));
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckForOnlyOneBankAcc()
    begin
        if TempBankAcc.Count <> 1 then
            CheckPaymJnlLine.InsertErrorLog(Text002);
    end;

    [Scope('OnPrem')]
    procedure CheckCurrencyEuro(var PmtJnlLine: Record "Payment Journal Line")
    begin
        // Check whether the currency being used is Euro
        if PmtJnlLine."Currency Code" <> GLSetup."Currency Euro" then
            CheckPaymJnlLine.InsertErrorLog(StrSubstNo(Text004, PmtJnlLine."Line No."));
    end;

    [Scope('OnPrem')]
    procedure GetBankAccount(BankAccCode: Code[20])
    begin
        if (BankAcc."No." <> BankAccCode) and (BankAccCode <> '') then
            BankAcc.Get(BankAccCode);
    end;
}

