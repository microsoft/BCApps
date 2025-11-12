// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using System.Text;

report 6625 "Item GTIN Label"
{
    UsageCategory = Tasks;
    ApplicationArea = All;
    Caption = 'Item GTIN Label';
    WordMergeDataItem = Items;
    DefaultRenderingLayout = Word;

    dataset
    {
        dataitem(Items; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Items';

            // Column that provides the data string for the barcode
            column(No_; "No.")
            {
            }

            column(Description; Description)
            {
            }

            column(GTIN; GTINBarCode)
            {
            }

            column(GTIN_2D; GTINQRCode)
            {
            }

            trigger OnAfterGetRecord()
            var
                BarcodeString: Text;
                BarcodeFontProvider: Interface "Barcode Font Provider";
                BarcodeFontProvider2D: Interface "Barcode Font Provider 2D";

            begin
                // Clear strings
                GTINBarCode := '';
                GTINQRCode := '';

                // Set data string source
                if GTIN <> '' then begin
                    // Declare the barcode provider using the barcode provider interface and enum
                    BarcodeFontProvider := Enum::"Barcode Font Provider"::IDAutomation1D;
                    BarcodeFontProvider2D := Enum::"Barcode Font Provider 2D"::IDAutomation2D;

                    BarcodeString := GTIN;
                    // Validate the input
                    BarcodeFontProvider.ValidateInput(BarcodeString, BarcodeSymbology);
                    // Encode the data string to the barcode font
                    GTINBarCode := BarcodeFontProvider.EncodeFont(BarcodeString, BarcodeSymbology);
                    GTINQRCode := BarcodeFontProvider2D.EncodeFont(BarcodeString, BarcodeSymbology2D);
                end;
            end;
        }
    }

    rendering
    {
        layout(Word)
        {
            Type = Word;
            LayoutFile = './Inventory/Item/ItemGTINLabel.docx';
        }
    }

    var
        BarcodeSymbology: Enum "Barcode Symbology";
        BarcodeSymbology2D: Enum "Barcode Symbology 2D";
        GTINBarCode: Text;
        GTINQRCode: Text;

    trigger OnInitReport()
    begin
        BarcodeSymbology := Enum::"Barcode Symbology"::Code39;
        BarcodeSymbology2D := Enum::"Barcode Symbology 2D"::"QR-Code";
    end;
}
