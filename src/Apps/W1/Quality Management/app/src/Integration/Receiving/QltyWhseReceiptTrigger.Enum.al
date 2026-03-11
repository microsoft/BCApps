// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Receiving;

/// <summary>
/// The warehouse receipt behavior to create an inspection.
/// </summary>
enum 20450 "Qlty. Whse. Receipt Trigger"
{
    Extensible = true;
    Caption = 'Quality Warehouse Receipt Trigger';

    value(0; NoTrigger)
    {
        Caption = 'Never';
    }
    value(1; OnWarehouseReceiptCreate)
    {
        Caption = 'When Warehouse Receipt is created';
    }
    value(2; OnWarehouseReceiptPost)
    {
        Caption = 'When Warehouse Receipt is posted';
    }
}
