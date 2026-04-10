// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

table 5907 "Service Ledger Entry"
{
    Caption = 'Service Ledger Entry';
    DrillDownPageID = "Service Ledger Entries";
    LookupPageID = "Service Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Service Contract No."; Code[20])
        {
            Caption = 'Service Contract No.';
            ToolTip = 'Specifies the number of the service contract, if this entry is linked to a service contract.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(3; "Document Type"; Enum "Service Ledger Entry Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type of the service ledger entry.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the document from which this entry was created.';
        }
        field(5; "Serv. Contract Acc. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Contract Acc. Gr. Code';
            ToolTip = 'Specifies the service contract account group code the service contract is associated with, if this entry is included in a service contract.';
            TableRelation = "Service Contract Account Group".Code;
        }
        field(6; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(8; "Moved from Prepaid Acc."; Boolean)
        {
            Caption = 'Moved from Prepaid Acc.';
            ToolTip = 'Specifies that this entry is not a prepaid entry from a service contract.';
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date when this entry was posted.';
        }
        field(11; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(12; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the number of the customer related to this entry.';
            TableRelation = Customer;
        }
        field(13; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(14; "Item No. (Serviced)"; Code[20])
        {
            Caption = 'Item No. (Serviced)';
            TableRelation = Item;
        }
        field(15; "Serial No. (Serviced)"; Code[50])
        {
            Caption = 'Serial No. (Serviced)';
        }
        field(16; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(17; "Contract Invoice Period"; Text[30])
        {
            Caption = 'Contract Invoice Period';
            ToolTip = 'Specifies the invoice period of that contract, if this entry originates from a service contract.';
        }
        field(18; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(19; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(20; "Service Item No. (Serviced)"; Code[20])
        {
            Caption = 'Service Item No. (Serviced)';
            TableRelation = "Service Item";
        }
        field(21; "Variant Code (Serviced)"; Code[10])
        {
            Caption = 'Variant Code (Serviced)';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No. (Serviced)"));
        }
        field(22; "Contract Group Code"; Code[10])
        {
            Caption = 'Contract Group Code';
            ToolTip = 'Specifies the contract group code of the service contract to which this entry is associated.';
            TableRelation = "Contract Group".Code;
        }
        field(23; Type; Enum "Service Ledger Entry Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of origin of this entry.';
        }
        field(24; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const("Service Contract")) "Service Contract Header"."Contract No." where("Contract Type" = const(Contract))
            else
            if (Type = const(" ")) "Standard Text"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Service Cost")) "Service Cost"
            else
            if (Type = const("G/L Account")) "G/L Account";
        }
        field(25; "Cost Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            ToolTip = 'Specifies the total cost on the line by multiplying the unit cost by the quantity.';
        }
        field(26; "Discount Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Discount Amount';
            ToolTip = 'Specifies the total discount amount on this entry.';
        }
        field(27; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
        }
        field(28; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of units in this entry.';
            DecimalPlaces = 0 : 5;
        }
        field(29; "Charged Qty."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Charged Qty.';
            ToolTip = 'Specifies the number of units in this entry that should be invoiced.';
            DecimalPlaces = 0 : 5;
        }
        field(30; "Unit Price"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
        }
        field(31; "Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Discount %';
            ToolTip = 'Specifies the discount percentage of this entry.';
            DecimalPlaces = 0 : 5;
        }
        field(32; "Contract Disc. Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Contract Disc. Amount';
            ToolTip = 'Specifies the total contract discount amount of this entry.';
        }
        field(33; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
            TableRelation = Customer;
        }
        field(34; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            ToolTip = 'Specifies the fault reason code for this entry.';
            TableRelation = "Fault Reason Code";
        }
        field(35; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the resource, item, cost, standard text, general ledger account, or service contract associated with this entry.';
        }
        field(37; "Service Order Type"; Code[10])
        {
            Caption = 'Service Order Type';
            ToolTip = 'Specifies the type of the service order if this entry was created for a service order.';
            TableRelation = "Service Order Type";
        }
        field(39; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            ToolTip = 'Specifies the number of the service order, if this entry was created for a service order.';

            trigger OnLookup()
            begin
                Clear(ServOrderMgt);
                ServOrderMgt.ServHeaderLookup(1, "Service Order No.");
            end;
        }
        field(40; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
            TableRelation = Job."No." where("Bill-to Customer No." = field("Bill-to Customer No."));
        }
        field(41; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        field(42; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        field(43; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code for the location associated with this entry.';
            TableRelation = Location;
        }
        field(44; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(45; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
        }
        field(46; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the items are picked or put away.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(47; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(48; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(50; "Entry Type"; Enum "Service Ledger Entry Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the type for this entry.';
        }
        field(51; Open; Boolean)
        {
            Caption = 'Open';
            ToolTip = 'Specifies contract-related service ledger entries.';
        }
        field(52; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            TableRelation = "Service Price Adjustment Group";
        }
        field(53; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";
        }
        field(54; Prepaid; Boolean)
        {
            Caption = 'Prepaid';
            ToolTip = 'Specifies whether the service contract or contract-related service order was prepaid.';
        }
        field(55; "Apply Until Entry No."; Integer)
        {
            Caption = 'Apply Until Entry No.';
        }
        field(56; "Applies-to Entry No."; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Applies-to Entry No.';
            ToolTip = 'Specifies the number of the entry to which this entry is applied, if an entry is created for a service credit memo.';
        }
        field(57; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount on this entry.';
        }
        field(58; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the number of the related project task.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(59; "Job Line Type"; Enum "Job Line Type")
        {
            Caption = 'Project Line Type';
            ToolTip = 'Specifies the journal line type that is created in the Project Planning Line table and linked to this project ledger entry.';
            InitValue = Budget;
        }
        field(60; "Job Posted"; Boolean)
        {
            Caption = 'Project Posted';
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s numbering system.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Posting Date")
        {
        }
        key(Key3; "Entry Type", "Document Type", "Document No.", "Document Line No.")
        {
        }
        key(Key4; "Service Contract No.", "Entry No.", "Entry Type", Type, "Moved from Prepaid Acc.", "Posting Date", Open, Prepaid, "Service Item No. (Serviced)", "Customer No.", "Contract Group Code", "Responsibility Center")
        {
            SumIndexFields = "Amount (LCY)", "Cost Amount", Quantity, "Charged Qty.", "Contract Disc. Amount";
        }
        key(Key5; "Service Order No.", "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Type, "Service Contract No.")
        {
            SumIndexFields = "Amount (LCY)", "Cost Amount", Quantity, "Charged Qty.", Amount;
        }
        key(Key6; Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Prepaid)
        {
            SumIndexFields = "Amount (LCY)", "Cost Amount", Quantity, "Charged Qty.";
        }
        key(Key7; "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date", Open, "Service Contract No.", Prepaid, "Customer No.", "Contract Group Code", "Responsibility Center")
        {
            SumIndexFields = "Amount (LCY)", "Cost Amount";
        }
        key(Key8; "Service Item No. (Serviced)", "Entry Type", Type, "Service Contract No.", "Posting Date", "Service Order No.")
        {
            SumIndexFields = "Amount (LCY)", "Cost Amount", Quantity, "Charged Qty.";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Entry Type", "Service Contract No.", "Posting Date")
        {
        }
    }

    var
        ServOrderMgt: Codeunit ServOrderManagement;
        DimMgt: Codeunit DimensionManagement;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Service Ledger Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure CopyFromServHeader(ServHeader: Record "Service Header")
    begin
        "Service Order Type" := ServHeader."Service Order Type";
        "Customer No." := ServHeader."Customer No.";
        "Bill-to Customer No." := ServHeader."Bill-to Customer No.";
        "Service Order Type" := ServHeader."Service Order Type";
        "Responsibility Center" := ServHeader."Responsibility Center";

        OnAfterCopyFromServHeader(Rec, ServHeader);
    end;

    procedure CopyFromServLine(ServLine: Record "Service Line"; DocNo: Code[20])
    begin
        case ServLine.Type of
            ServLine.Type::Item:
                begin
                    Type := Type::Item;
                    "Bin Code" := ServLine."Bin Code";
                end;
            ServLine.Type::Resource:
                Type := Type::Resource;
            ServLine.Type::Cost:
                Type := Type::"Service Cost";
            ServLine.Type::"G/L Account":
                Type := Type::"G/L Account";
        end;

        if ServLine."Document Type" = ServLine."Document Type"::Order then
            "Service Order No." := ServLine."Document No.";

        "Location Code" := ServLine."Location Code";
        "Job No." := ServLine."Job No.";
        "Job Task No." := ServLine."Job Task No.";
        "Job Line Type" := ServLine."Job Line Type";

        "Document Type" := "Document Type"::Shipment;
        "Document No." := DocNo;
        "Document Line No." := ServLine."Line No.";
        "Moved from Prepaid Acc." := true;
        "Posting Date" := ServLine."Posting Date";
        "Entry Type" := "Entry Type"::Usage;
        "Ship-to Code" := ServLine."Ship-to Code";
        "Global Dimension 1 Code" := ServLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := ServLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServLine."Dimension Set ID";
        "Gen. Bus. Posting Group" := ServLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServLine."Gen. Prod. Posting Group";
        Description := ServLine.Description;
        "Fault Reason Code" := ServLine."Fault Reason Code";
        "Unit of Measure Code" := ServLine."Unit of Measure Code";
        "Work Type Code" := ServLine."Work Type Code";
        "Serv. Price Adjmt. Gr. Code" := ServLine."Serv. Price Adjmt. Gr. Code";
        "Service Price Group Code" := ServLine."Service Price Group Code";
        "Discount %" := ServLine."Line Discount %";
        "Variant Code" := ServLine."Variant Code";

        OnAfterCopyFromServLine(Rec, ServLine);
    end;

    procedure CopyServicedInfo(ServiceItemNo: Code[20]; ItemNo: Code[20]; SerialNo: Code[50]; VariantCode: Code[10])
    begin
        "Service Item No. (Serviced)" := ServiceItemNo;
        "Item No. (Serviced)" := ItemNo;
        "Serial No. (Serviced)" := SerialNo;
        "Variant Code (Serviced)" := VariantCode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromServHeader(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromServLine(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceLine: Record "Service Line")
    begin
    end;
}

