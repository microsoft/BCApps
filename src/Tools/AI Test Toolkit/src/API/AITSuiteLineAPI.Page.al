// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

page 149037 "AIT Suite Line API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'aiTestToolkit';
    APIVersion = 'v1.0';
    Caption = 'AI Test Suite Lines';
    EntityCaption = 'AI Test Suite Line';
    EntitySetCaption = 'AI Test Suite Lines';
    EntityName = 'aiTestSuiteLine';
    EntitySetName = 'aiTestSuiteLines';
    SourceTable = "AIT Test Method Line";
    ODataKeyFields = SystemId;
    Extensible = false;
    DelayedInsert = true;

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
                    Caption = 'AIT Code';
                    Editable = false;
                    NotBlank = true;
                    TableRelation = "AIT Test Suite";
                }
                field("codeunitID"; Rec."Codeunit ID")
                {
                    Caption = 'Codeunit ID';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field("delayBetweenIterations"; Rec."Delay (ms btwn. iter.)")
                {
                    Caption = 'Delay between iterations (ms.)';
                }
                field(dataset; Rec."Input Dataset")
                {
                    Caption = 'Override the suite dataset';
                    TableRelation = "Test Input Group".Code;
                }
                field("minimumUserDelay"; Rec."Min. User Delay (ms)")
                {
                    Caption = 'Min. User Delay (ms)';
                }
                field("maximumUserDelay"; Rec."Max. User Delay (ms)")
                {
                    Caption = 'Max. User Delay (ms)';
                }
            }
        }
    }
}