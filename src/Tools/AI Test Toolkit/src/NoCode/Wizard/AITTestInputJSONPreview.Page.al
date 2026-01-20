// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// FactBox page for previewing the JSON of a test input.
/// </summary>
page 149074 "AIT Test Input JSON Preview"
{
    Caption = 'JSON Preview';
    PageType = CardPart;
    SourceTable = "AIT Test Input";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            field(JsonPreview; JsonPreview)
            {
                Caption = 'Test Input JSON';
                ToolTip = 'Specifies a preview of the complete test input JSON.';
                MultiLine = true;
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        TestInputJson: JsonObject;
        JsonText: Text;
    begin
        TestInputJson := Rec.BuildTestInputJson();
        TestInputJson.WriteTo(JsonText);
        if StrLen(JsonText) > 2048 then
            JsonPreview := CopyStr(JsonText, 1, 2045) + '...'
        else
            JsonPreview := CopyStr(JsonText, 1, 2048);
    end;

    var
        JsonPreview: Text[2048];
}
