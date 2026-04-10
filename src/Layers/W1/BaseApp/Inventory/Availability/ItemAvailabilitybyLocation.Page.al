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

page 492 "Item Availability by Location"
{
    Caption = 'Item Availability by Location';
    DataCaptionFields = "No.", Description;
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ItemPeriodLength; ItemPeriodLength)
                {
                    ApplicationArea = Location;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        if ItemPeriodLength = ItemPeriodLength::"Accounting Period" then
                            PeriodItemPeriodLengthOnValida();
                        if ItemPeriodLength = ItemPeriodLength::Year then
                            YearItemPeriodLengthOnValidate();
                        if ItemPeriodLength = ItemPeriodLength::Quarter then
                            QuarterItemPeriodLengthOnValid();
                        if ItemPeriodLength = ItemPeriodLength::Month then
                            MonthItemPeriodLengthOnValidat();
                        if ItemPeriodLength = ItemPeriodLength::Week then
                            WeekItemPeriodLengthOnValidate();
                        if ItemPeriodLength = ItemPeriodLength::Day then
                            DayItemPeriodLengthOnValidate();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Location;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        if AmountType = AmountType::"Balance at Date" then
                            BalanceatDateAmountTypeOnValid();
                        if AmountType = AmountType::"Net Change" then
                            NetChangeAmountTypeOnValidate();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Date Filter';
                    Editable = false;
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                }
            }
            part(ItemAvailLocLines; "Item Avail. by Location Lines")
            {
                ApplicationArea = Location;
                Editable = false;
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
                        ApplicationArea = Location;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItem(Rec, "Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Location;
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
                        ApplicationArea = Location;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItem(Rec, "Item Availability Type"::BOM);
                        end;
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

    trigger OnAfterGetRecord()
    begin
        Rec.SetRange("Drop Shipment Filter", false);
        FindPeriod('');
        UpdateSubForm();
    end;

    trigger OnClosePage()
    var
        Location: Record Location;
    begin
        CurrPage.ItemAvailLocLines.PAGE.GetRecord(Location);
        LastLocation := Location.Code;
    end;

    trigger OnOpenPage()
    begin
        FindPeriod('');
    end;

    protected var
        Calendar: Record Date;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        AmountType: Enum "Analysis Amount Type";
        ItemPeriodLength: Enum "Analysis Period Type";
        LastLocation: Code[10];
        DateFilter: Text;

    local procedure FindPeriod(SearchText: Code[10])
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageMgt.FindDate('+', Calendar, ItemPeriodLength) then
                PeriodPageMgt.FindDate('+', Calendar, "Analysis Period Type"::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageMgt.FindDate(SearchText, Calendar, ItemPeriodLength);
        if AmountType = AmountType::"Net Change" then begin
            Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
            if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
                Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        end else
            Rec.SetRange("Date Filter", 0D, Calendar."Period End");
        DateFilter := Rec.GetFilter("Date Filter");
    end;

    protected procedure UpdateSubForm()
    begin
        CurrPage.ItemAvailLocLines.PAGE.SetLines(Rec, AmountType);
    end;

    procedure GetLastLocation(): Code[10]
    begin
        exit(LastLocation);
    end;

    local procedure PeriodItemPeriodLengthOnPush()
    begin
        FindPeriod('');
        UpdateSubForm();
    end;

    local procedure YearItemPeriodLengthOnPush()
    begin
        FindPeriod('');
        UpdateSubForm();
    end;

    local procedure QuarterItemPeriodLengthOnPush()
    begin
        FindPeriod('');
        UpdateSubForm();
    end;

    local procedure MonthItemPeriodLengthOnPush()
    begin
        FindPeriod('');
        UpdateSubForm();
    end;

    local procedure WeekItemPeriodLengthOnPush()
    begin
        FindPeriod('');
        UpdateSubForm();
    end;

    local procedure DayItemPeriodLengthOnPush()
    begin
        FindPeriod('');
        UpdateSubForm();
    end;

    local procedure NetChangeAmountTypeOnPush()
    begin
        FindPeriod('');
        UpdateSubForm();
    end;

    local procedure BalanceatDateAmountTypeOnPush()
    begin
        FindPeriod('');
        UpdateSubForm();
    end;

    local procedure DayItemPeriodLengthOnValidate()
    begin
        DayItemPeriodLengthOnPush();
    end;

    local procedure WeekItemPeriodLengthOnValidate()
    begin
        WeekItemPeriodLengthOnPush();
    end;

    local procedure MonthItemPeriodLengthOnValidat()
    begin
        MonthItemPeriodLengthOnPush();
    end;

    local procedure QuarterItemPeriodLengthOnValid()
    begin
        QuarterItemPeriodLengthOnPush();
    end;

    local procedure YearItemPeriodLengthOnValidate()
    begin
        YearItemPeriodLengthOnPush();
    end;

    local procedure PeriodItemPeriodLengthOnValida()
    begin
        PeriodItemPeriodLengthOnPush();
    end;

    local procedure NetChangeAmountTypeOnValidate()
    begin
        NetChangeAmountTypeOnPush();
    end;

    local procedure BalanceatDateAmountTypeOnValid()
    begin
        BalanceatDateAmountTypeOnPush();
    end;
}

