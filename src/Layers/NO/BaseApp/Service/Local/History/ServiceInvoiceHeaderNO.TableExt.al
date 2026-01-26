// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

tableextension 10612 "Service Invoice Header NO" extends "Service Invoice Header"
{
    fields
    {
        field(10600; GLN; Code[13])
        {
            Caption = 'GLN';
            DataClassification = CustomerContent;
        }
        field(10601; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10604; "E-Invoice Created"; Boolean)
        {
            Caption = 'E-Invoice Created';
            DataClassification = CustomerContent;
            Editable = false;
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

    procedure AccountCodeLineSpecified(): Boolean
    var
        ServInvLine: Record "Service Invoice Line";
    begin
        ServInvLine.Reset();
        ServInvLine.SetRange("Document No.", "No.");
        ServInvLine.SetFilter(Type, '>%1', ServInvLine.Type::" ");
        ServInvLine.SetFilter("Account Code", '<>%1&<>%2', '', "Account Code");
        exit(not ServInvLine.IsEmpty);
    end;
}