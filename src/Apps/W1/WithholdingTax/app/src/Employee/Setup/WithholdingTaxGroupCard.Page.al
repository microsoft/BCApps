// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

page 6790 "Withholding Tax Group Card"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Withholding Tax Group Card';
    PageType = Card;
    SourceTable = "Withholding Tax Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the withholding tax group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the withholding tax group.';
                }
                field("Party Applicability"; Rec."Party Applicability")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which party type this withholding tax group applies to.';
                }
            }
            part(Lines; "WHT Group Lines Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Group Lines';
                SubPageLink = "Group Code" = field(Code);
            }
        }
    }
}
