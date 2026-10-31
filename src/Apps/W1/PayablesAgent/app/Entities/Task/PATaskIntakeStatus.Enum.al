// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

enum 3342 "PA Task Intake Status"
{
    Access = Internal;
    Extensible = false;

    value(0; Received)
    {
        Caption = 'Received';
    }
    value(1; Accepted)
    {
        Caption = 'Accepted';
    }
    value(2; Rejected)
    {
        Caption = 'Rejected';
    }
}
