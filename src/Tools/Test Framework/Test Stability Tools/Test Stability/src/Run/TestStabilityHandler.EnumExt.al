// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.Testability;

enumextension 130482 "Test Stability Handler" extends DefaultTestHandler
{
    value(130482; TestStability)
    {
        Caption = 'Test stability';
        Implementation = ITestHandler = "Test Configuration Runner";
    }
}
