// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.IO;

codeunit 1261 "Imp. SEPA CAMT Bank Rec. Lines"
{
    TableNo = "Bank Acc. Reconciliation Line";

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        DataExch.Get(Rec."Data Exch. Entry No.");
        RecRef.GetTable(Rec);
        RunPreProcess(Rec);
        ProcessDataExch.ProcessAllLinesColumnMapping(DataExch, RecRef);
        RunPostProcess(Rec);
        OnAfterOnRun(Rec, RecRef);
    end;

    var
        StatementIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Id', Locked = true;
        IBANTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/IBAN', Locked = true;
        BankIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/Othr/Id', Locked = true;
        CurrencyTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt[@Ccy]', Locked = true;
        BalTypeTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd', Locked = true;
        ClosingBalTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt', Locked = true;
        StatementDateTxt: Label '/Document/BkToCstmrStmt/Stmt/CreDtTm', Locked = true;
        CrdDbtIndTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/CdtDbtInd', Locked = true;

    procedure RunPreProcess(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        DataExch: Record "Data Exch.";
        PrePostProcessXMLImport: Codeunit "Pre & Post Process XML Import";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePreProcess(BankAccReconciliationLine, IsHandled);
        if IsHandled then
            exit;

        DataExch.Get(BankAccReconciliationLine."Data Exch. Entry No.");
        PrePostProcessXMLImport.PreProcessFile(DataExch, StatementIDTxt);
        PrePostProcessXMLImport.PreProcessBankAccount(
          DataExch, BankAccReconciliationLine."Bank Account No.", IBANTxt, BankIDTxt, CurrencyTxt);
    end;

    procedure RunPostProcess(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        DataExch: Record "Data Exch.";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PrePostProcessXMLImport: Codeunit "Pre & Post Process XML Import";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostProcess(BankAccReconciliationLine, IsHandled);
        if IsHandled then
            exit;

        DataExch.Get(BankAccReconciliationLine."Data Exch. Entry No.");
        BankAccReconciliation.Get(
          BankAccReconciliationLine."Statement Type",
          BankAccReconciliationLine."Bank Account No.",
          BankAccReconciliationLine."Statement No.");

        RecRef.GetTable(BankAccReconciliation);
        PrePostProcessXMLImport.PostProcessStatementEndingBalance(DataExch, RecRef,
          BankAccReconciliation.FieldNo("Statement Ending Balance"), 'CLBD', BalTypeTxt, ClosingBalTxt, CrdDbtIndTxt, 4);
        PrePostProcessXMLImport.PostProcessStatementDate(DataExch, RecRef, BankAccReconciliation.FieldNo("Statement Date"),
          StatementDateTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreProcess(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostProcess(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    begin
    end;
}

