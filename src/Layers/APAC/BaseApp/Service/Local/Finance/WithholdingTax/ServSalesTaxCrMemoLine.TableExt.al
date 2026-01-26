// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Service.Contract;
using Microsoft.Service.Item;

tableextension 28074 "Serv. Sales Tax Cr.Memo Line" extends "Sales Tax Cr.Memo Line"
{
    fields
    {
        field(5900; "Service Contract No."; Code[20])
        {
            Caption = 'Service Contract No.';
            DataClassification = CustomerContent;
            TableRelation = "Service Contract Header"."Contract No.";
        }
        field(5901; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            DataClassification = CustomerContent;
        }
        field(5902; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            DataClassification = CustomerContent;
            TableRelation = "Service Item";
        }
        field(5903; "Appl.-to Service Entry"; Integer)
        {
            Caption = 'Appl.-to Service Entry';
            DataClassification = CustomerContent;
        }
    }
}