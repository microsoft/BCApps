// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

table 9088 "Top Vendors By Purchase"
{
    Caption = 'Top Vendors By Purchase';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; Ranking; Integer)
        {
            Caption = 'Ranking';
            DataClassification = SystemMetadata;
        }
        field(2; VendorName; Text[100])
        {
            Caption = 'VendorName';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(3; PurchasesLCY; Decimal)
        {
            Caption = 'PurchasesLCY';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(4; LastVendLedgerEntryNo; Integer)
        {
            Caption = 'LastVendLedgerEntryNo';
            DataClassification = SystemMetadata;
        }
        field(5; VendorNo; Code[20])
        {
            Caption = 'VendorNo';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(6; DateTimeUpdated; DateTime)
        {
            Caption = 'DateTimeUpdated';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Ranking)
        {
            Clustered = true;
        }
    }
}
