// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using Microsoft.Sales.Customer;

page 36954 Customers
{
    PageType = API;
    Caption = 'Power BI Customers';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'customer';
    EntitySetName = 'customers';
    SourceTable = Customer;
    DelayedInsert = true;
    DataAccessIntent = ReadOnly;
    Editable = false;
    Extensible = false;
    AboutText = 'Provides access to customer data from the Customer table, including customer numbers, names, addresses, posting groups, price groups, and discount groups. Supports read-only GET operations to provide data feeds optimized for Power BI and business intelligence dashboards.';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(customerNo; Rec."No.")
                {
                }
                field(customerName; Rec.Name)
                {
                }
                field(address; Rec.Address)
                {
                }
                field(address2; Rec."Address 2")
                {
                }
                field(city; Rec.City)
                {
                }
                field(postCode; Rec."Post Code")
                {
                }
                field(county; Rec.County)
                {
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                }
                field(customerPostingGroup; Rec."Customer Posting Group")
                {
                }
                field(customerPriceGroup; Rec."Customer Price Group")
                {
                }
                field(customerDiscGroup; Rec."Customer Disc. Group")
                {
                }
            }
        }
    }
}
