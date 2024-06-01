// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

page 130462 "Test Input Groups"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Test Input Group";
    CardPageId = "Test Input";
    Caption = 'Test Inputs';
    Editable = false;
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the test input group.';
                    Caption = 'Code';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the test input group.';
                    Caption = 'Description';
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
                Caption = 'Import data-driven test inputs';
                Image = ImportCodes;
                ToolTip = 'Import data-driven test inputs from a JSON file';

                trigger OnAction()
                var
                    TestInputsManagement: Codeunit "Test Inputs Management";
                begin
                    TestInputsManagement.UploadAndImportDataInputsFromJson();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ImportDefinition_Promoted; ImportDataInputs)
            {
            }
        }
    }
}