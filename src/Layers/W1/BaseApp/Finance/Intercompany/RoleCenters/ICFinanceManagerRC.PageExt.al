// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Reports;
using Microsoft.Intercompany.Setup;

/// <summary>
/// Extends the Finance Manager Role Center with Intercompany-specific functionality.
/// Adds navigation actions for IC transactions, setup, and reporting.
/// </summary>
pageextension 8406 "IC Finance Manager RC" extends "Finance Manager Role Center"
{
    actions
    {
        addafter("Group2")
        {
            group("Group3")
            {
                Caption = 'Intercompany';
                action("General Journals")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Intercompany General Journal';
                    RunObject = page "IC General Journal";
                    Tooltip = 'Open the Intercompany General Journal page.';
                }
                action("Inbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Intercompany Inbox Transactions';
                    RunObject = page "IC Inbox Transactions";
                    Tooltip = 'Open the Intercompany Inbox Transactions page.';
                }
                action("Outbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Intercompany Outbox Transactions';
                    RunObject = page "IC Outbox Transactions";
                    Tooltip = 'Open the Intercompany Outbox Transactions page.';
                }
                action("Handled Inbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Handled Intercompany Inbox Transactions';
                    RunObject = page "Handled IC Inbox Transactions";
                    Tooltip = 'Open the Handled Intercompany Inbox Transactions page.';
                }
                action("Handled Outbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Handled Intercompany Outbox Transactions';
                    RunObject = page "Handled IC Outbox Transactions";
                    Tooltip = 'Open the Handled Intercompany Outbox Transactions page.';
                }
                action("Intercompany Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC Transaction';
                    RunObject = report "IC Transactions";
                    Tooltip = 'Run the IC Transaction report.';
                }
            }
        }
        addafter("Recurring Journals")
        {
            action("General Journals2")
            {
                ApplicationArea = Intercompany;
                Caption = 'Intercompany General Journal';
                RunObject = page "IC General Journal";
                Tooltip = 'Open the Intercompany General Journal page.';
            }
        }
        addafter("Group57")
        {
            group("Group58")
            {
                Caption = 'Intercompany';
                action("Intercompany Setup")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Intercompany Setup';
                    RunObject = page "Intercompany Setup";
                    Tooltip = 'Open the Intercompany Setup page.';
                }
                action("Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Intercompany Partners';
                    RunObject = page "IC Partner List";
                    Tooltip = 'Open the Intercompany Partners page.';
                }
                action("Chart of Accounts2")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Intercompany Chart of Accounts';
                    RunObject = page "IC Chart of Accounts";
                    Tooltip = 'Open the Intercompany Chart of Accounts page.';
                }
                action("Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Intercompany Dimensions';
                    RunObject = page "IC Dimensions";
                    Tooltip = 'Open the Intercompany Dimensions page.';
                }
            }
        }
    }
}

