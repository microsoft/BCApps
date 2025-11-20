// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Service.Item;

table 5971 "Filed Contract Line"
{
    Caption = 'Filed Service Contract Line';
    LookupPageID = "Filed Service Contract Lines";
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
            ValidateTableRelation = false;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Contract Status"; Enum "Service Contract Status")
        {
            Caption = 'Contract Status';
        }
        field(5; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item";
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(8; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group";
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(10; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Type = const(Inventory));
        }
        field(12; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if ("Item No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("Item No."))
            else
            "Unit of Measure";
        }
        field(13; "Response Time (Hours)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(14; "Last Planned Service Date"; Date)
        {
            Caption = 'Last Planned Service Date';
            Editable = false;
        }
        field(15; "Next Planned Service Date"; Date)
        {
            Caption = 'Next Planned Service Date';
        }
        field(16; "Last Service Date"; Date)
        {
            Caption = 'Last Service Date';
        }
        field(17; "Last Preventive Maint. Date"; Date)
        {
            Caption = 'Last Preventive Maint. Date';
            Editable = false;
        }
        field(18; "Invoiced to Date"; Date)
        {
            Caption = 'Invoiced to Date';
            Editable = false;
        }
        field(19; "Credit Memo Date"; Date)
        {
            Caption = 'Credit Memo Date';
        }
        field(20; "Contract Expiration Date"; Date)
        {
            Caption = 'Contract Expiration Date';
        }
        field(21; "Service Period"; DateFormula)
        {
            Caption = 'Service Period';
        }
        field(22; "Line Value"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Value';
        }
        field(23; "Line Discount %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(24; "Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Amount';
            MinValue = 0;
        }
        field(28; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(29; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            Editable = false;
        }
        field(30; "New Line"; Boolean)
        {
            Caption = 'New Line';
        }
        field(31; Credited; Boolean)
        {
            Caption = 'Credited';
        }
        field(32; "Line Cost"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Cost';
        }
        field(33; "Line Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Discount Amount';
        }
        field(34; Profit; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Profit';
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Filed Contract Line"."Line No." where("Contract Type" = field("Contract Type"),
                                                                   "Contract No." = field("Contract No."),
                                                                   "Entry No." = field("Entry No."));
        }
        field(100; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique number of filed service contract or service contract quote.';
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    internal procedure ShowComments()
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        FiledServContractCmtLine: Record "Filed Serv. Contract Cmt. Line";
    begin
        Rec.TestField("Line No.");

        FiledServiceContractHeader.SetLoadFields("Customer No.");
        FiledServiceContractHeader.Get(Rec."Entry No.");
        FiledServiceContractHeader.TestField("Customer No.");

        FiledServContractCmtLine.SetRange("Entry No.", Rec."Entry No.");
        FiledServContractCmtLine.SetRange("Table Name", FiledServContractCmtLine."Table Name"::"Service Contract");
        FiledServContractCmtLine.SetRange("Table Subtype", Rec."Contract Type");
        FiledServContractCmtLine.SetRange("No.", Rec."Contract No.");
        FiledServContractCmtLine.SetRange(Type, FiledServContractCmtLine.Type::General);
        FiledServContractCmtLine.SetRange("Table Line No.", Rec."Line No.");
        Page.RunModal(Page::"Filed Serv. Contract Cm. Sheet", FiledServContractCmtLine);
    end;
}
