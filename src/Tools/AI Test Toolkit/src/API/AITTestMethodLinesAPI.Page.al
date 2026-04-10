// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
page 149030 "AIT Test Method Lines API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'aiTestToolkit';
    APIVersion = 'v2.0';
    Caption = 'AI Test Method Lines';
    EntityCaption = 'AI Test Method Line';
    EntitySetCaption = 'AI Test Method Lines';
    EntityName = 'aiTestMethodLine';
    EntitySetName = 'aitTestMethodLines';
    SourceTable = "AIT Test Method Line";
    ODataKeyFields = SystemId;
    Extensible = false;
    DelayedInsert = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field("aitCode"; Rec."Test Suite Code")
                {
                    Caption = 'Test Suite Code';
                    Editable = false;
                    NotBlank = true;
                    TableRelation = "AIT Test Suite";
                }
                field("lineNumber"; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field("codeunitID"; Rec."Codeunit ID")
                {
                    Caption = 'Codeunit ID';
                }
                field("codeunitName"; Rec."Codeunit Name")
                {
                    Caption = 'Codeunit Name';
                }
                field("testDescription"; Rec."Description")
                {
                    Caption = 'Test Description';
                }
                field(dataset; Rec."Input Dataset")
                {
                    Caption = 'Dataset';
                }
                field("version"; Rec."Version Filter")
                {
                    Caption = 'Version';
                }
                field("status"; Rec.Status)
                {
                    Caption = 'Status';
                }
                field("noOfTestsExecuted"; Rec."No. of Tests Executed")
                {
                    Caption = 'No. of Tests Executed';
                }
                field("noOfTestsPassed"; Rec."No. of Tests Passed")
                {
                    Caption = 'No. of Tests Passed';
                }
                field("noOfTestsFailed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                {
                    Caption = 'No. of Tests Failed';
                }
                field("durationMs"; Rec."Total Duration (ms)")
                {
                    Caption = 'Duration (ms)';
                }
                field(tokensConsumed; Rec."Tokens Consumed")
                {
                    Caption = 'Total Tokens Consumed';
                }
            }
        }
    }
}