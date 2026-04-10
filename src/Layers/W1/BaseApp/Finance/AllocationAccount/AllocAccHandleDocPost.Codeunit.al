// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Finance.Deferral;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

/// <summary>
/// Manages VAT posting group handling during document posting operations for allocation accounts.
/// Provides event-driven VAT posting group assignment and deferral schedule redistribution control.
/// </summary>
codeunit 2674 "Alloc. Acc. Handle Doc. Post"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeValidateVATProdPostingGroup', '', false, false)]
    local procedure SalesBeforeValidateVATProdPostingGroup(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
        if VATBusPostingGroupCode <> '' then
            SalesLine."VAT Bus. Posting Group" := VATBusPostingGroupCode;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeValidateVATProdPostingGroupTrigger', '', false, false)]
    local procedure SalesBeforeValidateVATProdPostingGroupTrigger(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        if VATProdPostingGroupCode <> '' then
            SalesLine."VAT Prod. Posting Group" := VATProdPostingGroupCode;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeValidateVATProdPostingGroup', '', false, false)]
    local procedure PurchaseBeforeValidateVATProdPostingGroup(var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
        if VATBusPostingGroupCode <> '' then
            PurchaseLine."VAT Bus. Posting Group" := VATBusPostingGroupCode;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnValidateVATProdPostingGroupOnAfterTestStatusOpen', '', false, false)]
    local procedure BeforeValidateVATProdPostingGroupTrigger(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var xPurchaseLine: Record "Purchase Line")
    begin
        if VATProdPostingGroupCode <> '' then
            PurchaseLine."VAT Prod. Posting Group" := VATProdPostingGroupCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Deferral Utilities", 'OnBeforeCreateDeferralSchedule', '', false, false)]
    local procedure OnBeforeCreateDeferralSchedule(var RedistributeDeferralSchedule: Boolean)
    begin
        RedistributeDeferralSchedule := true;
    end;

    /// <summary>
    /// Sets the VAT business posting group code for document line processing.
    /// </summary>
    /// <param name="NewVATBusPostingGroupCode">VAT business posting group code to apply</param>
    procedure SetVATBusPostingGroupCode(NewVATBusPostingGroupCode: Code[20])
    begin
        VATBusPostingGroupCode := NewVATBusPostingGroupCode;
    end;

    /// <summary>
    /// Sets the VAT product posting group code for document line processing.
    /// </summary>
    /// <param name="NewVATProdPostingGroupCode">VAT product posting group code to apply</param>
    procedure SetVATProdPostingGroupCode(NewVATProdPostingGroupCode: Code[20])
    begin
        VATProdPostingGroupCode := NewVATProdPostingGroupCode;
    end;

    var
        VATBusPostingGroupCode: Code[20];
        VATProdPostingGroupCode: Code[20];
}
