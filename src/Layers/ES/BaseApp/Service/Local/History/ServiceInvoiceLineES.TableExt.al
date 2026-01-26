// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;

tableextension 10793 "Service Invoice Line ES" extends "Service Invoice Line"
{
    fields
    {
        field(10700; "Pmt. Disc. Given Amount (Old)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Given Amount (Old)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10701; "EC %"; Decimal)
        {
            Caption = 'EC %';
            DataClassification = CustomerContent;
        }
        field(10702; "EC Difference"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'EC Difference';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(10709; "Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
        }
    }
}