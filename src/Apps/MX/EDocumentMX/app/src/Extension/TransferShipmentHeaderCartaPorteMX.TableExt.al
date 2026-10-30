// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Inventory.Transfer;

tableextension 3375 "Transfer Shpt. Hdr. CartaPorte" extends "Transfer Shipment Header"
{
    fields
    {
        field(3390; "SAT Transport Type"; Code[10])
        {
            Caption = 'SAT Transport Type';
            DataClassification = CustomerContent;
            TableRelation = "SAT Transport Type MX";
            ValidateTableRelation = false;
        }
        field(3391; "SAT ISTMO"; Boolean)
        {
            Caption = 'SAT ISTMO';
            DataClassification = CustomerContent;
        }
        field(3392; "SAT ISTMO Polo Origen"; Code[10])
        {
            Caption = 'SAT ISTMO Polo Origen';
            DataClassification = CustomerContent;
            TableRelation = "SAT ISTMO Region MX";
            ValidateTableRelation = false;
        }
        field(3393; "SAT ISTMO Polo Destino"; Code[10])
        {
            Caption = 'SAT ISTMO Polo Destino';
            DataClassification = CustomerContent;
            TableRelation = "SAT ISTMO Region MX";
            ValidateTableRelation = false;
        }
    }
}
