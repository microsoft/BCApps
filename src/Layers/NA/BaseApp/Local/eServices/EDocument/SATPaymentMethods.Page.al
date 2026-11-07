// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27018 "SAT Payment Methods"
{
    Caption = 'SAT Payment Methods';
    PageType = List;
    SourceTable = "SAT Payment Method";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT payment method definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT payment method definition.';
                }
            }
        }
    }

    actions
    {
    }
}

