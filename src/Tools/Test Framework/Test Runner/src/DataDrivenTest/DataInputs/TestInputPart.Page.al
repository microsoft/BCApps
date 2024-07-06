// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

page 130459 "Test Input Part"
{
    PageType = ListPart;
    SourceTable = "Test Input";
    Caption = 'Test inputs';
    InsertAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(TestInputs)
            {
                Editable = false;
                field(TestGroup; Rec."Test Input Group Code")
                {
                }
                field(TestInputCode; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(InputTestInputText; TestInputDisplayText)
                {
                    Caption = 'Test Input';
                    ToolTip = 'Specifies the data input for the test method line';

                    trigger OnDrillDown()
                    begin
                        Message(TestInputText);
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ImportDataInputs)
            {
                Caption = 'Import';
                Image = ImportCodes;
                ToolTip = 'Import data-driven test inputs from a JSON file';

                trigger OnAction()
                var
                    TestInputGroup: Record "Test Input Group";
                    TestInputsManagement: Codeunit "Test Inputs Management";
                begin
                    TestInputGroup.Get(Rec."Test Input Group Code");
                    TestInputsManagement.UploadAndImportDataInputsFromJson(TestInputGroup);
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        TestInputText := Rec.GetInput(Rec);
        if Rec.IsSensitive() then
            TestInputDisplayText := ClickToShowLbl
        else
            TestInputDisplayText := TestInputText;
    end;

    var
        TestInputText: Text;
        TestInputDisplayText: Text;
        ClickToShowLbl: Label 'Show data input';
}