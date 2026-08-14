// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using System.Text;

report 6627 "SN Label"
{
    UsageCategory = Tasks;
    ApplicationArea = All;
    Caption = 'SN Label';
    WordMergeDataItem = "Serial No. Information";
    DefaultRenderingLayout = Word;
    //DefaultHeaderFooterPart = None;
    //DefaultThemePart = "BC Default Theme";

    dataset
    {
        dataitem("Serial No. Information"; "Serial No. Information")
        {
            DataItemTableView = sorting("Item No.");
            RequestFilterFields = "Item No.";
            RequestFilterHeading = 'Serial No. Information';

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

            column(SerialNo; SerialNoCode)
            {
            }

            column(SerialNo_2D; SerialNoQRCode)
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
                if "Serial No." <> '' then begin
                    BarcodeString := "Serial No.";
                    // Validate the input
                    BarcodeFontProvider.ValidateInput(BarcodeString, BarcodeSymbology);
                    // Encode the data string to the barcode font
                    SerialNoCode := BarcodeFontProvider.EncodeFont(BarcodeString, BarcodeSymbology);
                    SerialNoQRCode := BarcodeFontProvider2D.EncodeFont(BarcodeString, BarcodeSymbology2D);
                end
            end;

        }
    }
    rendering
    {
//#if not CLEAN32
        layout(Word)
        {
            Type = Word;
            LayoutFile = './Inventory/Tracking/SNLabel.docx';
            Summary = 'Report layout made for print. Use a Word editor to modify the layout.';
            ObsoleteState = Pending;
            ObsoleteReason = 'This Word layout will be replaced by the Document Report Experience. Use the corresponding composite (body) layout instead. It will be removed in a future release.';
            ObsoleteTag = '32.0';
        }
//#endif
        layout(WordBody)
        {
            Type = Word;
            //Subtype = Body;
            LayoutFile = './Inventory/Tracking/SNLabelBody.docx';
            Caption = 'Body-only: SN Label (Word)';
            Summary = 'Portrait item tracking label. Item description and number with the serial number as text and a 2D barcode. For labelling serial-tracked items.';
        }
    }

    var
        BarcodeSymbology: Enum "Barcode Symbology";
        BarcodeSymbology2D: Enum "Barcode Symbology 2D";
        SerialNoCode: Text;
        SerialNoQRCode: Text;


    trigger OnInitReport()
    begin
        BarcodeSymbology := Enum::"Barcode Symbology"::Code39;
        BarcodeSymbology2D := Enum::"Barcode Symbology 2D"::"QR-Code";
    end;
}
