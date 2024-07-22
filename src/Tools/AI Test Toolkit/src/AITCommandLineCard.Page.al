// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Environment;
using System.TestTools.TestRunner;
using System.Utilities;

page 149042 "AIT CommandLine Card"
{
    Caption = 'AI Test CommandLine Runner';
    PageType = Card;
    Extensible = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("AIT Suite Code"; AITCode)
                {
                    Caption = 'Test Suite Code';
                    ToolTip = 'Specifies the ID of the suite.';
                    TableRelation = "AIT Test Suite".Code;

                    trigger OnValidate()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                    begin
                        if not AITTestSuite.Get(AITCode) then
                            Error(CannotFindAITSuiteErr, AITCode);

                        RefreshNoOfPendingTests();
                    end;
                }
                field("No. of Pending Tests"; NoOfPendingTests)
                {
                    Caption = 'No. of Pending Tests';
                    ToolTip = 'Specifies the number of test suite lines in the test suite that are yet to be run.';
                    Editable = false;
                }
            }
            group(DatasetGroup)
            {
                ShowCaption = false;

                field("Input Dataset Filename"; InputDatasetFilename)
                {
                    Caption = 'Input Dataset Filename';
                    ToolTip = 'Specifies the input dataset filename to import for running the test suite.';
                    ShowMandatory = InputDataset <> '';
                }
                field("Input Dataset"; InputDataset)
                {
                    Caption = 'Input Dataset';
                    MultiLine = true;
                    ToolTip = 'Specifies the input dataset to import for running the test suite.';

                    trigger OnValidate()
                    var
                        TestInputsManagement: Codeunit "Test Inputs Management";
                        TempBlob: Codeunit "Temp Blob";
                        InputDatasetOutStream: OutStream;
                        InputDatasetInStream: InStream;
                        FileNameRequiredErr: Label 'Input Dataset Filename is required to import the dataset.';
                    begin
                        if InputDataset.Trim() = '' then
                            exit;
                        if InputDatasetFilename = '' then
                            Error(FileNameRequiredErr);

                        // Import the dataset
                        InputDatasetOutStream := TempBlob.CreateOutStream();
                        InputDatasetOutStream.WriteText(InputDataset);
                        TempBlob.CreateInStream(InputDatasetInStream);
                        TestInputsManagement.UploadAndImportDataInputsFromJson(InputDatasetFilename, InputDatasetInStream);
                    end;
                }
            }
            group(SuiteDefinitionGroup)
            {
                ShowCaption = false;

                field("Suite Definition"; SuiteDefinition)
                {
                    Caption = 'Suite Definition';
                    ToolTip = 'Specifies the suite definition to import.';
                    MultiLine = true;

                    trigger OnValidate()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        SuiteDefinitionXML: XmlDocument;
                        SuiteDefinitionOutStream: OutStream;
                        SuiteDefinitionInStream: InStream;
                        InvalidXMLFormatErr: Label 'Invalid XML format for Suite Definition.';
                        SuiteImportErr: Label 'Error importing Suite Definition.';
                    begin
                        // Import the suite definition
                        if SuiteDefinition.Trim() = '' then
                            exit;

                        if not XmlDocument.ReadFrom(SuiteDefinition, SuiteDefinitionXML) then
                            Error(InvalidXMLFormatErr);

                        SuiteDefinitionOutStream := TempBlob.CreateOutStream();
                        SuiteDefinitionXML.WriteTo(SuiteDefinitionOutStream);
                        TempBlob.CreateInStream(SuiteDefinitionInStream);

                        // Import the suite definition
                        if not XmlPort.Import(XmlPort::"AIT Test Suite Import/Export", SuiteDefinitionInStream) then
                            Error(SuiteImportErr);
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(RunSuite)
            {
                Enabled = EnableActions;
                Caption = 'Run Suite';
                Image = Start;
                ToolTip = 'Starts running the AI test suite.';

                trigger OnAction()
                begin
                    StartAITSuite();
                end;
            }
            action(RunNextTest)
            {
                Enabled = EnableActions;
                Caption = 'Run Next Test';
                Image = TestReport;
                ToolTip = 'Starts running the next test in the AI test suite.';

                trigger OnAction()
                begin
                    StartNextTest();
                end;
            }
            action(ResetTestSuite)
            {
                Enabled = EnableActions;
                Caption = 'Reset Test Suite';
                Image = Restore;
                ToolTip = 'Resets the test method lines status to run them again.';

                trigger OnAction()
                var
                    AITTestMethodLine: Record "AIT Test Method Line";
                begin
                    AITTestMethodLine.SetRange("Test Suite Code", AITCode);
                    AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::" ", true);
                    RefreshNoOfPendingTests();
                end;
            }

        }
        area(Navigation)
        {
            action("AI Test Suite")
            {
                Caption = 'AI Test Suite';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Opens the AI Test Suite page.';

                trigger OnAction()
                var
                    AITTestSuite: Record "AIT Test Suite";
                    AITTestSuitePage: Page "AIT Test Suite";
                begin
                    AITTestSuite.Get(AITCode);
                    AITTestSuitePage.SetRecord(AITTestSuite);
                    AITTestSuitePage.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(RunSuite_Promoted; RunSuite)
                {
                }
                actionref(RunNextTest_Promoted; RunNextTest)
                {
                }
                actionref(ClearTestStatus_Promoted; ResetTestSuite)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        EnableActions := (EnvironmentInformation.IsSaaS() and EnvironmentInformation.IsSandbox()) or EnvironmentInformation.IsOnPrem();
    end;

    var
        CannotFindAITSuiteErr: Label 'The specified Test Suite with code %1 cannot be found.', Comment = '%1 = Test Suite id.';
        EnableActions: Boolean;
        AITCode: Code[100];
        NoOfPendingTests: Integer;
        InputDataset: Text;
        SuiteDefinition: Text;
        InputDatasetFilename: Text;

    local procedure StartAITSuite()
    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        if not AITTestSuite.Get(AITCode) then
            exit;

        AITTestSuiteMgt.StartAITSuite(AITTestSuite);
        RefreshNoOfPendingTests();
    end;

    local procedure StartNextTest()
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        if NoOfPendingTests = 0 then
            exit;
        AITTestMethodLine.SetRange("Test Suite Code", AITCode);
        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::" ");
        if AITTestMethodLine.FindFirst() then
            AITTestSuiteMgt.RunAITestLine(AITTestMethodLine, true);

        RefreshNoOfPendingTests();
    end;

    local procedure RefreshNoOfPendingTests(): Integer
    var
        AITTestMethodLine: Record "AIT Test Method Line";
    begin
        if AITCode <> '' then begin
            AITTestMethodLine.SetRange("Test Suite Code", AITCode);
            AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::" ");
            NoOfPendingTests := AITTestMethodLine.Count();
        end else
            NoOfPendingTests := 0;
    end;

}