// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149050 "BCCT Dataset API"
{
    PageType = API;

    APIPublisher = 'microsoft';
    APIGroup = 'copilotTestToolkit';
    APIVersion = 'v1.0';
    Caption = 'BCCT Dataset API';

    EntityCaption = 'BCCTDataset';
    EntitySetCaption = 'BCCTDataset';
    EntityName = 'bcctDataset';
    EntitySetName = 'bcctDatasets';

    SourceTable = "BCCT Dataset";
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
                    Editable = false;
                }

                part("bcctDatasetLines"; "BCCT Dataset Line API")
                {
                    Caption = 'BCCT Dataset Line';
                    EntityName = 'bcctDatasetLine';
                    EntitySetName = 'bcctDatasetLines';
                    SubPageLink = "Dataset Name" = field("Dataset Name");
                }
            }
        }
    }
}