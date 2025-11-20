// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;

table 6011 "Service Item Line Archive"
{
    Caption = 'Service Item Line Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
            TableRelation = "Service Header Archive"."No." where("Document Type" = field("Document Type"),
                                                                 "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                 "Version No." = field("Version No."));
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item"."No.";
        }
        field(4; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group".Code;
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
        }
        field(6; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';

        }
        field(8; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(9; "Repair Status Code"; Code[10])
        {
            Caption = 'Repair Status Code';
            TableRelation = "Repair Status";
        }
        field(10; Priority; Option)
        {
            Caption = 'Priority';
            OptionCaption = 'Low,Medium,High';
            OptionMembers = Low,Medium,High;
        }
        field(11; "Response Time (Hours)"; Decimal)
        {
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Response Date"; Date)
        {
            Caption = 'Response Date';
        }
        field(13; "Response Time"; Time)
        {
            Caption = 'Response Time';
        }
        field(14; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(15; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
        }
        field(16; "Finishing Date"; Date)
        {
            Caption = 'Finishing Date';
        }
        field(17; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';
        }
        field(18; "Service Shelf No."; Code[10])
        {
            Caption = 'Service Shelf No.';
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
        }
        field(22; "Warranty % (Parts)"; Decimal)
        {
            Caption = 'Warranty % (Parts)';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(23; "Warranty % (Labor)"; Decimal)
        {
            Caption = 'Warranty % (Labor)';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
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
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(28; "Loaner No."; Code[20])
        {
            Caption = 'Loaner No.';
            TableRelation = Loaner."No.";
        }
        field(29; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(30; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(31; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            TableRelation = "Fault Reason Code";
        }
        field(32; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";
        }
        field(33; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";
        }
        field(34; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code";
        }
        field(35; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            TableRelation = "Fault Code".Code where("Fault Area Code" = field("Fault Area Code"),
                                                    "Symptom Code" = field("Symptom Code"));
        }
        field(36; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            TableRelation = "Resolution Code";
        }
        field(40; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(42; "Actual Response Time (Hours)"; Decimal)
        {
            Caption = 'Actual Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(43; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(44; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
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
            Caption = 'Base Amount to Adjust';
            Editable = false;
        }
        field(63; "Contract Line No."; Integer)
        {
            Caption = 'Contract Line No.';
            TableRelation = "Service Contract Line"."Line No." where("Contract Type" = const(Contract),
                                                                     "Contract No." = field("Contract No."));
        }
        field(64; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(65; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer."No.";
        }
        field(97; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";
        }
        field(100; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(101; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(130; "Release Status"; Enum "Service Doc. Release Status")
        {
            Caption = 'Release Status';
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
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Service Item No.", Description, "Version No.", "Serial No.")
        {
        }
        fieldgroup(Brick; "Item No.", Description, "Service Item No.", "Serial No.", "Repair Status Code")
        {
        }
    }

    trigger OnDelete()
    var
        ServiceLineArchive: Record "Service Line Archive";
        ServiceOrderAllocatArchive: Record "Service Order Allocat. Archive";
        ServiceCommentLineArchive: Record "Service Comment Line Archive";
    begin
        ServiceLineArchive.SetRange("Document Type", Rec."Document Type");
        ServiceLineArchive.SetRange("Document No.", Rec."Document No.");
        ServiceLineArchive.SetRange("Doc. No. Occurrence", Rec."Doc. No. Occurrence");
        ServiceLineArchive.SetRange("Version No.", Rec."Version No.");
        ServiceLineArchive.SetRange("Service Item Line No.", Rec."Line No.");
        if not ServiceLineArchive.IsEmpty() then
            Error(
                ServiceItemLineArchiveAttachedToServiceLineArchiveErr,
                Rec.TableCaption(), Rec."Document No.", Rec."Line No.", ServiceLineArchive.TableCaption());

        ServiceOrderAllocatArchive.SetRange("Document Type", "Document Type");
        ServiceOrderAllocatArchive.SetRange("Document No.", Rec."Document No.");
        ServiceOrderAllocatArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        ServiceOrderAllocatArchive.SetRange("Version No.", "Version No.");
        ServiceOrderAllocatArchive.SetRange("Service Item Line No.", Rec."Line No.");
        if not ServiceOrderAllocatArchive.IsEmpty() then
            ServiceOrderAllocatArchive.DeleteAll();

        ServiceCommentLineArchive.SetRange("Table Name", ServiceCommentLineArchive."Table Name"::"Service Header");
        ServiceCommentLineArchive.SetRange("Table Subtype", Rec."Document Type");
        ServiceCommentLineArchive.SetRange("No.", Rec."Document No.");
        ServiceCommentLineArchive.SetRange("Table Line No.", Rec."Line No.");
        ServiceCommentLineArchive.SetRange("Doc. No. Occurrence", Rec."Doc. No. Occurrence");
        ServiceCommentLineArchive.SetRange("Version No.", Rec."Version No.");
        if not ServiceCommentLineArchive.IsEmpty() then
            ServiceCommentLineArchive.DeleteAll();
    end;

    var
        ServiceItemLineArchiveAttachedToServiceLineArchiveErr: Label 'You cannot delete %1 %2,%3, because %4 is attached to it.', Comment = '%1 = Table Caption , %2 = Document No. , %3 = Line No. , %4 = Table Caption';

    procedure ShowDimensions()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "Document No."));
    end;

    procedure ShowComments(Type: Option General,Fault,Resolution,Accessory,Internal,"Service Item Loaner")
    var
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceCommentLineArchive: Record "Service Comment Line Archive";
    begin
        ServiceHeaderArchive.Get(Rec."Document Type", Rec."Document No.", Rec."Doc. No. Occurrence", Rec."Version No.");
        ServiceHeaderArchive.TestField("Customer No.");
        Rec.TestField("Line No.");

        ServiceCommentLineArchive.Reset();
        ServiceCommentLineArchive.SetRange("Table Name", ServiceCommentLineArchive."Table Name"::"Service Header");
        ServiceCommentLineArchive.SetRange("Table Subtype", "Document Type");
        ServiceCommentLineArchive.SetRange("No.", "Document No.");
        ServiceCommentLineArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        ServiceCommentLineArchive.SetRange("Version No.", "Version No.");
        case Type of
            Type::Fault:
                ServiceCommentLineArchive.SetRange(Type, ServiceCommentLineArchive.Type::Fault);
            Type::Resolution:
                ServiceCommentLineArchive.SetRange(Type, ServiceCommentLineArchive.Type::Resolution);
            Type::Accessory:
                ServiceCommentLineArchive.SetRange(Type, ServiceCommentLineArchive.Type::Accessory);
            Type::Internal:
                ServiceCommentLineArchive.SetRange(Type, ServiceCommentLineArchive.Type::Internal);
            Type::"Service Item Loaner":
                ServiceCommentLineArchive.SetRange(Type, ServiceCommentLineArchive.Type::"Service Item Loaner");
        end;
        ServiceCommentLineArchive.SetRange("Table Line No.", "Line No.");
        Page.RunModal(Page::"Service Archive Comment Sheet", ServiceCommentLineArchive);
    end;
}