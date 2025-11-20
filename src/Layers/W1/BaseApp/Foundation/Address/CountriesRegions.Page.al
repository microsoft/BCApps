// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Finance.VAT.Registration;

page 10 "Countries/Regions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Countries/Regions';
    PageType = List;
    SourceTable = "Country/Region";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("ISO Code"; Rec."ISO Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a two-letter country code defined in ISO 3166-1.';
                }
                field("ISO Numeric Code"; Rec."ISO Numeric Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a three-digit code number defined in ISO 3166-1.';
                }
                field("Address Format"; Rec."Address Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the address that is displayed on external-facing documents. You link an address format to a country/region code so that external-facing documents based on cards or documents with that country/region code use the specified address format. NOTE: If the County field is filled in, then the county will be printed above the country/region unless you select the City+County+Post Code option.';
                }
                field("Contact Address Format"; Rec."Contact Address Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where you want the contact name to appear in mailing addresses.';
                }
                field("County Name"; Rec."County Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the county.';
                }
                field("EU Country/Region Code"; Rec."EU Country/Region Code")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the EU code for the country/region you are doing business with.';
                }
                field("Intrastat Code"; Rec."Intrastat Code")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies an INTRASTAT code for the country/region you are trading with.';
                }
                field("VAT Scheme"; Rec."VAT Scheme")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the national body that issues the VAT registration number for the country/region in connection with electronic document sending.';
                }
            }
        }
        area(factboxes)
        {
            part(Control8; "Custom Address Format Factbox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Country/Region Code" = field(Code);
                Visible = Rec."Address Format" = Rec."Address Format"::Custom;
            }
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
        area(navigation)
        {
            group("&Country/Region")
            {
                Caption = '&Country/Region';
                Image = CountryRegion;
                action("VAT Reg. No. Formats")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Reg. No. Formats';
                    Image = NumberSetup;
                    RunObject = Page "VAT Registration No. Formats";
                    RunPageLink = "Country/Region Code" = field(Code);
                    ToolTip = 'Specify that the tax registration number for an account, such as a customer, corresponds to the standard format for tax registration numbers in an account''s country/region.';
                }
                action(Translations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    Image = Translations;
                    ToolTip = 'Opens a window in which you can define the translations for the name of the selected country/region.';
                    RunObject = Page "Country/Region Translations";
                    RunPageLink = "Country/Region Code" = field(Code);
                }
                action(CustomAddressFormat)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Custom Address Format';
                    Enabled = Rec."Address Format" = Rec."Address Format"::Custom;
                    Image = Addresses;
                    ToolTip = 'Define the scope and order of fields that make up the country/region address.';

                    trigger OnAction()
                    var
                        CustomAddressFormat: Record "Custom Address Format";
                        CustomAddressFormatPage: Page "Custom Address Format";
                    begin
                        if Rec."Address Format" <> Rec."Address Format"::Custom then
                            exit;

                        CustomAddressFormat.FilterGroup(2);
                        CustomAddressFormat.SetRange("Country/Region Code", Rec.Code);
                        CustomAddressFormat.FilterGroup(0);

                        Clear(CustomAddressFormatPage);
                        CustomAddressFormatPage.SetTableView(CustomAddressFormat);
                        CustomAddressFormatPage.RunModal();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(CustomAddressFormat_Promoted; CustomAddressFormat)
                {
                }
            }
            group("Category_Country/Region")
            {
                Caption = 'Country/Region';
                actionref("VAT Reg. No. Formats_Promoted"; "VAT Reg. No. Formats")
                {
                }
                actionref(Translations_Promoted; Translations)
                {
                }
            }
        }
    }
}

