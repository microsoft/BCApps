// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Stores ranked customer sales data for the top customers by sales chart visualization.
/// </summary>
table 1328 "Top Customers By Sales Buffer"
{
    Caption = 'Top Customers By Sales Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer's position in the top sales ranking.
        /// </summary>
        field(1; Ranking; Integer)
        {
            Caption = 'Ranking';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Stores the name of the customer for display in the top customers chart.
        /// </summary>
        field(2; CustomerName; Text[100])
        {
            Caption = 'CustomerName';
            DataClassification = OrganizationIdentifiableInformation;
        }
        /// <summary>
        /// Specifies the total sales amount in local currency for this customer.
        /// </summary>
        field(3; SalesLCY; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'SalesLCY';
            DataClassification = OrganizationIdentifiableInformation;
        }
        /// <summary>
        /// Stores the entry number of the last customer ledger entry processed for incremental updates.
        /// </summary>
        field(4; LastCustLedgerEntryNo; Integer)
        {
            Caption = 'LastCustLedgerEntryNo';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the unique identifier of the customer in the ranking.
        /// </summary>
        field(5; CustomerNo; Code[20])
        {
            Caption = 'CustomerNo';
            DataClassification = OrganizationIdentifiableInformation;
        }
        /// <summary>
        /// Indicates when the sales data for this customer was last refreshed.
        /// </summary>
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

