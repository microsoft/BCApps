// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

/// <summary>
/// Enum Shpfy Inventory Retry Scenario (ID 139617).
/// Scenarios for simulating inventory API retry behavior in tests.
/// </summary>
enum 139617 "Shpfy Inventory Retry Scenario"
{
    Extensible = false;

    value(0; Success)
    {
        Caption = 'Success';
    }
    value(1; FailOnceThenSucceed)
    {
        Caption = 'Fail Once Then Succeed';
    }
    value(2; AlwaysFail)
    {
        Caption = 'Always Fail';
    }
}
