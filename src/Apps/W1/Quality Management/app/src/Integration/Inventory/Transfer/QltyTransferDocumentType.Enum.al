// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer;

/// <summary>
/// When building a buffer table for related transfers this enum helps indicate the transfer order type.
/// </summary>
enum 20455 "Qlty. Transfer Document Type"
{
    Extensible = true;
    Caption = 'Quality Transfer Document Type';

    value(0; "Transfer Order")
    {
        Caption = 'Transfer Order';
    }
    value(1; "Direct Transfer")
    {
        Caption = 'Direct Transfer';
    }
    value(2; "Transfer Shipment")
    {
        Caption = 'Transfer Shipment';
    }
    value(3; "Transfer Receipt")
    {
        Caption = 'Transfer Receipt';
    }
}
