// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 1394 "Trial Balance Setup"
{
    Caption = 'Trial Balance Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Trial Balance Setup";

    layout
    {
        area(content)
        {
            group(Step0)
            {
                Caption = '';
                group(Control1)
                {
                    InstructionalText = 'The Trial Balance page shows a simplified version of the Trial Balance chart. It shows the first nine rows from the rows definition, and the first two columns defined for the column definition in reverse order. The second column is on the left, and the first column is on the right. You can set the order of the columns on the Column Definitions page.';
                    ShowCaption = false;
                }
            }
            group(General)
            {
                Caption = 'General';
                field("Account Schedule Name"; Rec."Account Schedule Name")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the rows definition to use to calculate the results that display in the Trial Balance chart.';
                }
                field("Column Layout Name"; Rec."Column Layout Name")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the columns definition to use to determine how columns display in the Trial Balance chart.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

