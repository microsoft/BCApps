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
                        MCPConfigImplementation.GetAPIPublishers(APIPublishers, APIGroupPublishers);
                        MCPConfigImplementation.LoookupAPIPublishers(APIPublishers, APIPublisher);
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

                        MCPConfigImplementation.LookupAPIGroupsAPIGroupPublishers(APIGroupPublishers, APIPublisher, APIGroup);
                    end;
                }
            }
        }
    }

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        APIPublisher: Text;
        APIGroup: Text;
        APIPublishers: List of [Text];
        APIGroupPublishers: Dictionary of [Text, Text];
        APIPublisherNotSelectedErr: Label 'Please select an API Publisher first.';

    internal procedure GetAPIGroup(): Text
    begin
        exit(APIGroup);
    end;

    internal procedure GetAPIPublisher(): Text
    begin
        exit(APIPublisher);
    end;
}