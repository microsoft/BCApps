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
            ToolTip = 'Specifies the type of contract that was filed.';
        }
        field(2; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            ToolTip = 'Specifies the number of the service contract or service contract quote that was filed.';
            TableRelation = "Filed Service Contract Header"."Contract No." where("Contract Type" = field("Contract Type"));
            ValidateTableRelation = false;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the filed contract line.';
        }
        field(4; "Contract Status"; Enum "Service Contract Status")
        {
            Caption = 'Contract Status';
        }
        field(5; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            ToolTip = 'Specifies the number of the service item on the filed service contract line.';
            TableRelation = "Service Item";
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the service item group associated with the filed service item line.';
        }
        field(7; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number of the service item on the filed service item line.';
        }
        field(8; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            ToolTip = 'Specifies the code for the service item group associated with this service item.';
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
            ToolTip = 'Specifies the item number linked to the service item in the filed contract.';
            TableRelation = Item where(Type = const(Inventory));
        }
        field(12; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if ("Item No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("Item No."))
            else
            "Unit of Measure";
        }
        field(13; "Response Time (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(14; "Last Planned Service Date"; Date)
        {
            Caption = 'Last Planned Service Date';
            ToolTip = 'Specifies the date of the last planned service on this item.';
            Editable = false;
        }
        field(15; "Next Planned Service Date"; Date)
        {
            Caption = 'Next Planned Service Date';
            ToolTip = 'Specifies the date of the next planned service on this item.';
        }
        field(16; "Last Service Date"; Date)
        {
            Caption = 'Last Service Date';
            ToolTip = 'Specifies the date of the last actual service on this item.';
        }
        field(17; "Last Preventive Maint. Date"; Date)
        {
            Caption = 'Last Preventive Maint. Date';
            ToolTip = 'Specifies the date when the last time preventative service was performed on this item.';
            Editable = false;
        }
        field(18; "Invoiced to Date"; Date)
        {
            Caption = 'Invoiced to Date';
            ToolTip = 'Specifies the date when the contract was last invoiced.';
            Editable = false;
        }
        field(19; "Credit Memo Date"; Date)
        {
            Caption = 'Credit Memo Date';
            ToolTip = 'Specifies the date when you can create a credit memo for the item that needs to be removed from the service contract.';
        }
        field(20; "Contract Expiration Date"; Date)
        {
            Caption = 'Contract Expiration Date';
            ToolTip = 'Specifies the date when the service item should be removed from the service contract.';
        }
        field(21; "Service Period"; DateFormula)
        {
            Caption = 'Service Period';
            ToolTip = 'Specifies the estimated time that elapses until service starts on the service item.';
        }
        field(22; "Line Value"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Value';
            ToolTip = 'Specifies the value on the service item line in the service contract.';
        }
        field(23; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Line Discount %';
            ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(24; "Line Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Amount';
            ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
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
            ToolTip = 'Specifies that this service contract line is a new line.';
        }
        field(31; Credited; Boolean)
        {
            Caption = 'Credited';
        }
        field(32; "Line Cost"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Cost';
            ToolTip = 'Specifies the calculated cost of the item line in the filed service contract or filed service contract quote.';
        }
        field(33; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the amount of the discount on the contract line in the filed service contract or filed contract quote.';
        }
        field(34; Profit; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Profit';
            ToolTip = 'Specifies the profit on the contract line in the filed service contract or filed contract quote.';
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
