// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.MCP;

query 130135 "Mock API Query"
{
    QueryType = API;
    Caption = 'Mock API Query';
    APIPublisher = 'mock';
    APIGroup = 'mcp';
    APIVersion = 'v1.0';
    EntityName = 'mockQuery';
    EntitySetName = 'mockQueries';

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
