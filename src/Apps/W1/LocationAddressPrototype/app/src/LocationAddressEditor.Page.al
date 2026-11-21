// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location.AddressPrototype;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Location;

page 17700 "Location Address Editor"
{
    Caption = 'Edit Address';
    PageType = StandardDialog;
    SourceTable = Location;
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Address)
            {
                Caption = 'Address';
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite, Location;

                    trigger OnValidate()
                    begin
                        RefreshLayout();
                    end;
                }
                field(StreetAddress; Rec.Address)
                {
                    ApplicationArea = Basic, Suite, Location;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite, Location;
                }
            }
            group(PostCodeFirst)
            {
                ShowCaption = false;
                Visible = ShowPostCodeFirst;
                field(PostCodeFirstPostCode; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite, Location;

                    trigger OnValidate()
                    begin
                        RefreshLayout();
                    end;
                }
                field(PostCodeFirstCity; Rec.City)
                {
                    ApplicationArea = Basic, Suite, Location;

                    trigger OnValidate()
                    begin
                        RefreshLayout();
                    end;
                }
                group(PostCodeFirstCountyGroup)
                {
                    ShowCaption = false;
                    Visible = ShowCounty;
                    field(PostCodeFirstCounty; Rec.County)
                    {
                        ApplicationArea = Basic, Suite, Location;
                    }
                }
            }
            group(CityFirst)
            {
                ShowCaption = false;
                Visible = ShowCityFirst;
                field(CityFirstCity; Rec.City)
                {
                    ApplicationArea = Basic, Suite, Location;

                    trigger OnValidate()
                    begin
                        RefreshLayout();
                    end;
                }
                field(CityFirstPostCode; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite, Location;

                    trigger OnValidate()
                    begin
                        RefreshLayout();
                    end;
                }
                group(CityFirstCountyGroup)
                {
                    ShowCaption = false;
                    Visible = ShowCounty;
                    field(CityFirstCounty; Rec.County)
                    {
                        ApplicationArea = Basic, Suite, Location;
                    }
                }
            }
            group(CountyBeforePostCode)
            {
                ShowCaption = false;
                Visible = ShowCountyBeforePostCode;
                field(CountyFirstCity; Rec.City)
                {
                    ApplicationArea = Basic, Suite, Location;

                    trigger OnValidate()
                    begin
                        RefreshLayout();
                    end;
                }
                field(CountyFirstCounty; Rec.County)
                {
                    ApplicationArea = Basic, Suite, Location;
                }
                field(CountyFirstPostCode; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite, Location;

                    trigger OnValidate()
                    begin
                        RefreshLayout();
                    end;
                }
            }
            group(CustomFormatNotice)
            {
                ShowCaption = false;
                Visible = ShowCustomFormatNotice;
                field(CustomFormatInformation; CustomFormatInformationLbl)
                {
                    ApplicationArea = Basic, Suite, Location;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Explains how custom address formats are edited in this prototype.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateLayout();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateLayout();
    end;

    var
        ShowPostCodeFirst: Boolean;
        ShowCityFirst: Boolean;
        ShowCountyBeforePostCode: Boolean;
        ShowCounty: Boolean;
        ShowCustomFormatNotice: Boolean;
        CustomFormatInformationLbl: Label 'The preview uses the custom address format. This prototype edits custom formats using postcode-first field order.';

    procedure SetLocation(Location: Record Location)
    begin
        Rec.DeleteAll(false);
        Rec := Location;
        Rec.Insert(false);
    end;

    procedure GetLocation(var Location: Record Location temporary)
    begin
        Location := Rec;
    end;

    local procedure RefreshLayout()
    begin
        UpdateLayout();
        CurrPage.Update(false);
    end;

    local procedure UpdateLayout()
    var
        CountryRegion: Record "Country/Region";
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        AddressFormat: Enum "Country/Region Address Format";
    begin
        if Rec."Country/Region Code" = '' then begin
            GeneralLedgerSetup.Get();
            AddressFormat := "Country/Region Address Format".FromInteger(GeneralLedgerSetup."Local Address Format");
        end else begin
            CountryRegion.Get(Rec."Country/Region Code");
            AddressFormat := CountryRegion."Address Format";
        end;

        ShowCityFirst := AddressFormat = AddressFormat::"City+Post Code";
        ShowCountyBeforePostCode := AddressFormat = AddressFormat::"City+County+Post Code";
        ShowPostCodeFirst := not (ShowCityFirst or ShowCountyBeforePostCode);
        ShowCounty := FormatAddress.UseCounty(Rec."Country/Region Code");
        ShowCustomFormatNotice := AddressFormat = AddressFormat::Custom;
    end;
}
