// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

tableextension 10600 "Service Header Archive NO" extends "Service Header Archive"
{
    fields
    {
        field(10600; GLN; Code[13])
        {
            Caption = 'GLN';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the global location number of the customer.';
        }
        field(10601; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the account code of the customer.';
        }
        field(10605; "E-Invoice"; Boolean)
        {
            Caption = 'E-Invoice';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the customer is part of the EHF system and requires an electronic service order.';
        }
        field(10606; "External Document No. NO"; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
        }
        field(10607; "Delivery Date"; Date)
        {
            Caption = 'Delivery Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the date that the item was requested for delivery in the service order.';
        }
    }
}