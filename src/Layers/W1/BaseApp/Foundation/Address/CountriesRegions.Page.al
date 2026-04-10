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
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("ISO Code"; Rec."ISO Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("ISO Numeric Code"; Rec."ISO Numeric Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Address Format"; Rec."Address Format")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contact Address Format"; Rec."Contact Address Format")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("County Name"; Rec."County Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EU Country/Region Code"; Rec."EU Country/Region Code")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Intrastat Code"; Rec."Intrastat Code")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("VAT Scheme"; Rec."VAT Scheme")
                {
                    ApplicationArea = Basic, Suite;
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
