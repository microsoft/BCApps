// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 745 "VAT Report Error Log"
{
    Caption = 'VAT Report Error Log';
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Error Log";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the error message that is the result of validating a VAT report.';
                }
            }
        }
    }

    actions
    {
    }
}

