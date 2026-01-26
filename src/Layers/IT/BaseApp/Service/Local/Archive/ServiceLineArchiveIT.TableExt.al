// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Inventory.Intrastat;

tableextension 12141 "Service Line Archive IT" extends "Service Line Archive"
{
    fields
    {
        field(10600; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the account code of the customer.';
        }
        field(12101; "Deductible %"; Decimal)
        {
            Caption = 'Deductible %';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
            Editable = false;
            InitValue = 100;
            MaxValue = 100;
        }
        field(12125; "Service Tariff No."; Code[10])
        {
            Caption = 'Service Tariff No.';
            DataClassification = CustomerContent;
            TableRelation = "Service Tariff Number";
        }
        field(12130; "Include in VAT Transac. Rep."; Boolean)
        {
            Caption = 'Include in VAT Transac. Rep.';
            DataClassification = CustomerContent;
        }
        field(12131; "Refers to Period"; Option)
        {
            Caption = 'Refers to Period';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Current,Current Calendar Year,Previous Calendar Year';
            OptionMembers = " ",Current,"Current Calendar Year","Previous Calendar Year";
        }
        field(12145; "Automatically Generated"; Boolean)
        {
            Caption = 'Automatically Generated';
            DataClassification = CustomerContent;
        }
    }
}