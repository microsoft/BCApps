// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Telemetry;
using System.TestTools.TestRunner;
using System.Utilities;

page 149042 "AIT CommandLine Card"
{
    Caption = 'AI Test Command Line Runner';
    PageType = Card;
    Extensible = false;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "AIT Test Method Line";

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
                    ShowMandatory = true;

                    trigger OnValidate()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                    begin
                        if not AITTestSuite.Get(AITCode) then
                            Error(CannotFindAITSuiteErr, AITCode);

                        // Clear the filter on the test lines
                        if AITCode <> xRec."Test Suite Code" then
                            Clear(LineNoFilter);

                        UpdateAITestMethodLines();
                    end;
                }
                field("Line No. Filter"; LineNoFilter)
                {
                    Caption = 'Line No. Filter';
                    ToolTip = 'Specifies the line number to filter the test method lines.';
                    TableRelation = "AIT Test Method Line"."Line No." where("Test Suite Code" = field("Test Suite Code"));
                    BlankZero = true;

                    trigger OnValidate()
                    begin
                        UpdateAITestMethodLines();
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
                Caption = 'Test Inputs';

                field("Input Dataset Filename"; InputDatasetFilename)
                {
                    Caption = 'Import Input Dataset Filename';
                    ToolTip = 'Specifies the input dataset filename to import for running the test suite.';
                    ShowMandatory = InputDataset <> '';
                }
                field("Input Dataset"; InputDataset)
                {
                    Caption = 'Import Input Dataset';
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
                        TestInputsManagement.UploadAndImportDataInputs(InputDatasetFilename, InputDatasetInStream);
                    end;
                }
            }
            group(SuiteDefinitionGroup)
            {
                Caption = 'Suite Definition';

                field("Suite Definition"; SuiteDefinition)
                {
                    Caption = 'Import Suite Definition';
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
            group("Test Method Lines Group")
            {
                Editable = false;
                Caption = 'Test Method Lines';

                repeater("Test Method Lines")
                {
                    field("TML Suite Code"; Rec."Test Suite Code")
                    {
                    }
                    field("Line No."; Rec."Line No.")
                    {
                    }
                    field("Codeunit ID"; Rec."Codeunit ID")
                    {
                    }
                    field("Codeunit Name"; Rec."Codeunit Name")
                    {
                    }
                    field("Test Description"; Rec."Description")
                    {
                    }
                    field("Dataset"; Rec."Input Dataset")
                    {
                    }
                    field("Status"; Rec.Status)
                    {
                    }
                    field("No. of Tests Executed"; Rec."No. of Tests Executed")
                    {
                    }
                    field("No. of Tests Passed"; Rec."No. of Tests Passed")
                    {
                    }
                    field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                    {
                        Caption = 'No. of Tests Failed';
                        ToolTip = 'Specifies the number of failed tests for the test line.';
                    }
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
                Caption = 'Run Suite';
                Image = Start;
                ToolTip = 'Starts running the AI test suite. This action ignores the line number filter and runs all the test lines in the suite.';

                trigger OnAction()
                begin
                    StartAITSuite();
                end;
            }
            action(RunNextTest)
            {
                Caption = 'Run Next Test';
                Image = TestReport;
                ToolTip = 'Starts running the next test from the Test Method Lines for the given suite.';

                trigger OnAction()
                begin
                    StartNextTest();
                end;
            }
            action(ResetTestSuite)
            {
                Caption = 'Reset Test Suite';
                Image = Restore;
                ToolTip = 'Resets the test method lines status to run them again. This action ignores the line number filter and resets all the test lines in the suite.';

                trigger OnAction()
                var
                    AITTestMethodLine: Record "AIT Test Method Line";
                begin
                    AITTestMethodLine.SetRange("Test Suite Code", AITCode);
                    AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::" ", true);
                    UpdateAITestMethodLines();
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
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        FeatureTelemetry.LogUptake('0000NF0', AITTestSuiteMgt.GetFeatureName(), Enum::"Feature Uptake Status"::Discovered);
        Rec.SetRange("Test Suite Code", AITCode);
    end;

    var
        CannotFindAITSuiteErr: Label 'The specified Test Suite with code %1 cannot be found.', Comment = '%1 = Test Suite id.';
        AITCode: Code[100];
        LineNoFilter: Integer;
        NoOfPendingTests: Integer;
        InputDataset: Text;
        SuiteDefinition: Text;
        InputDatasetFilename: Text;

    local procedure StartAITSuite()
    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        TestSuiteCodeNotFoundErr: Label 'Test Suite with code %1 not found.', Comment = '%1 = Test Suite id.';
    begin
        VerifyTestSuiteCode();
        if not AITTestSuite.Get(AITCode) then
            Error(TestSuiteCodeNotFoundErr, AITCode);

        AITTestSuiteMgt.StartAITSuite(AITTestSuite);
        UpdateAITestMethodLines();
    end;

    local procedure StartNextTest()
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        VerifyTestSuiteCode();
        AITTestMethodLine.Copy(Rec);
        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::" ");
        if AITTestMethodLine.FindFirst() then begin
            AITTestSuiteMgt.RunAITestLine(AITTestMethodLine, false);
            UpdateAITestMethodLines();
        end;
    end;

    local procedure VerifyTestSuiteCode()
    var
        TestSuiteCodeRequiredErr: Label 'Test Suite Code is required to run the suite.';
    begin
        if AITCode = '' then
            Error(TestSuiteCodeRequiredErr);
    end;

    local procedure RefreshNoOfPendingTests(): Integer
    var
        Rec2: Record "AIT Test Method Line";
    begin
        Rec2.CopyFilters(Rec);
        Rec.SetRange(Status, Rec.Status::" ");
        NoOfPendingTests := Rec.Count();
        Rec.CopyFilters(Rec2);
    end;

    local procedure SetFilterOnTestLines(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        AITTestMethodLine.SetRange("Test Suite Code", AITCode);
        if LineNoFilter > 0 then
            AITTestMethodLine.SetRange("Line No.", LineNoFilter)
        else
            AITTestMethodLine.SetRange("Line No.");
    end;

    local procedure UpdateAITestMethodLines()
    begin
        SetFilterOnTestLines(Rec);
        RefreshNoOfPendingTests();
        CurrPage.Update(false);
    end;

}