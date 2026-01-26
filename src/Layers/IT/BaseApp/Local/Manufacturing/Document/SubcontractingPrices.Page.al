#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;
using System.Globalization;

page 12156 "Subcontracting Prices"
{
    Caption = 'Subcontracting Prices';
    DataCaptionExpression = GetCaption();
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "Subcontractor Prices";
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendNoFilterCtrl; VendNoFilter)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Vendor No. Filter';
                    ToolTip = 'Specifies the filter for finding the vendor.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vendor: Record Vendor;
                        VendList: Page "Vendor List";
                    begin
                        Vendor.SetRange(Subcontractor, true);
                        VendList.SetTableView(Vendor);
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
                field(WorkCenterFilterCtrl; WorkCenterFilter)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Work Center Filter';
                    ToolTip = 'Specifies the work center filter.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WorkCenter: Record "Work Center";
                        WorkCenterList: Page "Work Center List";
                    begin
                        WorkCenter.SetFilter("Subcontractor No.", '<>%1', '');
                        WorkCenterList.SetTableView(WorkCenter);
                        WorkCenterList.LookupMode := true;
                        if WorkCenterList.RunModal() = ACTION::LookupOK then
                            Text := WorkCenterList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        WorkCenterFilterOnAfterValidat();
                    end;
                }
                field(TaskCodeFilterCtrl; TaskCodeFilter)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Task Code Filter';
                    ToolTip = 'Specifies the task code filter.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TaskList: Page "Standard Tasks";
                    begin
                        TaskList.Editable := false;
                        TaskList.LookupMode := true;
                        if TaskList.RunModal() = ACTION::LookupOK then
                            Text := TaskList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        TaskCodeFilterOnAfterValidate();
                    end;
                }
                field(ItemNoFIlterCtrl; ItemNoFilter)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Item No. Filter';
                    ToolTip = 'Specifies the item filter.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        Item.SetFilter("Routing No.", '<>%1', '');
                        ItemList.SetTableView(Item);
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
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Date Filter';
                    ToolTip = 'Specifies the starting date filter.';

                    trigger OnValidate()
                    begin
                        StartingDateFilterOnAfterValid();
                    end;
                }
            }
            repeater(Control1130004)
            {
                ShowCaption = false;
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code that is assigned to the work center and that is associated with the subcontracting price.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code assigned to the vendor that is associated with the subcontracting price.';
                }
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code assigned to the standard task that is associated with the subcontracting price.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code assigned to the item that is associated with the subcontracting price.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the variant code assigned to the item that is associated with the subcontracting price.';
                    Visible = false;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the start date that is associated with the subcontracting price.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the end date that is associated with the subcontracting price.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code assigned to the unit of measure that is associated with the subcontracting price.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the minimum quantity that your order must total for the subcontracting order to be granted the subcontracting price.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the currency that is associated with the document.';
                    Visible = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the direct unit cost that is associated with the subcontracting price.';
                }
                field("Minimum Amount"; Rec."Minimum Amount")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the minimum amount that your order must total for the subcontracting order to be granted the subcontracting price.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        GetRecFilters();
        SetRecFilters();
    end;

    var
        Vend: Record Vendor;

    protected var
        VendNoFilter: Code[30];
        ItemNoFilter: Code[30];
        WorkCenterFilter: Code[30];
        TaskCodeFilter: Code[30];
        StartingDateFilter: Text[30];

    [Scope('OnPrem')]
    procedure GetRecFilters()
    begin
        if Rec.GetFilters() <> '' then begin
            VendNoFilter := CopyStr(Rec.GetFilter("Vendor No."), 1, MaxStrLen(VendNoFilter));
            ItemNoFilter := CopyStr(Rec.GetFilter("Item No."), 1, MaxStrLen(ItemNoFilter));
            WorkCenterFilter := CopyStr(Rec.GetFilter("Work Center No."), 1, MaxStrLen(WorkCenterFilter));
            TaskCodeFilter := CopyStr(Rec.GetFilter("Standard Task Code"), 1, MaxStrLen(TaskCodeFilter));
            Evaluate(StartingDateFilter, CopyStr(Rec.GetFilter("Start Date"), 1, MaxStrLen(StartingDateFilter)));
        end;
    end;

    [Scope('OnPrem')]
    procedure SetRecFilters()
    begin
        if VendNoFilter <> '' then
            Rec.SetFilter("Vendor No.", VendNoFilter)
        else
            Rec.SetRange("Vendor No.");

        if StartingDateFilter <> '' then
            Rec.SetFilter("Start Date", StartingDateFilter)
        else
            Rec.SetRange("Start Date");

        if ItemNoFilter <> '' then
            Rec.SetFilter("Item No.", ItemNoFilter)
        else
            Rec.SetRange("Item No.");

        if WorkCenterFilter <> '' then
            Rec.SetFilter("Work Center No.", WorkCenterFilter)
        else
            Rec.SetRange("Work Center No.");

        if TaskCodeFilter <> '' then
            Rec.SetFilter("Standard Task Code", TaskCodeFilter)
        else
            Rec.SetRange("Standard Task Code");

        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure GetCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
        SourceTableName: Text[100];
        Description: Text[250];
    begin
        GetRecFilters();

        if ItemNoFilter <> '' then
            SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 27)
        else
            SourceTableName := '';

        Vend."No." := VendNoFilter;
        if Vend.Find() then
            Description := Vend.Name;

        exit(StrSubstNo('%1 %2 %3 %4 ', VendNoFilter, Description, SourceTableName, ItemNoFilter));
    end;

    local procedure VendNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure WorkCenterFilterOnAfterValidat()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure ItemNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure StartingDateFilterOnAfterValid()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure TaskCodeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;
}
#endif

