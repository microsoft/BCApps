// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Extends the Accounting Manager Role Center with Intercompany-specific functionality.
/// Adds Intercompany Activities part and navigation actions for IC setup and transactions.
/// </summary>
pageextension 8407 "IC Accounting Manager RC" extends "Accounting Manager Role Center"
{
    actions
    {
        addafter(PaymentJournals)
        {
            action(ICGeneralJournals)
            {
                ApplicationArea = Intercompany;
                Caption = 'IC General Journals';
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(Intercompany),
                                    Recurring = const(false));
                ToolTip = 'Post intercompany transactions. IC general journal lines must contain either an IC partner account or a customer or vendor account that has been assigned an intercompany partner code.';
            }
        }
    }
}