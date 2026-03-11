// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Warehouse;

/// <summary>
/// Determines what triggers an inspection from a warehouse movement.
/// </summary>
enum 20438 "Qlty. Warehouse Trigger"
{
    Caption = 'Quality Warehouse Trigger';

    value(0; NoTrigger)
    {
        Caption = 'Never';
    }
    value(1; OnWhseMovementRegister)
    {
        Caption = 'When Warehouse Movement is registered';
    }
}
