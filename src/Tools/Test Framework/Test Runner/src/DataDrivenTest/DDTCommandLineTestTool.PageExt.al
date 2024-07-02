// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

pageextension 130452 "DDT Command Line Test Tool" extends "Command Line Test Tool"
{
    layout
    {
        addafter(CCResultsCSVText)
        {
#pragma warning disable AA0248
            field(DataOutput; DataOutputTxt)
#pragma warning restore AA0248
            {
                ApplicationArea = All;
                Caption = 'Data Output';
                ToolTip = 'Specifies the data output for the test method line';
            }
#pragma warning disable AA0248
            field(DataInput; DataInputTxt)
#pragma warning restore AA0248
            {
                ApplicationArea = All;
                Caption = 'Data Input';
                ToolTip = 'Specifies the data input for the test method line';

                trigger OnValidate()
                var
                    TestInputGroup: Record "Test Input Group";
                    TestInputsManagement: Codeunit "Test Inputs Management";
                begin
                    TestInputGroup.CreateUniqueGroupForALTest(GlobalALTestSuite);
#pragma warning disable AA0248
                    TestInputsManagement.ImportDataInputsFromText(TestInputGroup, DataInputTxt);
#pragma warning restore AA0248
                end;
            }
        }
    }

    actions
    {
        addafter(GetCodeCoverageMap)
        {
            action(GetDataOutput)
            {
                ApplicationArea = All;
                Caption = 'Get Data Output';
                ToolTip = 'Specifies the action for invoking GetDataOutput procedure';
                Image = DataEntry;

                trigger OnAction()
                var
                    TestOutput: Codeunit "Test Output";
                    TestOutputJson: Codeunit "Test Output Json";
                begin
                    TestOutputJson := TestOutput.GetAllTestOutput();
#pragma warning disable AA0248
                    DataOutputTxt := TestOutputJson.ToText();
#pragma warning restore AA0248
                end;
            }
            action(ClearDataOuput)
            {
                ApplicationArea = All;
                Caption = 'Clear Data Output';
                ToolTip = 'Specifies the action for invoking ClearDataOutput procedure';
                Image = Delete;

                trigger OnAction()
                var
                    TestOutput: Codeunit "Test Output";
                begin
                    Clear(TestOutput);
#pragma warning disable AA0248
                    DataOutputTxt := '';
#pragma warning restore AA0248
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(GetDataOutput_Promoted; GetDataOutput)
            {
            }
            actionref(ClearDataOuput_Promoted; ClearDataOuput)
            {
            }
        }
    }

    var
        DataOutputTxt: Text;
        DataInputTxt: Text;
}