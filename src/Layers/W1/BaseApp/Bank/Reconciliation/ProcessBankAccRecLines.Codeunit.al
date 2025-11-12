// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using System.IO;
using System.Telemetry;

codeunit 1248 "Process Bank Acc. Rec Lines"
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Bank Acc. Reconciliation Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        DataExch.Get(Rec."Data Exch. Entry No.");
        RecRef.GetTable(Rec);
        ProcessDataExch.ProcessAllLinesColumnMapping(DataExch, RecRef);
    end;

    var
        ProgressWindowMsg: Label 'Please wait while the operation is being completed.';
        BankAccountRecImportedBankStatementLinesCountMsg: Label 'Number of imported lines in bank statement: %1', Locked = true;
        BankAccountRecCategoryLbl: Label 'AL Bank Account Rec', Locked = true;
        PaymentRecCategoryLbl: Label 'AL Payment Reconciliation', Locked = true;
        InvalidFileFormatErr: Label 'The format of the chosen file is incompatible with the bank statement import format %2 specified on bank account %1. You must choose another file or change the bank statement import format on bank account %1.', Comment = '%1 - bank account code, %2 - name of a bank statement import format';
        BankAccountNo: Code[20];

    procedure ImportBankStatement(BankAccRecon: Record "Bank Acc. Reconciliation"; DataExch: Record "Data Exch."): Boolean
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBankAccReconLine: Record "Bank Acc. Reconciliation Line" temporary;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ProgressWindow: Dialog;
        NumberOfLinesImported: Integer;
        StartDateTime: DateTime;
        FinishDateTime: DateTime;
    begin
        case BankAccRecon."Statement Type" of
            BankAccRecon."Statement Type"::"Bank Reconciliation":
                FeatureTelemetry.LogUptake('0000JLJ', BankAccRecon.GetBankReconciliationTelemetryFeatureName(), Enum::"Feature Uptake Status"::Used);
            BankAccRecon."Statement Type"::"Payment Application":
                FeatureTelemetry.LogUptake('0000KMD', BankAccRecon.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::Used);
        end;
        PrepareDataExch(BankAccRecon, DataExch, DataExchDef);

        if not DataExch.ImportToDataExch(DataExchDef) then
            exit(false);

        StartDateTime := CurrentDateTime();
        ProgressWindow.Open(ProgressWindowMsg);

        CreateBankAccRecLineTemplate(TempBankAccReconLine, BankAccRecon, DataExch);
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindFirst();

        DataExchMapping.Get(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Bank Acc. Reconciliation Line");

        if DataExchMapping."Pre-Mapping Codeunit" <> 0 then
            CODEUNIT.Run(DataExchMapping."Pre-Mapping Codeunit", TempBankAccReconLine);

        DataExchMapping.TestField("Mapping Codeunit");
        CODEUNIT.Run(DataExchMapping."Mapping Codeunit", TempBankAccReconLine);

        if DataExchMapping."Post-Mapping Codeunit" <> 0 then
            CODEUNIT.Run(DataExchMapping."Post-Mapping Codeunit", TempBankAccReconLine);

        NumberOfLinesImported := 0;
        InsertNonReconciledOrImportedLines(TempBankAccReconLine, GetLastStatementLineNo(BankAccRecon), NumberOfLinesImported);

        ProgressWindow.Close();
        FinishDateTime := CurrentDateTime();
        OnLogTelemetryAfterImportBankStatement(BankAccRecon, NumberOfLinesImported);
        LogTelemetryOnBankAccRecOnAfterImportBankStatement(BankAccRecon, NumberOfLinesImported, StartDateTime, FinishDateTime);
        case BankAccRecon."Statement Type" of
            BankAccRecon."Statement Type"::"Bank Reconciliation":
                FeatureTelemetry.LogUptake('0000JLK', BankAccRecon.GetBankReconciliationTelemetryFeatureName(), Enum::"Feature Uptake Status"::Used);
            BankAccRecon."Statement Type"::"Payment Application":
                FeatureTelemetry.LogUptake('0000KME', BankAccRecon.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::Used);
        end;
        OnAfterImportBankStatement(TempBankAccReconLine, DataExch);
        exit(true);
    end;

    local procedure PrepareDataExch(BankAccRecon: Record "Bank Acc. Reconciliation"; var DataExch: Record "Data Exch."; var DataExchDef: Record "Data Exch. Def")
    var
        BankAcc: Record "Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrepareDataExch(BankAccRecon, DataExch, DataExchDef, IsHandled);
        if IsHandled then
            exit;

        BankAcc.Get(BankAccRecon."Bank Account No.");
        BankAcc.GetDataExchDef(DataExchDef);

        DataExch."Related Record" := BankAcc.RecordId;
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
    end;

    procedure CreateBankAccRecLineTemplate(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; BankAccRecon: Record "Bank Acc. Reconciliation"; DataExch: Record "Data Exch.")
    begin
        BankAccReconLine.Init();
        BankAccReconLine."Statement Type" := BankAccRecon."Statement Type";
        BankAccReconLine."Statement No." := BankAccRecon."Statement No.";
        BankAccReconLine."Bank Account No." := BankAccRecon."Bank Account No.";
        BankAccReconLine."Data Exch. Entry No." := DataExch."Entry No.";
    end;

    procedure InsertNonReconciledOrImportedLines(var TempBankAccReconLine: Record "Bank Acc. Reconciliation Line" temporary; StatementLineNoOffset: Integer)
    var
        NumberOfLinesImported: Integer;
    begin
        InsertNonReconciledOrImportedLines(TempBankAccReconLine, StatementLineNoOffset, NumberOfLinesImported)
    end;

    procedure InsertNonReconciledOrImportedLines(var TempBankAccReconLine: Record "Bank Acc. Reconciliation Line" temporary; StatementLineNoOffset: Integer; var NumberOfLinesImported: Integer)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if TempBankAccReconLine.FindSet() then
            repeat
                if TempBankAccReconLine.CanImport() then begin
                    BankAccReconciliationLine := TempBankAccReconLine;
                    BankAccReconciliationLine."Statement Line No." += StatementLineNoOffset;
                    BankAccReconciliationLine.Insert();
                    NumberOfLinesImported += 1;
                end;
            until TempBankAccReconLine.Next() = 0;
    end;

    procedure GetLastStatementLineNo(BankAccRecon: Record "Bank Acc. Reconciliation"): Integer
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconLine.SetRange("Statement Type", BankAccRecon."Statement Type");
        BankAccReconLine.SetRange("Statement No.", BankAccRecon."Statement No.");
        BankAccReconLine.SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
        if BankAccReconLine.FindLast() then
            exit(BankAccReconLine."Statement Line No.");
        exit(0)
    end;

    local procedure LogTelemetryOnBankAccRecOnAfterImportBankStatement(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; NumberOfLinesImported: Integer; StartDateTime: DateTime; FinishDateTime: DateTime)
    var
        Dimensions: Dictionary of [Text, Text];
        ImportDuration: BigInteger;
    begin
        ImportDuration := FinishDateTime - StartDateTime;
        Dimensions.Add('ImportStartTime', Format(StartDateTime, 0, 9));
        Dimensions.Add('ImportFinishTime', Format(FinishDateTime, 0, 9));
        Dimensions.Add('ImportDuration', Format(ImportDuration));
        Dimensions.Add('NumberOfLines', Format(NumberOfLinesImported));
        case BankAccReconciliation."Statement Type" of
            BankAccReconciliation."Statement Type"::"Bank Reconciliation":
                begin
                    Dimensions.Add('Category', BankAccountRecCategoryLbl);
                    Session.LogMessage('0000FJW', StrSubstNo(BankAccountRecImportedBankStatementLinesCountMsg, NumberOfLinesImported), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
                end;
            BankAccReconciliation."Statement Type"::"Payment Application":
                begin
                    Dimensions.Add('Category', PaymentRecCategoryLbl);
                    Session.LogMessage('0000KMF', StrSubstNo(BankAccountRecImportedBankStatementLinesCountMsg, NumberOfLinesImported), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
                end;
        end;
    end;

    internal procedure SetBankAccountNo(NewValue: Code[20])
    begin
        BankAccountNo := NewValue;
    end;

    local procedure GetBankAccountNo(): Code[20]
    begin
        exit(BankAccountNo);
    end;

    local procedure InvalidFileFormatError(var ErrorMessage: Text)
    var
        BankAccount: Record "Bank Account";
    begin
        if GetBankAccountNo() = '' then
            exit;

        if not BankAccount.Get(GetBankAccountNo()) then
            exit;

        ErrorMessage := StrSubstNo(InvalidFileFormatErr, BankAccount."No.", BankAccount."Bank Statement Import Format");
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Data Exch. Import - CSV", 'OnInvalidHeaderSetErrorMessage', '', false, false)]
    local procedure HandleOnInvalidHeaderSetErrorMessage(var ErrorMessage: Text);
    begin
        InvalidFileFormatError(ErrorMessage);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Data Exch. Import - CSV", 'OnNoLinesFoundSetErrorMessage', '', false, false)]
    local procedure HandleOnNoLinesFoundSetErrorMessage(var ErrorMessage: Text);
    begin
        InvalidFileFormatError(ErrorMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogTelemetryAfterImportBankStatement(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; NumberOfLinesImported: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportBankStatement(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DataExch: Record "Data Exch.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareDataExch(BankAccRecon: Record "Bank Acc. Reconciliation"; var DataExch: Record "Data Exch."; var DataExchDef: Record "Data Exch. Def"; var IsHandled: Boolean)
    begin
    end;
}

