// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Purchases.Vendor;

#pragma warning disable PTE0002
tableextension 10973 "E-Reporting Vendor" extends Vendor
{
    fields
    {
        field(10973; "FR E-Reporting Trans. Type"; Enum "FR E-Reporting Trans. Type")
        {
            Caption = 'E-Reporting Transaction Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the transaction type for French e-reporting. This determines how transactions for this vendor are categorized in the e-reporting file sent to the tax authorities.';
        }
        field(10976; "FR Electronic Address"; Text[250])
        {
            Caption = 'Electronic Address';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the electronic address used for PDP routing in French e-invoicing. This is the endpoint identifier for the vendor.';
        }
        field(10977; "FR Elec. Address Scheme"; Enum "Electronic Address Scheme")
        {
            Caption = 'Electronic Address Scheme';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the scheme of the electronic address (e.g., EM for email, 0009 for SIRET, 0002 for SIREN) used for PDP routing.';
        }
    }
}
#pragma warning restore PTE0002
