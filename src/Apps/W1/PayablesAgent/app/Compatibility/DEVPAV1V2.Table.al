// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

//TODOPAV1V2
table 3309 "DEVPAV1V2"
{
    Access = Internal;
    fields
    {
        field(1; PK; Integer)
        { }
        field(2; V2; Boolean)
        { }
    }
    keys
    {
        key(PK; PK)
        { }
    }
}