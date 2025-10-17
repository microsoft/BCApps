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
                field(APIPublisher; APIPublisher)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API publisher.';
                    Caption = 'API Publisher';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MCPAPIPublisherGroup.Reset();
                        if MCPAPIPublisherGroup.IsEmpty() then
                            MCPConfigImplementation.GetAPIPublishers(MCPAPIPublisherGroup);

                        MCPConfigImplementation.LookupAPIPublisher(MCPAPIPublisherGroup, APIPublisher, APIGroup);
                    end;
                }
                field(APIGroup; APIGroup)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API group.';
                    Caption = 'API Group';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if APIPublisher = '' then
                            Error(APIPublisherNotSelectedErr);

                        if MCPAPIPublisherGroup.IsEmpty() then
                            MCPConfigImplementation.GetAPIPublishers(MCPAPIPublisherGroup);

                        MCPConfigImplementation.LookupAPIGroup(MCPAPIPublisherGroup, APIPublisher, APIGroup);
                    end;
                }
            }
        }
    }

    var
        MCPAPIPublisherGroup: Record "MCP API Publisher Group";
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        APIPublisher: Text;
        APIGroup: Text;
        APIPublisherNotSelectedErr: Label 'Select an API Publisher first.';

    internal procedure GetAPIGroup(): Text
    begin
        exit(APIGroup);
    end;

    internal procedure GetAPIPublisher(): Text
    begin
        exit(APIPublisher);
    end;
}
