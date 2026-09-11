// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Sales.Customer;

#pragma warning disable PTE0002
tableextension 10972 "E-Reporting Customer" extends Customer
{
    fields
    {
        field(10972; "FR E-Reporting Trans. Type"; Enum "FR E-Reporting Trans. Type")
        {
            Caption = 'E-Reporting Transaction Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the transaction type for French e-reporting. This determines how transactions for this customer are categorized in the e-reporting file sent to the tax authorities.';
        }
        field(10976; "FR Electronic Address"; Text[250])
        {
            Caption = 'Electronic Address';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the electronic address used for PDP routing in French e-invoicing. Enter a nine-digit SIREN, optionally followed by an underscore and a suffix. The electronic address scheme is 0225.';
        }
        field(10977; "FR Elec. Address Scheme"; Enum "Electronic Address Scheme")
        {
            Caption = 'Electronic Address Scheme';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the legacy electronic address scheme. French buyer electronic addresses use scheme 0225.';
        }
    }
}
#pragma warning restore PTE0002
