// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Utilities;

page 520 "Item Availability by Lot No."
{
    Caption = 'Item Availability by Lot No.';
    DataCaptionFields = "No.", Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    RefreshOnActivate = true;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ItemFilter; ItemNo)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item for which to show availability.';
                    TableRelation = Item;

                    trigger OnValidate()
                    begin
                        if ItemNo <> Rec."No." then begin
                            Rec.SetRange("No.", ItemNo);
                            Rec.Get(ItemNo);
                        end
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the location that availability is shown for.';
                    TableRelation = Location;

                    trigger OnValidate()
                    var
                        Location: Record Location;
                    begin
                        if LocationFilter <> '' then
                            Location.Get(LocationFilter);
                        RefreshPage();
                    end;
                }
                field(VariantFilter; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies the item variant you want to show availability for.';
                    TableRelation = "Item Variant".Code where("Item No." = field("No."));

                    trigger OnValidate()
                    var
                        ItemVariant: Record "Item Variant";
                    begin
                        if VariantFilter <> '' then
                            ItemVariant.Get(Rec."No.", VariantFilter);
                        RefreshPage();
                    end;
                }
                group(Period1)
                {
                    Caption = 'Period';
                    field(PeriodType; PeriodType)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'View by';
                        ToolTip = 'Specifies by which period amounts are displayed.';

                        trigger OnValidate()
                        begin
                            FindPeriod('');
                            UpdateSubForm();
                        end;
                    }
                    field(AmountType; AmountType)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'View as';
                        ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                        trigger OnValidate()
                        begin
                            FindPeriod('');
                            UpdateSubForm();
                        end;
                    }
                    field(DateFilter; DateFilter)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Date Filter';
                        Editable = false;
                        ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                    }
                }

            }
            part(ItemAvailLoTNoLines; "Item Avail. by Lot No. Lines")
            {
                ApplicationArea = ItemTracking;
                Editable = false;
                SubPageLink = "Item No." = field("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                group("&Item Availability by")
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailabilityFormsMgt.ShowItemAvailabilityFromItem(Rec, "Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Period';
                        Image = Period;
                        RunObject = Page "Item Availability by Periods";
                        RunPageLink = "No." = field("No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        RunObject = Page "Item Availability by Variant";
                        RunPageLink = "No." = field("No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailabilityFormsMgt.ShowItemAvailabilityFromItem(Rec, "Item Availability Type"::BOM);
                        end;
                    }
                    action(Location)
                    {
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        RunObject = Page "Item Availability by Location";
                        RunPageLink = "No." = field("No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                        ToolTip = 'View the actual and projected quantity of the item per location.';
                    }
                }
            }
        }
        area(processing)
        {
            action(PreviousPeriod)
            {
                ApplicationArea = Location;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                    UpdateSubForm();
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Location;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                    UpdateSubForm();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(PreviousPeriod_Promoted; PreviousPeriod)
                {
                }
                actionref(NextPeriod_Promoted; NextPeriod)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ItemNo := Rec.GetFilter("No.");

        if HasFilterSet(Rec.GetFilter("Location Filter")) then
            LocationFilter := Rec.GetFilter("Location Filter");
        if HasFilterSet(Rec.GetFilter("Variant Filter")) then
            VariantFilter := Rec.GetFilter("Variant Filter");

        Rec.SetRange("No.");
    end;

    trigger OnAfterGetRecord()
    begin
        if (xRec."No." <> '') and (xRec."No." <> Rec."No.") then
            VariantFilter := '';
        ItemNo := Rec."No.";
        FindPeriod('');
        RefreshPage();
    end;

    var
        CalendarDate: Record Date;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        DateFilter: Text;
        ItemNo: Text;
        LocationFilter: Text;
        VariantFilter: Text;
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    procedure RefreshPage()
    begin
        if LocationFilter = '' then
            Rec.SetRange("Location Filter")
        else
            Rec.SetFilter("Location Filter", LocationFilter);

        if VariantFilter = '' then
            Rec.SetRange("Variant Filter")
        else
            Rec.SetFilter("Variant Filter", VariantFilter);
        UpdateSubForm();
    end;

    protected procedure UpdateSubForm()
    begin
        CurrPage.ItemAvailLoTNoLines.PAGE.SetItem(Rec, AmountType);
    end;

    local procedure FindPeriod(SearchText: Code[3])
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            CalendarDate.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageMgt.FindDate('+', CalendarDate, PeriodType) then
                PeriodPageMgt.FindDate('+', CalendarDate, PeriodType::Day);
            CalendarDate.SetRange("Period Start");
        end;
        PeriodPageMgt.FindDate(SearchText, CalendarDate, PeriodType);
        if AmountType = AmountType::"Net Change" then begin
            Rec.SetRange("Date Filter", CalendarDate."Period Start", CalendarDate."Period End");
            if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
                Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        end else
            Rec.SetRange("Date Filter", 0D, CalendarDate."Period End");
        DateFilter := Rec.GetFilter("Date Filter");
    end;

    local procedure HasFilterSet(content: Text): Boolean
    begin
        exit((content <> '') and (content <> ''''''));
    end;
}

