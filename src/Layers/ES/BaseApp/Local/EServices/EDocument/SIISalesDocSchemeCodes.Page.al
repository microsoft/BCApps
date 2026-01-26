// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 10770 "SII Sales Doc. Scheme Codes"
{
    Caption = 'SII Sales Document Special Scheme Codes';
    PageType = List;
    SourceTable = "SII Sales Document Scheme Code";

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

