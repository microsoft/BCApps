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
#if not CLEAN27
            action("Work Center Load")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Center Load';
                Image = "Report";
                RunObject = Report "Work Center Load";
                ToolTip = 'Get an overview of availability at the work center, such as the capacity, the allocated quantity, availability after order, and the load in percent.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the "Work/Machine Center Load" report and will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
            action("Work Center Load/Bar")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Center Load/Bar';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Work Center Load/Bar";
                ToolTip = 'View a list of work centers that are overloaded according to the plan. The efficiency or overloading is shown by efficiency bars.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the "Work/Machine Center Load" report and will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
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
            group(Category_Report)
            {
                Caption = 'Reports';
#if not CLEAN27
                actionref("Work Center Load_Promoted"; "Work Center Load")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the "Work/Machine Center Load" report and will be removed in a future release.';
                    ObsoleteTag = '27.0';
                }
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

