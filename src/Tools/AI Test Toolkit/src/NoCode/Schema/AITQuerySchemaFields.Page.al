// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// ListPart page for previewing schema fields.
/// </summary>
page 149072 "AIT Query Schema Fields"
{
    Caption = 'Schema Fields';
    PageType = ListPart;
    SourceTable = "AIT Query Schema Field";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Fields)
            {
                field("Field Order"; Rec."Field Order")
                {
                    ToolTip = 'Specifies the display order of the field.';
                    Visible = false;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ToolTip = 'Specifies the JSON property name.';
                }
                field("Field Label"; Rec."Field Label")
                {
                    ToolTip = 'Specifies the display label.';
                }
                field("Field Type"; Rec."Field Type")
                {
                    ToolTip = 'Specifies the data type.';
                }
                field("Is Required"; Rec."Is Required")
                {
                    ToolTip = 'Specifies whether the field is required.';
                }
                field("Field Description"; Rec."Field Description")
                {
                    ToolTip = 'Specifies help text for the field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadSchemaFields();
    end;

    local procedure LoadSchemaFields()
    var
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
    begin
        if FeatureCode = '' then
            exit;

        AITNoCodeMgt.LoadQuerySchemaFields(FeatureCode, Rec);
        if Rec.FindFirst() then;
    end;

    procedure SetFeatureCode(NewFeatureCode: Code[50])
    begin
        FeatureCode := NewFeatureCode;
        LoadSchemaFields();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Feature Code" <> '' then
            FeatureCode := Rec."Feature Code";
    end;

    var
        FeatureCode: Code[50];
}
