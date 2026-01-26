// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.EServices.EDocument;
using Microsoft.Sales.Customer;

tableextension 10710 "Service Header Archive ES" extends "Service Header Archive"
{
    fields
    {
        field(10705; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;
        }
        field(10707; "Invoice Type"; Enum "SII Sales Invoice Type")
        {
            Caption = 'Invoice Type';
            DataClassification = CustomerContent;
        }
        field(10708; "Cr. Memo Type"; Enum "SII Sales Credit Memo Type")
        {
            Caption = 'Cr. Memo Type';
            DataClassification = CustomerContent;
        }
        field(10709; "Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
        }
        field(10710; "Operation Description"; Text[250])
        {
            Caption = 'Operation Description';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10711; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;
        }
        field(10712; "Operation Description 2"; Text[250])
        {
            Caption = 'Operation Description 2';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10720; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10721; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10722; "ID Type"; Option)
        {
            Caption = 'ID Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,02-VAT Registration No.,03-Passport,04-ID Document,05-Certificate Of Residence,06-Other Probative Document,07-Not On The Census';
            OptionMembers = " ","02-VAT Registration No.","03-Passport","04-ID Document","05-Certificate Of Residence","06-Other Probative Document","07-Not On The Census";
        }
        field(10724; "Do Not Send To SII"; Boolean)
        {
            Caption = 'Do Not Send To SII';
            DataClassification = CustomerContent;
        }
        field(10725; "Issued By Third Party"; Boolean)
        {
            Caption = 'Issued By Third Party';
            DataClassification = CustomerContent;
        }
        field(10726; "SII First Summary Doc. No."; Blob)
        {
            Caption = 'First Summary Doc. No.';
            DataClassification = CustomerContent;
        }
        field(10727; "SII Last Summary Doc. No."; Blob)
        {
            Caption = 'Last Summary Doc. No.';
            DataClassification = CustomerContent;
        }
        field(7000000; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000001; "Cust. Bank Acc. Code"; Code[20])
        {
            Caption = 'Cust. Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
    }
}