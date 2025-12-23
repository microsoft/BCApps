// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
/// Used to help choose existing tests to add.
/// </summary>
page 20433 "Qlty. Choose Existing Tests"
{
    Caption = 'Quality Choose Existing Tests';
    PageType = ListPart;
    SourceTable = "Qlty. Test";
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
                field(ChooseAddThis; ShouldAddTestForThisRow)
                {
                    Caption = 'Select';
                    ToolTip = 'Specifies to select this test to add.';

                    trigger OnValidate()
                    begin
                        SetChooseTest(Rec.Code, ShouldAddTestForThisRow);
                        CurrPage.Update();
                    end;
                }
                field(ChooseCode; Rec.Code)
                {
                    ToolTip = 'Specifies the short code for the Test. You can enter a maximum of 20 characters, both numbers and letters. The code serves to identify the Test. You must always enter a code before you can fill in the other tests in the table.';
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
        MapOfTestsToAdd: Dictionary of [Code[20], Boolean];
        ShouldAddTestForThisRow: Boolean;

    trigger OnAfterGetRecord()
    begin
        if not MapOfTestsToAdd.Get(Rec.Code, ShouldAddTestForThisRow) then
            ShouldAddTestForThisRow := false;
    end;

    procedure SetChooseTest(CurrentTest: Code[20]; ChooseTest: Boolean)
    var
        IgnorePreviousValue: Boolean;
    begin
        if MapOfTestsToAdd.Set(CurrentTest, ChooseTest, IgnorePreviousValue) then;
        if not ChooseTest then
            if MapOfTestsToAdd.Remove(CurrentTest) then;
    end;

    procedure GetTestsToAdd(var OfTestsToAdd: List of [Code[20]]) AddedOrChooseATest: Boolean
    var
        CurrentKey: Code[20];
    begin
        Clear(OfTestsToAdd);
        foreach CurrentKey in MapOfTestsToAdd.Keys() do
            OfTestsToAdd.Add(CurrentKey);

        AddedOrChooseATest := (OfTestsToAdd.Count() > 0);
    end;
}
