#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

reportextension 10818 "Std. Sales Credit Memo FR Ext" extends "Standard Sales - Credit Memo"
{
    dataset
    {
        add(Header)
        {
            column(CustomerSirenNo; CustomerFR.GetSIRENNoWithCaptionFR())
            {
            }
            column(GoodsAndServices_Lbl; GetGoodsAndServicesText())
            {
            }
            column(VATPaidOnDebits_Lbl; GetVATPaidOnDebitsText())
            {
            }
        }

        modify(Header)
        {
            trigger OnAfterAfterGetRecord()
            begin
                FillFRFields();
            end;
        }
    }

    rendering
    {
        layout("StandardSalesCreditMemoFR.rdlc")
        {
            Type = RDLC;
            LayoutFile = './src/ReportExtensions/StandardSalesCreditMemoFR.rdlc';
            Caption = 'Standard Sales Credit Memo (RDLC) (FR)';
            Summary = 'The Standard Sales Credit Memo (RDLC) provides a detailed layout.';
        }
        layout("StandardSalesCreditMemoFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesCreditMemoFR.docx';
            Caption = 'Standard Sales Credit Memo (Word) (FR)';
            Summary = 'The Standard Sales Credit Memo (Word) provides a basic layout.';
        }
        layout("StandardSalesCreditMemoThemableFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesCreditMemoThemable.docx';
            Caption = 'Standard Sales Credit Memo - themable Word layout (FR)';
            Summary = 'The Standard Sales Credit Memo (Word) provides a basic Themable layout.';
        }
        layout("StandardSalesCreditMemoEmailFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesCreditMemoEmail.docx';
            Caption = 'Standard Sales Credit Memo Email (Word) (FR)';
            Summary = 'The Standard Sales Credit Memo Email (Word) provides an email body layout.';
        }
    }

    var
        CustomerFR: Record Customer;
        IncludesGoodsLbl: Label 'Sales credit memo includes only goods.';
        IncludesServicesLbl: Label 'Sales credit memo includes only services.';
        IncludesGoodsAndServicesLbl: Label 'Sales credit memo includes goods and services.';

    local procedure FillFRFields()
    begin
        if not CustomerFR.Get(Header."Bill-to Customer No.") then
            Clear(CustomerFR);
    end;

    local procedure GetGoodsAndServicesText(): Text
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GotGoods: Boolean;
        GotServices: Boolean;
    begin
        SalesCrMemoLine.SetRange("Document No.", Header."No.");
        SalesCrMemoLine.SetFilter(Type, '<> %1', SalesCrMemoLine.Type::Item);
        if not SalesCrMemoLine.IsEmpty() then
            GotServices := true;
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.SetLoadFields("No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                if IsItemInventory(SalesCrMemoLine."No.") then
                    GotGoods := true
                else
                    GotServices := true;
            until SalesCrMemoLine.Next() = 0;
        if GotServices then
            if GotGoods then
                exit(IncludesGoodsAndServicesLbl)
            else
                exit(IncludesServicesLbl)
        else
            exit(IncludesGoodsLbl);
    end;

    local procedure IsItemInventory(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        Item.SetLoadFields(Type);
        if Item.Get(ItemNo) then
            exit(Item.Type = Item.Type::Inventory);
    end;

    local procedure GetVATPaidOnDebitsText(): Text
    begin
        if Header."VAT Paid on Debits FR" then
            exit(Header.FieldCaption("VAT Paid on Debits FR"));
    end;
}
#endif
