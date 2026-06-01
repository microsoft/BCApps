// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.MCP;

page 130133 "Mock APIV2"
{
    PageType = API;
    Caption = 'Mock APIV2';
    APIVersion = 'v2.0';
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