// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

tableextension 28011 WHTPurchRcptHeader extends "Purch. Rcpt. Header"
{
    fields
    {
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Business Posting Group";
        }
        field(28041; "Actual Vendor No."; Code[20])
        {
            Caption = 'Actual Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
        }
    }
}
