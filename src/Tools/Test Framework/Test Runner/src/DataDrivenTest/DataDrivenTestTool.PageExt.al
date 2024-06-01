// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

pageextension 130451 MyExtension extends "AL Test Tool"
{
    layout
    {
        addafter(Name)
        {
            field("Data Input"; DataInputDisplayText)
            {
                ApplicationArea = All;
                Visible = DataInputVisible;
                Caption = 'Data Input';
                ToolTip = 'Data input for the test method line';
                Editable = false;
            }
        }
    }
    actions
    {
        addafter(RunTests)
        {
            group(DataDrivenTesting)
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
                action(DataInputs)
                {
                    ApplicationArea = All;
                    Caption = 'Data inputs';
                    Image = TestFile;

                    trigger OnAction()
                    begin
                        Page.RunModal(Page::"Test Input Groups");
                        CurrPage.Update(false);
                    end;
                }
                action(ExpandTestLine)
                {
                    ApplicationArea = All;
                    Caption = 'Expand test line with data inputs';
                    Image = ExpandDepositLine;
                    trigger OnAction()
                    var
                        TestInputsManagement: Codeunit "Test Inputs Management";
                    begin
                        TestInputsManagement.SelectTestGroupsAndExpandTestLine(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(DataOutput)
                {
                    ApplicationArea = All;
                    Caption = 'Download';
                    Image = Export;
                    trigger OnAction()
                    var
                        TestOutput: Codeunit "Test Output";
                    begin
                        TestOutput.DownloadTestOutput();
                    end;
                }
                action(ViewDataOutputs)
                {
                    ApplicationArea = All;
                    Caption = 'View data outputs';
                    Image = OutputJournal;
                    trigger OnAction()
                    var
                        TestOutput: Codeunit "Test Output";
                    begin
                        TestOutput.ShowTestOutputs();
                    end;
                }
                action(ClearDataOutput)
                {
                    ApplicationArea = All;
                    Caption = 'Clear data output';
                    Image = ClearLog;

                    trigger OnAction()
                    var
                        TestOutput: Codeunit "Test Output";
                    begin
                        Clear(TestOutput);
                    end;
                }
            }
        }

        addlast(Category_Process)
        {
            group(DataDrivenTest)
            {
                Caption = 'Data inputs';
                Image = TestReport;

                actionref(DataInputs_Promoted; DataInputs)
                {
                }
                actionref(ExpandTestLine_Promoted; ExpandTestLine)
                {
                }
                actionref(ImportDefinition_Promoted; ImportDataInputs)
                {
                }
            }
            group(DataOutputs)
            {
                Caption = 'Data outputs';
                Image = OutputJournal;

                actionref(DataOutput_Promoted; DataOutput)
                {
                }
                actionref(ClearDataOutput_Promoted; ClearDataOutput)
                {
                }
                actionref(ViewDataOutputs_Promoted; ViewDataOutputs)
                {
                }
            }
        }
    }
    var
        DataInputDisplayText: Text;
        DataInputVisible: Boolean;

    trigger OnAfterGetRecord()
    var
        TestInput: Record "Test Input";
    begin
        TestInput.ReadIsolation := IsolationLevel::ReadUncommitted;
        DataInputVisible := not TestInput.IsEmpty();
        if DataInputVisible then
            DataInputDisplayText := TestInput.GetTestInputDisplayName(Rec."Data Input Group Code", Rec."Data Input")
    end;


}