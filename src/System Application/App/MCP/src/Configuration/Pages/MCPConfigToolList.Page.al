// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;

page 8352 "MCP Config Tool List"
{
    Caption = 'Available APIs';
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
                field("Object Type"; Rec."Object Type")
                {
                    ToolTip = 'Specifies the type of the object.';
                }
                field("Object Id"; Rec."Object Id")
                {
                    ToolTip = 'Specifies the ID of the object.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        // Routes through the same unified (pages + queries) lookup as the Select APIs action.
                        AddAPIObjects();
                    end;

                    trigger OnValidate()
                    var
                        PageMetadata: Record "Page Metadata";
                        QueryMetadata: Record "Query Metadata";
                    begin
                        case Rec."Object Type" of
                            Rec."Object Type"::Page:
                                begin
                                    PageMetadata := MCPConfigImplementation.ValidateAPIPageTool(Rec."Object Id", true);
                                    Rec."API Version" := MCPConfigImplementation.GetHighestAPIPageVersion(PageMetadata);
                                end;
                            Rec."Object Type"::Query:
                                begin
                                    QueryMetadata := MCPConfigImplementation.ValidateAPIQueryTool(Rec."Object Id");
                                    Rec."API Version" := MCPConfigImplementation.GetHighestAPIQueryVersion(QueryMetadata);
                                end;
                        end;
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
                    ToolTip = 'Specifies whether read operations are allowed for this API.';
                }
                field("Allow Create"; Rec."Allow Create")
                {
                    ToolTip = 'Specifies whether create operations are allowed for this API.';
                    Editable = AllowCreateEditable and AllowCreateUpdateDeleteTools and (Rec."Object Type" = Rec."Object Type"::Page);
                }
                field("Allow Modify"; Rec."Allow Modify")
                {
                    ToolTip = 'Specifies whether modify operations are allowed for this API.';
                    Editable = AllowModifyEditable and AllowCreateUpdateDeleteTools and (Rec."Object Type" = Rec."Object Type"::Page);
                }
                field("Allow Delete"; Rec."Allow Delete")
                {
                    ToolTip = 'Specifies whether delete operations are allowed for this API.';
                    Editable = AllowDeleteEditable and AllowCreateUpdateDeleteTools and (Rec."Object Type" = Rec."Object Type"::Page);
                }
                field("Allow Bound Actions"; Rec."Allow Bound Actions")
                {
                    ToolTip = 'Specifies whether bound actions are allowed for this API.';
                    Editable = AllowCreateUpdateDeleteTools and (Rec."Object Type" = Rec."Object Type"::Page);
                }
                field("API Version"; Rec."API Version")
                {
                    Caption = 'API Version';
                    ToolTip = 'Specifies the API version.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        APIVersion: Text[30];
                    begin
                        if Rec."Object ID" = 0 then
                            exit;

                        case Rec."Object Type" of
                            Rec."Object Type"::Page:
                                MCPConfigImplementation.LookupAPIPageVersions(Rec."Object Id", APIVersion);
                            Rec."Object Type"::Query:
                                MCPConfigImplementation.LookupAPIQueryVersions(Rec."Object Id", APIVersion);
                        end;
                        if APIVersion <> '' then
                            Rec."API Version" := APIVersion;
                    end;

                    trigger OnValidate()
                    begin
                        case Rec."Object Type" of
                            Rec."Object Type"::Page:
                                MCPConfigImplementation.ValidateAPIPageVersion(Rec."Object Id", Rec."API Version");
                            Rec."Object Type"::Query:
                                MCPConfigImplementation.ValidateAPIQueryVersion(Rec."Object Id", Rec."API Version");
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectAPIs)
            {
                Caption = 'Select APIs';
                Ellipsis = true;
                Image = Resource;
                ToolTip = 'Opens a lookup to select API objects to add to this configuration.';
                Enabled = not IsConfigActive;

                trigger OnAction()
                begin
                    AddAPIObjects();
                end;
            }
            action(AddAPIsByAPIGroup)
            {
                Caption = 'Add APIs by API Group';
                Image = NewResourceGroup;
                ToolTip = 'Adds APIs to the configuration by API publisher and group.';
                Enabled = not IsConfigActive;

                trigger OnAction()
                begin
                    MCPConfigImplementation.AddToolsByAPIGroup(Rec.ID);
                    CurrPage.Update();
                end;
            }
            action(AddStandardAPITools)
            {
                Caption = 'Add All Standard APIs';
                Image = ResourceGroup;
                ToolTip = 'Adds all standard API pages and queries to the configuration.';
                Enabled = not IsConfigActive;

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
        IsConfigActive := MCPConfigImplementation.IsConfigurationActive(Rec.ID);
    end;

    internal procedure SetConfigActive(IsActive: Boolean)
    begin
        IsConfigActive := IsActive;
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
        IsConfigActive: Boolean;

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

    local procedure AddAPIObjects()
    var
        TempSelectedObjects: Record "MCP API Object Buffer";
    begin
        if not MCPConfigImplementation.LookupAPIObjects(TempSelectedObjects) then
            exit;

        if TempSelectedObjects.FindSet() then
            repeat
                case TempSelectedObjects."Object Type" of
                    TempSelectedObjects."Object Type"::Page:
                        if not MCPConfigImplementation.CheckAPIToolExists(Rec.ID, TempSelectedObjects."Object ID", Rec."Object Type"::Page) then
                            MCPConfig.CreateAPITool(Rec.ID, TempSelectedObjects."Object ID");
                    TempSelectedObjects."Object Type"::Query:
                        if not MCPConfigImplementation.CheckAPIToolExists(Rec.ID, TempSelectedObjects."Object ID", Rec."Object Type"::Query) then
                            MCPConfig.CreateQueryAPITool(Rec.ID, TempSelectedObjects."Object ID");
                end;
            until TempSelectedObjects.Next() = 0;

        if not IsNullGuid(Rec.SystemId) then
            Rec.Delete();
        CurrPage.Update();
    end;
}
