// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

enum 3308 "PA BC IQ Batch Status"
{
    Access = Internal;
    Extensible = false;

    value(0; Submitting)
    {
        Caption = 'Submitting';
    }
    value(1; Submitted)
    {
        Caption = 'Submitted';
    }
    value(2; Partial)
    {
        Caption = 'Partial';
    }
}
