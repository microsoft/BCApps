// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.MachineCenter;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;

page 99000760 "Machine Center Card"
{
    Caption = 'Machine Center Card';
    PageType = Card;
    SourceTable = "Machine Center";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Overhead Rate"; Rec."Overhead Rate")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
            }
            group(Scheduling)
            {
                Caption = 'Scheduling';
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field(Efficiency; Rec.Efficiency)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Queue Time"; Rec."Queue Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Queue Time Unit of Meas. Code"; Rec."Queue Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                }
            }
            group("Routing Setup")
            {
                Caption = 'Routing Setup';
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Move Time"; Rec."Move Time")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Minimum Process Time"; Rec."Minimum Process Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Maximum Process Time"; Rec."Maximum Process Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Open Shop Floor Bin Code"; Rec."Open Shop Floor Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Enabled = OpenShopFloorBinCodeEnable;
                }
                field("To-Production Bin Code"; Rec."To-Production Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Enabled = ToProductionBinCodeEnable;
                }
                field("From-Production Bin Code"; Rec."From-Production Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Enabled = FromProductionBinCodeEnable;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Mach. Ctr.")
            {
                Caption = '&Mach. Ctr.';
                Image = MachineCenter;
                action("Capacity Ledger E&ntries")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Ledger E&ntries';
                    Image = CapacityLedger;
                    RunObject = Page "Capacity Ledger Entries";
                    RunPageLink = Type = const("Machine Center"),
                                  "No." = field("No."),
                                  "Posting Date" = field("Date Filter");
                    RunPageView = sorting(Type, "No.", "Item No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "No." = field("No.");
                    RunPageView = where("Table Name" = const("Machine Center"));
                    ToolTip = 'View or add comments for the record.';
                }
                action("Lo&ad")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Lo&ad';
                    Image = WorkCenterLoad;
                    RunObject = Page "Machine Center Load";
                    RunPageLink = "No." = field("No."),
                                  "Work Shift Filter" = field("Work Shift Filter");
                    ToolTip = 'View the availability of the machine or work center, including its capacity, the allocated quantity, availability after orders, and the load in percent of its total capacity.';
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Machine Center Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Work Shift Filter" = field("Work Shift Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
            group("Pla&nning")
            {
                Caption = 'Pla&nning';
                Image = Planning;
                action("&Calendar")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Calendar';
                    Image = MachineCenterCalendar;
                    RunObject = Page "Machine Center Calendar";
                    ToolTip = 'Open the shop calendar, for example to see the load.';
                }
                action("A&bsence")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'A&bsence';
                    Image = WorkCenterAbsence;
                    RunObject = Page "Capacity Absence";
                    RunPageLink = "Capacity Type" = const("Machine Center"),
                                  "No." = field("No."),
                                  Date = field("Date Filter");
                    ToolTip = 'View which working days are not available. ';
                }
                action("Ta&sk List")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ta&sk List';
                    Image = TaskList;
                    RunObject = Page "Machine Center Task List";
                    RunPageLink = "No." = field("No.");
                    RunPageView = sorting(Type, "No.")
                                  where(Type = const("Machine Center"),
                                        Status = filter(.. Released),
                                        "Routing Status" = filter(<> Finished));
                    ToolTip = 'View the list of operations that are scheduled for the machine center.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Lo&ad_Promoted"; "Lo&ad")
                {
                }
                actionref("&Calendar_Promoted"; "&Calendar")
                {
                }
                actionref("A&bsence_Promoted"; "A&bsence")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Machine Center', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEnabled();
    end;

    trigger OnInit()
    begin
        FromProductionBinCodeEnable := true;
        ToProductionBinCodeEnable := true;
        OpenShopFloorBinCodeEnable := true;
    end;

    trigger OnOpenPage()
    begin
        OnActivateForm();
    end;

    var
        OpenShopFloorBinCodeEnable: Boolean;
        ToProductionBinCodeEnable: Boolean;
        FromProductionBinCodeEnable: Boolean;

    local procedure UpdateEnabled()
    var
        Location: Record Location;
        EditEnabled: Boolean;
    begin
        if Rec."Location Code" <> '' then
            Location.Get(Rec."Location Code");

        EditEnabled := (Rec."Location Code" <> '') and Location."Bin Mandatory";
        OpenShopFloorBinCodeEnable := EditEnabled;
        ToProductionBinCodeEnable := EditEnabled;
        FromProductionBinCodeEnable := EditEnabled;
    end;

    local procedure OnActivateForm()
    begin
        UpdateEnabled();
    end;
}

