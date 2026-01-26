// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;
using Microsoft.EServices.EDocument;

tableextension 10602 "Service Header NO" extends "Service Header"
{
    fields
    {
        field(10600; GLN; Code[13])
        {
            Caption = 'GLN';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not EInvoiceDocumentEncode.IsValidEANNo(GLN, true) then
                    FieldError(GLN, GLNNoErr);
            end;
        }
        field(10601; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if "Account Code" <> xRec."Account Code" then
                    UpdateServLinesByFieldNo(FieldNo("Account Code"), false);
            end;
        }
        field(10605; "E-Invoice"; Boolean)
        {
            Caption = 'E-Invoice';
            DataClassification = CustomerContent;
        }
        field(10607; "Delivery Date"; Date)
        {
            Caption = 'Delivery Date';
            DataClassification = CustomerContent;
        }
    }

    var
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        GLNNoErr: Label 'The GLN No. field does not contain a valid, 13-digit GLN  number';
}