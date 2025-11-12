// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using System.Text;

report 6626 "Reference No Label"
{
    UsageCategory = Tasks;
    ApplicationArea = All;
    Caption = 'Reference No. Label';
    WordMergeDataItem = ItemReference;
    DefaultRenderingLayout = Word;

    dataset
    {
        dataitem(ItemReference; "Item Reference")
        {
            DataItemTableView = sorting("Item No.");
            RequestFilterFields = "Item No.";
            RequestFilterHeading = 'ItemReference';

            // Column that provides the data string for the barcode
            column(Item_No_; "Item No.")
            {
            }
            column(Description; Description)
            {

            }
            column(Unit_of_Measure; "Unit of Measure")
            {

            }
            column(Reference_No_; ReferenceNoCode)
            {

            }
            column(Reference_No_2D; ReferenceNoQRCode)
            {

            }
            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                BarcodeString: Text;
                BarcodeFontProvider: Interface "Barcode Font Provider";
                BarcodeFontProvider2D: Interface "Barcode Font Provider 2D";

            begin
                // Declare the barcode provider using the barcode provider interface and enum
                BarcodeFontProvider := Enum::"Barcode Font Provider"::IDAutomation1D;
                BarcodeFontProvider2D := Enum::"Barcode Font Provider 2D"::IDAutomation2D;

                // Set data string source 
                if "Reference No." <> '' then begin
                    BarcodeString := "Reference No.";
                    // Validate the input
                    BarcodeFontProvider.ValidateInput(BarcodeString, BarcodeSymbology);

                    // Encode the data string to the barcode font
                    ReferenceNoCode := BarcodeFontProvider.EncodeFont(BarcodeString, BarcodeSymbology);
                    ReferenceNoQRCode := BarcodeFontProvider2D.EncodeFont(BarcodeString, BarcodeSymbology2D);
                end;

                if Description = '' then begin
                    Item.SetLoadFields(Item.Description);
                    Item.Get("Item No.");
                    Description := Item.Description;
                end
            end;

        }
    }
    rendering
    {
        layout(Word)
        {
            Type = Word;
            LayoutFile = './Inventory/Reports/ReferenceNoLabel.docx';
        }
    }

    var
        BarcodeSymbology: Enum "Barcode Symbology";
        BarcodeSymbology2D: Enum "Barcode Symbology 2D";
        ReferenceNoCode: Text;
        ReferenceNoQRCode: Text;


    trigger OnInitReport()
    begin
        BarcodeSymbology := Enum::"Barcode Symbology"::Code39;
        BarcodeSymbology2D := Enum::"Barcode Symbology 2D"::"QR-Code";
    end;
}
