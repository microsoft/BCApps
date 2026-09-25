// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.SalesTax;
using System.Security.Encryption;

tableextension 10015 "Location NA" extends Location
{
    fields
    {
        field(10010; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                if "Do Not Use For Tax Calculation" then
                    "Tax Area Code" := '';
            end;
        }
        field(10015; "Tax Exemption No."; Text[30])
        {
            Caption = 'Tax Exemption No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Do Not Use For Tax Calculation" then
                    "Tax Exemption No." := '';
            end;
        }
        field(10016; "Do Not Use For Tax Calculation"; Boolean)
        {
            Caption = 'Do Not Use For Tax Calculation';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Do Not Use For Tax Calculation" then begin
                    "Tax Area Code" := '';
                    "Tax Exemption No." := '';
                    "Provincial Tax Area Code" := '';
                end;
            end;
        }
        field(10017; "Provincial Tax Area Code"; Code[20])
        {
            Caption = 'Provincial Tax Area Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Area" where("Country/Region" = const(CA));

            trigger OnValidate()
            begin
                if "Do Not Use For Tax Calculation" then
                    "Provincial Tax Area Code" := '';
            end;
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
                if SATAddress.LookupSATAddress(SATAddress, Rec."Country/Region Code", '') then
                    Rec."SAT Address ID" := SATAddress.Id;
            end;
        }
        field(27020; "SAT Certificate"; Code[20])
        {
            Caption = 'SAT Certificate';
            DataClassification = CustomerContent;
            TableRelation = "Isolated Certificate";
        }
        field(27030; "ID Ubicacion"; Integer)
        {
            Caption = 'ID Ubicacion';
            DataClassification = CustomerContent;
        }
    }

    procedure GetSATAddress(): Text
    var
        SATAddress: Record "SAT Address";
    begin
        if SATAddress.Get("SAT Address ID") then
            exit(SATAddress.GetSATAddress());
        exit('');
    end;

    procedure GetSATPostalCode(): Code[20]
    var
        SATAddress: Record "SAT Address";
    begin
        if SATAddress.Get("SAT Address ID") then
            exit(SATAddress.GetSATPostalCode());
        exit('');
    end;
}
