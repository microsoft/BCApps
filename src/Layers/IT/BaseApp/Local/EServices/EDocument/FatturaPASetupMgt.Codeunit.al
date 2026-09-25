// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;

codeunit 12255 "FatturaPA Setup Mgt."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    begin
        EnsureStandardFiscalRegimes();
    end;

    procedure EnsureStandardFiscalRegimes()
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

    local procedure InsertOrUpdateFiscalRegime(FiscalRegimeCode: Code[2]; FiscalRegimeDescription: Text[30])
    var
        CompanyTypes: Record "Company Types";
    begin
        if not CompanyTypes.Get(FiscalRegimeCode) then begin
            CompanyTypes.Init();
            CompanyTypes.Code := FiscalRegimeCode;
            CompanyTypes.Description := FiscalRegimeDescription;
            CompanyTypes.Insert(false);
            exit;
        end;

        if CompanyTypes.Description <> FiscalRegimeDescription then begin
            CompanyTypes.Description := FiscalRegimeDescription;
            CompanyTypes.Modify(false);
        end;
    end;

    var
        OrdinaryLbl: Label 'Ordinary', Comment = 'Description of FatturaPA fiscal regime RF01.';
        MinimumTaxpayersLbl: Label 'Minimum taxpayers', Comment = 'Description of FatturaPA fiscal regime RF02.';
        NewProductionInitiativesLbl: Label 'New production initiatives', Comment = 'Description of FatturaPA fiscal regime RF03.';
        AgricultureFishingLbl: Label 'Agriculture and fishing', Comment = 'Description of FatturaPA fiscal regime RF04.';
        SaltTobaccoSalesLbl: Label 'Sale of salts and tobaccos', Comment = 'Description of FatturaPA fiscal regime RF05.';
        MatchSalesLbl: Label 'Match sales', Comment = 'Description of FatturaPA fiscal regime RF06.';
        PublishingLbl: Label 'Publishing', Comment = 'Description of FatturaPA fiscal regime RF07.';
        PhoneServicesLbl: Label 'Management of phone services', Comment = 'Description of FatturaPA fiscal regime RF08.';
        PublicTransportResaleLbl: Label 'Resale of public transport', Comment = 'Description of FatturaPA fiscal regime RF09.';
        EntertainmentGamingLbl: Label 'Entertainment and gaming', Comment = 'Description of FatturaPA fiscal regime RF10.';
        TravelTourismLbl: Label 'Travel and tourism agencies', Comment = 'Description of FatturaPA fiscal regime RF11.';
        FarmhouseAccommodationLbl: Label 'Farmhouse accommodation', Comment = 'Description of FatturaPA fiscal regime RF12.';
        DoorToDoorSalesLbl: Label 'Door to door sales', Comment = 'Description of FatturaPA fiscal regime RF13.';
        UsedGoodsArtworksLbl: Label 'Resale of used goods,artworks', Comment = 'Description of FatturaPA fiscal regime RF14.';
        ArtworkAntiquesLbl: Label 'Artwork and antiques', Comment = 'Description of FatturaPA fiscal regime RF15.';
        VATPaidCashPALbl: Label 'VAT paid in cash by P.A.', Comment = 'Description of FatturaPA fiscal regime RF16.';
        VATPaidBelowThresholdLbl: Label 'VAT paid below Euro 200,000', Comment = 'Description of FatturaPA fiscal regime RF17.';
        OtherLbl: Label 'Other', Comment = 'Description of FatturaPA fiscal regime RF18.';
        FlatRateLbl: Label 'Flat rate', Comment = 'Description of FatturaPA fiscal regime RF19.';
}
