// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

#if not CLEANSCHEMA25
using Microsoft.Purchases.Reports;
#endif
using Microsoft.Purchases.Vendor;

tableextension 7000077 "Purch. Rcpt. Header ES" extends "Purch. Rcpt. Header"
{
    fields
    {
        field(10702; "Generate AutoInvoices"; Boolean)
        {
            Caption = 'Generate AutoInvoices';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7000001; "Vendor Bank Acc. Code"; Code[20])
        {
            Caption = 'Vendor Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Pay-to Vendor No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Pmt. Address".Code where("Vendor No." = field("Pay-to Vendor No."));
            ObsoleteReason = 'Address is taken from the fields Pay-to Address, Pay-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }
}
