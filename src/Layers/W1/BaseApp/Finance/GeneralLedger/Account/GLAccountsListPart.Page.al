// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// A list part page displaying G/L accounts filtered to show only posting accounts.
/// This page is typically used as a subpage or part within other forms to allow selection of posting-type G/L accounts.
/// </summary>
page 791 "G/L Accounts ListPart"
{
    Caption = 'G/L Accounts ListPart';
    Editable = false;
    PageType = ListPart;
    SourceTable = "G/L Account";
    SourceTableView = where("Account Type" = const(Posting));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies is the general ledger account is an income statement account or a balance sheet account.';
                }
            }
        }
    }

    actions
    {
    }
}

