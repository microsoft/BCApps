// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;

tableextension 10011 "Service Header NA" extends "Service Header"
{
    fields
    {
        field(10015; "Tax Exemption No."; Text[30])
        {
            Caption = 'Tax Exemption No.';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10018; "STE Transaction ID"; Text[20])
        {
            Caption = 'STE Transaction ID';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
            Editable = false;
        }
        field(10050; "Foreign Trade"; Boolean)
        {
            Caption = 'Foreign Trade';
            DataClassification = CustomerContent;
        }
        field(10059; "SAT International Trade Term"; Code[10])
        {
            Caption = 'SAT International Trade Term';
            DataClassification = CustomerContent;
            TableRelation = "SAT International Trade Term";
        }
        field(10060; "Exchange Rate USD"; Decimal)
        {
            Caption = 'Exchange Rate USD';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 6;
        }
        field(27000; "CFDI Purpose"; Code[10])
        {
            Caption = 'CFDI Purpose';
            DataClassification = CustomerContent;
            TableRelation = "SAT Use Code";
        }
        field(27001; "CFDI Relation"; Code[10])
        {
            Caption = 'CFDI Relation';
            DataClassification = CustomerContent;
            TableRelation = "SAT Relationship Type";
        }
        field(27004; "CFDI Export Code"; Code[10])
        {
            Caption = 'CFDI Export Code';
            DataClassification = CustomerContent;
            TableRelation = "CFDI Export Code";

            trigger OnValidate()
            var
                CurrencyExchangeRate: Record "Currency Exchange Rate";
                GeneralLedgerSetup: Record "General Ledger Setup";
                CFDIExportCode: Record "CFDI Export Code";
            begin
                "Foreign Trade" := false;
                if CFDIExportCode.Get("CFDI Export Code") then
                    "Foreign Trade" := CFDIExportCode."Foreign Trade";
                GeneralLedgerSetup.Get();
                "Exchange Rate USD" := 1 / CurrencyExchangeRate.ExchangeRate("Posting Date", GeneralLedgerSetup."USD Currency Code");
            end;
        }
        field(27005; "CFDI Period"; Option)
        {
            Caption = 'CFDI Period';
            DataClassification = CustomerContent;
            OptionCaption = 'Diario,Semanal,Quincenal,Mensual';
            OptionMembers = "Diario","Semanal","Quincenal","Mensual";
        }
        field(27009; "SAT Address ID"; Integer)
        {
            Caption = 'SAT Address ID';
            DataClassification = CustomerContent;
            TableRelation = "SAT Address";

            trigger OnLookup()
            var
                SATAddress: Record "SAT Address";
            begin
                if SATAddress.LookupSATAddress(SATAddress, Rec."Ship-to Country/Region Code", Rec."Bill-to Country/Region Code") then
                    Rec."SAT Address ID" := SATAddress.Id;
            end;
        }
        field(27012; "CFDI Certificate of Origin No."; Text[50])
        {
            Caption = 'CFDI Certificate of Origin No.';
            DataClassification = CustomerContent;
            Description = 'NumCertificadoOrigen';
        }
    }
}
