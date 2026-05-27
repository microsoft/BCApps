// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8354 "MCP Tools By API Group"
{
    Caption = 'Add Tools by API Group';
    PageType = StandardDialog;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field(APIGroup; APIGroup)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API group. The publisher is auto-filled when only one publisher exposes the selected group; otherwise you are prompted to choose.';
                    Caption = 'API Group';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if TempMCPAPIPublisherGroup.IsEmpty() then
                            MCPConfigImplementation.GetAPIPublishers(TempMCPAPIPublisherGroup);

                        MCPConfigImplementation.LookupAPIPublisher(TempMCPAPIPublisherGroup, APIPublisher, APIGroup);
                    end;

                    trigger OnValidate()
                    begin
                        if TempMCPAPIPublisherGroup.IsEmpty() then
                            MCPConfigImplementation.GetAPIPublishers(TempMCPAPIPublisherGroup);

                        MCPConfigImplementation.ResolvePublisherForGroup(TempMCPAPIPublisherGroup, APIPublisher, APIGroup);
                    end;
                }
                field(APIPublisher; APIPublisher)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API publisher.';
                    Caption = 'API Publisher';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        TempMCPAPIPublisherGroup.Reset();
                        if TempMCPAPIPublisherGroup.IsEmpty() then
                            MCPConfigImplementation.GetAPIPublishers(TempMCPAPIPublisherGroup);

                        MCPConfigImplementation.LookupAPIPublisher(TempMCPAPIPublisherGroup, APIPublisher, APIGroup);
                    end;
                }
            }
        }
    }

    var
        TempMCPAPIPublisherGroup: Record "MCP API Publisher Group";
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        APIPublisher: Text;
        APIGroup: Text;

    internal procedure GetAPIGroup(): Text
    begin
        exit(APIGroup);
    end;

    internal procedure GetAPIPublisher(): Text
    begin
        exit(APIPublisher);
    end;
}