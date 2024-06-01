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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
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

    local procedure OpenTestInputCard()
    begin
        Page.RunModal(Page::"Test Input", Rec);
        CurrPage.Update(false);
    end;
}