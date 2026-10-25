// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;

/// <summary>
/// Extends the Accountant Role Center with Intercompany-specific functionality.
/// Adds Intercompany Activities part and navigation actions for IC setup and transactions.
/// </summary>
pageextension 8405 "IC Accountant Role Center" extends "Accountant Role Center"
{
    layout
    {
        addafter(Control1902304208)
        {
            part("Intercompany Activities"; "Intercompany Activities")
            {
                ApplicationArea = Intercompany;
            }
        }
    }

    actions
    {
        addafter(Dimensions)
        {
            action(Partners)
            {
                ApplicationArea = Intercompany;
                Caption = 'Partners';
                RunObject = Page "IC Partner List";
                ToolTip = 'Set up each company or department within the group of companies as an intercompany partner of type Vendor or Customer. Intercompany partners can then be inserted on regular sales and purchase documents or journal lines that are exchanged through the intercompany inbox/outbox system and posted to agreed accounts in an intercompany chart of accounts.';
            }
            action(Action171)
            {
                ApplicationArea = Intercompany;
                Caption = 'IC Chart of Accounts';
                RunObject = Page "IC Chart of Accounts";
                ToolTip = 'Manage intercompany transactions within your group of companies in an aligned chart of accounts that uses the same account numbers and settings. In the setup phase, the parent company of the group can create a simplified version of their own chart of accounts and exports it to an XML file that each subsidiary can quickly implement.';
            }
            action(Action173)
            {
                ApplicationArea = Intercompany;
                Caption = 'Intercompany Dimensions';
                RunObject = Page "IC Dimensions";
                ToolTip = 'Enable companies within a group to exchange transactions with dimensions and to perform financial analysis by dimensions across the group. The parent company of the group can create a simplified version of their own set of dimensions and export them to an XML file that each subsidiary can import into the intercompany Dimensions window and then map them to their own dimensions.';
            }
        }
        addafter(SalesJournals)
        {
            action(ICGeneralJournals)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'IC General Journals';
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(Intercompany),
                                    Recurring = const(false));
                ToolTip = 'Post intercompany transactions. IC general journal lines must contain either an IC partner account or a customer or vendor account that has been assigned an intercompany partner code.';
            }
        }
    }
}
