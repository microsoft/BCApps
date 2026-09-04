#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

reportextension 10820 "Std. Sales Draft Inv. FR Ext" extends "Standard Sales - Draft Invoice"
{
    dataset
    {
        add(Header)
        {
            column(AlternativeAddress_Lbl; AlternativeAddressTxt)
            {
            }
            column(AlternativeAddress1; AlternativeAddress[1])
            {
            }
            column(AlternativeAddress2; AlternativeAddress[2])
            {
            }
            column(AlternativeAddress3; AlternativeAddress[3])
            {
            }
            column(AlternativeAddress4; AlternativeAddress[4])
            {
            }
            column(AlternativeAddress5; AlternativeAddress[5])
            {
            }
            column(AlternativeAddress6; AlternativeAddress[6])
            {
            }
            column(AlternativeAddress7; AlternativeAddress[7])
            {
            }
            column(AlternativeAddress8; AlternativeAddress[8])
            {
            }
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
        layout("StandardSalesDraftInvoiceFR.rdlc")
        {
            Type = RDLC;
            LayoutFile = './src/ReportExtensions/StandardSalesDraftInvoiceFR.rdlc';
            Caption = 'Standard Sales Draft Invoice (RDLC) (FR)';
            Summary = 'The Standard Sales Draft Invoice (RDLC) provides a detailed layout.';
        }
        layout("StandardSalesDraftInvoiceFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesDraftInvoiceFR.docx';
            Caption = 'Standard Sales Draft Invoice (Word) (FR)';
            Summary = 'The Standard Sales Draft Invoice (Word) provides a basic layout.';
        }
        layout("StandardDraftSalesInvoiceBlueFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardDraftSalesInvoiceBlue.docx';
            Caption = 'Standard Sales Draft Invoice - Blue (Word) (FR)';
            Summary = 'The Standard Sales Draft Invoice -Blue (Word) provides a basic layout with a blue theme.';
        }
        layout("StandardDraftSalesInvoiceBlueThemableFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardDraftSalesInvoiceBlueThemable.docx';
            Caption = 'Standard Sales Draft Invoice - themable Word layout (FR)';
            Summary = 'The Standard Sales Draft Invoice -Themable (Word) provides a Themable layout.';
        }
        layout("StandardDraftSalesInvoiceEmailFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardDraftSalesInvoiceEmail.docx';
            Caption = 'Standard Sales Draft Invoice Email (Word) (FR)';
            Summary = 'The Standard Sales Draft Invoice Email (Word) provides a email body layout.';
        }
    }

    var
        CustomerFR: Record Customer;
        FormatAddressFR: Codeunit "Format Address";
        AlternativeAddress: array[8] of Text[100];
        BillToAddrFR: array[8] of Text[100];
        ShipToAddrFR: array[8] of Text[100];
        AlternativeAddressTxt: Text;
        ShiptoAddrLbl: Label 'Ship-to Address';
        IncludesGoodsLbl: Label 'Sales invoice includes only goods.';
        IncludesServicesLbl: Label 'Sales invoice includes only services.';
        IncludesGoodsAndServicesLbl: Label 'Sales invoice includes goods and services.';

    local procedure FillFRFields()
    var
        i: Integer;
    begin
        if not CustomerFR.Get(Header."Bill-to Customer No.") then
            Clear(CustomerFR);

        Clear(AlternativeAddress);
        AlternativeAddressTxt := '';

        FormatAddressFR.SalesHeaderBillTo(BillToAddrFR, Header);
        if FormatAddressFR.SalesHeaderShipTo(ShipToAddrFR, BillToAddrFR, Header) then begin
            for i := 1 to 8 do
                AlternativeAddress[i] := ShipToAddrFR[i];
            AlternativeAddressTxt := ShiptoAddrLbl;
        end;
    end;

    local procedure GetGoodsAndServicesText(): Text
    var
        SalesLine: Record "Sales Line";
        GotGoods: Boolean;
        GotServices: Boolean;
    begin
        SalesLine.SetRange("Document No.", Header."No.");
        SalesLine.SetRange("Document Type", Header."Document Type");
        SalesLine.SetFilter(Type, '<> %1', SalesLine.Type::Item);
        if not SalesLine.IsEmpty() then
            GotServices := true;
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetLoadFields("No.");
        if SalesLine.FindSet() then
            repeat
                if IsItemInventory(SalesLine."No.") then
                    GotGoods := true
                else
                    GotServices := true;
            until SalesLine.Next() = 0;
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
