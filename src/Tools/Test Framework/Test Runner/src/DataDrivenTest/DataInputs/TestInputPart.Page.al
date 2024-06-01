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

    layout
    {
        area(Content)
        {
            repeater(TestInputs)
            {
                Editable = false;
                field(TestGroup; Rec."Test Input Group Code")
                {
                    ApplicationArea = All;
                }
                field(TestInputCode; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(InputTestInputText; this.TestInputDisplayText)
                {
                    ApplicationArea = All;
                    Caption = 'Test Input';
                    ToolTip = 'Data input for the test method line';

                    trigger OnDrillDown()
                    begin
                        Message(this.TestInputText);
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
                ApplicationArea = All;
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
        this.TestInputText := Rec.GetInput(Rec);
        if Rec.Sensitive then
            this.TestInputDisplayText := this.ClickToShowLbl
        else
            this.TestInputDisplayText := this.TestInputText;
    end;

    var
        TestInputText: Text;
        TestInputDisplayText: Text;
        ClickToShowLbl: Label 'Click to show data input';
}