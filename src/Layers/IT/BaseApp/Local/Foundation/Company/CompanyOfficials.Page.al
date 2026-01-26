// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

page 12160 "Company Officials"
{
    Caption = 'Company Officials';
    CardPageID = "Company Officials Card";
    Editable = false;
    PageType = List;
    SourceTable = "Company Officials";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number that is assigned to the company official.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee identification number of the company official.';
                }
                field(FullName; Rec.FullName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of the person.';
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first name of the company official.';
                    Visible = false;
                }
                field("Middle Name"; Rec."Middle Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the middle name of the company official.';
                    Visible = false;
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last name of the company official.';
                    Visible = false;
                }
                field(Initials; Rec.Initials)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the initials of the company official.';
                    Visible = false;
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job title of the company official.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the post code of the company official.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the residence of the company official.';
                    Visible = false;
                }
                field(Extension; Rec.Extension)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone extension number of the company official.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the company official.';
                    Visible = false;
                }
                field("Mobile Phone No."; Rec."Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mobile telephone number of the company official.';
                    Visible = false;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the email address of the company official.';
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name for the company official.';
                }
            }
        }
    }

    actions
    {
    }
}

