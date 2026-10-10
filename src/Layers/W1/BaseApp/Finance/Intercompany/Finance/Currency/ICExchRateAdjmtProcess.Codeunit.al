// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 8420 "IC Exch. Rate. Adjmt. Process"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", OnPostAdjmtOnBeforePostGenJnlLine, '', false, false)]
    local procedure OnPostAdjmtOnBeforePostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PartnerCode: Code[20])
    begin
        GenJnlLine."IC Partner Code" := PartnerCode;
    end;
}