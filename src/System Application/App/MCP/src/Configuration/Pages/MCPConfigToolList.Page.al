// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;

page 8352 "MCP Config Tool List"
{
    Caption = 'Available Tools';
    ApplicationArea = All;
    PageType = ListPart;
    SourceTable = "MCP Configuration Tool";
    DelayedInsert = true;
    MultipleNewLines = true;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object Type"; Rec."Object Type") { }
                field("Object Id"; Rec."Object Id")
                {

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PageMetadata: Record "Page Metadata";
                    begin
                        if not MCPConfigImplementation.LookupAPITools(PageMetadata) then
                            exit;

                        if not PageMetadata.FindSet() then
                            exit;

                        repeat
                            MCPConfig.CreateAPITool(Rec.ID, PageMetadata.ID);
                        until PageMetadata.Next() = 0;

                        if not IsNullGuid(Rec.SystemId) then
                            Rec.Delete();
                        CurrPage.Update();
                    end;

                    trigger OnValidate()
                    begin
                        MCPConfigImplementation.ValidateAPITool(Rec."Object Id", true);
                        SetPermissions();
                    end;
                }
                field("Object Name"; MCPConfigImplementation.GetObjectCaption(Rec.SystemId))
                {
                    Caption = 'Object Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the object.';
                }
                field("Allow Read"; Rec."Allow Read") { }
                field("Allow Create"; Rec."Allow Create")
                {
                    Editable = AllowCreateEditable and AllowCreateUpdateDeleteTools;
                }
                field("Allow Modify"; Rec."Allow Modify")
                {
                    Editable = AllowModifyEditable and AllowCreateUpdateDeleteTools;
                }
                field("Allow Delete"; Rec."Allow Delete")
                {
                    Editable = AllowDeleteEditable and AllowCreateUpdateDeleteTools;
                }
                field("Allow Bound Actions"; Rec."Allow Bound Actions")
                {
                    Editable = AllowCreateUpdateDeleteTools;
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
                    MCPConfigImplementation.AddToolsByAPIGroup(Rec.ID);
                    CurrPage.Update();
                end;
            }
            action(AddStandardAPITools)
            {
                Caption = 'Add All Standard APIs as Tools';
                Image = ResourceGroup;
                ToolTip = 'Adds tools for all standard API v2.0 to the configuration.';

                trigger OnAction()
                begin
                    MCPConfigImplementation.AddStandardAPITools(Rec.ID);
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetPermissions();
        GetAllowCreateUpdateDeleteTools();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetPermissions();
        GetAllowCreateUpdateDeleteTools();
    end;

    trigger OnOpenPage()
    begin
        GetAllowCreateUpdateDeleteTools();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Allow Read" := true;
    end;

    var
        MCPConfig: Codeunit "MCP Config";
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        AllowCreateEditable: Boolean;
        AllowModifyEditable: Boolean;
        AllowDeleteEditable: Boolean;
        AllowCreateUpdateDeleteTools: Boolean;

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

    local procedure GetAllowCreateUpdateDeleteTools(): Boolean
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if MCPConfiguration.GetBySystemId(Rec.ID) then
            AllowCreateUpdateDeleteTools := MCPConfiguration.AllowProdChanges;
    end;
}