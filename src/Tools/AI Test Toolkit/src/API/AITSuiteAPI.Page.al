// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
// TODO: Do we need this for v1?
page 149046 "AIT Suite API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'aiTestToolkit';
    APIVersion = 'v1.0';
    Caption = 'AI Test Suite';
    EntityCaption = 'AI Test Suite';
    EntitySetCaption = 'AI Test Suite';
    EntityName = 'aiTestSuite';
    EntitySetName = 'aiTestSuites';
    SourceTable = "AIT Test Suite";
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
                field(dataset; Rec."Input Dataset")
                {
                    Caption = 'Dataset';
                }
                field(tag; Rec.Tag)
                {
                    Caption = 'Tag';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                { 
                    Caption = 'Last Modified Date Time';
                }

                part("testSuitesLines"; "AIT Suite Line API")
                {
                    Caption = 'AIT Suite Line';
                    EntityName = 'aiTestSuiteLine';
                    EntitySetName = 'aiTestSuiteLines';
                    SubPageLink = "Test Suite Code" = field("Code");
                }
            }
        }
    }
}