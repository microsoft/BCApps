// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 13673 "OIOUBL-Tax Group Buffer"
{
    TableType = Temporary;
    Caption = 'OIOUBL Tax Group Buffer';

    fields
    {
        field(1; "OIOUBL-Tax Category ID"; Text[15])
        {
            Caption = 'Tax Category ID';
        }
        field(2; "OIOUBL-VAT %"; Decimal)
        {
            Caption = 'VAT %';
        }
        field(3; "OIOUBL-Taxable Amount"; Decimal)
        {
            Caption = 'Taxable Amount';
        }
        field(4; "OIOUBL-Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
        }
        field(5; "OIOUBL-Inv. Discount Amount"; Decimal)
        {
            Caption = 'Inv. Discount Amount';
        }
    }

    keys
    {
        key(PK; "OIOUBL-Tax Category ID", "OIOUBL-VAT %")
        {
            Clustered = true;
        }
    }
}
