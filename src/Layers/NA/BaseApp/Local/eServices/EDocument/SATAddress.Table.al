// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Foundation.Address;

table 27009 "SAT Address"
{
    Caption = 'SAT Address';
    DrillDownPageID = "SAT Addresses";
    LookupPageID = "SAT Addresses";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Country/Region Code"; Code[10])
        {
            TableRelation = "Country/Region";
            NotBlank = true;
        }
        field(3; "SAT State Code"; Code[10])
        {
            TableRelation = "SAT State";
            NotBlank = true;
        }
        field(4; "SAT Municipality Code"; Code[10])
        {
            TableRelation = "SAT Municipality" where(State = field("SAT State Code"));
        }
        field(5; "SAT Locality Code"; Code[10])
        {
            TableRelation = "SAT Locality" where(State = field("SAT State Code"));
        }
        field(6; "SAT Suburb ID"; Integer)
        {
            TableRelation = "SAT Suburb";
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetSATAddress() LocationAddress: Text
    var
        SATState: Record "SAT State";
        SATMunicipality: Record "SAT Municipality";
        SATLocality: Record "SAT Locality";
        SATSuburb: Record "SAT Suburb";
    begin
        if SATState.Get("SAT State Code") then
            LocationAddress := SATState.Description;
        if SATMunicipality.Get("SAT Municipality Code") then
            LocationAddress += ' ' + SATMunicipality.Description;
        if SATLocality.Get("SAT Locality Code") then
            LocationAddress += ' ' + SATLocality.Description;
        if SATSuburb.Get("SAT Suburb ID") then
            LocationAddress += ' ' + SATSuburb.Description;
    end;

    procedure GetSATPostalCode(): Code[20]
    var
        SATSuburb: Record "SAT Suburb";
    begin
        SATSuburb.Get("SAT Suburb ID");
        exit(SATSuburb."Postal Code");
    end;

    procedure LookupSATAddress(var SATAddress: Record "SAT Address"; ShipToCountryCode: Code[10]; BillToCountryCode: Code[10]): Boolean
    var
        SATAddresses: Page "SAT Addresses";
        CountryCode: Code[10];
    begin
        CountryCode := ShipToCountryCode;
        if CountryCode = '' then
            CountryCode := BillToCountryCode;
        if CountryCode <> '' then
            SATAddress.SetRange("Country/Region Code", CountryCode);
        SATAddresses.SetRecord(SATAddress);
        SATAddresses.LookupMode(true);
        if SATAddresses.RunModal() = Action::LookupOK then begin
            SATAddresses.GetRecord(SATAddress);
            exit(true);
        end;
        exit(false);
    end;
}

