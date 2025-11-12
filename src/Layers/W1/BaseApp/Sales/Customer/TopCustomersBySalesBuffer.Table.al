// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

table 1328 "Top Customers By Sales Buffer"
{
    Caption = 'Top Customers By Sales Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Ranking; Integer)
        {
            Caption = 'Ranking';
            DataClassification = SystemMetadata;
        }
        field(2; CustomerName; Text[100])
        {
            Caption = 'CustomerName';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(3; SalesLCY; Decimal)
        {
            Caption = 'SalesLCY';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(4; LastCustLedgerEntryNo; Integer)
        {
            Caption = 'LastCustLedgerEntryNo';
            DataClassification = SystemMetadata;
        }
        field(5; CustomerNo; Code[20])
        {
            Caption = 'CustomerNo';
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
        key(Key1; Ranking)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

