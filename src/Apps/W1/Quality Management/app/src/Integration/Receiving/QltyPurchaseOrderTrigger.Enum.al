// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Receiving;

/// <summary>
/// Helps determine how receiving behaviors should occur.
/// </summary>
enum 20452 "Qlty. Purchase Order Trigger"
{
    Extensible = true;
    Caption = 'Quality Purchase Order Trigger';

    value(0; NoTrigger)
    {
        Caption = 'Never';
    }
    value(1; OnPurchaseOrderPostReceive)
    {
        Caption = 'When Purchase Order is received';
    }
    value(2; OnPurchaseOrderRelease)
    {
        Caption = 'When Purchase Order is released';
    }
}
