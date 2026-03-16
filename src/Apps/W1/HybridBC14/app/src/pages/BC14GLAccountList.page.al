// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

page 50173 "BC14 G/L Account List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "BC14 G/L Account";
    Caption = 'BC14 G/L Account Buffer';
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L account number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L account name.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the account type.';
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this is an income statement or balance sheet account.';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the totaling formula.';
                }
                field("Direct Posting"; Rec."Direct Posting")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether direct posting is allowed.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the account is blocked.';
                }
            }
        }
    }
}
