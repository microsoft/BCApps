// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

enum 3305 "PA Email Review Policy"
{
    Access = Internal;
    Extensible = false;

    value(0; Unset)
    {
        Caption = ' ';
    }
    value(1; OnlyIfUntrusted)
    {
        Caption = 'Manage per sender (recommended)';
    }
    value(2; Never)
    {
        Caption = 'Never';
    }
    value(3; Always)
    {
        Caption = 'Always';
    }
}
