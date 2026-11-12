// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Sales.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Integration.Dataverse;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;

pageextension 13576 "Sales Setup Payments FI" extends "Sales & Receivables Setup"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Invoice No.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast("Reference No.")
        {
            field("Use Invoice No. in Reference"; Rec."Use Invoice No. in Reference")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice number that is calculated from the reference number.';
                }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("Customer No.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast("Reference No.")
        {
            field("Use Customer No. in Reference"; Rec."Use Customer No. in Reference")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoicing customer number.';
                }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify(Date)
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast("Reference No.")
        {
            field("Use Date in Reference"; Rec."Use Date in Reference")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice date in the format DDMMYY.';
                }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("Default Number")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast("Reference No.")
        {
            field("Default Reference Number"; Rec."Default Reference Number")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a constant number that appears as the first part of the reference number.';
                }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("Reference Nos.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast("Reference No.")
        {
            field("Payment Reference Nos."; Rec."Payment Reference Nos.")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
                }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("Print Reference No.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast("Reference No.")
        {
            field("Print Payment Reference"; Rec."Print Payment Reference")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
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
