// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

page 149046 "BCCT Suite API"
{
    PageType = API;

    APIPublisher = 'microsoft';
    APIGroup = 'performancToolkit';
    APIVersion = 'v1.0';
    Caption = 'BCCT Suite API';

    EntityCaption = 'BCCTSuite';
    EntitySetCaption = 'BCCTSuite';
    EntityName = 'bcctSuite';
    EntitySetName = 'bcctSuites';

    SourceTable = "BCCT Header";
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
                field("code"; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(modelVersion; Rec.ModelVersion)
                {
                    Caption = 'Model Version';
                }
                field(dataset; Rec.Dataset)
                {
                    Caption = 'Dataset';
                }
                field(tag; Rec.Tag)
                {
                    Caption = 'Tag';
                }
                field("defaultMinimumUserDelayInMilliSeconds"; Rec."Default Min. User Delay (ms)")
                {
                    Caption = 'Default Min. User Delay (ms)';
                }
                field("defaultMaximumUserDelayInMilliSeconds"; Rec."Default Max. User Delay (ms)")
                {
                    Caption = 'Default Max. User Delay (ms)';
                }
                part("testSuitesLines"; "BCCT Suite Line API")
                {
                    Caption = 'BCCT Suite Line';
                    EntityName = 'bcctSuiteLine';
                    EntitySetName = 'bcctSuiteLines';
                    SubPageLink = "BCCT Code" = field("Code");
                }
            }
        }
    }
}