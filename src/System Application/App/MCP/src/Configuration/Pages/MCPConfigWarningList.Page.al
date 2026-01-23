// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8359 "MCP Config Warning List"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = "MCP Config Warning";
    SourceTableTemporary = true;
    Caption = 'MCP Configuration Warnings';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Warning Message"; MCPConfigImplementation.GetWarningMessage(Rec))
                {
                    Caption = 'Warning Message';
                    ToolTip = 'Specifies the warning message.';
                }
                field("Recommended Action"; MCPConfigImplementation.GetRecommendedAction(Rec))
                {
                    Caption = 'Recommended Action';
                    ToolTip = 'Specifies the recommended action for the warning.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Fix)
            {
                ApplicationArea = All;
                Caption = 'Apply Recommended Action';
                ToolTip = 'Applies the recommended action for the selected warnings.';
                Image = ApprovalSetup;

                trigger OnAction()
                begin
                    SetSelectionFilter(Rec);
                    MCPConfigImplementation.ApplyRecommendedActions(Rec);
                    Rec.Reset();
                    if not Rec.IsEmpty() then
                        Rec.FindSet();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Promoted_Fix; Fix) { }
        }
    }

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
}
