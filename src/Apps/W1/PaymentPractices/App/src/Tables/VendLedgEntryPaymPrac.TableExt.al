// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;

tableextension 685 "Vend. Ledg. Entry Paym. Prac." extends "Vendor Ledger Entry"
{
    fields
    {
        field(686; "Overdue Due to Dispute"; Boolean)
        {
            Caption = 'Overdue Due to Dispute';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies if the late payment on this invoice was due to a dispute.';

            trigger OnValidate()
            begin
                if Rec."Document Type" <> Rec."Document Type"::Invoice then
                    Error(OverdueDueToDisputeOnlyForInvoicesErr);
            end;
        }
        field(687; "SCF Payment Date"; Date)
        {
            Caption = 'SCF Payment Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the date when the finance provider paid the supplier under a Supply Chain Finance arrangement. Enter this on the payment entry, not the invoice.';

            trigger OnValidate()
            begin
                if Rec."Document Type" <> Rec."Document Type"::Payment then
                    Error(SCFPaymentDateOnlyForPaymentsErr);
            end;
        }
    }

    var
        OverdueDueToDisputeOnlyForInvoicesErr: Label 'Overdue Due to Dispute can only be set on invoice entries.';
        SCFPaymentDateOnlyForPaymentsErr: Label 'SCF Payment Date can only be set on payment entries.';
}
