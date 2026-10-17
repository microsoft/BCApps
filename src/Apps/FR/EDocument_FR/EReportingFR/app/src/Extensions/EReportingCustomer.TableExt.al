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
        modify("SIREN No.")
        {
            trigger OnAfterValidate()
            var
                FRLegalIdentifiers: Codeunit "FR Legal Identifiers";
            begin
                FRLegalIdentifiers.ValidatePair("SIREN No.", "FR SIRET No.", Rec);
            end;
        }
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
            ToolTip = 'Specifies the electronic routing address, separate from the legal SIREN and SIRET. Domestic B2B receiving addresses use scheme 0225 and start with the customer''s SIREN.';
        }
        field(10977; "FR Elec. Address Scheme"; Enum "Electronic Address Scheme")
        {
            Caption = 'Electronic Address Scheme';
            DataClassification = CustomerContent;
            InitValue = " ";
            ToolTip = 'Specifies the scheme of the electronic routing address. The scheme must be permitted for the transaction and match the address format.';
        }
        field(10978; "FR SIRET No."; Code[14])
        {
            Caption = 'SIRET No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the fourteen-digit establishment identifier, composed of the nine-digit SIREN and the five-digit NIC.';

            trigger OnValidate()
            var
                FRLegalIdentifiers: Codeunit "FR Legal Identifiers";
            begin
                FRLegalIdentifiers.ValidatePair("SIREN No.", "FR SIRET No.", Rec);
            end;
        }
    }
}
#pragma warning restore PTE0002
