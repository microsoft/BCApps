// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;

table 5989 "Service Shipment Item Line"
{
    Caption = 'Service Shipment Item Line';
    DrillDownPageID = "Posted Shpt. Item Line List";
    LookupPageID = "Posted Shpt. Item Line List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            Editable = false;
            TableRelation = "Service Shipment Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of this line.';
        }
        field(3; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            ToolTip = 'Specifies the number of the service item registered in the Service Item table and associated with the customer.';
            TableRelation = "Service Item";
        }
        field(4; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            ToolTip = 'Specifies the code for the group associated with this service item.';
            TableRelation = "Service Item Group";
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item to which this posted service item is related.';
            TableRelation = Item;
        }
        field(6; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number of this service item.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the service item specified in the Service Item No. field on this line.';
        }
        field(8; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies an additional description of this service item.';
        }
        field(10; Priority; Option)
        {
            Caption = 'Priority';
            ToolTip = 'Specifies the service priority for this posted service item.';
            OptionCaption = 'Low,Medium,High';
            OptionMembers = Low,Medium,High;
        }
        field(11; "Response Time (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Response Date"; Date)
        {
            Caption = 'Response Date';
            ToolTip = 'Specifies the estimated date when service starts on this service item.';
        }
        field(13; "Response Time"; Time)
        {
            Caption = 'Response Time';
            ToolTip = 'Specifies the time when service is expected to start on this service item.';
        }
        field(14; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date when service on this service item started.';
            Editable = false;
        }
        field(15; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            ToolTip = 'Specifies the time when service on this service item started.';
            Editable = false;
        }
        field(16; "Finishing Date"; Date)
        {
            Caption = 'Finishing Date';
            ToolTip = 'Specifies the time when service on this service item is finished.';
            Editable = false;
        }
        field(17; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';
            ToolTip = 'Specifies the time when the service on the order is finished.';
            Editable = false;
        }
        field(18; "Service Shelf No."; Code[10])
        {
            Caption = 'Service Shelf No.';
            ToolTip = 'Specifies the number of the service shelf where the service item is stored while it is in the repair shop.';
            TableRelation = "Service Shelf";
        }
        field(19; "Warranty Starting Date (Parts)"; Date)
        {
            Caption = 'Warranty Starting Date (Parts)';
        }
        field(20; "Warranty Ending Date (Parts)"; Date)
        {
            Caption = 'Warranty Ending Date (Parts)';
        }
        field(21; Warranty; Boolean)
        {
            Caption = 'Warranty';
            ToolTip = 'Specifies that there is a warranty on either parts or labor for this service item.';
        }
        field(22; "Warranty % (Parts)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Warranty % (Parts)';
            DecimalPlaces = 0 : 2;
        }
        field(23; "Warranty % (Labor)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Warranty % (Labor)';
            DecimalPlaces = 0 : 2;
        }
        field(24; "Warranty Starting Date (Labor)"; Date)
        {
            Caption = 'Warranty Starting Date (Labor)';
        }
        field(25; "Warranty Ending Date (Labor)"; Date)
        {
            Caption = 'Warranty Ending Date (Labor)';
        }
        field(26; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            ToolTip = 'Specifies the number of the contract associated with the posted service item.';
            Editable = false;
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(27; "Location of Service Item"; Text[30])
        {
            CalcFormula = lookup("Service Item"."Location of Service Item" where("No." = field("Service Item No.")));
            Caption = 'Location of Service Item';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Loaner No."; Code[20])
        {
            Caption = 'Loaner No.';
            ToolTip = 'Specifies the number of the loaner that has been lent to the customer to replace this service item.';
            TableRelation = Loaner;
        }
        field(29; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the number of the vendor who sold this service item.';
            TableRelation = Vendor;
        }
        field(30; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
            ToolTip = 'Specifies the number that the vendor uses for this item.';
        }
        field(31; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            ToolTip = 'Specifies the fault reason code assigned to the posted service item.';
            TableRelation = "Fault Reason Code";
        }
        field(32; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            ToolTip = 'Specifies the code of the service price group associated with this service item.';
            TableRelation = "Service Price Group";
        }
        field(33; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            ToolTip = 'Specifies the code that identifies the area of the fault encountered with this service item.';
            TableRelation = "Fault Area";
        }
        field(34; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            ToolTip = 'Specifies the code to identify the symptom of the service item fault.';
            TableRelation = "Symptom Code";
        }
        field(35; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            ToolTip = 'Specifies the code to identify the fault of the posted service item or the actions taken on the item.';
            TableRelation = "Fault Code".Code where("Fault Area Code" = field("Fault Area Code"),
                                                     "Symptom Code" = field("Symptom Code"));
        }
        field(36; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            ToolTip = 'Specifies the resolution code assigned to this item.';
            TableRelation = "Resolution Code";
        }
        field(37; "Fault Comment"; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Shipment Header"),
                                                              "Table Subtype" = const("0"),
                                                              "No." = field("No."),
                                                              Type = const(Fault),
                                                              "Table Line No." = field("Line No.")));
            Caption = 'Fault Comment';
            ToolTip = 'Specifies that there is a fault comment for this service item.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(38; "Resolution Comment"; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Shipment Header"),
                                                              "Table Subtype" = const("0"),
                                                              "No." = field("No."),
                                                              Type = const(Resolution),
                                                              "Table Line No." = field("Line No.")));
            Caption = 'Resolution Comment';
            ToolTip = 'Specifies that there is a resolution comment for this service item.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; "Accessory Comment"; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Shipment Header"),
                                                              "Table Subtype" = const("0"),
                                                              "No." = field("No."),
                                                              Type = const(Accessory),
                                                              "Table Line No." = field("Line No.")));
            Caption = 'Accessory Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(42; "Actual Response Time (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Actual Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(44; "Service Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Service Price Adjmt. Gr. Code';
            Editable = false;
            TableRelation = "Service Price Adjustment Group";
        }
        field(45; "Adjustment Type"; Option)
        {
            Caption = 'Adjustment Type';
            Editable = false;
            OptionCaption = 'Fixed,Maximum,Minimum';
            OptionMembers = "Fixed",Maximum,Minimum;
        }
        field(46; "Base Amount to Adjust"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Base Amount to Adjust';
            Editable = false;
        }
        field(60; "No. of Active/Finished Allocs"; Integer)
        {
            CalcFormula = count("Service Order Allocation" where("Document Type" = const(Order),
                                                                  "Document No." = field("No."),
                                                                  "Service Item Line No." = field("Line No."),
                                                                  "Resource No." = field("Resource Filter"),
                                                                  "Allocation Date" = field("Allocation Date Filter"),
                                                                  Status = filter(Active | Finished)));
            Caption = 'No. of Active/Finished Allocs';
            Editable = false;
            FieldClass = FlowField;
        }
        field(64; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
            Editable = false;
            TableRelation = "Ship-to Address".Code;
        }
        field(65; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer."No.";
        }
        field(91; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(92; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(93; "Allocation Date Filter"; Date)
        {
            Caption = 'Allocation Date Filter';
            FieldClass = FlowFilter;
        }
        field(95; "Resource Group Filter"; Code[20])
        {
            Caption = 'Resource Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(97; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Service Item No.")
        {
        }
        key(Key3; "Item No.", "Serial No.", "Loaner No.")
        {
        }
        key(Key4; "Service Price Group Code", "Adjustment Type", "Base Amount to Adjust", "Customer No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ShowComments(Type: Option General,Fault,Resolution,Accessory,Internal,"Service Item Loaner")
    var
        ServShipmentHeader: Record "Service Shipment Header";
        ServCommentLine: Record "Service Comment Line";
    begin
        ServShipmentHeader.Get("No.");
        ServShipmentHeader.TestField("Customer No.");
        TestField("Line No.");

        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Shipment Header");
        ServCommentLine.SetRange("Table Subtype", 0);
        ServCommentLine.SetRange("No.", "No.");
        case Type of
            Type::Fault:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Fault);
            Type::Resolution:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Resolution);
            Type::Accessory:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Accessory);
            Type::Internal:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Internal);
            Type::"Service Item Loaner":
                ServCommentLine.SetRange(Type, ServCommentLine.Type::"Service Item Loaner");
        end;
        ServCommentLine.SetRange("Table Line No.", "Line No.");
        OnShowCommentsOnAfterServCommentLineSetFilters(ServCommentLine);
        PAGE.RunModal(PAGE::"Service Comment Sheet", ServCommentLine);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID",
          StrSubstNo('%1 %2 %3', TableCaption(), "No.", "Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCommentsOnAfterServCommentLineSetFilters(var ServiceCommentLine: Record "Service Comment Line")
    begin
    end;
}

