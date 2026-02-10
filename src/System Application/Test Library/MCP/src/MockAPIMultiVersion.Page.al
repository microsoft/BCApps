// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.MCP;

page 130134 "Mock API Multi Version"
{
    PageType = API;
    Caption = 'Mock API Multi Version';
    APIPublisher = 'mock';
    APIGroup = 'mcp';
    APIVersion = 'v1.0', 'v2.0', 'beta';
    EntityName = 'mockMultiVersion';
    EntitySetName = 'mockMultiVersions';
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
