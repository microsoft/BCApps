// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 10771 "SII Purch. Doc. Scheme Codes"
{
    Caption = 'SII Purchase Document Special Scheme Codes';
    PageType = List;
    SourceTable = "SII Purch. Doc. Scheme Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Special Scheme Code"; Rec."Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the special scheme codes that are used for VAT reporting.';
                }
            }
        }
    }

    actions
    {
    }
}

