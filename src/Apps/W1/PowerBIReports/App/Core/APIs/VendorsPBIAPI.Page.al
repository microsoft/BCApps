// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using Microsoft.Purchases.Vendor;

page 36959 "Vendors - PBI API"
{
    PageType = API;
    Caption = 'Power BI Vendors';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'vendor';
    EntitySetName = 'vendors';
    SourceTable = Vendor;
    DelayedInsert = true;
    DataAccessIntent = ReadOnly;
    Editable = false;
    Extensible = false;
    AboutText = 'Provides access to vendor data from the Vendor table, including vendor numbers, names, addresses, and posting groups. Supports read-only GET operations to provide data feeds optimized for Power BI and business intelligence dashboards.';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(vendorNo; Rec."No.")
                {
                }
                field(vendorName; Rec.Name)
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
                field(vendorPostingGroup; Rec."Vendor Posting Group")
                {
                }
            }
        }
    }
}