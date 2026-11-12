// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Threading;
using Microsoft.Bank.Payment;

pageextension 13560 "Sales Journal Payments FI" extends "Sales Journal"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Message Type")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(Control1)
        {
            field("Bank Message Type"; Rec."Bank Message Type")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the message type for the purchase header.';
                }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("Invoice Message")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(Control1)
        {
            field("Payment Message"; Rec."Payment Message")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an invoice message for the general journal.';
                }
        }
    }
#if not CLEAN30
    trigger OnOpenPage()
    var
        Feature: Codeunit "Banking Payments Feature FI";
    begin
        FeatureEnabled := Feature.IsEnabled();
    end;

    var
        FeatureEnabled: Boolean;
#endif
}
