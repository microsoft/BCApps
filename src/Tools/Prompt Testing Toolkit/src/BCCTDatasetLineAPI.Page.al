// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

page 149047 "BCCT Dataset Line API"
{
    PageType = API;

    APIPublisher = 'microsoft';
    APIGroup = 'copilotTestToolkit';
    APIVersion = 'v1.0';
    Caption = 'BCCT Dataset Line API';

    EntityCaption = 'BCCTDatasetLine';
    EntitySetCaption = 'BCCTDatasetLine';
    EntityName = 'bcctDatasetLine';
    EntitySetName = 'bcctDatasetLines';

    SourceTable = "BCCT Dataset Line";
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
                field("datasetName"; Rec."Dataset Name")
                {
                    Caption = 'BCCT Dataset Name';
                    NotBlank = true;
                    TableRelation = "BCCT Dataset"."Dataset Name";
                }
                field(inputData; Rec."Input Blob") //TODO: consider converting this to text
                {
                    Caption = 'Input Data';
                }
            }
        }
    }
}