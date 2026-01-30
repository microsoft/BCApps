// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

/// <summary>
/// The trigger for when to create inspections for production orders.
/// </summary>
enum 20406 "Qlty. Production Order Trigger"
{
    Caption = 'Quality Production Order Trigger';

    value(0; NoTrigger)
    {
        Caption = 'Never';
    }
    value(1; OnProductionOutputPost)
    {
        Caption = 'When Production Output is posted';
    }
    value(2; OnProductionOrderRelease)
    {
        Caption = 'When Production Order is released';
    }
    value(3; OnReleasedProductionOrderRefresh)
    {
        Caption = 'When a Released Production Order is refreshed';
    }
}
