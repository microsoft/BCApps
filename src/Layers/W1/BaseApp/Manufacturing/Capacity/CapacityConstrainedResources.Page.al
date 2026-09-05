// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.Reports;

page 99000866 "Capacity Constrained Resources"
{
    AdditionalSearchTerms = 'finite loading';
    ApplicationArea = Manufacturing;
    Caption = 'Capacity Constrained Resources';
    PageType = List;
    SourceTable = "Capacity Constrained Resource";
    UsageCategory = Administration;

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
                field("Capacity No."; Rec."Capacity No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    Enabled = true;
                }
                field("Critical Load %"; Rec."Critical Load %")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Dampener (% of Total Capacity)"; Rec."Dampener (% of Total Capacity)")
                {
                    ApplicationArea = Manufacturing;
                    Editable = true;
                    ToolTip = 'Specifies the tolerance as a percent that you will allow the critical load percent to be exceeded for this work or machine center.';
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
        area(reporting)
        {
            action("Work/Machine Center Load")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work/Machine Center Load';
                Image = "Report";
                RunObject = Report "Work/Machine Center Load";
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';
                actionref("Work/Machine Center Load_Promoted"; "Work/Machine Center Load")
                {
                }
            }
        }
    }
}

