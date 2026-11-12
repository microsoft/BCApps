// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Sales.History;

using Microsoft.Bank.Setup;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Automation;
using Microsoft.Bank.Payment;

pageextension 13573 "Posted Sales Inv. Payments FI" extends "Posted Sales Invoice"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Reference No.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast("Shipping and Billing")
        {
            field("Payment Reference No."; Rec."Payment Reference No.")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
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
