// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.MachineCenter;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Reports;

page 99000761 "Machine Center List"
{
    ApplicationArea = Manufacturing, Planning;
    Caption = 'Machine Centers';
    CardPageID = "Machine Center Card";
    Editable = false;
    PageType = List;
    SourceTable = "Machine Center";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a name for the machine center.';
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the work center to assign this machine center to.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the capacity of the machine center.';
                }
                field(Efficiency; Rec.Efficiency)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the efficiency factor as a percentage of the machine center.';
                }
                field("Minimum Efficiency"; Rec."Minimum Efficiency")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the minimum efficiency of this machine center.';
                    Visible = false;
                }
                field("Maximum Efficiency"; Rec."Maximum Efficiency")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the maximum efficiency of this machine center.';
                    Visible = false;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how much available capacity must be concurrently planned for one operation at this machine center.';
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the percentage of the center''s cost that includes indirect costs, such as machine maintenance.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Overhead Rate"; Rec."Overhead Rate")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the overhead rate of this machine center.';
                    Visible = false;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the machine center card was last modified.';
                    Visible = false;
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
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
                    RunPageLink = "Table Name" = const("Machine Center"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Lo&ad")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Lo&ad';
                    Image = WorkCenterLoad;
                    RunObject = Page "Machine Center Load";
                    RunPageLink = "No." = field("No.");
                    RunPageView = sorting("No.");
                    ToolTip = 'View the availability of the machine or work center, including its the capacity, the allocated quantity, availability after orders, and the load in percent of its total capacity.';
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
        area(processing)
        {
            action("Calculate Machine Center Calendar")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Calculate Machine Center Calendar';
                Image = CalcWorkCenterCalendar;
                RunObject = Report "Calc. Machine Center Calendar";
                ToolTip = 'Create new calendar entries for the machine center to define the available daily capacity.';
            }
        }
        area(reporting)
        {
#if not CLEAN26
            action("Machine Center List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Center List';
                Image = "Report";
                RunObject = Report "Machine Center List";
                ToolTip = 'View the list of machine centers.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the page Machine Center List and will be removed in a future release.';
                ObsoleteTag = '26.0';
            }
#endif
#if not CLEAN27
            action("Machine Center Load")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Center Load';
                Image = "Report";
                RunObject = Report "Machine Center Load";
                ToolTip = 'Get an overview of availability at the machine center, such as the capacity, the allocated quantity, availability after order, and the load in percent.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the "Work/Machine Center Load" report and will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
            action("Machine Center Load/Bar")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Center Load/Bar';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Machine Center Load/Bar";
                ToolTip = 'View a list of machine centers that are overloaded according to the plan. The efficiency or overloading is shown by efficiency bars.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the "Work/Machine Center Load" report and will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
#endif
            action("Work/Machine Center Load")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work/Machine Center Load';
                Image = "Report";
                RunObject = Report "Work/Machine Center Load";
                ToolTip = 'Get an overview of availability at the work center and machine center, such as the capacity, the allocated quantity, availability after order, and the load in percent.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Calculate Machine Center Calendar_Promoted"; "Calculate Machine Center Calendar")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("&Calendar_Promoted"; "&Calendar")
                {
                }
                actionref("A&bsence_Promoted"; "A&bsence")
                {
                }
                actionref("Ta&sk List_Promoted"; "Ta&sk List")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';
#if not CLEAN26
                actionref("Machine Center List_Promoted"; "Machine Center List")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the page Machine Center List and will be removed in a future release.';
                    ObsoleteTag = '26.0';
                }
#endif
#if not CLEAN27
                actionref("Machine Center Load_Promoted"; "Machine Center Load")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the "Work/Machine Center Load" report and will be removed in a future release.';
                    ObsoleteTag = '27.0';
                }
#endif
                actionref("Work/Machine Center Load_Promoted"; "Work/Machine Center Load")
                {
                }
            }
        }
    }
}

