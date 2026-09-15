// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Catalog;
using Microsoft.Warehouse.Structure;

page 6531 "Item Bin Content Inquiry"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    RefreshOnActivate = true;
    Caption = 'Item Bin Content Inquiry';

    layout
    {
        area(content)
        {
            group(ItemInquiry)
            {
                Caption = 'Item Bin Content Inquiry';

                field(BarcodeNo; BarcodeNo)
                {
                    ApplicationArea = All;
                    Caption = 'Barcode No.';
                    ToolTip = 'Enter/Scan the GTIN/Reference No. to search for an item in Bin.';
                    ExtendedDatatype = Barcode;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if BarcodeNo <> '' then
                            BarcodeNo := BarcodeNo.ToUpper();
                        SearchAndOpenBinContent();
                    end;
                }
            }
        }
    }

    local procedure SearchAndOpenBinContent()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        BinContent: Record "Bin Content";
        BinContentPage: Page "Bin Content";
    begin
        Item.SetFilter(GTIN, BarcodeNo);
        Item.SetLoadFields("No.");
        if Item.Find('-') then begin
            if Item."No." <> '' then
                BinContent.SetRange("Item No.", Item."No.");
            if BinContent.FindSet() then begin
                BinContentPage.SetTableView(BinContent);
                BinContentPage.RunModal();
            end else
                Message(ItemNotFoundLbl);
        end else begin
            ItemReference.SetRange("Reference Type", Enum::"Item Reference Type"::"Bar Code");
            ItemReference.SetFilter("Reference No.", BarcodeNo);
            ItemReference.SetLoadFields("Item No.", "Unit of Measure");
            if ItemReference.FindFirst() then begin
                Item.Reset();
                if ItemReference."Item No." <> '' then
                    Item.SetRange("No.", ItemReference."Item No.");
                if Item.FindFirst() then begin
                    if Item."No." <> '' then
                        BinContent.SetRange("Item No.", Item."No.");
                    if ItemReference."Unit of Measure" <> '' then
                        BinContent.SetRange("Unit of Measure Code", ItemReference."Unit of Measure");
                    if BinContent.FindSet() then begin
                        BinContentPage.SetTableView(BinContent);
                        BinContentPage.RunModal();
                    end else
                        Message(ItemNotFoundLbl);
                end
            end else
                Message(ItemNotFoundLbl);
        end;
    end;

    var
        BarcodeNo: Text[50];
        ItemNotFoundLbl: Label 'Bin content with item having the specified barcode (GTIN/Reference No.) not found.';
}
