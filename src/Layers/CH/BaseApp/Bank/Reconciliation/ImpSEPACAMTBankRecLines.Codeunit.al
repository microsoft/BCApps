// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.IO;

/// <summary>
/// Imports bank reconciliation lines from SEPA CAMT format files.
/// Processes structured payment data and creates reconciliation line entries.
/// </summary>
codeunit 1261 "Imp. SEPA CAMT Bank Rec. Lines"
{
    TableNo = "Bank Acc. Reconciliation Line";

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        InitNodeText();
        InitBalTypeDescriptor();
        DataExch.Get(Rec."Data Exch. Entry No.");
        RecRef.GetTable(Rec);
        RunPreProcess(Rec);
        ProcessDataExch.ProcessAllLinesColumnMapping(DataExch, RecRef);
        RunPostProcess(Rec);
        OnAfterOnRun(Rec, RecRef);
    end;

    var
        IBANTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/IBAN', Locked = true;
        BankIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/Othr/Id', Locked = true;
        CurrencyTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt[@Ccy]', Locked = true;
        BalTypeTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd', Locked = true;
        ClosingBalTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt', Locked = true;
        StatementDateTxt: Label '/Document/BkToCstmrStmt/Stmt/CreDtTm', Locked = true;
        CrdDbtIndTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/CdtDbtInd', Locked = true;
        IBAN054Txt: Label '/Document/BkToCstmrDbtCdtNtfctn/Ntfctn/Acct/Id/IBAN', Locked = true;
        BankID054Txt: Label '/Document/BkToCstmrDbtCdtNtfctn/Ntfctn/Acct/Id/Othr/Id', Locked = true;
        Currency054Txt: Label '/Document/BkToCstmrDbtCdtNtfctn/Ntfctn/Bal/Amt[@Ccy]', Locked = true;
        BalType054Txt: Label '/Document/BkToCstmrDbtCdtNtfctn/Ntfctn/Bal/Tp/CdOrPrtry/Cd', Locked = true;
        ClosingBal054Txt: Label '/Document/BkToCstmrDbtCdtNtfctn/Ntfctn/Bal/Amt', Locked = true;
        StatementDate054Txt: Label '/Document/BkToCstmrDbtCdtNtfctn/Ntfctn/CreDtTm', Locked = true;
        CrdDbtInd054Txt: Label '/Document/BkToCstmrDbtCdtNtfctn/Ntfctn/Bal/CdtDbtInd', Locked = true;
        ImportType: Option W1,CH053,CH054;
        IBANNodeText: Text;
        BankIDNodeText: Text;
        CurrencyNodeText: Text;
        BalTypeNodeText: Text;
        ClosingBalNodeText: Text;
        StatementDateNodeText: Text;
        CrdDbtIndNodeText: Text;
        BalTypeDescriptorText: Text;

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
        PrePostProcessXMLImport.PreProcessFile(DataExch, StatementDateNodeText);
        PrePostProcessXMLImport.PreProcessBankAccount(
          DataExch, BankAccReconciliationLine."Bank Account No.", IBANNodeText, BankIDNodeText, CurrencyNodeText);
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
        if BalTypeDescriptorText <> '' then
            PrePostProcessXMLImport.PostProcessStatementEndingBalance(DataExch, RecRef,
              BankAccReconciliation.FieldNo("Statement Ending Balance"),
              BalTypeDescriptorText, BalTypeNodeText, ClosingBalNodeText, CrdDbtIndNodeText, 4);
        PrePostProcessXMLImport.PostProcessStatementDate(DataExch, RecRef, BankAccReconciliation.FieldNo("Statement Date"),
          StatementDateNodeText);
    end;

    [Scope('OnPrem')]
    procedure SetImportType(NewImportType: Option W1,CH053,CH054)
    begin
        ImportType := NewImportType;
    end;

    [Scope('OnPrem')]
    procedure InitNodeText()
    begin
        if ImportType = ImportType::CH054 then begin
            IBANNodeText := IBAN054Txt;
            BankIDNodeText := BankID054Txt;
            CurrencyNodeText := Currency054Txt;
            BalTypeNodeText := BalType054Txt;
            ClosingBalNodeText := ClosingBal054Txt;
            StatementDateNodeText := StatementDate054Txt;
            CrdDbtIndNodeText := CrdDbtInd054Txt;
        end else begin
            IBANNodeText := IBANTxt;
            BankIDNodeText := BankIDTxt;
            CurrencyNodeText := CurrencyTxt;
            BalTypeNodeText := BalTypeTxt;
            ClosingBalNodeText := ClosingBalTxt;
            StatementDateNodeText := StatementDateTxt;
            CrdDbtIndNodeText := CrdDbtIndTxt;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitBalTypeDescriptor()
    begin
        case ImportType of
            ImportType::W1:
                BalTypeDescriptorText := 'CLBD';
            ImportType::CH053:
                BalTypeDescriptorText := 'CLBD';
            ImportType::CH054:
                BalTypeDescriptorText := '';
        end;
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

