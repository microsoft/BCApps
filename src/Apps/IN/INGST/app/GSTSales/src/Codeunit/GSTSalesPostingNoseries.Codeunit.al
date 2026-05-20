// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GST.Sales;

using Microsoft.Finance.TaxBase;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

codeunit 18142 "GST Sales Posting No. Series"
{
    var
        PostingNoSeries: Record "Posting No. Series";

    //No Series for Sales 
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEvent(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGSTSalesPostingNoSeriesOnAfterInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Rec.IsTemporary() then begin
            Record := Rec;
            PostingNoSeries.GetPostingNoSeriesCode(Record);
            Rec := Record;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer No.', false, false)]
    local procedure SelltoCustomer(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelltoCustomerPostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Bill-to Customer no.', false, false)]
    local procedure BilltoCustomer(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBilltoCustomerPostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Contact No.', false, false)]
    local procedure SelltoContact(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelltoContactPostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer Templ. Code', false, false)]
    local procedure SelltoCustomerTemplateCode(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelltoCustomerTemplateCodePostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Bill-to Contact No.', false, false)]
    local procedure BilltoContact(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBilltoContactPostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Bill-to Customer Templ. Code', false, false)]
    local procedure BilltoCustomerTemplateCode(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBilltoCustomerTemplateCodePostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Trading', false, false)]
    local procedure Trading(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTradingPostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Location Code', false, false)]
    local procedure Location(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLocationPostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Invoice Type', false, false)]
    local procedure PurchaseInvoiceType(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInvoiceTypePostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Shortcut Dimension 1 Code', false, false)]
    local procedure DepartmentCode(var Rec: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDepartmentCodePostingNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        Record := Rec;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        Rec := Record;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyFieldsFromOldSalesHeader', '', false, false)]
    local procedure OnAfterCopyFieldsFromOldSalesHeader(var ToSalesHeader: Record "Sales Header")
    var
        Record: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDocPostingNoSeries(ToSalesHeader, IsHandled);
        if IsHandled then
            exit;

        Record := ToSalesHeader;
        PostingNoSeries.GetPostingNoSeriesCode(Record);
        ToSalesHeader := Record;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGSTSalesPostingNoSeriesOnAfterInsert(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelltoCustomerPostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBilltoCustomerPostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelltoContactPostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelltoCustomerTemplateCodePostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBilltoContactPostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBilltoCustomerTemplateCodePostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTradingPostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLocationPostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoiceTypePostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDepartmentCodePostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDocPostingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}
