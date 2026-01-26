// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

page 2000043 "CODA Statement Info"
{
    Caption = 'CODA Statement Info';
    Editable = false;
    PageType = List;
    SourceTable = "CODA Statement Line";
    SourceTableView = sorting("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Statement Message"; Rec."Statement Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the message as reflected on the bank account statement.';
                }
            }
        }
    }

    actions
    {
    }
}

