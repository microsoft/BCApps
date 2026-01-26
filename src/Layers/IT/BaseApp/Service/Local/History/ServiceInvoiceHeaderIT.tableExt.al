// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Intrastat;
using Microsoft.Utilities;

tableextension 12456 "Service Invoice Header IT" extends "Service Invoice Header"
{
    fields
    {
        field(12100; "Operation Type"; Code[20])
        {
            Caption = 'Operation Type';
            DataClassification = CustomerContent;
            TableRelation = "No. Series" where("No. Series Type" = filter(Sales));
        }
        field(12101; "Operation Occurred Date"; Date)
        {
            Caption = 'Operation Occurred Date';
            DataClassification = CustomerContent;
        }
        field(12123; "Activity Code"; Code[6])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
            TableRelation = "Activity Code".Code;
        }
        field(12125; "Service Tariff No."; Code[10])
        {
            Caption = 'Service Tariff No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Service Tariff Number";
        }
        field(12130; "Fiscal Code"; Code[20])
        {
            Caption = 'Fiscal Code';
            DataClassification = CustomerContent;
        }
        field(12132; Resident; Option)
        {
            Caption = 'Resident';
            DataClassification = CustomerContent;
            OptionCaption = 'Resident,Non-Resident';
            OptionMembers = Resident,"Non-Resident";
        }
        field(12133; "First Name"; Text[30])
        {
            Caption = 'First Name';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12134; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12135; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
            DataClassification = CustomerContent;
        }
        field(12136; "Individual Person"; Boolean)
        {
            Caption = 'Individual Person';
            DataClassification = CustomerContent;
        }
        field(12138; "Place of Birth"; Text[30])
        {
            Caption = 'Place of Birth';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12172; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            DataClassification = CustomerContent;
        }
        field(12173; "Cumulative Bank Receipts"; Boolean)
        {
            Caption = 'Cumulative Bank Receipts';
            DataClassification = CustomerContent;
        }
        field(12182; "Fattura Project Code"; Code[15])
        {
            Caption = 'Fattura Project Code';
            DataClassification = CustomerContent;
            TableRelation = "Fattura Project Info".Code where(Type = filter(Project));
        }
        field(12183; "Fattura Tender Code"; Code[15])
        {
            Caption = 'Fattura Tender Code';
            DataClassification = CustomerContent;
            TableRelation = "Fattura Project Info".Code where(Type = filter(Tender));
        }
        field(12184; "Customer Purchase Order No."; Text[35])
        {
            Caption = 'Customer Purchase Order No.';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12185; "Fattura Stamp"; Boolean)
        {
            Caption = 'Fattura Stamp';
            DataClassification = CustomerContent;
        }
        field(12186; "Fattura Stamp Amount"; Decimal)
        {
            Caption = 'Fattura Stamp Amount';
            DataClassification = CustomerContent;
        }
        field(12187; "Fattura Document Type"; Code[20])
        {
            Caption = 'Fattura Document Type';
            DataClassification = CustomerContent;
            TableRelation = "Fattura Document Type";
        }
    }
}