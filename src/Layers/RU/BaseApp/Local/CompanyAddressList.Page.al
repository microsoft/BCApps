#pragma warning disable AA0247
page 12493 "Company Address List"
{
    Caption = 'Company Address List';
    CardPageID = "Company Address";
    Editable = false;
    PageType = List;
    SourceTable = "Company Address";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Primary Key of the Company Information card, to which this address record is attached.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company name for this address, as you want it to appear on printed materials.';
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of this company name.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company address.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the address.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a contact name at the company address.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("Telex No."; Rec."Telex No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telex number at this company address.';
                }
                field("Registration No."; Rec."Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s registration number.';
                }
                field("Region Code"; Rec."Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the region code for this company address.';
                }
                field("Region Name"; Rec."Region Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the region name for this company address.';
                }
                field(Settlement; Rec.Settlement)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company location.';
                }
                field(Street; Rec.Street)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the street name for this company address.';
                }
                field(House; Rec.House)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the house number for the company address.';
                }
                field(Building; Rec.Building)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the building number for this company address.';
                }
                field(Apartment; Rec.Apartment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the apartment number for this company address.';
                }
                field("Address Type"; Rec."Address Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of company address for use in statutory reports.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was last modified.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county for this address.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s email address.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the web site.';
                }
                field(OKPO; Rec.OKPO)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the federation-wide organizational classification of the company.';
                }
                field(KPP; Rec.KPP)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the KPP reason code of the company.';
                }
                field("Director Phone No."; Rec."Director Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the director of the company.';
                }
                field("Accountant Phone No."; Rec."Accountant Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the company accountant.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

