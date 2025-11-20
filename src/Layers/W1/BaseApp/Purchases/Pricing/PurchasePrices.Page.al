// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using System.Text;
using System.Globalization;

page 7012 "Purchase Prices"
{
    Caption = 'Purchase Prices';
    DataCaptionExpression = GetCaption();
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Purchase Price";

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
                    ToolTip = 'Specifies a filter for which purchase prices display.';

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
                field(ItemNoFIlterCtrl; ItemNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No. Filter';
                    ToolTip = 'Specifies a filter for which purchase prices to display.';

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
                    ToolTip = 'Specifies a filter for which purchase prices to display.';

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
                    ToolTip = 'Specifies the number of the vendor who offers the line discount on the item.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item that the purchase price applies to.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the purchase price.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum quantity of the item that you must buy from the vendor in order to get the purchase price.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which the purchase price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date to which the purchase price is valid.';
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
        area(processing)
        {
            action(CopyPrices)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Prices';
                Image = Copy;
                ToolTip = 'Select prices and press OK to copy them to Vendor No.';
                Visible = not IsLookupMode;

                trigger OnAction()
                begin
                    CopyPricesToVendor();
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyPrices_Promoted; CopyPrices)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        GetRecFilters();
        SetRecFilters();
        IsLookupMode := CurrPage.LookupMode;
    end;

    var
        Vend: Record Vendor;
        VendNoFilter: Text;
        ItemNoFilter: Text;
        StartingDateFilter: Text[30];
        NoDataWithinFilterErr: Label 'There is no %1 within the filter %2.', Comment = '%1: Field(Code), %2: GetFilter(Code)';
        MultipleVendorsSelectedErr: Label 'More than one vendor uses these purchase prices. To copy prices, the Vendor No. Filter field must contain one vendor only.';
        IsLookupMode: Boolean;

    local procedure GetRecFilters()
    begin
        if Rec.GetFilters() <> '' then begin
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

        CheckFilters(DATABASE::Vendor, VendNoFilter);
        CheckFilters(DATABASE::Item, ItemNoFilter);

        CurrPage.Update(false);
    end;

    local procedure GetCaption(): Text
    var
        ObjTransl: Record "Object Translation";
        SourceTableName: Text[250];
        Description: Text[100];
    begin
        GetRecFilters();

        if ItemNoFilter <> '' then
            SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 27)
        else
            SourceTableName := '';

        if Vend.Get(CopyStr(VendNoFilter, 1, MaxStrLen(Vend."No."))) then
            Description := Vend.Name;

        exit(StrSubstNo('%1 %2 %3 %4 ', VendNoFilter, Description, SourceTableName, ItemNoFilter));
    end;

    local procedure VendNoFilterOnAfterValidate()
    var
        Item: Record Item;
    begin
        if Item.Get(Rec."Item No.") then
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

    procedure CheckFilters(TableNo: Integer; FilterTxt: Text)
    var
        FilterRecordRef: RecordRef;
        FilterFieldRef: FieldRef;
    begin
        if FilterTxt = '' then
            exit;
        Clear(FilterRecordRef);
        Clear(FilterFieldRef);
        FilterRecordRef.Open(TableNo);
        FilterFieldRef := FilterRecordRef.Field(1);
        FilterFieldRef.SetFilter(FilterTxt);
        if FilterRecordRef.IsEmpty() then
            Error(NoDataWithinFilterErr, FilterRecordRef.Caption, FilterTxt);
    end;

    local procedure CopyPricesToVendor()
    var
        Vendor: Record Vendor;
        PurchasePrice: Record "Purchase Price";
        SelectedPurchasePrice: Record "Purchase Price";
        PurchasePrices: Page "Purchase Prices";
        CopyToVendorNo: Code[20];
    begin
        Vendor.SetFilter("No.", VendNoFilter);
        if Vendor.Count <> 1 then
            Error(MultipleVendorsSelectedErr);
        CopyToVendorNo := CopyStr(VendNoFilter, 1, MaxStrLen(CopyToVendorNo));

        PurchasePrice.SetFilter("Vendor No.", '<>%1', VendNoFilter);
        PurchasePrices.LookupMode(true);
        PurchasePrices.SetTableView(PurchasePrice);
        if PurchasePrices.RunModal() = ACTION::LookupOK then begin
            PurchasePrices.GetSelectionFilter(SelectedPurchasePrice);
            Rec.CopyPurchPriceToVendorsPurchPrice(SelectedPurchasePrice, CopyToVendorNo);
        end;
    end;

    procedure GetSelectionFilter(var PurchasePrice: Record "Purchase Price")
    begin
        CurrPage.SetSelectionFilter(PurchasePrice);
    end;
}
