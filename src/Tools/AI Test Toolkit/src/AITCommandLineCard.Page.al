// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Environment;
using System.TestTools.TestRunner;
using System.Xml;
using System.Utilities;

page 149042 "AIT CommandLine Card"
{
    Caption = 'AI Test CommandLine Runner';
    PageType = Card;
    Extensible = false;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("AIT Suite Code"; AITCode)
                {
                    Caption = 'AIT Suite Code', Locked = true;
                    ToolTip = 'Specifies the ID of the suite.';
                    TableRelation = "AIT Test Suite".Code;

                    trigger OnValidate()
                    var
                        AITTestSuite: record "AIT Test Suite";
                        AITTestMethodLine: record "AIT Test Method Line";
                    begin
                        if not AITTestSuite.Get(AITCode) then
                            Error(CannotFindAITSuiteErr, AITCode);

                        AITTestMethodLine.SetRange("Test Suite Code", AITCode);
                        NoOfTests := AITTestMethodLine.Count();
                    end;
                }
                field("Input Dataset Filename"; InputDatasetFilename)
                {
                    Caption = 'Input Dataset Filename', Locked = true;
                    ToolTip = 'Specifies the input dataset filename to import for running the test suite';
                    ShowMandatory = InputDataset <> '';
                }
                field("Input Dataset"; InputDataset)
                {
                    Caption = 'Input Dataset', Locked = true;
                    MultiLine = true;
                    ToolTip = 'Specifies the input dataset to import for running the test suite';

                    trigger OnValidate()
                    var
                        TestInputsManagement: Codeunit "Test Inputs Management";
                        TempBlob: Codeunit "Temp Blob";
                        InputDatasetOutStream: OutStream;
                        InputDatasetInStream: InStream;
                    begin
                        if InputDataset.Trim() = '' then
                            exit;
                        if InputDatasetFilename = '' then
                            Error('Input Dataset Filename is required to import the dataset.');

                        // Import the dataset
                        InputDatasetOutStream := TempBlob.CreateOutStream();
                        InputDatasetOutStream.WriteText(InputDataset);
                        TempBlob.CreateInStream(InputDatasetInStream);
                        TestInputsManagement.UploadAndImportDataInputsFromJson(InputDatasetFilename, InputDatasetInStream);
                    end;
                }
                field("Suite Definition"; SuiteDefinition)
                {
                    Caption = 'Suite Definition', Locked = true;
                    ToolTip = 'Specifies the suite definition to import';
                    MultiLine = true;

                    trigger OnValidate()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        SuiteDefinitionXML: XmlDocument;
                        SuiteDefinitionOutStream: OutStream;
                        SuiteDefinitionInStream: InStream;
                    begin
                        // Import the suite definition
                        if SuiteDefinition.Trim() = '' then
                            exit;

                        if not XmlDocument.ReadFrom(SuiteDefinition, SuiteDefinitionXML) then
                            Error('Invalid XML format for Suite Definition.');

                        SuiteDefinitionOutStream := TempBlob.CreateOutStream();
                        SuiteDefinitionXML.WriteTo(SuiteDefinitionOutStream);
                        TempBlob.CreateInStream(SuiteDefinitionInStream);

                        // Import the suite definition
                        if not Xmlport.Import(XMLPORT::"AIT Test Suite Import/Export", SuiteDefinitionInStream) then
                            Error('Error importing Suite Definition.');
                    end;
                }
                field("No. of Tests"; NoOfTests)
                {
                    Caption = 'No. of Tests', Locked = true;
                    ToolTip = 'Specifies the number of AIT Suite Lines present in the AIT Suite';
                    Editable = false;
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
                Caption = 'Run Suite', Locked = true;
                Image = Start;
                ToolTip = 'Starts running the AI test suite.';

                trigger OnAction()
                begin
                    StartAITSuite();
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
            }
        }
    }

    var
        CannotFindAITSuiteErr: Label 'The specified AIT Suite with code %1 cannot be found.', Comment = '%1 = AIT Suite id.';
        EnableActions: Boolean;
        AITCode: Code[100];
        NoOfTests: Integer;
        InputDataset: Text;
        SuiteDefinition: Text;
        InputDatasetFilename: Text;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        EnableActions := (EnvironmentInformation.IsSaas() and EnvironmentInformation.IsSandbox()) or EnvironmentInformation.IsOnPrem();
    end;

    local procedure StartAITSuite()
    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        if AITTestSuite.Get(AITCode) then
            AITTestSuiteMgt.StartAITSuite(AITTestSuite);
    end;
}