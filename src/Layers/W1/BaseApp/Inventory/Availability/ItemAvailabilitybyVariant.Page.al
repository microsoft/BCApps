// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using System.Utilities;

page 5414 "Item Availability by Variant"
{
    Caption = 'Item Availability by Variant';
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
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Planning;
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
                    ApplicationArea = Planning;
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
            part(ItemAvailLocLines; "Item Avail. by Variant Lines")
            {
                ApplicationArea = Planning;
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
                    action("<Action4>")
                    {
                        ApplicationArea = Planning;
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
                        ApplicationArea = Planning;
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
                    action(Location)
                    {
                        ApplicationArea = Planning;
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
                    action("BOM Level")
                    {
                        ApplicationArea = Planning;
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
                ApplicationArea = Planning;
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
                ApplicationArea = Planning;
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
        ItemVariant: Record "Item Variant";
    begin
        CurrPage.ItemAvailLocLines.PAGE.GetRecord(ItemVariant);
        LastVariant := ItemVariant.Code;
    end;

    trigger OnOpenPage()
    begin
        FindPeriod('');
    end;

    var
        Calendar: Record Date;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        LastVariant: Code[10];

    protected var
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        DateFilter: Text;

    local procedure FindPeriod(SearchText: Text[3])
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageMgt.FindDate('+', Calendar, PeriodType) then
                PeriodPageMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageMgt.FindDate(SearchText, Calendar, PeriodType);
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
        CurrPage.ItemAvailLocLines.PAGE.Set(Rec, AmountType);
    end;

    procedure GetLastVariant(): Code[10]
    begin
        exit(LastVariant);
    end;
}

