// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

enum 3306 "PA Setup Change Impact"
{
    Access = Internal;
    Extensible = false;

    value(0; None) { }
    value(1; KnownSendersIgnoredByFolder) { }
    value(2; KnownSendersIgnoredByPolicy) { }
}
