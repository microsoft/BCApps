// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Purchases.Vendor;
using System.Globalization;
using System.Text;

page 7014 "Purchase Line Discounts"
{
    Caption = 'Purchase Line Discounts';
    DataCaptionExpression = GetCaption();
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Purchase Line Discount";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendNoFilterCtrl; VendNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor No. Filter';
                    ToolTip = 'Specifies a filter for which purchase line discounts display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VendList: Page "Vendor List";
                    begin
                        VendList.LookupMode := true;
                        if VendList.RunModal() = ACTION::LookupOK then
                            Text := VendList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        VendNoFilterOnAfterValidate();
                    end;
                }
                field(ItemNoFilterCtrl; ItemNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No. Filter';
                    ToolTip = 'Specifies a filter for which purchase line discounts to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode := true;
                        if ItemList.RunModal() = ACTION::LookupOK then
                            Text := ItemList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        ItemNoFilterOnAfterValidate();
                    end;
                }
                field(StartingDateFilter; StartingDateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date Filter';
                    ToolTip = 'Specifies a filter for which purchase line discounts to display.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(StartingDateFilter);
                        StartingDateFilterOnAfterValid();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureEnabled();
    end;

    var
        VendNoFilter: Text;
        ItemNoFilter: Text;
        StartingDateFilter: Text[30];

    local procedure GetRecFilters()
    begin
        if Rec.GetFilters <> '' then begin
            VendNoFilter := Rec.GetFilter("Vendor No.");
            ItemNoFilter := Rec.GetFilter("Item No.");
            Evaluate(StartingDateFilter, Rec.GetFilter("Starting Date"));
        end;
    end;

    procedure SetRecFilters()
    begin
        if VendNoFilter <> '' then
            Rec.SetFilter("Vendor No.", VendNoFilter)
        else
            Rec.SetRange("Vendor No.");

        if StartingDateFilter <> '' then
            Rec.SetFilter("Starting Date", StartingDateFilter)
        else
            Rec.SetRange("Starting Date");

        if ItemNoFilter <> '' then
            Rec.SetFilter("Item No.", ItemNoFilter)
        else
            Rec.SetRange("Item No.");

        CurrPage.Update(false);
    end;

    local procedure GetCaption(): Text[250]
    var
        Vendor: Record Vendor;
        ObjTransl: Record "Object Translation";
        SourceTableName: Text[250];
        Description: Text[250];
    begin
        GetRecFilters();

        if ItemNoFilter <> '' then
            SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DATABASE::Item)
        else
            SourceTableName := '';

        if VendNoFilter = '' then
            Description := ''
        else begin
            Vendor.SetFilter("No.", VendNoFilter);
            if Vendor.FindFirst() then
                Description := Vendor.Name;
        end;

        exit(StrSubstNo('%1 %2 %3 %4 ', VendNoFilter, Description, SourceTableName, ItemNoFilter));
    end;

    local procedure VendNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure StartingDateFilterOnAfterValid()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure ItemNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;
}
