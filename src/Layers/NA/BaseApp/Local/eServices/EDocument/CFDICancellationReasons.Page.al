// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27003 "CFDI Cancellation Reasons"
{
    Caption = 'CFDI Cancellation Reasons';
    PageType = List;
    SourceTable = "CFDI Cancellation Reason";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT cancellation reason definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT cancellation reason definition.';
                }
                field("Substitution Number Required"; Rec."Substitution Number Required")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether a substitution number is required for this entry according to the SAT cancellation reason definition.';
                }
            }
        }
    }

    actions
    {
    }
}

