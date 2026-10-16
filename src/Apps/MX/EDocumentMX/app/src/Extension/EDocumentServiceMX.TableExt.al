// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;

tableextension 3352 "E-Document Service MX" extends "E-Document Service"
{
    fields
    {
        field(3352; "SAT Certificate"; Blob)
        {
            Caption = 'SAT Certificate';
            DataClassification = CustomerContent;
        }
        field(3353; "SAT Certificate Key"; Blob)
        {
            Caption = 'SAT Certificate Key';
            DataClassification = CustomerContent;
        }
        field(3354; "SAT Certificate Password"; Text[250])
        {
            Caption = 'SAT Certificate Password';
            DataClassification = CustomerContent;
        }
        field(3355; "SAT Certificate Serial"; Text[250])
        {
            Caption = 'SAT Certificate Serial';
            DataClassification = CustomerContent;
        }
        field(3356; "SAT Certificate Expiry"; Date)
        {
            Caption = 'SAT Certificate Expiry';
            DataClassification = CustomerContent;
        }
        field(3357; "Send PDF Report"; Boolean)
        {
            Caption = 'Send PDF Report';
            DataClassification = CustomerContent;
        }
    }
}