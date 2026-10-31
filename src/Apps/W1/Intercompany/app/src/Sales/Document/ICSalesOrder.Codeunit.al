// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;

/// <summary>
/// Handles Intercompany subscriber logic for Sales Order page.
/// </summary>
codeunit 8487 "IC Sales Order"
{
    [EventSubscriber(ObjectType::Page, Page::"Sales Order", 'OnShowPostedConfirmationMessageIC', '', false, false)]
    local procedure OnShowPostedConfirmationMessageIC(var SalesHeader: Record "Sales Header")
    var
        ICFeedback: Codeunit "IC Feedback";
    begin
        ICFeedback.ShowIntercompanyMessage(SalesHeader, Enum::"IC Transaction Document Type"::Order);
    end;
}
