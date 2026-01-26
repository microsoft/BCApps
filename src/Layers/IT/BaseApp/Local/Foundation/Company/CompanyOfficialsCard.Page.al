// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

page 12159 "Company Officials Card"
{
    Caption = 'Company Officials Card';
    PageType = Card;
    SourceTable = "Company Officials";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique entry number that is assigned to the company official.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job title of the company official.';
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first name of the company official.';
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last name of the company official.';
                }
                field("Middle Name"; Rec."Middle Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Middle Name/Initials';
                    ToolTip = 'Specifies the middle name of the company official.';
                }
                field(Initials; Rec.Initials)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the initials of the company official.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the company official.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information for the company official.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code/City';
                    ToolTip = 'Specifies the post code of the company official.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of residence of the company official.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the residence of the company official.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the company official.';
                }
                field("Date of Birth"; Rec."Date of Birth")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of birth of the individual person.';
                }
                field("Birth Post Code"; Rec."Birth Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the city where the person was born.';
                }
                field("Birth City"; Rec."Birth City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city where the person was born.';
                }
                field("Birth County"; Rec."Birth County")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county where the person was born.';
                }
                field(Gender; Rec.Gender)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the gender of the person.';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name for the company official.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee identification number of the company official.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the area of residence of the company official.';
                }
                field("Fiscal Code"; Rec."Fiscal Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fiscal identification code that is assigned by the government to interact with state and public offices and authorities.';
                }
                field("Appointment Code"; Rec."Appointment Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the company that is submitting VAT statements on behalf of other legal entities.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the company official''s information was last changed.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field(Extension; Rec.Extension)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone extension number of the company official.';
                }
                field("Mobile Phone No."; Rec."Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mobile telephone number of the company official.';
                }
                field(Pager; Rec.Pager)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pager number of the company official.';
                }
                field("Phone No.2"; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the company official.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the email address of the company official.';
                }
            }
        }
    }

    actions
    {
    }
}

