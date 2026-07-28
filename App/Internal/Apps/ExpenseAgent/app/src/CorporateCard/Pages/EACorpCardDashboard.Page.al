// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7228 "EACorpCardDashboard"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Import Dashboard';
    PageType = RoleCenter;
    UsageCategory = Administration;

    layout
    {
        area(RoleCenter)
        {
            group(Group1)
            {
                part(RecentBatches; EACorpCardDashboardFactbox)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Group2)
            {
                part(Statistics; EACorpCardStatisticsFactbox)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(Sections)
        {
            group(CorpCards)
            {
                action(Providers)
                {
                    Caption = 'Providers';
                    ApplicationArea = Basic, Suite;
                    Image = Setup;
                    RunObject = Page EACorpCardProviders;
                    ToolTip = 'View and manage corporate card providers.';
                }
                action(Transactions)
                {
                    Caption = 'Transactions';
                    ApplicationArea = Basic, Suite;
                    Image = List;
                    RunObject = Page EACorpCardTransList;
                    ToolTip = 'View imported corporate card transactions.';
                }
                action(Batches)
                {
                    Caption = 'Import Batches';
                    ApplicationArea = Basic, Suite;
                    Image = History;
                    RunObject = Page EACorpCardBatches;
                    ToolTip = 'View all import batches.';
                }
                action(Exceptions)
                {
                    Caption = 'Exceptions';
                    ApplicationArea = Basic, Suite;
                    Image = ErrorLog;
                    RunObject = Page EACorpCardExceptions;
                    ToolTip = 'View import exceptions and errors.';
                }
                action(Setup)
                {
                    Caption = 'Setup';
                    ApplicationArea = Basic, Suite;
                    Image = Setup;
                    RunObject = Page EACorpCardSetupPage;
                    ToolTip = 'Configure import settings and rules.';
                }
            }
        }
    }
}
