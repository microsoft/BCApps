// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using System.Utilities;

report 7053 "Implement Price Change"
{
    Caption = 'Implement Price Change';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Price Worksheet"; "Sales Price Worksheet")
        {
            DataItemTableView = sorting("Starting Date", "Ending Date", "Sales Type", "Sales Code", "Currency Code", "Item No.", "Variant Code", "Unit of Measure Code", "Minimum Quantity");
            RequestFilterFields = "Item No.", "Sales Type", "Sales Code", "Unit of Measure Code", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "Item No.");
                Window.Update(2, "Sales Type");
                Window.Update(3, "Sales Code");
                Window.Update(4, "Currency Code");
                Window.Update(5, "Starting Date");

                SalesPrice.Init();
                SalesPrice.Validate("Item No.", "Item No.");
                SalesPrice.Validate("Sales Type", "Sales Type");
                SalesPrice.Validate("Sales Code", "Sales Code");
                SalesPrice.Validate("Unit of Measure Code", "Unit of Measure Code");
                SalesPrice.Validate("Variant Code", "Variant Code");
                SalesPrice.Validate("Starting Date", "Starting Date");
                SalesPrice.Validate("Ending Date", "Ending Date");
                SalesPrice."Minimum Quantity" := "Minimum Quantity";
                SalesPrice."Currency Code" := "Currency Code";
                SalesPrice."Unit Price" := "New Unit Price";
                SalesPrice."Price Includes VAT" := "Price Includes VAT";
                SalesPrice."Allow Line Disc." := "Allow Line Disc.";
                SalesPrice."Allow Invoice Disc." := "Allow Invoice Disc.";
                SalesPrice."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
                OnAfterCopyToSalesPrice(SalesPrice, "Sales Price Worksheet");
                if SalesPrice."Unit Price" <> 0 then
                    if not SalesPrice.Insert(true) then
                        SalesPrice.Modify(true);
            end;

            trigger OnPostDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                Commit();
                if not DeleteWhstLine then
                    DeleteWhstLine := ConfirmManagement.GetResponseOrDefault(Text005, true);
                if DeleteWhstLine then
                    DeleteAll();
                Commit();
                if SalesPrice.FindFirst() then;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text000 +
                  Text007 +
                  Text008 +
                  Text009 +
                  Text010 +
                  Text011);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        SalesPrice: Record "Sales Price";
        Window: Dialog;
        DeleteWhstLine: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Updating Unit Prices...\\';
        Text005: Label 'The item prices have now been updated in accordance with the suggested price changes.\\Do you want to delete the suggested price changes?';
#pragma warning disable AA0470
        Text007: Label 'Item No.               #1##########\';
        Text008: Label 'Sales Type             #2##########\';
        Text009: Label 'Sales Code             #3##########\';
        Text010: Label 'Currency Code          #4##########\';
        Text011: Label 'Starting Date          #5######';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure InitializeRequest(NewDeleteWhstLine: Boolean)
    begin
        DeleteWhstLine := NewDeleteWhstLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToSalesPrice(var SalesPrice: Record "Sales Price"; SalesPriceWorksheet: Record "Sales Price Worksheet")
    begin
    end;
}
