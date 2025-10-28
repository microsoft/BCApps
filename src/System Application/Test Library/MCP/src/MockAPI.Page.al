// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.MCP;

page 130131 "Mock API"
{
    PageType = API;
    Caption = 'Mock API';
    APIPublisher = 'mock';
    APIGroup = 'mcp';
    APIVersion = 'v0.1';
    EntityName = 'entityName';
    EntitySetName = 'entitySetName';
    SourceTable = "Mock API";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'ID';

                }
            }
        }
    }
}