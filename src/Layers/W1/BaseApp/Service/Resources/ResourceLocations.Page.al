// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

page 6015 "Resource Locations"
{
    Caption = 'Resource Locations';
    DataCaptionFields = "Location Code", "Location Name";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Resource Location";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = Jobs;
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

