// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

page 7602 "Base Calendar Changes"
{
    Caption = 'Base Calendar Changes';
    DataCaptionFields = "Base Calendar Code";
    PageType = List;
    SourceTable = "Base Calendar Change";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Recurring System"; Rec."Recurring System")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring System';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Suite;
                }
                field(Day; Rec.Day)
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field(Nonworking; Rec.Nonworking)
                {
                    ApplicationArea = Suite;
                    Caption = 'Nonworking';
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

