// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

page 149037 "BCCT Suite Line API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'copilotTestToolkit';
    APIVersion = 'v1.0';

    Caption = 'BCCT Suite Lines API';

    EntityCaption = 'BCCTSuiteLine';
    EntitySetCaption = 'BCCTSuiteLine';
    EntityName = 'bcctSuiteLine';
    EntitySetName = 'bcctSuiteLines';

    SourceTable = "BCCT Line";
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
                field("bcctCode"; Rec."BCCT Code")
                {
                    Caption = 'BCCT Code';
                    Editable = false;
                    NotBlank = true;
                    TableRelation = "BCCT Header";
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
                field(dataset; Rec.Dataset)
                {
                    Caption = 'Override the suite dataset';
                    TableRelation = "BCCT Dataset"."Dataset Name";
                }
                field("runInForeground"; Rec."Run in Foreground")
                {
                    Caption = 'Run in Foreground';
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