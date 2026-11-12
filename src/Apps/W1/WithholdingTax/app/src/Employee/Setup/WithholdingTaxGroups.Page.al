// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax.Employee;

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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Party Applicability"; Rec."Party Applicability")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}
