// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7431 "EA Corp Card Prov Reg"
{
    Access = Internal;

    internal procedure ResolveProvider(CorpCardProvider: Record "EA Corp Card Provider"; var CorpCardProviderImpl: Interface "EA Corp Card Provider")
    begin
        CorpCardProviderImpl := CorpCardProvider."Feed Type";
    end;
}