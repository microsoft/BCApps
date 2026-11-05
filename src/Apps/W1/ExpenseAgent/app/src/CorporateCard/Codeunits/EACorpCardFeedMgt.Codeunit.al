// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7430 "EA Corp Card Feed Mgt"
{
    Access = Internal;

    internal procedure ImportStatement(ProviderCode: Code[20]): Boolean
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        SourceInStream: InStream;
        SourceFileName: Text;
    begin
        CorpCardProvider.Get(ProviderCode);
        CorpCardProvider.TestField(Enabled, true);
        if CorpCardProvider.IsFileBasedImport() then begin
            if not UploadIntoStream('', '', '', SourceFileName, SourceInStream) then
                exit(false);
            CorpCardImportOrch.RunFileImport(CorpCardProvider, SourceInStream, SourceFileName);
        end else
            CorpCardImportOrch.RunProvider(CorpCardProvider);
        exit(true);
    end;

    internal procedure RunImport(ProviderCode: Code[20])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
    begin
        CorpCardProvider.Get(ProviderCode);
        CorpCardProvider.TestField(Enabled, true);

        CorpCardImportOrch.RunProvider(CorpCardProvider);
    end;

    internal procedure RunAllEnabledProviders()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        ImportErrorText: Text;
        FirstImportErrorText: Text;
        ImportErrorInfo: ErrorInfo;
        FirstActionableErrorInfo: ErrorInfo;
        HasStructuredErrorInfo: Boolean;
        HasActionableErrorInfo: Boolean;
        HasFailedImport: Boolean;
    begin
        CorpCardProvider.SetRange(Enabled, true);
        CorpCardProvider.SetFilter("Feed Type", '<>%1&<>%2&<>%3', CorpCardProvider."Feed Type"::DataExch, CorpCardProvider."Feed Type"::CSV, CorpCardProvider."Feed Type"::XML);
        if not CorpCardProvider.FindFirst() then
            exit;

        repeat
            if not CorpCardImportOrch.RunProvider(CorpCardProvider, false, ImportErrorText, ImportErrorInfo, HasStructuredErrorInfo) then begin
                if not HasFailedImport then
                    FirstImportErrorText := ImportErrorText;
                HasFailedImport := true;
                if HasStructuredErrorInfo and not HasActionableErrorInfo then begin
                    FirstActionableErrorInfo := ImportErrorInfo;
                    HasActionableErrorInfo := true;
                end;
            end;
            CorpCardProvider.SetFilter(Code, '>%1', CorpCardProvider.Code);
        until not CorpCardProvider.FindFirst();

        if HasActionableErrorInfo then
            Error(FirstActionableErrorInfo);
        if HasFailedImport then
            Error(ProviderImportFailedErr, FirstImportErrorText);
    end;

    var
        ProviderImportFailedErr: Label 'One or more corporate card imports failed. First error: %1', Comment = '%1 = error detail of the first failed import';
}