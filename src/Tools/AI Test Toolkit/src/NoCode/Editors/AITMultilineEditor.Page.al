// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Editor page for multiline text content.
/// </summary>
page 149068 "AIT Multiline Editor"
{
    Caption = 'Edit Text';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Editor)
            {
                Caption = '';
                ShowCaption = false;

                field(FieldLabel; FieldLabel)
                {
                    Caption = 'Field';
                    ToolTip = 'Specifies the field name being edited.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(TextContent; TextContent)
                {
                    Caption = 'Content';
                    ToolTip = 'Specifies the text content.';
                    MultiLine = true;
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetContent(NewContent: Text; NewLabel: Text)
    begin
        TextContent := NewContent;
        FieldLabel := NewLabel;
    end;

    procedure GetContent(): Text
    begin
        exit(TextContent);
    end;

    var
        TextContent: Text;
        FieldLabel: Text;
}
