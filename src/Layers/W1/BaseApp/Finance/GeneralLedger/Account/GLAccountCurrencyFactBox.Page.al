// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

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
                    ToolTip = 'Specifies the source currency code.';
                }
                field("Balance at Date"; Rec."Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account balance in local currency.';
                }
                field("Source Curr. Balance at Date"; Rec."Source Curr. Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account balance in source currency.';
                }
                field("Entries Exists"; Rec."Entries Exists")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if general ledger entries with this source currency code exists.';
                }
            }
        }
    }

    actions
    {
    }
}

