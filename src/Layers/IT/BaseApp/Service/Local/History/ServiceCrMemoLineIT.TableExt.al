// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Inventory.Intrastat;

tableextension 12455 "Service Cr.Memo Line IT" extends "Service Cr.Memo Line"
{
    fields
    {
        field(12101; "Deductible %"; Decimal)
        {
            Caption = 'Deductible %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
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
    }
}