// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;

codeunit 11321 PurchPostPrepayNL
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchase-Post Prepayments", 'OnPostVendorEntryOnAfterInitNewLine', '', false, false)]
    local procedure OnPostVendorEntryOnAfterInitNewLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header")
    begin
        GenJnlLine."Transaction Mode Code" := PurchHeader."Transaction Mode Code";
        GenJnlLine."Recipient Bank Account" := PurchHeader."Bank Account Code";
    end;
}
