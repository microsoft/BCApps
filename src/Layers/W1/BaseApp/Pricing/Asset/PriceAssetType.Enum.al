// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

enum 7004 "Price Asset Type" implements "Price Asset"
{
    Extensible = true;
    value(0; " ")
    {
        Caption = '(All)';
        Implementation = "Price Asset" = "Price Asset - All";
    }
    value(10; Item)
    {
        Caption = 'Item';
        Implementation = "Price Asset" = "Price Asset - Item";
    }
    value(20; "Item Discount Group")
    {
        Caption = 'Item Discount Group';
        Implementation = "Price Asset" = "Price Asset - Item Disc. Group";
    }
    value(30; Resource)
    {
        Caption = 'Resource';
        Implementation = "Price Asset" = "Price Asset - Resource";
    }
    value(40; "Resource Group")
    {
        Caption = 'Resource Group';
        Implementation = "Price Asset" = "Price Asset - Resource Group";
    }
    value(60; "G/L Account")
    {
        Caption = 'G/L Account';
        Implementation = "Price Asset" = "Price Asset - G/L Account";
    }
}