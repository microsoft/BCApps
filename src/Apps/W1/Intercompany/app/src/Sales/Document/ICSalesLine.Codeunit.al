// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Intercompany.GLAccount;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Sales.Setup;

/// <summary>
/// Handles Intercompany subscriber logic for Sales Line.
/// </summary>
codeunit 8482 "IC Sales Line"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterUpdateItemReference', '', false, false)]
    local procedure OnAfterUpdateItemReference(var SalesLine: Record "Sales Line")
    begin
        SalesLine.UpdateICPartner();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeGetJnlTemplateName', '', false, false)]
    local procedure OnBeforeGetJnlTemplateName(var SalesLine: Record "Sales Line"; var JnlTemplateName: Code[10]; var IsHandled: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if SalesLine."IC Partner Code" = '' then
            exit;

        IsHandled := true;
        SalesSetup.Get();
        if SalesLine.IsCreditDocType() then begin
            SalesSetup.TestField("IC Sales Cr. Memo Templ. Name");
            JnlTemplateName := SalesSetup."IC Sales Cr. Memo Templ. Name";
        end else begin
            SalesSetup.TestField("IC Sales Invoice Template Name");
            JnlTemplateName := SalesSetup."IC Sales Invoice Template Name";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Reference Management", 'OnSalesReferenceNoLookupForGLAccountAndResource', '', false, false)]
    local procedure OnSalesReferenceNoLookupForGLAccountAndResource(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        ICGLAcc: Record "IC G/L Account";
    begin
        SalesLine.SetSalesHeader(SalesHeader);
        SalesHeader.TestField("Sell-to IC Partner Code");
        if PAGE.RunModal(PAGE::"IC G/L Account List", ICGLAcc) = ACTION::LookupOK then
            SalesLine."Item Reference No." := ICGLAcc."No.";
    end;
}
