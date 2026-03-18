// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

tableextension 149050 "Agent Test Suite" extends "AIT Test Suite"
{
    fields
    {
        field(4900; "Agent User Security ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Agent User Security ID';
            ToolTip = 'Specifies the agent to be used by the test suite.';
        }
        field(4901; "Suite Credit Limit"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Suite Credit Limit';
            ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed by this test suite during the current month. Set to 0 for no suite-specific limit (global limit still applies).';
            MinValue = 0;
            DecimalPlaces = 2 : 5;
        }
    }
}