// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7438 "EA Corp Card Dashboard"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corporate Card Dashboard';
    PageType = Card;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Group1)
            {
                part(RecentStatements; "EA Corp Card Dashboard Fact")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Group2)
            {
                part(Statistics; "EA Corp Card Stats Factbox")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(CorpCards)
            {
                Caption = 'Corporate Cards';

                action(Cards)
                {
                    Caption = 'Corporate Cards';
                    ApplicationArea = Basic, Suite;
                    Image = Card;
                    RunObject = Page "EA Corp Card Cards";
                    ToolTip = 'View and manage corporate cards.';
                }
                action(Providers)
                {
                    Caption = 'Corporate Card Providers';
                    ApplicationArea = Basic, Suite;
                    Image = Setup;
                    RunObject = Page "EA Corp Card Providers";
                    ToolTip = 'View and manage corporate card providers.';
                }
                action(Transactions)
                {
                    Caption = 'Corporate Card Transactions';
                    ApplicationArea = Basic, Suite;
                    Image = List;
                    RunObject = Page "EA Corp Card Trans List";
                    ToolTip = 'View imported corporate card transactions.';
                }
                action(ProviderStatements)
                {
                    Caption = 'Corporate Card Statements';
                    ApplicationArea = Basic, Suite;
                    Image = Documents;
                    RunObject = Page "EA Corp Card Statements";
                    ToolTip = 'View and validate corporate card provider statements.';
                }
                action(Settlements)
                {
                    Caption = 'Corporate Card Settlements';
                    ApplicationArea = Basic, Suite;
                    Image = Payment;
                    RunObject = Page "EA Corp Card Settlements";
                    ToolTip = 'View and prepare corporate card provider settlements.';
                }
                action(Exceptions)
                {
                    Caption = 'Exceptions';
                    ApplicationArea = Basic, Suite;
                    Image = ErrorLog;
                    RunObject = Page "EA Corp Card Exceptions";
                    ToolTip = 'View import exceptions and errors.';
                }
                action(Setup)
                {
                    Caption = 'Setup';
                    ApplicationArea = Basic, Suite;
                    Image = Setup;
                    RunObject = Page "Expense Agent Setup";
                    ToolTip = 'Configure import settings and rules.';
                }
            }
        }
    }
}
