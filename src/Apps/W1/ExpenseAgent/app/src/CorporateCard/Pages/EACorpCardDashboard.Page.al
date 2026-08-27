// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7228 "EA Corp Card Dashboard"
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
                part(RecentBatches; "EA Corp Card Dashboard Fact")
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
        area(Sections)
        {
            group(CorpCards)
            {
                action(Providers)
                {
                    Caption = 'Providers';
                    ApplicationArea = Basic, Suite;
                    Image = Setup;
                    RunObject = Page "EA Corp Card Providers";
                    ToolTip = 'View and manage corporate card providers.';
                }
                action(Transactions)
                {
                    Caption = 'Transactions';
                    ApplicationArea = Basic, Suite;
                    Image = List;
                    RunObject = Page "EA Corp Card Trans List";
                    ToolTip = 'View imported corporate card transactions.';
                }
                action(Batches)
                {
                    Caption = 'Import Batches';
                    ApplicationArea = Basic, Suite;
                    Image = History;
                    RunObject = Page "EA Corp Card Batches";
                    ToolTip = 'View all import batches.';
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
