// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

enum 3307 "PA Sender Policy"
{
    Access = Internal;
    Extensible = false;

    value(0; Ask)
    {
        Caption = 'Ask';
    }
    value(1; Approve)
    {
        Caption = 'Approve';
    }
    value(2; Reject)
    {
        Caption = 'Reject';
    }
}
