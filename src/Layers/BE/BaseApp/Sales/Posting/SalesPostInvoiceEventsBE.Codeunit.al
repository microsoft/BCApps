// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Document;

codeunit 854 "Sales Post Invoice Events BE"
{
    procedure RunOnPrepareGenJnlLineOnBeforeUpdateCountryRegionCode(var SalesHeader: Record "Sales Header"; var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnPrepareGenJnlLineOnBeforeUpdateCountryRegionCode(SalesHeader, GenJnlLine, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareGenJnlLineOnBeforeUpdateCountryRegionCode(var SalesHeader: Record "Sales Header"; var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;
}