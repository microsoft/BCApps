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
                    ToolTip = 'Specifies the code for the Project WIP Method. There are system-defined codes. In addition, you can create a Project WIP Method, and the code for it is in the list of Project WIP Methods.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description of the project WIP method. If the WIP method is system-defined, you cannot edit the description.';
                }
                field("Recognized Costs"; Rec."Recognized Costs")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a Recognized Cost option to apply when creating a calculation method for WIP. You must select one of the five options:';
                }
                field("Recognized Sales"; Rec."Recognized Sales")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a Recognized Sales option to apply when creating a calculation method for WIP. You must select one of the six options:';
                }
                field("WIP Cost"; Rec."WIP Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if the Project Costs Applied and Recognized Costs are posted to the general ledger. For system defined WIP methods, the WIP Cost field is always enabled. For WIP methods that you create, you can only clear the check box if you set Recognized Costs to Usage (Total Cost). ';
                }
                field("WIP Sales"; Rec."WIP Sales")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if the contract (invoiced price) is posted to the general ledger. For system-defined WIP methods, the WIP Sales field is the default and is checked. For WIP methods that you create, you can only clear the check box if you set Recognized Sales to Contract (Invoiced Price).';
                }
                field(Valid; Rec.Valid)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a WIP method can be associated with a project when you are creating or modifying a project. If you select this check box in the Project WIP Methods window, you can then set the method as a default WIP method in the Projects Setup window.';
                }
                field("System Defined"; Rec."System Defined")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a Project WIP Method is system-defined.';
                }
            }
        }
    }

    actions
    {
    }
}

