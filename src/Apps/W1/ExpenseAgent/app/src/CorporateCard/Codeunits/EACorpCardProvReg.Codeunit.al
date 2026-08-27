// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7221 "EA Corp Card Prov Reg"
{
    Access = Internal;

    var
        UnsupportedFeedTypeErr: Label 'Feed type %1 is not supported yet.', Comment = '%1 = Feed type';

    internal procedure ResolveProvider(CorpCardProvider: Record "EA Corp Card Provider"; var CorpCardProviderImpl: Interface "EA Corp Card Provider")
    var
        CorpCardDataExchProv: Codeunit "EA Corp Card Data Exch Prov";
    begin
        case CorpCardProvider."Feed Type" of
            CorpCardProvider."Feed Type"::DataExch,
            CorpCardProvider."Feed Type"::API,
            CorpCardProvider."Feed Type"::CAMT053,
            CorpCardProvider."Feed Type"::CAMT054,
            CorpCardProvider."Feed Type"::ISO20022,
            CorpCardProvider."Feed Type"::XML,
            CorpCardProvider."Feed Type"::CSV:
                CorpCardProviderImpl := CorpCardDataExchProv;
            else
                Error(UnsupportedFeedTypeErr, CorpCardProvider."Feed Type");
        end;
    end;
}