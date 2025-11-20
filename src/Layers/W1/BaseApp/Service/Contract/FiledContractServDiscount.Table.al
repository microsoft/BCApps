// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;

table 5976 "Filed Contract/Serv. Discount"
{
    Caption = 'Filed Contract/Service Discount';
    DataCaptionFields = "Contract Type", "Contract No.";
    LookupPageID = "Filed Contract/Serv. Discounts";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contract Type"; Enum "Service Contract Type")
        {
            Caption = 'Contract Type';
        }
        field(2; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Filed Service Contract Header"."Contract No." where("Contract Type" = field("Contract Type"));
        }
        field(4; Type; Enum "Service Contract Discount Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of the contract/service discount.';
        }
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("Service Item Group")) "Service Item Group".Code
            else
            if (Type = const("Resource Group")) "Resource Group"."No."
            else
            if (Type = const(Cost)) "Service Cost".Code;
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date when the discount becomes applicable to the contract or quote.';
        }
        field(7; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
            ToolTip = 'Specifies the discount percentage.';
        }
        field(100; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique number of filed service contract or service contract quote.';
        }
    }

    keys
    {
        key(Key1; "Entry No.", Type, "No.", "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "Contract Type", "Contract No.", Type, "No.", "Starting Date")
        {
        }
    }
}