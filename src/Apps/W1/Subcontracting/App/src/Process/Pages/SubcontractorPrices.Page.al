// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;
using System.Globalization;
using System.Text;

page 99001500 "Subcontractor Prices"
{
    ApplicationArea = Manufacturing;
    Caption = 'Subcontractor Prices';
    DataCaptionExpression = GetCaption();
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Subcontractor Price";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendNoFilterCtrl; VendNoFilter)
                {
                    Caption = 'Vendor No. Filter';
                    ToolTip = 'Specifies a filter for which subcontractor prices display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VendorList: Page "Vendor List";
                    begin
                        VendorList.LookupMode := true;
                        if VendorList.RunModal() = Action::LookupOK then
                            Text := VendorList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        VendNoFilterOnAfterValidate();
                    end;
                }
                field(WorkCenterNoFilterCtrl; WorkCenterNoFilter)
                {
                    Caption = 'Work Center No. Filter';
                    ToolTip = 'Specifies a filter for which subcontractor prices to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WorkCenter: Record "Work Center";
                        WorkCenterList: Page "Work Center List";
                    begin
                        WorkCenter.SetFilter("Subcontractor No.", '<>%1', '');
                        WorkCenterList.SetTableView(WorkCenter);
                        WorkCenterList.LookupMode := true;
                        if WorkCenterList.RunModal() = Action::LookupOK then
                            Text := WorkCenterList.GetCurrSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        WorkCenterNoFilterOnAfterValidate();
                    end;
                }
                field(TaskCodeFilterCtrl; StandardTaskCodeFilter)
                {
                    Caption = 'Standard Task Code Filter';
                    ToolTip = 'Specifies a filter for which subcontractor prices to display.';

                    trigger OnValidate()
                    begin
                        StandardTaskCodeFilterOnAfterValidate();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        StandardTasks: Page "Standard Tasks";
                    begin

                        StandardTasks.Editable(false);
                        StandardTasks.LookupMode(true);
                        if StandardTasks.RunModal() = Action::LookupOK then
                            Text := StandardTasks.GetCurrSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;
                }
                field(ItemNoFilterCtrl; ItemNoFilter)
                {
                    Caption = 'Item No. Filter';
                    ToolTip = 'Specifies a filter for which purchase prices to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        Item.SetFilter("Routing No.", '<>%1', '');
                        ItemList.SetTableView(Item);
                        ItemList.LookupMode := true;
                        if ItemList.RunModal() = Action::LookupOK then
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
                field(StartingDateFilterCtrl; StartingDateFilter)
                {
                    Caption = 'Starting Date Filter';
                    ToolTip = 'Specifies a filter for which subcontractor prices to display.';

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

                field("Work Center No."; Rec."Work Center No.")
                {
                    ToolTip = 'Specifies the number of the work center that the subcontractor price applies to.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ToolTip = 'Specifies the number of the vendor who offers the line subcontractor price on the item.';
                }
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ToolTip = 'Specifies the code of the standard task that the subcontractor price applies to.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the number of the Item that the subcontractor price applies to.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ToolTip = 'Specifies the date from which the subcontractor price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ToolTip = 'Specifies the date to which the subcontractor price is valid.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies how each unit of the item is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item card is inserted.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ToolTip = 'Specifies the minimum quantity of the item that you must buy from the vendor in order to get the subcontractor price.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency code of the subcontractor price.';
                    Visible = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ToolTip = 'Specifies the cost of one unit of the selected item.';
                }
                field("Minimum Amount"; Rec."Minimum Amount")
                {
                    ToolTip = 'Specifies the minimum amount of the item that you must buy from the vendor in order to get the subcontractor price.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Control1900383207; Links)
            {
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                Visible = false;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CopyPrices)
            {
                Caption = 'Copy Subcontractor Prices';
                Image = Copy;
                ToolTip = 'Select prices and press OK to copy them to Vendor No. and Work Center No.';
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
        IsLookupMode := CurrPage.LookupMode();
    end;

    var
        Vendor: Record Vendor;
        IsLookupMode: Boolean;
        MultipleVendorsSelectedErr: Label 'More than one vendor uses these subcontractor prices. To copy prices, the Vendor No. Filter field must contain one vendor only.';
        MultipleWorkCenterSelectedErr: Label 'More than one work center uses these subcontractor prices. To copy prices, the Vendor No. Filter field must contain one vendor only.';
        NoDataWithinFilterErr: Label 'There is no %1 within the filter %2.',
            Comment = '@@@=%1: Field(Code), %2: GetFilter(Code)';
        ItemNoFilter: Text;
        StandardTaskCodeFilter: Text;
        StartingDateFilter: Text;
        VendNoFilter: Text;
        WorkCenterNoFilter: Text;

    local procedure GetRecFilters()
    begin
        if Rec.GetFilters() <> '' then begin
            VendNoFilter := Rec.GetFilter("Vendor No.");
            ItemNoFilter := Rec.GetFilter("Item No.");
            WorkCenterNoFilter := Rec.GetFilter("Work Center No.");
            StandardTaskCodeFilter := Rec.GetFilter("Standard Task Code");
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

        if WorkCenterNoFilter <> '' then
            Rec.SetFilter("Work Center No.", WorkCenterNoFilter)
        else
            Rec.SetRange("Work Center No.");

        if StandardTaskCodeFilter <> '' then
            Rec.SetFilter("Standard Task Code", StandardTaskCodeFilter)
        else
            Rec.SetRange("Standard Task Code");

        CheckFilters(Database::Vendor, VendNoFilter);
        CheckFilters(Database::"Work Center", WorkCenterNoFilter);
        CheckFilters(Database::Item, ItemNoFilter);
        CheckFilters(Database::"Standard Task", StandardTaskCodeFilter);

        CurrPage.Update(false);
    end;

    local procedure GetCaption(): Text
    var
        ObjectTranslation: Record "Object Translation";
        PlaceholderLbl: Label '%1 %2 %3 %4 ', Locked = true;
        Description: Text[100];
        SourceTableName: Text[250];
    begin
        GetRecFilters();

        if ItemNoFilter <> '' then
            SourceTableName := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, 27)
        else
            SourceTableName := '';

        if Vendor.Get(CopyStr(VendNoFilter, 1, MaxStrLen(Vendor."No."))) then
            Description := Vendor.Name;

        exit(StrSubstNo(PlaceholderLbl, VendNoFilter, Description, SourceTableName, ItemNoFilter));
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

    local procedure WorkCenterNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure StandardTaskCodeFilterOnAfterValidate()
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
            Error(NoDataWithinFilterErr, FilterRecordRef.Caption(), FilterTxt);
    end;

    local procedure CopyPricesToVendor()
    var
        SelectedSubcontractorPrice: Record "Subcontractor Price";
        SubcontractorPrice: Record "Subcontractor Price";
        ToVendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrices: Page "Subcontractor Prices";
        CopyToVendorNo: Code[20];
        CopyToWorkCenterNo: Code[20];
    begin
        ToVendor.SetFilter("No.", VendNoFilter);
        if ToVendor.Count() <> 1 then
            Error(MultipleVendorsSelectedErr);
        CopyToVendorNo := CopyStr(VendNoFilter, 1, MaxStrLen(CopyToVendorNo));

        WorkCenter.SetFilter("No.", WorkCenterNoFilter);
        if WorkCenter.Count() <> 1 then
            Error(MultipleWorkCenterSelectedErr);
        CopyToWorkCenterNo := CopyStr(WorkCenterNoFilter, 1, MaxStrLen(CopyToWorkCenterNo));

        SubcontractorPrice.SetFilter("Vendor No.", StrSubstNo('<>%1', VendNoFilter));
        SubcontractorPrice.SetFilter("Work Center No.", WorkCenterNoFilter);
        if ItemNoFilter <> '' then
            SubcontractorPrice.SetRange("Item No.", ItemNoFilter);
        SubcontractorPrices.LookupMode(true);
        SubcontractorPrices.SetTableView(SubcontractorPrice);
        if SubcontractorPrices.RunModal() = Action::LookupOK then begin
            SubcontractorPrices.GetSelectionFilter(SelectedSubcontractorPrice);
            Rec.CopySubcontractorPriceToVendorsSubcontractorPrice(SelectedSubcontractorPrice, CopyToVendorNo, CopyToWorkCenterNo);
        end;
    end;

    procedure GetSelectionFilter(var SubcontractorPrice: Record "Subcontractor Price")
    begin
        CurrPage.SetSelectionFilter(SubcontractorPrice);
    end;
}