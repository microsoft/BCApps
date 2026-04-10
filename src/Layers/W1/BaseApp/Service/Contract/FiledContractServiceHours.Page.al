// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6088 "Filed Contract Service Hours"
{
    Caption = 'Filed Contract Service Hours';
    DataCaptionFields = "Service Contract No.";
    Editable = false;
    PageType = List;
    SourceTable = "Filed Contract Service Hour";

    layout
    {
        area(content)
        {
            repeater(ServiceHours)
            {
                ShowCaption = false;
                field("Service Contract No."; Rec."Service Contract No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field(Day; Rec.Day)
                {
                    ApplicationArea = Service;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Service;
                }
                field("Valid on Holidays"; Rec."Valid on Holidays")
                {
                    ApplicationArea = Service;
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesPart; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }
}