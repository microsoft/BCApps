// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;

/// <summary>
/// Handles Intercompany subscriber logic for Sales Invoice page.
/// </summary>
codeunit 8489 "IC Sales Invoice"
{
    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice", 'OnShowPostedConfirmationMessageIC', '', false, false)]
    local procedure OnShowPostedConfirmationMessageIC(var SalesHeader: Record "Sales Header"; SalesInvoiceNo: Code[20])
    var
        ICFeedback: Codeunit "IC Feedback";
    begin
        ICFeedback.ShowIntercompanyMessage(SalesHeader, Enum::"IC Transaction Document Type"::Invoice, SalesInvoiceNo);
    end;
}
