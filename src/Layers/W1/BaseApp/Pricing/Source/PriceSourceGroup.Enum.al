// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

enum 7002 "Price Source Group" implements "Price Source Group"
{
    Extensible = true;
    value(0; All)
    {
        Caption = '(All)';
        Implementation = "Price Source Group" = "Price Source Group - All";
    }
    value(11; Customer)
    {
        Caption = 'Customer';
        Implementation = "Price Source Group" = "Price Source Group - Customer";
    }
    value(21; Vendor)
    {
        Caption = 'Vendor';
        Implementation = "Price Source Group" = "Price Source Group - Vendor";
    }
    value(31; Job)
    {
        Caption = 'Project';
        Implementation = "Price Source Group" = "Price Source Group - Job";
    }
}