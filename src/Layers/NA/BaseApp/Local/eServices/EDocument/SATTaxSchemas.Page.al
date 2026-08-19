// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27016 "SAT Tax Schemas"
{
    Caption = 'SAT Tax Schemas';
    PageType = List;
    SourceTable = "SAT Tax Scheme";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("SAT Tax Scheme"; Rec."SAT Tax Scheme")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT tax scheme definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT tax scheme definition.';
                }
            }
        }
    }

    actions
    {
    }
}

