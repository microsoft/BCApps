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
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        ImportStage: Text;
    begin
        ImportErrorText := '';
        ImportErrorInfo := ErrorInfo.Create();
        HasStructuredErrorInfo := false;
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := CorpCardProvider.Code;
        CorpCardStatement."Started DT" := CurrentDateTime();
        CorpCardStatement.Status := CorpCardStatement.Status::Importing;
        CorpCardStatement.Insert(true);

        AuditSubscribers.LogImportStarted(CorpCardProvider.Code, CorpCardStatement."Statement Entry No.");

        Commit();
        CorpCardErrorContext.ClearErrorInfo();
        if not CorpCardImportOrch.Run(CorpCardStatement) then begin
            ImportErrorText := GetLastErrorText();
            ImportStage := CorpCardErrorContext.GetImportStage();
            HasStructuredErrorInfo := CorpCardErrorContext.TryGetErrorInfo(ImportErrorInfo);
            CorpCardErrorContext.ClearErrorInfo();
            MarkImportFailed(CorpCardStatement);
            AuditSubscribers.LogImportFailed(CorpCardProvider.Code, CorpCardStatement."Statement Entry No.", ImportStage);
            ClearSourcePayload(CorpCardProvider.Code, CorpCardStatement);
            UpdateProviderLastStatementEntryNo(CorpCardProvider.Code, CorpCardStatement."Statement Entry No.");
            Commit();
            if RaiseImportError then begin
                if HasStructuredErrorInfo then
                    Error(ImportErrorInfo);
                Error(ImportFailedErr, ImportErrorText);
            end;
            exit(false);
        end;

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        if CorpCardStatement.Status <> CorpCardStatement.Status::Failed then
            CorpCardStatement.Status := CorpCardStatement.Status::Imported;

        CorpCardStatement."Ended DT" := CurrentDateTime();
        CorpCardStatement.Modify();

        if CorpCardStatement.Status = CorpCardStatement.Status::Imported then
            AuditSubscribers.LogImportCompleted(CorpCardProvider.Code, CorpCardStatement."Statement Entry No.", CorpCardStatement.Imported, CorpCardStatement.Exceptions, CorpCardStatement.Duplicates);

        ClearSourcePayload(CorpCardProvider.Code, CorpCardStatement);

        CorpCardProvider.Get(CorpCardProvider.Code);
        CorpCardProvider."Last Import DT" := CurrentDateTime();
        CorpCardProvider."Last Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardProvider.Modify();
        CorpCardErrorContext.ClearErrorInfo();
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

    local procedure ClearSourcePayload(ProviderCode: Code[20]; var CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        DataExch: Record "Data Exch.";
    begin
        if CorpCardProvider.Get(ProviderCode) then begin
            Clear(CorpCardProvider."Source Payload");
            CorpCardProvider."Source Payload Record Count" := 0;
            CorpCardProvider.Modify();
        end;

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
        ImportFailedErr: Label 'Corporate card import failed: %1', Comment = '%1 = error detail returned by the import';
}
