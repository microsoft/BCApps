// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Ledger;
using System.Text;

report 99000769 "Output Item Label"
{
    UsageCategory = Tasks;
    ApplicationArea = Manufacturing;
    WordMergeDataItem = ItemLedgerEntry;
    DefaultRenderingLayout = Word;
    Caption = 'Production Output Item Label';

    dataset
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableView = where("Entry Type" = const("Item Ledger Entry Type"::"Output"));
            RequestFilterFields = "Order No.", "Item No.";

            column(ItemNo; "Item No.")
            {
            }
            column(Description; ItemDescription)
            {
            }
            column(BaseUnitofMeasure; ItemBaseUnitOfMeasure)
            {
            }
            column(VariantCode; "Variant Code")
            {
            }
            column(BarCode; BarCode)
            {
            }
            column(QRCode; QRCode)
            {
            }

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                BarcodeString: Text;
                BarcodeFontProvider: Interface "Barcode Font Provider";
                BarcodeFontProvider2D: Interface "Barcode Font Provider 2D";
            begin
                BarcodeFontProvider := Enum::"Barcode Font Provider"::IDAutomation1D;
                BarcodeFontProvider2D := Enum::"Barcode Font Provider 2D"::IDAutomation2D;

                case ItemTrackingType of
                    ItemTrackingType::"Serial No.":
                        BarcodeString := "Serial No.";
                    ItemTrackingType::"Lot No.":
                        BarcodeString := "Lot No.";
                    ItemTrackingType::"Package No.":
                        BarcodeString := "Package No.";
                end;

                if StrLen(BarcodeString) > 0 then begin
                    BarcodeFontProvider.ValidateInput(BarcodeString, BarcodeSymbology);
                    BarCode := BarcodeFontProvider.EncodeFont(BarcodeString, BarcodeSymbology);
                    QRCode := BarcodeFontProvider2D.EncodeFont(BarcodeString, BarcodeSymbology2D);

                    if Item.Get("Item No.") then begin
                        ItemDescription := Item.Description;
                        ItemBaseUnitOfMeasure := Item."Base Unit of Measure";
                    end
                end else
                    CurrReport.Skip();
            end;

        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'Print labels for posted output items';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Item Tracking Type"; ItemTrackingType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Tracking Type';
                        ToolTip = 'Specifies which type of Item Tracking No. to print on the label.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout(Word)
        {
            Type = Word;
            LayoutFile = './Manufacturing/Document/OutputItemLabel.docx';
        }
    }

    var
        BarcodeSymbology: Enum "Barcode Symbology";
        BarcodeSymbology2D: Enum "Barcode Symbology 2D";
        ItemBaseUnitOfMeasure: Code[10];
        BarCode, QRCode, ItemDescription : Text;
        ItemTrackingType: Enum "Item Tracking Type";

    trigger OnInitReport()
    begin
        BarcodeSymbology := Enum::"Barcode Symbology"::Code39;
        BarcodeSymbology2D := Enum::"Barcode Symbology 2D"::"QR-Code";
    end;

}
