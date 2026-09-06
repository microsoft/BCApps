// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.DirectDebit;
using System.IO;

codeunit 11345 "Imp. SEPA CAMT Bank Rec. NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Imp. SEPA CAMT Bank Rec. Lines", 'OnBeforePreProcess', '', false, false)]
    local procedure OnBeforePreProcess(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    var
        DataExch: Record "Data Exch.";
        ImpBankTransDataUpdates: Codeunit "Imp. Bank Trans. Data Updates";
        PrePostProcessXMLImport: Codeunit "Pre & Post Process XML Import";
    begin
        if IsHandled then
            exit;

        IsHandled := true;
        DataExch.Get(BankAccReconciliationLine."Data Exch. Entry No.");
        PrePostProcessXMLImport.PreProcessFile(DataExch, StatementIDTxt);
        PrePostProcessXMLImport.PreProcessBankAccount(
          DataExch, BankAccReconciliationLine."Bank Account No.", IBANTxt, BankIDTxt, CurrencyTxt);
        ImpBankTransDataUpdates.InheritDataFromParentToChildNodes(BankAccReconciliationLine."Data Exch. Entry No.");
    end;

    var
        StatementIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Id', Locked = true;
        IBANTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/IBAN', Locked = true;
        BankIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/Othr/Id', Locked = true;
        CurrencyTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt[@Ccy]', Locked = true;
}
