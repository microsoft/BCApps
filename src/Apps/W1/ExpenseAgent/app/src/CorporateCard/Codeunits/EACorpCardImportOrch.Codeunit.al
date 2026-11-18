// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;

codeunit 7432 "EA Corp Card Import Orch"
{
    Access = Internal;
    Permissions = tabledata "Data Exch." = d;
    TableNo = "EA Corp Card Statement";

    trigger OnRun()
    begin
        ProcessProviderImport(Rec);
    end;

    internal procedure RunProvider(CorpCardProvider: Record "EA Corp Card Provider")
    begin
        RunProvider(CorpCardProvider, true);
    end;

    internal procedure RunProvider(CorpCardProvider: Record "EA Corp Card Provider"; RaiseImportError: Boolean)
    var
        ImportErrorText: Text;
        ImportErrorInfo: ErrorInfo;
        HasStructuredErrorInfo: Boolean;
    begin
        RunProvider(CorpCardProvider, RaiseImportError, ImportErrorText, ImportErrorInfo, HasStructuredErrorInfo);
    end;

    internal procedure RunProvider(CorpCardProvider: Record "EA Corp Card Provider"; RaiseImportError: Boolean; var ImportErrorText: Text; var ImportErrorInfo: ErrorInfo; var HasStructuredErrorInfo: Boolean): Boolean
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        InitializeStatement(CorpCardProvider, CorpCardStatement);
        exit(RunStatementImport(CorpCardProvider, CorpCardStatement, RaiseImportError, ImportErrorText, ImportErrorInfo, HasStructuredErrorInfo));
    end;

    internal procedure RunFileImport(CorpCardProvider: Record "EA Corp Card Provider"; SourceInStream: InStream; SourceFileName: Text)
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardDataExchProv: Codeunit "EA Corp Card Data Exch Prov";
        ImportErrorText: Text;
        ImportErrorInfo: ErrorInfo;
        HasStructuredErrorInfo: Boolean;
    begin
        CorpCardProvider.TestField(Enabled, true);
        InitializeStatement(CorpCardProvider, CorpCardStatement);
        CorpCardDataExchProv.SetSourceFile(CorpCardStatement, SourceInStream, SourceFileName);
        RunStatementImport(CorpCardProvider, CorpCardStatement, true, ImportErrorText, ImportErrorInfo, HasStructuredErrorInfo);
    end;

    local procedure InitializeStatement(CorpCardProvider: Record "EA Corp Card Provider"; var CorpCardStatement: Record "EA Corp Card Statement")
    begin
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := CorpCardProvider.Code;
        CorpCardStatement."Started DT" := CurrentDateTime();
        CorpCardStatement.Status := CorpCardStatement.Status::Importing;
        CorpCardStatement.Insert(true);
    end;

    local procedure RunStatementImport(CorpCardProvider: Record "EA Corp Card Provider"; var CorpCardStatement: Record "EA Corp Card Statement"; RaiseImportError: Boolean; var ImportErrorText: Text; var ImportErrorInfo: ErrorInfo; var HasStructuredErrorInfo: Boolean): Boolean
    var
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        PostImportOrch: Codeunit "EA Corp Card Post Import Orch";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ImportStage: Text;
        ImportTransactionSucceeded: Boolean;
    begin
        ImportErrorText := '';
        ImportErrorInfo := ErrorInfo.Create();
        HasStructuredErrorInfo := false;
        AuditSubscribers.LogImportStarted(CorpCardProvider.Code, CorpCardStatement."Statement Entry No.");

        Commit();
        CorpCardErrorContext.ClearErrorInfo();
        ClearLastError();
        ImportTransactionSucceeded := CorpCardImportOrch.Run(CorpCardStatement);
        if not ImportTransactionSucceeded then
            ImportErrorText := GetLastErrorText();
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        if not ImportTransactionSucceeded or (CorpCardStatement.Status = CorpCardStatement.Status::Failed) then begin
            ImportStage := CorpCardErrorContext.GetImportStage();
            HasStructuredErrorInfo := CorpCardErrorContext.TryGetErrorInfo(ImportErrorInfo);
            if ImportTransactionSucceeded then
                if HasStructuredErrorInfo then
                    ImportErrorText := ImportErrorInfo.Message
                else
                    ImportErrorText := StrSubstNo(StatementValidationFailedErr, CorpCardStatement."Statement Entry No.", CorpCardProvider.Code);
            CorpCardErrorContext.ClearErrorInfo();
            MarkImportFailed(CorpCardStatement);
            AuditSubscribers.LogImportFailed(CorpCardProvider.Code, CorpCardStatement."Statement Entry No.", ImportStage);
            DeleteSourceFile(CorpCardStatement);
            UpdateProviderLastStatementEntryNo(CorpCardProvider.Code, CorpCardStatement."Statement Entry No.");
            Commit();
            if RaiseImportError then begin
                if HasStructuredErrorInfo then
                    Error(ImportErrorInfo);
                Error(ImportFailedErr, ImportErrorText);
            end;
            exit(false);
        end;

        CorpCardStatement.Status := CorpCardStatement.Status::Imported;
        CorpCardStatement."Ended DT" := CurrentDateTime();
        CorpCardStatement.Modify();

        DeleteSourceFile(CorpCardStatement);

        CorpCardProvider.Get(CorpCardProvider.Code);
        CorpCardProvider."Last Import DT" := CurrentDateTime();
        CorpCardProvider."Last Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardProvider.Modify();
        CorpCardErrorContext.ClearErrorInfo();
        Commit();
        AuditSubscribers.LogImportCompleted(CorpCardProvider.Code, CorpCardStatement."Statement Entry No.", CorpCardStatement.Imported, CorpCardStatement.Exceptions, CorpCardStatement.Duplicates);
        PostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", ExpenseWriter);
        exit(true);
    end;

    local procedure ProcessProviderImport(var CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardProvReg: Codeunit "EA Corp Card Prov Reg";
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        CorpCardProviderImpl: Interface "EA Corp Card Provider";
    begin
        CorpCardErrorContext.SetImportStage('Provider setup');
        CorpCardProvider.Get(CorpCardStatement."Provider Code");
        CorpCardProvReg.ResolveProvider(CorpCardProvider, CorpCardProviderImpl);
        CorpCardErrorContext.SetImportStage('Download');
        CorpCardProviderImpl.Download(CorpCardStatement);
        CorpCardErrorContext.SetImportStage('Parse');
        CorpCardProviderImpl.ParseToStaging(CorpCardStatement."Statement Entry No.");
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        if CorpCardStatement.Status = CorpCardStatement.Status::Failed then
            exit;
        CorpCardErrorContext.SetImportStage('Acknowledge');
        CorpCardProviderImpl.Ack(CorpCardStatement."Statement Entry No.");
    end;

    local procedure MarkImportFailed(var CorpCardStatement: Record "EA Corp Card Statement")
    begin
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        CorpCardStatement.Status := CorpCardStatement.Status::Failed;
        CorpCardStatement."Ended DT" := CurrentDateTime();
        CorpCardStatement.Modify();
    end;

    local procedure DeleteSourceFile(var CorpCardStatement: Record "EA Corp Card Statement")
    var
        DataExch: Record "Data Exch.";
    begin
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        if DataExch.Get(CorpCardStatement."Data Exch Entry No.") then
            DataExch.Delete(true);

        CorpCardStatement."Data Exch Entry No." := 0;
        CorpCardStatement.Modify();
    end;

    local procedure UpdateProviderLastStatementEntryNo(ProviderCode: Code[20]; StatementEntryNo: Integer)
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        CorpCardProvider.Get(ProviderCode);
        CorpCardProvider."Last Statement Entry No." := StatementEntryNo;
        CorpCardProvider.Modify();
    end;

    var
        StatementValidationFailedErr: Label 'Corporate card statement %1 for provider %2 failed validation. Review its import exceptions.', Comment = '%1 = statement entry number, %2 = provider code';
        ImportFailedErr: Label 'Corporate card import failed: %1', Comment = '%1 = error detail returned by the import';
}
