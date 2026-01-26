// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.EServices.EDocument;

tableextension 10010 "Service Header Archive NA" extends "Service Header Archive"
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
        }
        field(27012; "CFDI Certificate of Origin No."; Text[50])
        {
            Caption = 'CFDI Certificate of Origin No.';
            DataClassification = CustomerContent;
            Description = 'NumCertificadoOrigen';
        }
    }
}