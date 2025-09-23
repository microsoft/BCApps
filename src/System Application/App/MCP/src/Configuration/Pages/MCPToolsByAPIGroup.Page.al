// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8354 "MCP Tools By API Group"
{
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
                }
                field(APIGroup; APIGroup)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API group.';
                    Caption = 'API Group';
                }
            }
        }
    }

    var
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