// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Payment;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Reporting;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Privacy;
using System.Threading;
using System.Utilities;

pageextension 13558 "Payment Journal Payments FI" extends "Payment Journal"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Message Type")
        {
            Visible = false;
        }
#pragma warning restore AL0432
#endif
        addlast(Control1)
        {
            field("Bank Message Type"; Rec."Bank Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the message type for the purchase header.';
                    Visible = false;
                }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("Invoice Message")
        {
            Visible = false;
        }
#pragma warning restore AL0432
#endif
        addlast(Control1)
        {
            field("Payment Message"; Rec."Payment Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an invoice message for the general journal.';
                    Visible = false;
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
