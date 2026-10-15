// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// Payables Agent owned processing state of a task, used to count and drill into tasks regardless of whether
/// they are backed by an e-document (v1) or a Payables Agent task (v2). See "PA Task Collection".
/// </summary>
enum 3345 "PA Task State"
{
    Access = Internal;
    Extensible = false;

    value(0; "Pending Processing")
    {
        Caption = 'Pending processing';
    }
    value(1; "Needs Attention")
    {
        Caption = 'Needs attention';
    }
    value(2; "Ready For Review")
    {
        Caption = 'Ready for review';
    }
    value(3; Processed)
    {
        Caption = 'Processed';
    }
}
