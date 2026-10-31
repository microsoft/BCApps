#if INTERCOMPANY_IT
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;

codeunit 8561 "IC Sales-Post IT"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostPayment', '', false, false)]
    local procedure InitializePaymentPartner(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
        GenJnlLine."IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
    end;
}
#endif
