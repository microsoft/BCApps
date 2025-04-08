// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

report 149030 "AIT Test Summary"
{
    Caption = 'AI Test Summary';
    ApplicationArea = All;
    UsageCategory = Tasks;
    DefaultLayout = Excel;
    ExcelLayout = 'AITestSummary.xlsx';

    dataset
    {
        dataitem(Results; "AIT Log Entry")
        {
            RequestFilterFields = Version;
            RequestFilterHeading = 'AI Test Log Entries';

            column(CodeunitID; Results."Codeunit ID")
            {
            }
            column(Name; Results."Codeunit Name")
            {
            }
            column(TestName; Results."Procedure Name")
            {
            }
            column(Status; Results.Status)
            {
            }
            column(Accuracy; Results."Test Method Line Accuracy")
            {
            }
            column(TurnsExecuted; Results."No. of Turns")
            {
            }
            column(TurnsPassed; Results."No. of Turns Passed")
            {
            }
            column(Input; Input)
            {
            }
            column(Output; Output)
            {
            }
            column(Error_Message; ErrorMessage)
            {
            }
            column(Error; ErrorCallstack)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Input := Results.GetInputBlob();
                Output := Results.GetOutputBlob();
                ErrorMessage := Results.GetMessage();
                ErrorCallstack := Results.GetErrorCallStack();
            end;
        }
    }

    var
        Input: Text;
        Output: Text;
        ErrorMessage: Text;
        ErrorCallstack: Text;
}