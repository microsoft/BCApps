// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7430 "EA Corp Card Feed Mgt"
{
    Access = Internal;

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
    begin
        CorpCardProvider.SetRange(Enabled, true);
        if not CorpCardProvider.FindSet() then
            exit;

        repeat
            if not CorpCardImportOrch.RunProvider(CorpCardProvider, false, ImportErrorText) then
                if FirstImportErrorText = '' then
                    FirstImportErrorText := ImportErrorText;
        until CorpCardProvider.Next() = 0;

        if FirstImportErrorText <> '' then
            Error(ProviderImportFailedErr, FirstImportErrorText);
    end;

    var
        ProviderImportFailedErr: Label 'One or more corporate card imports failed. First error: %1', Comment = '%1 = error detail of the first failed import';
}