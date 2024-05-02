// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

page 149032 "BCCT Dataset"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "BCCT Dataset";
    InsertAllowed = false;
    DataCaptionExpression = Rec."Dataset Name";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(Details)
            {
                field("Dataset Name"; Rec."Dataset Name")
                {
                }
            }
            part("BCCT Dataset Lines Part"; "BCCT Dataset Lines Part")
            {
                SubPageLink = "Dataset Name" = field("Dataset Name");
                UpdatePropagation = Both;
            }
        }
    }
}