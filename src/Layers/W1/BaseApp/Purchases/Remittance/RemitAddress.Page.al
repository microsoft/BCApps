// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Remittance;

using Microsoft.Foundation.Address;

page 2368 "Remit Address"
{
    Caption = 'Remit Address';
    DataCaptionExpression = Rec.Caption();
    DataCaptionFields = "Code";
    PageType = Card;
    SourceTable = "Remit Address";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an remit-to address code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company located at the address.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the street address.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                }
                group(CountyGroup)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field(County; Rec.County)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the county of the address.';
                    }
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                    end;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you do business with this vendor at this address.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use as default';
                    ToolTip = 'Specifies if this address is used by default for this vendor. Only one address can be set as the default.';

                    trigger OnValidate()
                    begin
                        if Rec.Default then
                            if Confirm(SelectCurrentRemitAddressAsDefaultQst, false) then
                                SetOtherAddressesAsNonDefault(Rec.Code)
                            else
                                Rec.Default := false;
                    end;
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number that is associated with the remit address.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number associated with the remit address.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address associated with the remit address.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the recipient''s web site.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Location")
            {
                Caption = 'Location';
                Image = Addresses;
                separator(Action001)
                {
                }
                action("Online Map")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the location on an online map.';

                    trigger OnAction()
                    begin
                        Rec.DisplayMap();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
        SelectCurrentRemitAddressAsDefaultQst: Label 'As a default address, this address will be autocompleted on new purchase orders and purchase invoices created for this vendor. This address will take the place of any other default address you have chosen.\\Do you want to continue?';

    local procedure SetOtherAddressesAsNonDefault(CodeToIgnore: Code[10])
    var
        OtherAllRemitAddresses: Record "Remit Address";
    begin
        OtherAllRemitAddresses.SetRange("Vendor No.", Rec."Vendor No.");
        OtherAllRemitAddresses.SetFilter("Code", '<>%1', CodeToIgnore);

        if not OtherAllRemitAddresses.IsEmpty() then
            OtherAllRemitAddresses.ModifyAll(Default, false);
    end;
}

