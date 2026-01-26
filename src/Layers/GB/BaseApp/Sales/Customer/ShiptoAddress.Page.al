// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Address;

page 300 "Ship-to Address"
{
    Caption = 'Ship-to Address';
    DataCaptionExpression = Rec.Caption();
    PageType = Card;
    SourceTable = "Ship-to Address";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Control3)
                {
                    ShowCaption = false;
#if not CLEAN27
                    group(Control1040006)
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
                        ApplicationArea = Basic, Suite;
                    }
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Name 2"; Rec."Name 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = false;
                    }
                    field(GLN; Rec.GLN)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Basic, Suite;
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
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    group(Control13)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
#if not CLEAN27
                            HandleAddressLookupVisibility();
#endif
                        end;
                    }
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;
                        ToolTip = 'Specifies the customer''s address on your preferred map website.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update(true);
                            Rec.DisplayMap();
                        end;
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Importance = Additional;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
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
            group("&Address")
            {
                Caption = '&Address';
                Image = Addresses;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
#if not CLEAN27
        HandleAddressLookupVisibility();
#endif
    end;

    trigger OnAfterGetRecord()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        if not Customer.Get(Rec.GetFilterCustNo()) then
            exit;

        IsHandled := false;
        OnBeforeOnNewRecord(Customer, IsHandled, Rec);
        if IsHandled then
            exit;

        Rec.Validate(Name, Customer.Name);
        Rec.Validate(Address, Customer.Address);
        Rec.Validate("Address 2", Customer."Address 2");
        Rec."Country/Region Code" := Customer."Country/Region Code";
        Rec.City := Customer.City;
        Rec.County := Customer.County;
        Rec."Post Code" := Customer."Post Code";
        Rec."Phone No." := Customer."Phone No.";
        Rec."E-Mail" := Customer."E-Mail";
        Rec.Validate(Contact, Customer.Contact);

        OnAfterOnNewRecord(Customer, Rec);
    end;

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
#if not CLEAN27
        IsAddressLookupTextEnabled: Boolean;
        LookupAddressLbl: Label 'Lookup address from postcode';
#endif        

        ShowMapLbl: Label 'Show on Map';

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

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnNewRecord(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnNewRecord(var Customer: Record Customer; var IsHandled: Boolean; var ShipToAddress: Record "Ship-to Address")
    begin
    end;
}

