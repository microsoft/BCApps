// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7220 EACorpCardFeedMgt
{
    Access = Internal;

    internal procedure RunImport(ProviderCode: Code[20])
    var
        CorpCardProvider: Record EACorpCardProvider;
        CorpCardImportOrch: Codeunit EACorpCardImportOrch;
    begin
        CorpCardProvider.Get(ProviderCode);
        CorpCardProvider.TestField(Enabled, true);

        CorpCardImportOrch.RunProvider(CorpCardProvider);
    end;

    internal procedure RunAllEnabledProviders()
    var
        CorpCardProvider: Record EACorpCardProvider;
        CorpCardImportOrch: Codeunit EACorpCardImportOrch;
    begin
        CorpCardProvider.SetRange(Enabled, true);
        if not CorpCardProvider.FindSet() then
            exit;

        repeat
            CorpCardImportOrch.RunProvider(CorpCardProvider);
        until CorpCardProvider.Next() = 0;
    end;
}