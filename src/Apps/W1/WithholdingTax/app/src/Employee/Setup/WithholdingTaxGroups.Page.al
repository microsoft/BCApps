// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

page 6789 "Withholding Tax Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Withholding Tax Groups';
    PageType = List;
    SourceTable = "Withholding Tax Group";
    Editable = false;
    UsageCategory = Lists;
    CardPageId = "Withholding Tax Group Card";

    layout
    {
        area(content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;
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
        }
    }
}
