// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

page 1010 "Job WIP Methods"
{
    AdditionalSearchTerms = 'work in process  to general ledger methods,work in progress to general ledger methods, Job WIP Methods';
    ApplicationArea = Jobs;
    Caption = 'Project WIP Methods';
    PageType = List;
    SourceTable = "Job WIP Method";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("Recognized Costs"; Rec."Recognized Costs")
                {
                    ApplicationArea = Jobs;
                }
                field("Recognized Sales"; Rec."Recognized Sales")
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Cost"; Rec."WIP Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if the Project Costs Applied and Recognized Costs are posted to the general ledger. For system defined WIP methods, the WIP Cost field is always enabled. For WIP methods that you create, you can only clear the check box if you set Recognized Costs to Usage (Total Cost). ';
                }
                field("WIP Sales"; Rec."WIP Sales")
                {
                    ApplicationArea = Jobs;
                }
                field(Valid; Rec.Valid)
                {
                    ApplicationArea = Jobs;
                }
                field("System Defined"; Rec."System Defined")
                {
                    ApplicationArea = Jobs;
                }
            }
        }
    }

    actions
    {
    }
}

