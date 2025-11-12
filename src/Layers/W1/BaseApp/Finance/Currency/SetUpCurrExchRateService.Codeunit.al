// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

codeunit 1242 "Set Up Curr Exch Rate Service"
{

    trigger OnRun()
    var
        Currency: Record Currency;
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        CurrExchRateUpdateSetup2: Record "Curr. Exch. Rate Update Setup";
        GLSetup: Record "General Ledger Setup";
    begin
        if Currency.IsEmpty() then
            exit;
        if not CurrExchRateUpdateSetup2.IsEmpty() then
            exit;
        if not CurrExchRateUpdateSetup2.WritePermission then
            exit;
        GLSetup.Get();
        if GLSetup."LCY Code" = 'EUR' then
            SetupECBDataExchange(CurrExchRateUpdateSetup, GetECB_URI());
        Commit();
    end;

    var
        DummyDataExchColumnDef: Record "Data Exch. Column Def";
        DummyCurrExchRate: Record "Currency Exchange Rate";
        ECB_EXCH_RATESTxt: Label 'ECB-EXCHANGE-RATES', Locked = true;
        ECB_EXCH_RATESDescTxt: Label 'European Central Bank Currency Exchange Rates Setup';
        ECB_URLTxt: Label 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml', Locked = true;
        ECBServiceProviderTxt: Label 'European Central Bank';

    [Scope('OnPrem')]
    procedure SetupECBDataExchange(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; PathToECBService: Text)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        SuggestColDefinitionXML: Codeunit "Suggest Col. Definition - XML";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", ECB_EXCH_RATESTxt);
        if DataExchLineDef.FindFirst() then;

        CreateCurrencyExchangeSetup(
          CurrExchRateUpdateSetup, ECB_EXCH_RATESTxt, ECB_EXCH_RATESDescTxt,
          DataExchLineDef."Data Exch. Def Code", ECBServiceProviderTxt, '');

        if StrPos(PathToECBService, 'http') = 1 then
            CurrExchRateUpdateSetup.SetWebServiceURL(PathToECBService);

        if DataExchLineDef."Data Exch. Def Code" = '' then begin
            CreateExchLineDef(DataExchLineDef, CurrExchRateUpdateSetup."Data Exch. Def Code", GetECBRepeaterPath());
            SuggestColDefinitionXML.GenerateDataExchColDef(PathToECBService, DataExchLineDef);

            MapECBDataExch(DataExchLineDef);
        end;
        Commit();
    end;

    local procedure CreateCurrencyExchangeSetup(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; NewCode: Code[20]; NewDesc: Text[250]; NewDataExchCode: Code[20]; NewServiceProvider: Text[30]; NewTermOfUse: Text[250])
    begin
        CurrExchRateUpdateSetup.Init();
        CurrExchRateUpdateSetup.Validate("Data Exch. Def Code", NewDataExchCode);
        CurrExchRateUpdateSetup.Validate(Code, NewCode);
        CurrExchRateUpdateSetup.Validate(Description, NewDesc);
        CurrExchRateUpdateSetup.Validate("Service Provider", NewServiceProvider);
        CurrExchRateUpdateSetup.Validate("Terms of Service", NewTermOfUse);
        CurrExchRateUpdateSetup.Insert(true);
    end;

    procedure GetECB_URI(): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code", 'EUR');
        exit(ECB_URLTxt);
    end;

    local procedure CreateExchLineDef(var DataExchLineDef: Record "Data Exch. Line Def"; DataExchDefCode: Code[20]; RepeaterPath: Text[250])
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.FindFirst();
        DataExchLineDef.Validate("Data Line Tag", RepeaterPath);
        DataExchLineDef.Modify(true);
    end;

    local procedure CreateExchMappingLine(DataExchMapping: Record "Data Exch. Mapping"; FromColumnName: Text[250]; ToFieldNo: Integer; DataType: Option; NewMultiplier: Decimal; NewDataFormat: Text[10]; NewTransformationRule: Code[20]; NewDefaultValue: Text[250])
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        if NewDefaultValue <> '' then begin
            if DataExchColumnDef.FindLast() then begin
                DataExchColumnDef.Init();
                DataExchColumnDef."Column No." += 10000;
                DataExchColumnDef.Insert();
            end
        end else begin
            DataExchColumnDef.SetRange(Name, FromColumnName);
            DataExchColumnDef.FindFirst();
        end;
        DataExchColumnDef.Validate("Data Type", DataType);
        DataExchColumnDef.Validate("Data Format", NewDataFormat);
        DataExchColumnDef.Modify(true);

        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchFieldMapping.Validate("Table ID", DataExchMapping."Table ID");
        DataExchFieldMapping.Validate("Column No.", DataExchColumnDef."Column No.");
        DataExchFieldMapping.Validate("Field ID", ToFieldNo);
        DataExchFieldMapping.Validate(Multiplier, NewMultiplier);
        DataExchFieldMapping.Validate("Transformation Rule", NewTransformationRule);
        DataExchFieldMapping.Validate("Default Value", NewDefaultValue);
        DataExchFieldMapping.Insert(true);
    end;

    local procedure MapECBDataExch(var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Get(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, GetMappingTable());

        CreateExchMappingLine(
          DataExchMapping, GetECBCurrencyCodeXMLElement(), GetCurrencyCodeFieldNo(),
          DummyDataExchColumnDef."Data Type"::Text, 1, '', '', '');
        CreateExchMappingLine(
          DataExchMapping, GetECBStartingDateXMLElement(), GetStartingDateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Date, 1, '', '', '');

        CreateExchMappingLine(
          DataExchMapping, GetECBExchRateXMLElement(), GetExchRateAmtFieldNo(),
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '', '');
        CreateExchMappingLine(
          DataExchMapping, '', GetRelationalExchRateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '', '1');
    end;

    local procedure GetECBRepeaterPath(): Text[250]
    begin
        exit('/gesmes:Envelope/Cube/Cube/Cube');
    end;

    local procedure GetMappingTable(): Integer
    begin
        exit(DATABASE::"Currency Exchange Rate")
    end;

    local procedure GetECBCurrencyCodeXMLElement(): Text[250]
    begin
        exit('currency');
    end;

    local procedure GetECBExchRateXMLElement(): Text[250]
    begin
        exit('rate');
    end;

    local procedure GetECBStartingDateXMLElement(): Text[250]
    begin
        exit('time');
    end;

    local procedure GetCurrencyCodeFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Currency Code"));
    end;

    local procedure GetRelationalExchRateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Relational Exch. Rate Amount"));
    end;

    local procedure GetExchRateAmtFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Exchange Rate Amount"));
    end;

    local procedure GetStartingDateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Starting Date"));
    end;
}

