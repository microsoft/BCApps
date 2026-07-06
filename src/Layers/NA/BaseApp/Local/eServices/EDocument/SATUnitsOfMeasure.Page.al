// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27043 "SAT Units Of Measure"
{
    Caption = 'SAT Units of Measure';
    PageType = List;
    SourceTable = "SAT Unit of Measure";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("SAT UofM Code"; Rec."SAT UofM Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT unit of measure definition.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a name for this entry according to the SAT unit of measure definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT unit of measure definition.';
                }
                field(Symbol; Rec.Symbol)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a symbol for this entry according to the SAT unit of measure definition.';
                }
            }
        }
    }

    actions
    {
    }
}

