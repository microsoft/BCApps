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
            field("Data Input"; Rec."Data Input")
            {
                ApplicationArea = All;
                Visible = DataInputVisible;
                Caption = 'Data Input';
                ToolTip = 'Data input for the test method line';

                trigger OnValidate()
                var
                    ChildTestMethodLine: Record "Test Method Line";
                    NextCodeunitLine: Record "Test Method Line";
                    TestSuiteMgt: Codeunit "Test Suite Mgt.";
                begin
                    if Rec."Line Type" = Rec."Line Type"::Codeunit then begin
                        ChildTestMethodLine.SetRange("Test Suite", Rec."Test Suite");
                        ChildTestMethodLine.SetRange("Test Codeunit", Rec."Test Codeunit");
                        ChildTestMethodLine.SetRange("Line Type", ChildTestMethodLine."Line Type"::Function);
                        ChildTestMethodLine.SetFilter("Line No.", TestSuiteMgt.GetLineNoFilterForTestCodeunit(Rec));
                        ChildTestMethodLine.ModifyAll("Data Input", Rec."Data Input");
                        CurrPage.Update(false);
                    end;
                end;
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
                        ALTestSuite: Record "AL Test Suite";
                        TestInputsManagement: Codeunit "Test Inputs Management";
                    begin
                        ALTestSuite.Get(Rec."Test Suite");
                        TestInputsManagement.UploadAndImportDataInputsFromJson(ALTestSuite);
                    end;
                }
                action(ImportTestDefinitions)
                {
                    ApplicationArea = All;
                    Caption = 'Import data-driven test definitions';
                    Image = ImportLog;

                    trigger OnAction()
                    var
                        ALTestSuite: Record "AL Test Suite";
                        TestInputsManagement: Codeunit "Test Inputs Management";
                    begin
                        ALTestSuite.Get(Rec."Test Suite");
                        TestInputsManagement.UploadAndImportTestDefinitions(ALTestSuite);
                    end;
                }
                action(DataInputs)
                {
                    ApplicationArea = All;
                    Caption = 'Data inputs';
                    Image = TestFile;
                    trigger OnAction()
                    var
                        TestInput: Record "Test Input";
                    begin
                        TestInput.SetRange("Test Suite", Rec."Test Suite");
                        Page.RunModal(Page::"Test Inputs", TestInput);
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
                        TestInputs: Record "Test Input";
                        TestInputsPage: Page "Test Inputs";
                        TestInputsManagement: Codeunit "Test Inputs Management";
                    begin
                        if Rec."Line Type" <> Rec."Line Type"::Codeunit then
                            Error(LineTypeMustBeCodeunitErr);

                        TestInputsPage.LookupMode(true);
                        if not (TestInputsPage.RunModal() = Action::LookupOK) then
                            exit;

                        TestInputsPage.SetSelectionFilter(TestInputs);

                        TestInputs.MarkedOnly(true);
                        TestInputsManagement.AssignDataDrivenTest(Rec, TestInputs);
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
                actionref(ImportTestDefinitions_Promoted; ImportTestDefinitions)
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
        DataInputVisible: Boolean;
        LineTypeMustBeCodeunitErr: Label 'Line type must be Codeunit.';

    trigger OnAfterGetRecord()
    var
        TestInput: Record "Test Input";
    begin
        TestInput.ReadIsolation := IsolationLevel::ReadUncommitted;
        DataInputVisible := not TestInput.IsEmpty();
    end;
}