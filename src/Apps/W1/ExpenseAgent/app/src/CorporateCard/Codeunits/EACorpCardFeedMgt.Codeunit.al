// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7220 "EA Corp Card Feed Mgt"
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
    begin
        CorpCardProvider.SetRange(Enabled, true);
        if not CorpCardProvider.FindSet() then
            exit;

        repeat
            if not TryRunProvider(CorpCardProvider) then
                ClearLastError();
        until CorpCardProvider.Next() = 0;
    end;

    [TryFunction]
    local procedure TryRunProvider(CorpCardProvider: Record "EA Corp Card Provider")
    var
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
    begin
        CorpCardImportOrch.RunProvider(CorpCardProvider);
    end;
}