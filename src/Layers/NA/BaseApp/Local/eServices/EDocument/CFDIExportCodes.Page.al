// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27004 "CFDI Export Codes"
{
    Caption = 'CFDI Export Codes';
    PageType = List;
    SourceTable = "CFDI Export Code";
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
                    ToolTip = 'Specifies a code for this entry according to the CFDI export definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the CFDI export definition.';
                }
                field("Foreign Trade"; Rec."Foreign Trade")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry indicates foreing trade according to the SAT export definition.';
                }
            }
        }
    }

    actions
    {
    }
}

