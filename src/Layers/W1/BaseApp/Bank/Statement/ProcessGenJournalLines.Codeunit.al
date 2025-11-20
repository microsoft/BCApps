// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;

codeunit 1247 "Process Gen. Journal  Lines"
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Gen. Journal Line";

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

    procedure ImportBankStatement(GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAcc: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        ProgressWindow: Dialog;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeImportBankStatement(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");

        case GenJnlBatch."Bal. Account Type" of
            GenJnlBatch."Bal. Account Type"::"Bank Account":
                begin
                    GenJnlBatch.TestField("Bal. Account No.");
                    BankAcc.Get(GenJnlBatch."Bal. Account No.");
                    BankAcc.GetDataExchDef(DataExchDef);
                end;
            GenJnlBatch."Bal. Account Type"::"G/L Account":
                begin
                    GenJnlBatch.TestField("Bank Statement Import Format");
                    BankExportImportSetup.Get(GenJnlBatch."Bank Statement Import Format");
                    BankExportImportSetup.TestField("Data Exch. Def. Code");
                    DataExchDef.Get(BankExportImportSetup."Data Exch. Def. Code");
                    DataExchDef.TestField(Type, DataExchDef.Type::"Bank Statement Import");
                end;
            else
                GenJnlBatch.FieldError("Bal. Account Type");
        end;
        CreateGeneralJournalLineTemplate(GenJnlLineTemplate, GenJnlLine);

        if not DataExch.ImportToDataExch(DataExchDef) then
            exit;

        GenJnlLineTemplate."Data Exch. Entry No." := DataExch."Entry No.";

        ProgressWindow.Open(ProgressWindowMsg);

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindFirst();

        DataExchMapping.Get(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line");
        DataExchMapping.TestField("Mapping Codeunit");
        CODEUNIT.Run(DataExchMapping."Mapping Codeunit", GenJnlLineTemplate);

        UpdateGenJournalLines(GenJnlLineTemplate);

        ProgressWindow.Close();

        OnAfterImportBankStatement(GenJnlLine, GenJnlLineTemplate);
    end;

    procedure CreateGeneralJournalLineTemplate(var GenJournalLineTemplate: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLineTemplate."Journal Template Name" := GenJournalLine."Journal Template Name";
        GenJournalLineTemplate."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        GenJournalLineTemplate.SetUpNewLine(GenJournalLine, GenJournalLine."Balance (LCY)", true);
        GenJournalLineTemplate."Account Type" := GenJournalLineTemplate."Account Type"::"G/L Account";

        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        if GenJournalLine.FindLast() then begin
            GenJournalLineTemplate."Line No." := GenJournalLine."Line No.";
            GenJournalLineTemplate."Document No." := IncStr(GenJournalLine."Document No.");
        end else
            GenJournalLineTemplate."Document No." := GenJournalLine."Document No.";

        OnAfterCreateGeneralJournalLineTemplate(GenJournalLineTemplate, GenJournalLine);
    end;

    procedure UpdateGenJournalLines(var GenJournalLineTemplate: Record "Gen. Journal Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateGenJnlLinesProcedure(GenJournalLineTemplate, IsHandled);
        if IsHandled then
            exit;

        GenJournalLine.SetRange("Journal Template Name", GenJournalLineTemplate."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLineTemplate."Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '>%1', GenJournalLineTemplate."Line No.");
        if GenJournalLine.FindSet() then begin
            DocNo := GenJournalLineTemplate."Document No.";
            repeat
                GenJournalLine.Validate("Document No.", DocNo);
                GenJournalLine.Modify(true);
                DocNo := IncStr(DocNo);
            until GenJournalLine.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateGeneralJournalLineTemplate(var GenJournalLineTemplate: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportBankStatement(var GenJournalLine: Record "Gen. Journal Line"; GenJournalLineTemplate: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportBankStatement(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGenJnlLinesProcedure(var GenJournalLineTemplate: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

