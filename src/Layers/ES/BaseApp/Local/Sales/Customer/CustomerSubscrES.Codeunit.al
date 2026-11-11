// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

#pragma warning disable AS0088
codeunit 7000135 "Customer Subscr. ES"
{
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterInitInvoiceDiscCode', '', true, false)]
    local procedure OnAfterInitInvoiceDiscCode(var Customer: Record Customer)
    begin
        Customer."Payment Days Code" := Customer."No.";
        Customer."Non-Paymt. Periods Code" := Customer."No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnApplyTemplateOnAfterCopyFields', '', true, false)]
    local procedure OnApplyTemplateOnAfterCopyFields(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; UpdateExistingValues: Boolean)
    begin
        if CustomerTempl."Payment Days Code" <> '' then
            Customer."Payment Days Code" := CustomerTempl."Payment Days Code";
        if CustomerTempl."Non-Paymt. Periods Code" <> '' then
            Customer."Non-Paymt. Periods Code" := CustomerTempl."Non-Paymt. Periods Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnFillFieldExclusionListOnAfterAddFields', '', true, false)]
    local procedure OnFillFieldExclusionListOnAfterAddFields(var FieldExclusionList: List of [Integer])
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        FieldExclusionList.Add(CustomerTempl.FieldNo("Payment Days Code"));
        FieldExclusionList.Add(CustomerTempl.FieldNo("Non-Paymt. Periods Code"));
    end;
}
