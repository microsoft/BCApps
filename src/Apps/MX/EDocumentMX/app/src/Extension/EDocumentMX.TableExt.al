// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.FixedAssets.FixedAsset;

tableextension 3376 "E-Document MX" extends "E-Document"
{
    fields
    {
        field(3353; "CFDI Export Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'CFDI Export Code';
            TableRelation = "CFDI Export Code";
        }
        field(3354; "CFDI Exchange Rate USD"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Exchange Rate USD';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 6;
        }
        field(3355; "CFDI Foreign Trade"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Foreign Trade';
        }
        field(3356; "CFDI SAT Address ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'SAT Address ID';
            TableRelation = "SAT Address";
            BlankZero = true;

            trigger OnLookup()
            var
                SATAddress: Record "SAT Address";
                EDocCFDIDataMX: Codeunit "EDoc CFDI Data MX";
                ShipToCountryCode: Code[10];
                BillToCountryCode: Code[10];
            begin
                EDocCFDIDataMX.GetSourceCountryCodes(Rec, ShipToCountryCode, BillToCountryCode);
                if SATAddress.Get(Rec."CFDI SAT Address ID") then;
                if SATAddress.LookupSATAddress(SATAddress, ShipToCountryCode, BillToCountryCode) then
                    Rec.Validate("CFDI SAT Address ID", SATAddress.Id);
            end;
        }
        field(3357; "CFDI Intl. Trade Term"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'SAT International Trade Term';
            TableRelation = "SAT International Trade Term";
        }
        field(3358; "CFDI Cert. of Origin No."; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'CFDI Certificate of Origin No.';
        }
        field(3359; "CFDI Transport Type"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'SAT Transport Type';
            TableRelation = "SAT Transport Type MX";
            ValidateTableRelation = false;
        }
        field(3360; "CFDI Transit-from Date/Time"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Transit-from Date/Time';
        }
        field(3361; "CFDI Transit Hours"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Transit Hours';
        }
        field(3362; "CFDI Transit Distance"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Transit Distance';
            AutoFormatType = 0;
        }
        field(3363; "CFDI Vehicle Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Vehicle Code';
            TableRelation = "Fixed Asset";
        }
        field(3364; "CFDI Trailer 1"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Trailer 1';
            TableRelation = "Fixed Asset" where("SAT Trailer Type" = filter(<> ''));
        }
        field(3365; "CFDI Trailer 2"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Trailer 2';
            TableRelation = "Fixed Asset" where("SAT Trailer Type" = filter(<> ''));
        }
        field(3366; "CFDI Customs Regime"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'SAT Customs Regime';
            TableRelation = "SAT Customs Regime";
        }
        field(3367; "CFDI Transfer Reason"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'SAT Transfer Reason';
            TableRelation = "SAT Transfer Reason";
        }
        field(3368; "CFDI SAT ISTMO"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'SAT ISTMO';
        }
        field(3369; "CFDI ISTMO Polo Origen"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'SAT ISTMO Polo Origen';
            TableRelation = "SAT ISTMO Region MX";
            ValidateTableRelation = false;
        }
        field(3370; "CFDI ISTMO Polo Destino"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'SAT ISTMO Polo Destino';
            TableRelation = "SAT ISTMO Region MX";
            ValidateTableRelation = false;
        }
        field(3371; "CFDI Insurer Name"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Insurer Name';
        }
        field(3372; "CFDI Insurer Policy Number"; Text[30])
        {
            DataClassification = CustomerContent;
            Caption = 'Insurer Policy Number';
        }
        field(3373; "CFDI Medical Insurer Name"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Medical Insurer Name';
        }
        field(3374; "CFDI Medical Ins. Policy No."; Text[30])
        {
            DataClassification = CustomerContent;
            Caption = 'Medical Ins. Policy Number';
        }
        field(3375; "CFDI Weight Unit Of Measure"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'SAT Weight Unit Of Measure';
            TableRelation = "SAT Weight Unit of Measure";
        }
        field(3390; "CFDI Cancellation ID"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'CFDI Cancellation ID';
        }
    }
}
