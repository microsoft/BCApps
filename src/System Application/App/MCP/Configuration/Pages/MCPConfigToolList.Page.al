// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;

page 8202 "MCP Config Tool List"
{
    ApplicationArea = All;
    PageType = ListPart;
    SourceTable = "MCP Configuration Tool";
    DelayedInsert = true;
    MultipleNewLines = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object Type"; Rec."Object Type")
                {
                }
                field("Object Id"; Rec."Object Id")
                {
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PageId: Integer;
                    begin
                        MCPConfigImplementation.LookupAPITools(PageId);
                        if PageId <> 0 then begin
                            Rec.Validate("Object Id", PageId);
                            CurrPage.Update();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        MCPConfigImplementation.ValidateAPITool(Rec."Object Id");
                        SetPermissions();
                    end;
                }
                field("Object Name"; MCPConfigImplementation.GetObjectCaption(Rec.SystemId))
                {
                    Caption = 'Object Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the object.';
                }
                field("Allow Read"; Rec."Allow Read")
                {
                }
                field("Allow Create"; Rec."Allow Create")
                {
                    Editable = AllowCreateEditable;
                }
                field("Allow Modify"; Rec."Allow Modify")
                {
                    Editable = AllowModifyEditable;
                }
                field("Allow Delete"; Rec."Allow Delete")
                {
                    Editable = AllowDeleteEditable;
                }
                field("Allow Bound Actions"; Rec."Allow Bound Actions")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddToolsByAPIGroup)
            {
                Caption = 'Add Tools by API Group';
                Image = NewResourceGroup;
                ToolTip = 'Adds tools to the configuration by API publisher and group.';

                trigger OnAction()
                begin
                    MCPConfigImplementation.AddToolsByAPIGroup(Rec."Config Id");
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetPermissions();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetPermissions();
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        AllowCreateEditable: Boolean;
        AllowModifyEditable: Boolean;
        AllowDeleteEditable: Boolean;

    local procedure SetPermissions()
    var
        PageMetadata: Record "Page Metadata";
    begin
        if not PageMetadata.Get(Rec."Object Id") then
            exit;

        AllowCreateEditable := PageMetadata.InsertAllowed;
        AllowModifyEditable := PageMetadata.ModifyAllowed;
        AllowDeleteEditable := PageMetadata.DeleteAllowed;
    end;
}