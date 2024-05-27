// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

page 130459 "Test Inputs"
{
    PageType = List;
    SourceTable = "Test Input";
    Caption = 'Test inputs';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(TestInputs)
            {
                Editable = false;
                field(TestSuite; Rec."Test Suite")
                {
                    ApplicationArea = All;
                }
                field(MethodName; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(InputDescription; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(InputTestInputText; TestInputText)
                {
                    ApplicationArea = All;
                    Caption = 'Test Input';
                    ToolTip = 'Data input for the test method line';

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
                ApplicationArea = All;
                Caption = 'Import';
                Image = ImportCodes;

                trigger OnAction()
                var
                    ALTestSuite: Record "AL Test Suite";
                    TestInputsManagement: Codeunit "Test Inputs Management";
                begin
                    ALTestSuite.Get(Rec."Test Suite");
                    TestInputsManagement.UploadAndImportDataInputsFromJson(ALTestSuite);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ImportDataInputs_Promoted; ImportDataInputs)
                {
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        TestInputText := Rec.GetInput(Rec);
    end;

    var
        TestInputText: Text;
}