// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

table 12169 "Company Types"
{
    Caption = 'FatturaPA Fiscal Regimes';
    DrillDownPageID = "Company Types";
    LookupPageID = "Company Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[2])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            begin
                if not IsValidFatturaPAFiscalRegimeCode(Code) then
                    Error(InvalidFiscalRegimeCodeErr, Code);
            end;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Error(ReadOnlyFiscalRegimesErr);
    end;

    trigger OnModify()
    begin
        Error(ReadOnlyFiscalRegimesErr);
    end;

    trigger OnDelete()
    begin
        Error(ReadOnlyFiscalRegimesErr);
    end;

    procedure EnsureStandardFatturaPAFiscalRegimes()
    begin
        InsertOrUpdateFiscalRegime('01', OrdinaryLbl);
        InsertOrUpdateFiscalRegime('02', MinimumTaxpayersLbl);
        InsertOrUpdateFiscalRegime('03', NewProductionInitiativesLbl);
        InsertOrUpdateFiscalRegime('04', AgricultureFishingLbl);
        InsertOrUpdateFiscalRegime('05', SaltTobaccoSalesLbl);
        InsertOrUpdateFiscalRegime('06', MatchSalesLbl);
        InsertOrUpdateFiscalRegime('07', PublishingLbl);
        InsertOrUpdateFiscalRegime('08', PhoneServicesLbl);
        InsertOrUpdateFiscalRegime('09', PublicTransportResaleLbl);
        InsertOrUpdateFiscalRegime('10', EntertainmentGamingLbl);
        InsertOrUpdateFiscalRegime('11', TravelTourismLbl);
        InsertOrUpdateFiscalRegime('12', FarmhouseAccommodationLbl);
        InsertOrUpdateFiscalRegime('13', DoorToDoorSalesLbl);
        InsertOrUpdateFiscalRegime('14', UsedGoodsArtworksLbl);
        InsertOrUpdateFiscalRegime('15', ArtworkAntiquesLbl);
        InsertOrUpdateFiscalRegime('16', VATPaidCashPALbl);
        InsertOrUpdateFiscalRegime('17', VATPaidBelowThresholdLbl);
        InsertOrUpdateFiscalRegime('18', OtherLbl);
        InsertOrUpdateFiscalRegime('19', FlatRateLbl);
    end;

    procedure IsValidFatturaPAFiscalRegimeCode(FiscalRegimeCode: Code[2]): Boolean
    begin
        case FiscalRegimeCode of
            '01', '02', '03', '04', '05', '06', '07', '08', '09',
            '10', '11', '12', '13', '14', '15', '16', '17', '18', '19':
                exit(true);
        end;

        exit(false);
    end;

    local procedure InsertOrUpdateFiscalRegime(FiscalRegimeCode: Code[2]; FiscalRegimeDescription: Text[30])
    begin
        if not Get(FiscalRegimeCode) then begin
            Init();
            Code := FiscalRegimeCode;
            Description := FiscalRegimeDescription;
            Insert(false);
            exit;
        end;

        if Description <> FiscalRegimeDescription then begin
            Description := FiscalRegimeDescription;
            Modify(false);
        end;
    end;

    var
        InvalidFiscalRegimeCodeErr: Label '%1 is not a valid FatturaPA fiscal regime code. Select a code from 01 through 19.', Comment = '%1 = invalid fiscal regime code';
        ReadOnlyFiscalRegimesErr: Label 'FatturaPA fiscal regimes are defined by the FatturaPA specification and cannot be changed.';
        OrdinaryLbl: Label 'Ordinary';
        MinimumTaxpayersLbl: Label 'Minimum taxpayers';
        NewProductionInitiativesLbl: Label 'New production initiatives';
        AgricultureFishingLbl: Label 'Agriculture and fishing';
        SaltTobaccoSalesLbl: Label 'Sale of salts and tobaccos';
        MatchSalesLbl: Label 'Match sales';
        PublishingLbl: Label 'Publishing';
        PhoneServicesLbl: Label 'Management of phone services';
        PublicTransportResaleLbl: Label 'Resale of public transport';
        EntertainmentGamingLbl: Label 'Entertainment and gaming';
        TravelTourismLbl: Label 'Travel and tourism agencies';
        FarmhouseAccommodationLbl: Label 'Farmhouse accommodation';
        DoorToDoorSalesLbl: Label 'Door to door sales';
        UsedGoodsArtworksLbl: Label 'Resale of used goods,artworks';
        ArtworkAntiquesLbl: Label 'Artwork and antiques';
        VATPaidCashPALbl: Label 'VAT paid in cash by P.A.';
        VATPaidBelowThresholdLbl: Label 'VAT paid below Euro 200,000';
        OtherLbl: Label 'Other';
        FlatRateLbl: Label 'Flat rate';
}

