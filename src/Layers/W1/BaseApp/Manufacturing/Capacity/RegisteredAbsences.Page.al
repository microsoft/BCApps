// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

page 99000920 "Registered Absences"
{
    ApplicationArea = Manufacturing;
    Caption = 'Registered Absences';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Registered Absence";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Capacity Type"; Rec."Capacity Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the absence entry is related to a machine center or a work center.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date of the absence. If the absence covers several days, there will be an entry line for each day.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a short description of the reason for the absence.';
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the starting time, which are combined in a format called "starting date-time".';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting time of the absence, such as the time the employee normally starts to work or the time the machine starts to operate.';
                    Visible = false;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the ending time, which are combined in a format called "ending date-time".';
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending time of day of the absence, such as the time the employee normally leaves, or the time the machine stops operating.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the amount of capacity, which cannot be used during the absence period.';
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
            action("Implement Registered Absence")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Implement Registered Absence';
                Image = ImplementRegAbsence;
                RunObject = Report "Implement Registered Absence";
                ToolTip = 'Implement the absence entries that you have made in the Reg. Abs. (from Machine Ctr.), Reg. Abs. (from Work Center), and Capacity Absence windows.';
            }
            action("Reg. Abs. (from Machine Ctr.)")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Reg. Abs. (from Machine Ctr.)';
                Image = CalendarMachine;
                RunObject = Report "Reg. Abs. (from Machine Ctr.)";
                ToolTip = 'Register planned absences at a machine center. The planned absence can be registered for both human and machine resources. You can register changes in the available resources in the Registered Absence table. When the batch job has been completed, you can see the result in the Registered Absences window.';
            }
            action("Reg. Abs. (from Work Ctr.)")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Reg. Abs. (from Work Ctr.)';
                Image = CalendarWorkcenter;
                RunObject = Report "Reg. Abs. (from Work Center)";
                ToolTip = 'Register planned absences at a machine center. The planned absence can be registered for both human and machine resources. You can register changes in the available resources in the Registered Absence table. When the batch job has been completed, you can see the result in the Registered Absences window.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Implement Registered Absence_Promoted"; "Implement Registered Absence")
                {
                }
                actionref("Reg. Abs. (from Machine Ctr.)_Promoted"; "Reg. Abs. (from Machine Ctr.)")
                {
                }
                actionref("Reg. Abs. (from Work Ctr.)_Promoted"; "Reg. Abs. (from Work Ctr.)")
                {
                }
            }
        }
    }
}

