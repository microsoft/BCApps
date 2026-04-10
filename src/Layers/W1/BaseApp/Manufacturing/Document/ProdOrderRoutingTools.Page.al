// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

page 99000844 "Prod. Order Routing Tools"
{
    AutoSplitKey = true;
    Caption = 'Prod. Order Routing Tools';
    DataCaptionExpression = Rec.Caption();
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Prod. Order Routing Tool";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

