// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using System.Text;

report 6628 "Lot No Label"
{
    UsageCategory = Tasks;
    ApplicationArea = All;
    Caption = 'Lot No Label';
    WordMergeDataItem = "Lot No. Information";
    DefaultRenderingLayout = Word;

    dataset
    {
        dataitem("Lot No. Information"; "Lot No. Information")
        {
            DataItemTableView = sorting("Item No.");
            RequestFilterFields = "Item No.";
            RequestFilterHeading = 'Lot No. Information';

            // Column that provides the data string for the barcode
            column(ItemNo; "Item No.")
            {
            }

            column(Description; "Description")
            {
            }

            column(Variant_Code; "Variant Code")
            {
            }

            column(LotNo; LotNoCode)
            {
            }

            column(LotNo_2D; LotNoQRCode)
            {
            }

            trigger OnAfterGetRecord()
            var
                Item: Record "Item";
                BarcodeString: Text;
                BarcodeFontProvider: Interface "Barcode Font Provider";
                BarcodeFontProvider2D: Interface "Barcode Font Provider 2D";

            begin
                // Declare the barcode provider using the barcode provider interface and enum
                BarcodeFontProvider := Enum::"Barcode Font Provider"::IDAutomation1D;
                BarcodeFontProvider2D := Enum::"Barcode Font Provider 2D"::IDAutomation2D;

                Item.SetLoadFields(Item.Description);
                Item.Get("Item No.");
                Description := Item.Description;

                // Set data string source 
                if "Lot No." <> '' then begin
                    BarcodeString := "Lot No.";
                    // Validate the input
                    BarcodeFontProvider.ValidateInput(BarcodeString, BarcodeSymbology);
                    // Encode the data string to the barcode font
                    LotNoCode := BarcodeFontProvider.EncodeFont(BarcodeString, BarcodeSymbology);
                    LotNoQRCode := BarcodeFontProvider2D.EncodeFont(BarcodeString, BarcodeSymbology2D);
                end
            end;

        }
    }
    rendering
    {
        layout(Word)
        {
            Type = Word;
            LayoutFile = './Inventory/Tracking/LotNoLabel.docx';
        }
    }

    var
        BarcodeSymbology: Enum "Barcode Symbology";
        BarcodeSymbology2D: Enum "Barcode Symbology 2D";
        LotNoCode: Text;
        LotNoQRCode: Text;


    trigger OnInitReport()
    begin
        BarcodeSymbology := Enum::"Barcode Symbology"::Code39;
        BarcodeSymbology2D := Enum::"Barcode Symbology 2D"::"QR-Code";
    end;
}
