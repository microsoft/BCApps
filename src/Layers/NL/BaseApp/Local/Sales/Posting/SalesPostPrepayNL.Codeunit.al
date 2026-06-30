// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Document;

codeunit 11339 SalesPostPrepayNL
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post Prepayments", 'OnBeforePostCustomerEntry', '', false, false)]
    local procedure OnBeforePostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
        GenJnlLine."Transaction Mode Code" := SalesHeader."Transaction Mode Code";
        GenJnlLine."Recipient Bank Account" := SalesHeader."Bank Account Code";
    end;
}
