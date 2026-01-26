// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Finance.GeneralLedger.Journal;

page 11409 "Gen. Journal Templ. List (CBG)"
{
    Caption = 'General Journal Template List';
    Editable = false;
    PageType = List;
    SourceTable = "Gen. Journal Template";

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("No. of CBG Statements"; Rec."No. of CBG Statements")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the number of CBG Statement lines that the bank journal contains.';
                }
            }
        }
    }

    actions
    {
    }
}

