// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// A FactBox page displaying source currency information for a G/L account.
/// This page shows the balances and currency details for different currencies in which entries have been posted to the account.
/// </summary>
page 590 "G/L Account Currency FactBox"
{
    Caption = 'Source Currencies';
    Editable = false;
    PageType = ListPart;
    SourceTable = "G/L Account Source Currency";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Balance at Date"; Rec."Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Source Curr. Balance at Date"; Rec."Source Curr. Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Entries Exists"; Rec."Entries Exists")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

