// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 736 "VAT Return Period FactBox"
{
    Caption = 'Additional Information';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Return Period";

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(WarningText; WarningText)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Style = Unfavorable;
                    StyleExpr = true;
                    ToolTip = 'Specifies the warning text that is displayed for an open or overdue obligation.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        WarningText := Rec.CheckOpenOrOverdue();
    end;

    var
        WarningText: Text;
}

