// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;

page 8353 "MCP API Config Tool Lookup"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Page Metadata";
    Caption = 'MCP API Tools';
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(ID; Rec.ID)
                {
                    Caption = 'ID';
                    ToolTip = 'Specifies the unique identifier for the API page.';
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the API page.';
                }
                field(EntityName; Rec.EntityName)
                {
                    Caption = 'Entity Name';
                    ToolTip = 'Specifies the entity name of the API page.';
                }
                field(APIPublisher; Rec.APIPublisher)
                {
                    Caption = 'API Publisher';
                    ToolTip = 'Specifies the API publisher of the API page.';
                }
                field(APIGroup; Rec.APIGroup)
                {
                    Caption = 'API Group';
                    ToolTip = 'Specifies the API group of the API page.';
                }
                field(APIVersion; Rec.APIVersion)
                {
                    Caption = 'API Version';
                    ToolTip = 'Specifies the API version of the API page.';
                }
            }
        }
    }
}
