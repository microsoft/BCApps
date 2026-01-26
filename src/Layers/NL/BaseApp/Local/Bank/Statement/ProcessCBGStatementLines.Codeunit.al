// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using System.IO;

codeunit 11405 "Process CBG Statement Lines"
{
    TableNo = "CBG Statement Line";

    trigger OnRun()
    var
        CBGStatement: Record "CBG Statement";
        DataExch: Record "Data Exch.";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        CBGStatement.Get(Rec."Journal Template Name", Rec."No.");
        DataExch.Get(Rec."Data Exch. Entry No.");

        PrePostProcessXMLImport.PreProcessBankAccount(DataExch, CBGStatement."Account No.", IBANTxt, BankAccountTxt, CurrencyTxt);

        RecRef.GetTable(Rec);
        ProcessDataExch.ProcessAllLinesColumnMapping(DataExch, RecRef);
        PostProcessCBGStatement(DataExch, CBGStatement);
    end;

    var
        PrePostProcessXMLImport: Codeunit "Pre & Post Process XML Import";
        IBANTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/IBAN', Locked = true;
        BankAccountTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/Othr/Id', Locked = true;
        CurrencyTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt[@Ccy]', Locked = true;
        BalTypeTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd', Locked = true;
        ClosingBalTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt', Locked = true;
        StatementDateTxt: Label '/Document/BkToCstmrStmt/Stmt/CreDtTm', Locked = true;
        CrdDbtIndTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/CdtDbtInd', Locked = true;

    local procedure PostProcessCBGStatement(DataExch: Record "Data Exch."; CBGStatement: Record "CBG Statement")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CBGStatement);
        PrePostProcessXMLImport.PostProcessStatementDate(DataExch, RecRef, CBGStatement.FieldNo(Date), StatementDateTxt);
        PrePostProcessXMLImport.PostProcessStatementEndingBalance(DataExch, RecRef, CBGStatement.FieldNo("Closing Balance"),
          'CLBD', BalTypeTxt, ClosingBalTxt, CrdDbtIndTxt, 4);
    end;
}

