// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Location;

table 10002 "Document Header"
{
    Caption = 'Document Header';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Sell-to/Buy-from No."; Code[20])
        {
            Caption = 'Sell-to/Buy-from No.';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Bill-to/Pay-To No."; Code[20])
        {
            Caption = 'Bill-to/Pay-To No.';
        }
        field(5; "Bill-to/Pay-To Name"; Text[100])
        {
            Caption = 'Bill-to/Pay-To Name';
        }
        field(6; "Bill-to/Pay-To Name 2"; Text[50])
        {
            Caption = 'Bill-to/Pay-To Name 2';
        }
        field(7; "Bill-to/Pay-To Address"; Text[100])
        {
            Caption = 'Bill-to/Pay-To Address';
        }
        field(8; "Bill-to/Pay-To Address 2"; Text[50])
        {
            Caption = 'Bill-to/Pay-To Address 2';
        }
        field(9; "Bill-to/Pay-To City"; Text[30])
        {
            Caption = 'Bill-to/Pay-To City';
        }
        field(10; "Bill-to/Pay-To Contact"; Text[100])
        {
            Caption = 'Bill-to/Pay-To Contact';
        }
        field(17; "Ship-to/Buy-from City"; Text[30])
        {
        }
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(60; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
        }
        field(79; "Sell-to/Buy-From Name"; Text[100])
        {
            Caption = 'Sell-to/Buy-From Name';
        }
        field(80; "Sell-to/Buy-From Name 2"; Text[50])
        {
            Caption = 'Sell-to/Buy-From Name 2';
        }
        field(81; "Sell-to/Buy-From Address"; Text[100])
        {
            Caption = 'Sell-to/Buy-From Address';
        }
        field(82; "Sell-to/Buy-From Address 2"; Text[50])
        {
            Caption = 'Sell-to/Buy-From Address 2';
        }
        field(83; "Sell-to/Buy-From City"; Text[30])
        {
            Caption = 'Sell-to/Buy-From City';
        }
        field(84; "Sell-to/Buy-From Contct"; Text[100])
        {
            Caption = 'Sell-to/Buy-From Contct';
        }
        field(85; "Bill-to/Pay-To Post Code"; Code[20])
        {
            Caption = 'Bill-to/Pay-To Post Code';
        }
        field(86; "Bill-to/Pay-To County"; Text[30])
        {
            Caption = 'Bill-to/Pay-To County';
        }
        field(87; "Bill-to/Pay-To Country Code"; Code[10])
        {
            Caption = 'Bill-to/Pay-To Country Code';
        }
        field(88; "Sell-to/Buy-from Post Code"; Code[20])
        {
            Caption = 'Sell-to/Buy-from Post Code';
        }
        field(89; "Sell-to/Buy-from County"; Text[30])
        {
            Caption = 'Sell-to/Buy-from County';
        }
        field(90; "Sell-to/Buy-from Country Code"; Code[10])
        {
            Caption = 'Sell-to/Buy-from Country Code';
        }
        field(91; "Ship-to/Buy-from Post Code"; Code[20])
        {
            Caption = 'Ship-to/Buy-from Post Code';
        }
        field(92; "Ship-to/Buy-from County"; Text[30])
        {
            Caption = 'Ship-to/Buy-from County';
        }
        field(93; "Ship-to/Buy-from Country Code"; Code[10])
        {
            Caption = 'Ship-to/Buy-from Country Code';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
        }
        field(10039; "Identifier IdCCP"; Text[50])
        {
            Caption = 'Identifier IdCCP';
            Editable = false;
        }
        field(10044; "Transport Operators"; Integer)
        {
            Caption = 'Transport Operators';
            CalcFormula = count("CFDI Transport Operator" where("Document Table ID" = field("Document Table ID"),
                                                                 "Document No." = field("No.")));
            FieldClass = FlowField;
        }
        field(10045; "Transit-from Date/Time"; DateTime)
        {
            Caption = 'Transit-from Date/Time';
        }
        field(10046; "Transit Hours"; Integer)
        {
            Caption = 'Transit Hours';
        }
        field(10047; "Transit Distance"; Decimal)
        {
            Caption = 'Transit Distance';
        }
        field(10048; "Insurer Name"; Text[50])
        {
            Caption = 'Insurer Name';
        }
        field(10049; "Insurer Policy Number"; Text[30])
        {
            Caption = 'Insurer Policy Number';
        }
        field(10050; "Foreign Trade"; Boolean)
        {
            Caption = 'Foreign Trade';
        }
        field(10051; "Vehicle Code"; Code[20])
        {
            Caption = 'Vehicle Code';
            TableRelation = "Fixed Asset";
        }
        field(10052; "Trailer 1"; Code[20])
        {
            Caption = 'Trailer 1';
            TableRelation = "Fixed Asset" where("SAT Trailer Type" = filter(<> ''));
        }
        field(10053; "Trailer 2"; Code[20])
        {
            Caption = 'Trailer 2';
            TableRelation = "Fixed Asset" where("SAT Trailer Type" = filter(<> ''));
        }
        field(10054; "Transit-from Location"; Code[10])
        {
            Caption = 'Transit-from Location';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(10055; "Transit-to Location"; Code[10])
        {
            Caption = 'Transit-to Location';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(10056; "Medical Insurer Name"; Text[50])
        {
            Caption = 'Medical Insurer Name';
        }
        field(10057; "Medical Ins. Policy Number"; Text[30])
        {
            Caption = 'Medical Ins. Policy Number';
        }
        field(10058; "SAT Weight Unit Of Measure"; Code[10])
        {
            Caption = 'SAT Weight Unit Of Measure';
        }
        field(10059; "SAT International Trade Term"; Code[10])
        {
            Caption = 'SAT International Trade Term';
            TableRelation = "SAT International Trade Term";
        }
        field(10060; "Exchange Rate USD"; Decimal)
        {
            Caption = 'Exchange Rate USD';
            DecimalPlaces = 0 : 6;
        }
        field(10061; "SAT Customs Regime"; Code[10])
        {
            Caption = 'SAT Customs Regime';
            TableRelation = "SAT Customs Regime";
        }
        field(10062; "SAT Transfer Reason"; Code[10])
        {
            Caption = 'SAT Transfer Reason';
            TableRelation = "SAT Transfer Reason";
        }
        field(27000; "CFDI Purpose"; Code[10])
        {
            Caption = 'CFDI Purpose';
            TableRelation = "SAT Use Code";
        }
        field(27001; "CFDI Relation"; Code[10])
        {
            Caption = 'CFDI Relation';
            TableRelation = "SAT Relationship Type";
        }
        field(27004; "CFDI Export Code"; Code[10])
        {
            Caption = 'CFDI Export Code';
            TableRelation = "CFDI Export Code";
        }
        field(27005; "CFDI Period"; Option)
        {
            Caption = 'CFDI Period';
            OptionCaption = 'Diario,Semanal,Quincenal,Mensual';
            OptionMembers = "Diario","Semanal","Quincenal","Mensual";
        }
        field(27009; "SAT Address ID"; Integer)
        {
            Caption = 'SAT Address ID';
        }
        field(27010; "Document Table ID"; Integer)
        {
            Caption = 'Document Table ID';
        }
        field(27012; "CFDI Certificate of Origin No."; Text[50])
        {
            Caption = 'CFDI Certificate of Origin No.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if not IsTemporary then
            Error(TemporaryErr);
    end;

    var
        TemporaryErr: Label 'Developer Message: The record must be temporary.';
}

