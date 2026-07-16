// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;

page 8368 "MCP CU Config Tool Lookup"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Codeunit Metadata";
    Caption = 'MCP Codeunit API Tools';
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
                    ToolTip = 'Specifies the unique identifier for the codeunit API tool.';
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the codeunit API tool.';
                }
                field(ALNamespace; Rec."AL Namespace")
                {
                    Caption = 'AL Namespace';
                    ToolTip = 'Specifies the AL namespace of the codeunit API tool.';
                }
            }
        }
    }
}
