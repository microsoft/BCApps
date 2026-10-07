// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;

/// <summary>
/// Imports SEPA CAMT (Customer Account Management) bank statement files into general journal lines.
/// Processes XML-formatted bank statements, extracts transaction details, and populates journal entries
/// for automated bank reconciliation and payment processing.
/// </summary>
codeunit 1260 "Imp. SEPA CAMT Gen. Jnl."
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        DataExch.Get(Rec."Data Exch. Entry No.");
        PreProcess(Rec);
        RecRef.GetTable(Rec);
        ProcessDataExch.ProcessAllLinesColumnMapping(DataExch, RecRef);
    end;

    var
        StatementIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Id', Locked = true;
        IBANTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/IBAN', Locked = true;
        BankIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/Othr/Id', Locked = true;
        CurrencyTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt[@Ccy]', Locked = true;

    local procedure PreProcess(var GenJnlLine: Record "Gen. Journal Line")
    var
        DataExch: Record "Data Exch.";
        GenJnlBatch: Record "Gen. Journal Batch";
        PrePostProcessXMLImport: Codeunit "Pre & Post Process XML Import";
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        DataExch.Get(GenJnlLine."Data Exch. Entry No.");
        PrePostProcessXMLImport.PreProcessFile(DataExch, StatementIDTxt);
        case GenJnlLine."Bal. Account Type" of
            GenJnlLine."Bal. Account Type"::"Bank Account":
                PrePostProcessXMLImport.PreProcessBankAccount(DataExch, GenJnlLine."Bal. Account No.", IBANTxt, BankIDTxt, CurrencyTxt);
            GenJnlLine."Bal. Account Type"::"G/L Account":
                PrePostProcessXMLImport.PreProcessGLAccount(DataExch, GenJnlLine, CurrencyTxt);
        end;
    end;
}

