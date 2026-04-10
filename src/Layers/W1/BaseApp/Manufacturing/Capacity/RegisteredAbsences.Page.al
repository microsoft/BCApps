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
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
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

