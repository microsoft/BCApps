#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Environment.Configuration;
using System.Telemetry;

codeunit 10815 "Sales FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Feature SalesFR will be enabled by default in version 31.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FeatureKeyIdTok: Label 'SalesFR', Locked = true;
        FeatureNameTok: Label 'Sales FR', Locked = true;

    procedure IsEnabled() Enabled: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        Enabled := FeatureManagementFacade.IsEnabled(FeatureKeyIdTok);
    end;

    procedure GetFeatureKeyId(): Text
    begin
        exit(FeatureKeyIdTok);
    end;

    procedure LogFeatureDiscovered()
    begin
        FeatureTelemetry.LogUptake('0000W22', FeatureNameTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    procedure LogFeatureSetUp()
    begin
        FeatureTelemetry.LogUptake('0000W23', FeatureNameTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    procedure LogFeatureUsed()
    begin
        FeatureTelemetry.LogUptake('0000W24', FeatureNameTok, Enum::"Feature Uptake Status"::Used);
    end;

#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterGetSIRENNoWithCaption', '', false, false)]
    local procedure CustomerOnAfterGetSIRENNoWithCaption(Customer: Record Customer; var SIRENNoWithCaption: Text)
    begin
        if IsEnabled() then
            SIRENNoWithCaption := Customer.GetSIRENNoWithCaptionFR();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Invoice", 'OnAfterGetVATPaidOnDebitsText', '', false, false)]
    local procedure SalesInvoiceOnAfterGetVATPaidOnDebitsText(SalesInvoiceHeader: Record "Sales Invoice Header"; var VATPaidOnDebitsText: Text)
    begin
        if not IsEnabled() then
            exit;

        VATPaidOnDebitsText := '';
        if SalesInvoiceHeader."VAT Paid on Debits FR" then
            VATPaidOnDebitsText := SalesInvoiceHeader.FieldCaption("VAT Paid on Debits FR");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Credit Memo", 'OnAfterGetVATPaidOnDebitsText', '', false, false)]
    local procedure SalesCreditMemoOnAfterGetVATPaidOnDebitsText(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var VATPaidOnDebitsText: Text)
    begin
        if not IsEnabled() then
            exit;

        VATPaidOnDebitsText := '';
        if SalesCrMemoHeader."VAT Paid on Debits FR" then
            VATPaidOnDebitsText := SalesCrMemoHeader.FieldCaption("VAT Paid on Debits FR");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Draft Invoice", 'OnAfterGetVATPaidOnDebitsText', '', false, false)]
    local procedure SalesDraftInvoiceOnAfterGetVATPaidOnDebitsText(SalesHeader: Record "Sales Header"; var VATPaidOnDebitsText: Text)
    begin
        if not IsEnabled() then
            exit;

        VATPaidOnDebitsText := '';
        if SalesHeader."VAT Paid on Debits FR" then
            VATPaidOnDebitsText := SalesHeader.FieldCaption("VAT Paid on Debits FR");
    end;
#pragma warning restore AL0432
}
#endif
