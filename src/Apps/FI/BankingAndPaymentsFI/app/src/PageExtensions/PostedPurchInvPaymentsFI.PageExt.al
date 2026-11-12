// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.History;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using System.Automation;
using Microsoft.Bank.Payment;

pageextension 13568 "Posted Purch. Inv. Payments FI" extends "Posted Purchase Invoice"
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
        addlast("Shipping and Payment")
        {
            field("Bank Message Type"; Rec."Bank Message Type")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the message type for the purchase header. A Message can be up to 70 characters, and a Long Message can be up to 420. You can extend long messages to the Invoice Message 2 field. A tax message has both a reference number and information bout the tax being paid. If you use a tax message, enter the reference number in the Invoice Message field and information about the paid levies in the Invoice Message 2 field.';
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
        addlast("Shipping and Payment")
        {
            field("Payment Message"; Rec."Payment Message")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a free-text message. The maximum length of the message is between 70 and 420 characters, depending on the selection in the Message Type field.  ';
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
