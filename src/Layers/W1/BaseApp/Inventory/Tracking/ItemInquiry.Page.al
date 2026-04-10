// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Catalog;

page 6530 "Item Inquiry"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    RefreshOnActivate = true;
    Caption = 'Item Inquiry';

    layout
    {
        area(content)
        {
            group(ItemInquiry)
            {
                Caption = 'Item Inquiry';

                field(BarcodeNo; BarcodeNo)
                {
                    ApplicationArea = All;
                    Caption = 'Barcode No.';
                    ToolTip = 'Enter/Scan the GTIN/Reference No. to search for an item.';
                    ExtendedDatatype = Barcode;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if BarcodeNo <> '' then
                            BarcodeNo := BarcodeNo.ToUpper();

                        SearchAndOpenItem()
                    end;
                }
            }
        }
    }

    local procedure SearchAndOpenItem()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemCard: Page "Item Card";
    begin
        Item.SetFilter(GTIN, BarcodeNo);
        if Item.FindFirst() then begin
            ItemCard.SetRecord(Item);
            ItemCard.Run();
        end else begin
            ItemReference.SetRange("Reference Type", Enum::"Item Reference Type"::"Bar Code");
            ItemReference.SetFilter("Reference No.", BarcodeNo);
            ItemReference.SetLoadFields("Item No.");
            if ItemReference.FindFirst() then begin
                Item.Reset();
                if ItemReference."Item No." <> '' then
                    Item.SetRange("No.", ItemReference."Item No.");
                if Item.Find('-') then begin
                    ItemCard.SetRecord(Item);
                    ItemCard.Run();
                end else
                    Message(ItemNotFoundLbl);
            end else
                Message(ItemNotFoundLbl);
        end;
    end;

    var
        BarcodeNo: Text[50];
        ItemNotFoundLbl: Label 'Item with specified barcode (GTIN/Reference No.) not found.';
}
