// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

#if not CLEAN27
using Microsoft.Foundation.Address;
#endif

page 5056 "Contact Alt. Address Card"
{
    Caption = 'Contact Alt. Address Card';
    DataCaptionExpression = Caption();
    PageType = Card;
    SourceTable = "Contact Alt. Address";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
#if not CLEAN27
                group(Control1040008)
                {
                    ShowCaption = false;
                    Visible = IsAddressLookupTextEnabled;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Functionality has been moved to the GetAddress.io UK Postcodes.';
                    ObsoleteTag = '27.0';
                    field(LookupAddress; LookupAddressLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Field has been moved to the GetAddress.io UK Postcodes.';
                        ObsoleteTag = '27.0';
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            ShowPostcodeLookup(true);
                        end;
                    }
                }
#endif
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the alternate address.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company for the alternate address.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s address. This address will appear on all sales documents for the customer.';
#if not CLEAN27
                    trigger OnValidate()
                    var
                        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
                    begin
                        PostcodeBusinessLogic.ShowDiscoverabilityNotificationIfNeccessary();
                    end;
#endif
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the contact''s alternative address.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county for the contact''s alternative address.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the postal code.';
#if not CLEAN27
                    trigger OnValidate()
                    var
                        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
                    begin
                        PostcodeBusinessLogic.ShowDiscoverabilityNotificationIfNeccessary();
                        ShowPostcodeLookup(false);
                    end;
#endif                    
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code for the contact''s alternate address. To see the country/region codes in the Country/Region table, click the field.';
#if not CLEAN27
                    trigger OnValidate()
                    begin
                        HandleAddressLookupVisibility();
                    end;
#endif
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number for the alternate address.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No.2"; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number for the alternate address.';
                }
                field("Mobile Phone No."; Rec."Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mobile phone number for the alternate address.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number for the alternate address.';
                }
                field("Telex No."; Rec."Telex No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telex number for the alternate address.';
                }
                field(Pager; Rec.Pager)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pager number for the contact at the alternate address.';
                }
                field("Telex Answer Back"; Rec."Telex Answer Back")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telex answer back number for the alternate address.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the e-mail address for the contact at the alternate address.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s web site.';
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
        area(navigation)
        {
            group("&Alt. Contact Address")
            {
                Caption = '&Alt. Contact Address';
                action("Date Ranges")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Ranges';
                    Image = DateRange;
                    RunObject = Page "Alt. Addr. Date Ranges";
                    RunPageLink = "Contact No." = field("Contact No."),
                                  "Contact Alt. Address Code" = field(Code);
                    ToolTip = 'Specify date ranges that apply to the contact''s alternate address.';
                }
            }
        }
    }

#if not CLEAN27
    trigger OnAfterGetCurrRecord()
    begin
        HandleAddressLookupVisibility();
    end;
#endif

    var
#pragma warning disable AA0074
        Text000: Label 'untitled';
#pragma warning restore AA0074
#if not CLEAN27
        IsAddressLookupTextEnabled: Boolean;
        LookupAddressLbl: Label 'Lookup address from postcode';
#endif

    procedure Caption(): Text
    var
        Cont: Record Contact;
    begin
        if Cont.Get(Rec."Contact No.") then
            exit(Rec."Contact No." + ' ' + Cont.Name + ' ' + Rec.Code + ' ' + Rec."Company Name");

        exit(Text000);
    end;

#if not CLEAN27
    [Obsolete('Functionality has been moved to the GetAddress.io UK Postcodes.', '27.0')]
    local procedure ShowPostcodeLookup(ShowInputFields: Boolean)
    var
        TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempAutocompleteAddress: Record "Autocomplete Address" temporary;
        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
    begin
        if not PostcodeBusinessLogic.SupportedCountryOrRegionCode(Rec."Country/Region Code") then
            exit;

        if not PostcodeBusinessLogic.IsConfigured() or ((Rec."Post Code" = '') and not ShowInputFields) then
            exit;

        TempEnteredAutocompleteAddress.Address := Rec.Address;
        TempEnteredAutocompleteAddress.Postcode := Rec."Post Code";

        if not PostcodeBusinessLogic.ShowLookupWindow(TempEnteredAutocompleteAddress, ShowInputFields, TempAutocompleteAddress) then
            exit;

        CopyAutocompleteFields(TempAutocompleteAddress);
        HandleAddressLookupVisibility();
    end;

    local procedure CopyAutocompleteFields(var TempAutocompleteAddress: Record "Autocomplete Address" temporary)
    begin
        Rec.Address := TempAutocompleteAddress.Address;
        Rec."Address 2" := TempAutocompleteAddress."Address 2";
        Rec."Post Code" := TempAutocompleteAddress.Postcode;
        Rec.City := TempAutocompleteAddress.City;
        Rec.County := TempAutocompleteAddress.County;
        Rec."Country/Region Code" := TempAutocompleteAddress."Country / Region";
    end;

    local procedure HandleAddressLookupVisibility()
    var
        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
    begin
        if not CurrPage.Editable or not PostcodeBusinessLogic.IsConfigured() then
            IsAddressLookupTextEnabled := false
        else
            IsAddressLookupTextEnabled := PostcodeBusinessLogic.SupportedCountryOrRegionCode(Rec."Country/Region Code");
    end;
#endif
}

