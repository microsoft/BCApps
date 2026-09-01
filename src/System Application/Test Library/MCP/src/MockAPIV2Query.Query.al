// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.MCP;

query 130136 "Mock APIV2 Query"
{
    QueryType = API;
    Caption = 'Mock APIV2 Query';
    APIVersion = 'v2.0';
    EntityName = 'mockV2Query';
    EntitySetName = 'mockV2Queries';

    elements
    {
        dataitem(MockAPI; "Mock API")
        {
            column(primaryKey; "Primary Key")
            {
            }
            column(systemId; SystemId)
            {
            }
        }
    }
}
