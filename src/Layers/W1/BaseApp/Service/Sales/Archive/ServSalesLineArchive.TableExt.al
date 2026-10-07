// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Archive;

using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;

tableextension 6408 "Serv. Sales Line Archive" extends "Sales Line Archive"
{
    fields
    {
        field(5900; "Service Contract No."; Code[20])
        {
            Caption = 'Service Contract No.';
            DataClassification = CustomerContent;
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract),
                                                                            "Customer No." = field("Sell-to Customer No."),
                                                                            "Bill-to Customer No." = field("Bill-to Customer No."));
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
            TableRelation = "Service Item"."No." where("Customer No." = field("Sell-to Customer No."));
        }
        field(5903; "Appl.-to Service Entry"; Integer)
        {
            Caption = 'Appl.-to Service Entry';
            DataClassification = CustomerContent;
        }
        field(5904; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
            DataClassification = CustomerContent;
        }
        field(5907; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            DataClassification = CustomerContent;
            TableRelation = "Service Price Adjustment Group";
        }
    }
}
