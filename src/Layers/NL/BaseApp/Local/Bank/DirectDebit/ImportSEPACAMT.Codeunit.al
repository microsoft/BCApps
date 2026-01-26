// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;

codeunit 11404 "Import SEPA CAMT"
{
    Permissions = TableData "Data Exch." = r;

    trigger OnRun()
    var
        CBGStatement: Record "CBG Statement";
        ImportProtocol: Record "Import Protocol";
        ImportProtocolMgt: Codeunit "Import Protocol Management";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
    begin
        if not ImportProtocolMgt.GetCurrentImportProtocol(ImportProtocol) then
            exit;

        ImportBankStatement(CBGStatement, ImportProtocol."Bank Account No.");

        OnAfterImportBankStatement(CBGStatement, ImportProtocol);

        if ImportProtocol."Automatic Reconciliation" then begin
            CBGStatementReconciliation.SetHideMessages(true);
            CBGStatementReconciliation.MatchCBGStatement(CBGStatement);
        end;
    end;

    var
        ProgressWindowMsg: Label 'Wait while the operation is being completed.';
        TemplateNotFoundErr: Label 'Could not find a %1 of type Bank for %2 %3.';

    [Scope('OnPrem')]
    procedure ImportBankStatement(var CBGStatement: Record "CBG Statement"; BankAccountNo: Code[20])
    var
        DataExchMapping: Record "Data Exch. Mapping";
        DataExch: Record "Data Exch.";
        BankAcc: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        CBGStatementLine: Record "CBG Statement Line";
        ProgressWindow: Dialog;
    begin
        BankAcc.Get(BankAccountNo);
        BankAcc.GetDataExchDef(DataExchDef);

        if not DataExch.ImportToDataExch(DataExchDef) then
            exit;

        ProgressWindow.Open(ProgressWindowMsg);

        CreateCBGStatementTemplate(CBGStatement, CBGStatementLine, BankAcc, DataExch);

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindFirst();

        DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);

        // Run all pre-mapping codeunits
        if DataExchMapping.FindSet() then
            repeat
                if DataExchMapping."Pre-Mapping Codeunit" <> 0 then
                    CODEUNIT.Run(DataExchMapping."Pre-Mapping Codeunit", CBGStatementLine);
            until DataExchMapping.Next() = 0;

        DataExchMapping.Get(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"CBG Statement Line");
        DataExchMapping.TestField("Mapping Codeunit");
        CODEUNIT.Run(DataExchMapping."Mapping Codeunit", CBGStatementLine);

        // Run all post-mapping codeunits
        if DataExchMapping.FindSet() then
            repeat
                if DataExchMapping."Post-Mapping Codeunit" <> 0 then
                    CODEUNIT.Run(DataExchMapping."Post-Mapping Codeunit", CBGStatementLine);
            until DataExchMapping.Next() = 0;

        ProgressWindow.Close();
    end;

    local procedure CreateCBGStatementTemplate(var CBGStatement: Record "CBG Statement"; var CBGStatementLineTemplate: Record "CBG Statement Line"; BankAccount: Record "Bank Account"; DataExch: Record "Data Exch.")
    begin
        CreateCBGStatementHeader(CBGStatement, BankAccount);
        CreateCBGStatementLineTemplate(CBGStatementLineTemplate, CBGStatement, DataExch);
    end;

    local procedure CreateCBGStatementHeader(var CBGStatement: Record "CBG Statement"; BankAccount: Record "Bank Account")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Bank);
        GenJnlTemplate.SetRange("Bal. Account Type", GenJnlTemplate."Bal. Account Type"::"Bank Account");
        GenJnlTemplate.SetRange("Bal. Account No.", BankAccount."No.");

        if not GenJnlTemplate.FindFirst() then
            Error(TemplateNotFoundErr, GenJnlTemplate.TableCaption(), BankAccount.TableCaption(), BankAccount."No.");

        CBGStatement.InitRecord(GenJnlTemplate.Name);
        CBGStatement.Insert(true);
    end;

    local procedure CreateCBGStatementLineTemplate(var CBGStatementLine: Record "CBG Statement Line"; CBGStatement: Record "CBG Statement"; DataExch: Record "Data Exch.")
    begin
        CBGStatementLine.Init();
        CBGStatementLine."Journal Template Name" := CBGStatement."Journal Template Name";
        CBGStatementLine."No." := CBGStatement."No.";
        CBGStatementLine."Data Exch. Entry No." := DataExch."Entry No.";
        CBGStatementLine.InitRecord(CBGStatementLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportBankStatement(var CBGStatement: Record "CBG Statement"; ImportProtocol: Record "Import Protocol")
    begin
    end;
}

