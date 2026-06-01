// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer;

/// <summary>
/// Used on a buffer table to help indicate the status of the transfer order.
/// </summary>
enum 20451 "Qlty. Transfer Buffer Status"
{
    Extensible = true;
    Caption = 'Quality Transfer Buffer Status';

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Released)
    {
        Caption = 'Released';
    }
    value(2; Posted)
    {
        Caption = 'Posted';
    }
}
