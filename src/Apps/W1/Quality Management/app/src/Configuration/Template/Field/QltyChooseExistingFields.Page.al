// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Field;

/// <summary>
/// Used to help choose existing fields to add.
/// </summary>
page 20433 "Qlty. Choose Existing Fields"
{
    Caption = 'Quality Choose Existing Fields';
    PageType = ListPart;
    SourceTable = "Qlty. Field";
    LinksAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = QualityManagement;

    layout

    {
        area(Content)
        {
            repeater(Repeater)
            {
                field(ChooseAddThis; ShouldAddFieldForThisRow)
                {
                    Caption = 'Select';
                    ToolTip = 'Specifies to select this field to add.';

                    trigger OnValidate()
                    begin
                        SetChooseField(Rec.Code, ShouldAddFieldForThisRow);
                        CurrPage.Update();
                    end;
                }
                field(ChooseCode; Rec.Code)
                {
                    ToolTip = 'Specifies the short code for the Field. You can enter a maximum of 20 characters, both numbers and letters. The code serves to identify the Field. You must always enter a code before you can fill in the other fields in the table.';
                }
                field(ChooseDescription; Rec.Description)
                {
                }
                field(ChooseAllowedValues; Rec."Allowable Values")
                {
                }
                field(ChooseDefaultValue; Rec."Default Value")
                {
                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditDefaultValue();
                    end;
                }
                field("Case Sensitive"; Rec."Case Sensitive")
                {
                    AboutTitle = 'Case Sensitivity';
                    AboutText = 'Choose if case sensitivity will be enabled for text based fields.';
                }
            }
        }
    }

    var
        MapOfFieldsToAdd: Dictionary of [Code[20], Boolean];
        ShouldAddFieldForThisRow: Boolean;

    trigger OnAfterGetRecord()
    begin
        if not MapOfFieldsToAdd.Get(Rec.Code, ShouldAddFieldForThisRow) then
            ShouldAddFieldForThisRow := false;
    end;

    procedure SetChooseField(CurrentField: Code[20]; ChooseField: Boolean)
    var
        IgnorePreviousValue: Boolean;
    begin
        if MapOfFieldsToAdd.Set(CurrentField, ChooseField, IgnorePreviousValue) then;
        if not ChooseField then
            if MapOfFieldsToAdd.Remove(CurrentField) then;
    end;

    procedure GetFieldsToAdd(var OfFieldsToAdd: List of [Code[20]]) AddedOrChooseAField: Boolean
    var
        CurrentKey: Code[20];
    begin
        Clear(OfFieldsToAdd);
        foreach CurrentKey in MapOfFieldsToAdd.Keys() do
            OfFieldsToAdd.Add(CurrentKey);

        AddedOrChooseAField := (OfFieldsToAdd.Count() > 0);
    end;
}
