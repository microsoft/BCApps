// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

enum 3341 "PA Version"
{
    Access = Internal;
    Extensible = false;

    value(0; Unknown)
    {
        Caption = 'Unknown';
    }
    value(1; V1)
    {
        Caption = 'Version 1';
    }
    value(2; V2)
    {
        Caption = 'Version 2';
    }
}
