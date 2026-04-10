// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

page 99000808 "Routing Version List"
{
    Caption = 'Routing Version List';
    CardPageID = "Routing Version";
    DataCaptionFields = "Routing No.";
    Editable = false;
    PageType = List;
    SourceTable = "Routing Version";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Version Code"; Rec."Version Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Status; Rec.Status)
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

