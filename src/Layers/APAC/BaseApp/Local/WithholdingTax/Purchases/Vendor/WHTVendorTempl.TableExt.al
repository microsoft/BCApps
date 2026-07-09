// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Vendor;

tableextension 28014 WHTVendorTempl extends "Vendor Templ."
{
    fields
    {
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Business Posting Group";
        }
        field(28042; "WHT Registration ID"; Text[20])
        {
            Caption = 'WHT Registration ID';
            DataClassification = CustomerContent;
        }
    }
}
