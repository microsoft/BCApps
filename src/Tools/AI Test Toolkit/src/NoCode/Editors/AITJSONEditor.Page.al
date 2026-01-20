// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Simple JSON editor page for editing schema and other JSON content.
/// </summary>
page 149073 "AIT JSON Editor"
{
    Caption = 'JSON Editor';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Editor)
            {
                Caption = 'JSON Content';
                ShowCaption = false;

                field(JsonContent; JsonContent)
                {
                    Caption = 'JSON';
                    ToolTip = 'Specifies the JSON content.';
                    MultiLine = true;
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetJsonContent(Content: Text)
    begin
        JsonContent := Content;
    end;

    procedure GetJsonContent(): Text
    begin
        exit(JsonContent);
    end;

    var
        JsonContent: Text;
}
