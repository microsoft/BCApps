// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

enum 7003 "Price Source Type" implements "Price Source", "Price Source Group"
{
    Extensible = true;
    value(0; All)
    {
        Caption = '(All)';
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - All";
    }
    value(10; "All Customers")
    {
        Caption = 'All Customers';
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - Customer";
    }
    value(11; Customer)
    {
        Caption = 'Customer';
        Implementation = "Price Source" = "Price Source - Customer", "Price Source Group" = "Price Source Group - Customer";
    }
    value(12; "Customer Price Group")
    {
        Caption = 'Customer Price Group';
        Implementation = "Price Source" = "Price Source - Cust. Price Gr.", "Price Source Group" = "Price Source Group - Customer";
    }
    value(13; "Customer Disc. Group")
    {
        Caption = 'Customer Disc. Group';
        Implementation = "Price Source" = "Price Source - Cust. Disc. Gr.", "Price Source Group" = "Price Source Group - Customer";
    }
    value(20; "All Vendors")
    {
        Caption = 'All Vendors';
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - Vendor";
    }
    value(21; Vendor)
    {
        Caption = 'Vendor';
        Implementation = "Price Source" = "Price Source - Vendor", "Price Source Group" = "Price Source Group - Vendor";
    }
    value(30; "All Jobs")
    {
        Caption = 'All Projects';
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - Job";
    }
    value(31; Job)
    {
        Caption = 'Project';
        Implementation = "Price Source" = "Price Source - Job", "Price Source Group" = "Price Source Group - Job";
    }
    value(32; "Job Task")
    {
        Caption = 'Project Task';
        Implementation = "Price Source" = "Price Source - Job Task", "Price Source Group" = "Price Source Group - Job";
    }
    value(50; Campaign)
    {
        Caption = 'Campaign';
        Implementation = "Price Source" = "Price Source - Campaign", "Price Source Group" = "Price Source Group - All";
    }
    value(51; Contact)
    {
        Caption = 'Contact';
        Implementation = "Price Source" = "Price Source - Contact", "Price Source Group" = "Price Source Group - All";
    }
}