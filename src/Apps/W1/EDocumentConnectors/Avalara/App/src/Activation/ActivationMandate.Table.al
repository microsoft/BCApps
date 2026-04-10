// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Stores mandate records linked to an Avalara activation, including country mandate, mandate type, and activation status.
/// </summary>
table 6377 "Activation Mandate"
{
    Caption = 'Activation Mandate';
    DataClassification = CustomerContent;
    DataPerCompany = true;

    fields
    {
        field(1; "Activation ID"; Guid)
        {
            Caption = 'Activation ID';
        }
        field(2; "Country Mandate"; Code[40])
        {
            Caption = 'Country Mandate';
        }
        field(3; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
        }
        field(4; "Mandate Type"; Code[10])
        {
            Caption = 'Mandate Type';
        }
        field(5; Activated; Boolean)
        {
            Caption = 'Activated';
        }
        field(6; "Company Id"; Text[100])
        {
            Caption = 'Company Id';
        }
        field(7; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(8; "Invoice Available Media Type"; Text[256])
        {
            Caption = 'Invoice Available Media Type';
        }
        field(9; "Input Data Formats"; Text[512])
        {
            Caption = 'Input Data Formats';
        }
    }

    keys
    {
        key(PK; "Activation ID", "Country Mandate", "Mandate Type") { Clustered = true; }
        key(CompanyMandate; "Company Id", "Country Mandate", "Mandate Type") { }
    }

    procedure SetBlocked(ConnectionSetup: Record "Connection Setup"; CountryMandate: Text; Block: Boolean)
    begin
        Rec.SetRange("Country Mandate", CountryMandate);
        Rec.SetRange("Mandate Type", GetMandateTypeFromName(CountryMandate));
        Rec.SetRange("Company Id", ConnectionSetup."Company Id");
        if Rec.FindSet(true) then
            Rec.ModifyAll(Blocked, Block, true);
    end;

    procedure GetBlocked(ConnectionSetup: Record "Connection Setup"; CountryMandate: Text): Boolean
    begin
        Rec.SetRange("Country Mandate", CountryMandate);
        Rec.SetRange("Mandate Type", GetMandateTypeFromName(CountryMandate));
        Rec.SetRange("Company Id", ConnectionSetup."Company Id");
        if not Rec.IsEmpty then
            exit(Rec.Blocked);
    end;

    procedure GetMandateTypeFromName(MandateText: Text): Code[10]
    begin
        if MandateText.Contains('B2B') then
            exit('B2B');

        if MandateText.Contains('B2G') then
            exit('B2G');
    end;
}