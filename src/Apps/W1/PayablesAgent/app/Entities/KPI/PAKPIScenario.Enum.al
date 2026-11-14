// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN27
#pragma warning disable AS0049
#endif
namespace Microsoft.Agent.PayablesAgent;

enum 3303 "PA KPI Scenario"
{
    Access = Internal;
    Extensible = false;

    value(0; "Agent Tasks Received")
    {
        Caption = 'Agent Tasks Received';
    }
#if not CLEAN30
    value(1; "Agent E-Docs Finalized by Agent")
    {
        Caption = 'Agent E-Documents Finalized by Agent';
        ObsoleteReason = 'Replaced by "Purchase Invoices created by Agent"';
        ObsoleteState = Pending;
        ObsoleteTag = '30.0';
    }
    value(2; "Agent E-Docs Finalized by User")
    {
        Caption = 'Agent E-Documents Finalized by User';
        ObsoleteReason = 'Replaced by "Purchase Invoices created by Agent"';
        ObsoleteState = Pending;
        ObsoleteTag = '30.0';
    }
#endif
    value(3; "Purchase Invoices created by Agent")
    {
        Caption = 'Purchase Invoices created by Agent';
    }
}
#if not CLEAN27
#pragma warning restore AS0049
#endif