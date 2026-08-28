#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

reportextension 10817 "Standard Sales Invoice FR Ext" extends "Standard Sales - Invoice"
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
        layout("StandardSalesInvoiceFR.rdlc")
        {
            Type = RDLC;
            LayoutFile = './src/ReportExtensions/StandardSalesInvoiceFR.rdlc';
            Caption = 'Standard Sales Invoice (RDLC) (FR)';
            Summary = 'The Standard Sales Invoice (RDLC) is the most detailed layout and provides most flexible layout options.';
        }
        layout("StandardSalesInvoiceFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesInvoiceFR.docx';
            Caption = 'Standard Sales Invoice (Word) (FR)';
            Summary = 'The Standard Sales Invoice (Word) provides a simple layout that is also relatively easy for an end-user to modify.';
        }
        layout("StandardSalesInvoiceBlueSimpleFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesInvoiceBlueSimple.docx';
            Caption = 'Standard Sales Invoice - Blue (Word) (FR)';
            Summary = 'The Standard Sales Invoice - Blue (Word) provides a simple layout with a blue theme.';
        }
        layout("StandardSalesInvoiceBlueSimpleThemableFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesInvoiceBlueSimpleThemable.docx';
            Caption = 'Standard Sales Invoice - themable Word layout (FR)';
            Summary = 'The Standard Sales Invoice - Themable (Word) provides a simple Themable layout.';
        }
        layout("StandardSalesInvoiceVatSpecFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesInvoiceVatSpec.docx';
            Caption = 'Standard Sales Invoice - VAT Spec (Word) (FR)';
            Summary = 'The Standard Sales Invoice - VAT Spec (Word) provides a layout with VAT Specification.';
        }
        layout("StandardSalesInvoiceDefEmailFR.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/StandardSalesInvoiceDefEmail.docx';
            Caption = 'Standard Sales Invoice Email (Word) (FR)';
            Summary = 'The Standard Sales Invoice Email (Word) provides the default email body layout.';
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

        FormatAddressFR.SalesInvBillTo(BillToAddrFR, Header);
        if FormatAddressFR.SalesInvShipTo(ShipToAddrFR, BillToAddrFR, Header) then begin
            for i := 1 to 8 do
                AlternativeAddress[i] := ShipToAddrFR[i];
            AlternativeAddressTxt := ShiptoAddrLbl;
        end;
    end;

    local procedure GetGoodsAndServicesText(): Text
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        GotGoods: Boolean;
        GotServices: Boolean;
    begin
        SalesInvoiceLine.SetRange("Document No.", Header."No.");
        SalesInvoiceLine.SetFilter(Type, '<> %1', SalesInvoiceLine.Type::Item);
        if not SalesInvoiceLine.IsEmpty() then
            GotServices := true;
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetLoadFields("No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                if IsItemInventory(SalesInvoiceLine."No.") then
                    GotGoods := true
                else
                    GotServices := true;
            until SalesInvoiceLine.Next() = 0;
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
