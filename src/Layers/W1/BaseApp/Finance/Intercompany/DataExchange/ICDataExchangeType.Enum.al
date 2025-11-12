// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

enum 532 "IC Data Exchange Type" implements "IC Data Exchange"
{
    Extensible = false;
    value(0; Database)
    {
        Implementation = "IC Data Exchange" = "IC Data Exchange Database";
    }
    value(1; API)
    {
        Implementation = "IC Data Exchange" = "IC Data Exchange API";
    }
}
