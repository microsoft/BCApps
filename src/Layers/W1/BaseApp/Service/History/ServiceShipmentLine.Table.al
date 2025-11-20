// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Inventory.Journal;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Reflection;
using System.Security.User;

table 5991 "Service Shipment Line"
{
    Caption = 'Service Shipment Line';
    LookupPageID = "Posted Serv. Shpt. Line List";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Service Shipment Header"."No.";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Service Line Type")
        {
            Caption = 'Type';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const(Cost)) "Service Cost"
            else
            if (Type = const("G/L Account")) "G/L Account";
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if (Type = const(Item)) "Inventory Posting Group";
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Unit Price"));
            Caption = 'Unit Price';
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
        }
        field(39; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            Editable = false;
            TableRelation = "Customer Price Group";
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(46; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
        }
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(66; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
        }
        field(81; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
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
        field(950; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(951; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            TableRelation = "Time Sheet Line"."Line No." where("Time Sheet No." = field("Time Sheet No."));
        }
        field(952; "Time Sheet Date"; Date)
        {
            Caption = 'Time Sheet Date';
            TableRelation = "Time Sheet Detail".Date where("Time Sheet No." = field("Time Sheet No."),
                                                            "Time Sheet Line No." = field("Time Sheet Line No."));
        }
        field(1019; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Planning Line No.';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";
        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5458; "Qty. Shipped Not Invd. (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category".Code;
        }
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(5901; "Appl.-to Warranty Entry"; Integer)
        {
            Caption = 'Appl.-to Warranty Entry';
        }
        field(5902; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item"."No.";
        }
        field(5903; "Appl.-to Service Entry"; Integer)
        {
            Caption = 'Appl.-to Service Entry';
        }
        field(5904; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
        }
        field(5905; "Service Item Serial No."; Code[50])
        {
            Caption = 'Service Item Serial No.';
        }
        field(5906; "Service Item Line Description"; Text[100])
        {
            Caption = 'Service Item Line Description';
        }
        field(5908; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5909; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(5910; "Needed by Date"; Date)
        {
            Caption = 'Needed by Date';
        }
        field(5916; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(5918; "Quantity Consumed"; Decimal)
        {
            Caption = 'Quantity Consumed';
            DecimalPlaces = 0 : 5;
        }
        field(5920; "Qty. Consumed (Base)"; Decimal)
        {
            Caption = 'Qty. Consumed (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5928; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";
        }
        field(5929; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";
        }
        field(5930; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code";
        }
        field(5931; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            TableRelation = "Fault Code".Code where("Fault Area Code" = field("Fault Area Code"),
                                                     "Symptom Code" = field("Symptom Code"));
        }
        field(5932; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            TableRelation = "Resolution Code";
        }
        field(5933; "Exclude Warranty"; Boolean)
        {
            Caption = 'Exclude Warranty';
        }
        field(5934; Warranty; Boolean)
        {
            Caption = 'Warranty';
        }
        field(5936; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(5938; "Contract Disc. %"; Decimal)
        {
            Caption = 'Contract Disc. %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5939; "Warranty Disc. %"; Decimal)
        {
            Caption = 'Warranty Disc. %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5965; "Component Line No."; Integer)
        {
            Caption = 'Component Line No.';
        }
        field(5966; "Spare Part Action"; Option)
        {
            Caption = 'Spare Part Action';
            OptionCaption = ' ,Permanent,Temporary,Component Replaced,Component Installed';
            OptionMembers = " ",Permanent,"Temporary","Component Replaced","Component Installed";
        }
        field(5967; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            TableRelation = "Fault Reason Code";
        }
        field(5968; "Replaced Item No."; Code[20])
        {
            Caption = 'Replaced Item No.';
            TableRelation = if ("Replaced Item Type" = const(Item)) Item
            else
            if ("Replaced Item Type" = const("Service Item")) "Service Item";
        }
        field(5969; "Exclude Contract Discount"; Boolean)
        {
            Caption = 'Exclude Contract Discount';
        }
        field(5970; "Replaced Item Type"; Option)
        {
            Caption = 'Replaced Item Type';
            OptionCaption = ' ,Service Item,Item';
            OptionMembers = " ","Service Item",Item;
        }
        field(5994; "Price Adjmt. Status"; Option)
        {
            Caption = 'Price Adjmt. Status';
            OptionCaption = ' ,Adjusted,Modified';
            OptionMembers = " ",Adjusted,Modified;
        }
        field(5997; "Line Discount Type"; Option)
        {
            Caption = 'Line Discount Type';
            OptionCaption = ' ,Warranty Disc.,Contract Disc.,Line Disc.,Manual';
            OptionMembers = " ","Warranty Disc.","Contract Disc.","Line Disc.",Manual;
        }
        field(5999; "Copy Components From"; Option)
        {
            Caption = 'Copy Components From';
            OptionCaption = 'None,Item BOM,Old Service Item,Old Serv.Item w/o Serial No.';
            OptionMembers = "None","Item BOM","Old Service Item","Old Serv.Item w/o Serial No.";
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.", "Order Line No.")
        {
        }
        key(Key3; "Item Shpt. Entry No.")
        {
        }
        key(Key4; "Service Item No.", Type, "Posting Date")
        {
        }
        key(Key5; "Customer No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
        key(Key7; "Fault Reason Code")
        {
        }
        key(Key8; "Contract No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", Description, Quantity, "Location Code", "Unit of Measure Code")
        { }
    }

    var
        Currency: Record Currency;
        DimMgt: Codeunit DimensionManagement;
        CurrencyRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Shipment No. %1:';
#pragma warning restore AA0470
        Text001: Label 'The program cannot find this Service line.';
#pragma warning restore AA0074

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID",
          StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Service Shipment Line", 0, "Document No.", '', 0, "Line No.");
    end;

    procedure InsertInvLineFromShptLine(var ServiceLine: Record "Service Line")
    var
        ServiceInvHeader: Record "Service Header";
        ServiceOrderHeader: Record "Service Header";
        ServiceOrderLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        ServDocReg: Record "Service Document Register";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ServItemTrackingMgt: Codeunit "Serv. Item Tracking Mgt.";
        ExtTextLine: Boolean;
        NextLineNo: Integer;
    begin
        SetRange("Document No.", "Document No.");

        TempServiceLine := ServiceLine;
        if ServiceLine.Find('+') then
            NextLineNo := ServiceLine."Line No." + 10000
        else
            NextLineNo := 10000;

        if ServiceInvHeader."No." <> TempServiceLine."Document No." then
            ServiceInvHeader.Get(TempServiceLine."Document Type", TempServiceLine."Document No.");

        if ServiceLine."Shipment No." <> "Document No." then begin
            ServiceLine.Init();
            ServiceLine."Line No." := NextLineNo;
            ServiceLine."Document Type" := TempServiceLine."Document Type";
            ServiceLine."Document No." := TempServiceLine."Document No.";
            ServiceLine.Description := StrSubstNo(Text000, "Document No.");
            ServiceLine."Shipment No." := "Document No.";
            ServiceLine.Insert();
            NextLineNo := NextLineNo + 10000;
        end;

        OnBeforeInsertInvLineFromShptLineOnAfterInsertTextLine(ServiceLine, Rec, NextLineNo);

        TransferOldExtLines.ClearLineNumbers();

        repeat
            ExtTextLine := (TransferOldExtLines.GetNewLineNumber("Attached to Line No.") <> 0);

            if ServiceOrderLine.Get(ServiceOrderLine."Document Type"::Order, "Order No.", "Order Line No.") then begin
                if (ServiceOrderHeader."Document Type" <> ServiceOrderLine."Document Type"::Order) or
                   (ServiceOrderHeader."No." <> ServiceOrderLine."Document No.")
                then
                    ServiceOrderHeader.Get(ServiceOrderLine."Document Type"::Order, "Order No.");

                if ServiceInvHeader."Prices Including VAT" <> ServiceOrderHeader."Prices Including VAT" then
                    InitCurrency("Currency Code");

                if ServiceInvHeader."Prices Including VAT" then begin
                    if not ServiceOrderHeader."Prices Including VAT" then
                        ServiceOrderLine."Unit Price" :=
                          Round(
                            ServiceOrderLine."Unit Price" * (1 + ServiceOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                end else
                    if ServiceOrderHeader."Prices Including VAT" then
                        ServiceOrderLine."Unit Price" :=
                          Round(
                            ServiceOrderLine."Unit Price" / (1 + ServiceOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
            end else begin
                ServiceOrderHeader.Init();
                if ExtTextLine then begin
                    ServiceOrderLine.Init();
                    ServiceOrderLine."Line No." := "Order Line No.";
                    ServiceOrderLine.Description := Description;
                    ServiceOrderLine."Description 2" := "Description 2";
                end else
                    Error(Text001);
            end;

            ServiceLine := ServiceOrderLine;
            ServiceLine."Line No." := NextLineNo;
            ServiceLine."Document Type" := TempServiceLine."Document Type";
            ServiceLine."Document No." := TempServiceLine."Document No.";
            ServiceLine."Variant Code" := "Variant Code";
            ServiceLine."Location Code" := "Location Code";

            ServiceLine.Quantity := 0;
            ServiceLine."Quantity (Base)" := 0;
            ServiceLine."Outstanding Qty. (Base)" := 0;
            ServiceLine."Outstanding Quantity" := 0;
            ServiceLine."Quantity Shipped" := 0;
            ServiceLine."Qty. Shipped (Base)" := 0;
            ServiceLine."Quantity Invoiced" := 0;
            ServiceLine."Qty. Invoiced (Base)" := 0;
            ServiceLine."Quantity Consumed" := 0;
            ServiceLine."Qty. Consumed (Base)" := 0;
            ServiceLine."Qty. to Consume" := 0;

            ServiceLine."Shipment No." := "Document No.";
            ServiceLine."Shipment Line No." := "Line No.";
            ServiceLine."Order No." := "Order No.";

            if not ExtTextLine then
                ValidateServiceLineAmounts(ServiceLine, ServiceOrderLine, ServiceInvHeader);

            ServiceLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                ServiceOrderLine."Line No.",
                NextLineNo,
                ServiceOrderLine."Attached to Line No.");
            ServiceLine."Shortcut Dimension 1 Code" := ServiceOrderLine."Shortcut Dimension 1 Code";
            ServiceLine."Shortcut Dimension 2 Code" := ServiceOrderLine."Shortcut Dimension 2 Code";
            ServiceLine."Dimension Set ID" := ServiceOrderLine."Dimension Set ID";
            ServiceLine.Validate("Posting Date", ServiceInvHeader."Posting Date");

            OnBeforeServiceInvLineInsert(ServiceLine, ServiceOrderLine, Rec);
            ServiceLine.Insert();
            OnAfterServiceInvLineInsert(ServiceLine, ServiceOrderLine, Rec, NextLineNo);

            if (ServiceLine."Contract No." <> '') and (ServiceLine.Type <> ServiceLine.Type::" ") then
                case ServiceLine."Document Type" of
                    ServiceLine."Document Type"::Invoice:
                        ServDocReg.InsertServiceSalesDocument(
                          ServDocReg."Source Document Type"::Contract, ServiceLine."Contract No.",
                          ServDocReg."Destination Document Type"::Invoice, ServiceLine."Document No.");
                    ServiceLine."Document Type"::"Credit Memo":
                        ServDocReg.InsertServiceSalesDocument(
                          ServDocReg."Source Document Type"::Contract, ServiceLine."Contract No.",
                          ServDocReg."Destination Document Type"::"Credit Memo", ServiceLine."Document No.")
                end;

            ServItemTrackingMgt.CopyHandledItemTrkgToServLine(ServiceOrderLine, ServiceLine);

            NextLineNo := NextLineNo + 10000;
            if "Attached to Line No." = 0 then
                SetRange("Attached to Line No.", "Line No.");
        until (Next() = 0) or ("Attached to Line No." = 0);

        if ServiceOrderHeader.Get(ServiceOrderHeader."Document Type"::Order, "Order No.") then
            ServiceOrderHeader.Modify();
    end;

    local procedure ValidateServiceLineAmounts(var ServiceLine: Record "Service Line"; ServiceOrderLine: Record "Service Line"; ServiceInvHeader: Record "Service Header")
    begin
        ServiceLine.Validate(Quantity, Quantity - "Quantity Invoiced" - "Quantity Consumed");
        ServiceLine.Validate("Unit Price", ServiceOrderLine."Unit Price");
        ServiceLine."Allow Line Disc." := ServiceOrderLine."Allow Line Disc.";
        ServiceLine."Allow Invoice Disc." := ServiceOrderLine."Allow Invoice Disc.";
        ServiceLine.Validate("Line Discount %", ServiceOrderLine."Line Discount %");

        OnAfterValidateServiceLineAmounts(ServiceLine, ServiceOrderLine, ServiceInvHeader);
    end;

    local procedure GetServInvLines(var TempServiceInvoiceLine: Record "Service Invoice Line" temporary)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        TempServiceInvoiceLine.Reset();
        TempServiceInvoiceLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_No, "Document No.");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Service Shipment");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Line_No, "Line No.");
        ValueItemLedgerEntries.SetFilter(Item_Ledg_Invoice_Quantity, '<>0');
        ValueItemLedgerEntries.SetRange(Value_Entry_Type, Enum::"Cost Entry Type"::"Direct Cost");
        ValueItemLedgerEntries.SetFilter(Value_Entry_Invoiced_Qty, '<>0');
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Service Invoice");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if ServiceInvoiceLine.Get(ValueItemLedgerEntries.Value_Entry_Doc_No, ValueItemLedgerEntries.Value_Entry_Doc_Line_No) then begin
                TempServiceInvoiceLine.Init();
                TempServiceInvoiceLine := ServiceInvoiceLine;
                if TempServiceInvoiceLine.Insert() then;
            end;
    end;

    procedure FilterPstdDocLnItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.SetRange("Document No.", "Document No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Service Shipment");
        ItemLedgEntry.SetRange("Document Line No.", "Line No.");
    end;

    procedure ShowItemServInvLines()
    var
        TempServInvLine: Record "Service Invoice Line" temporary;
    begin
        if Type = Type::Item then begin
            GetServInvLines(TempServInvLine);
            PAGE.RunModal(PAGE::"Posted Service Invoice Lines", TempServInvLine);
        end;
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        if (Currency.Code = CurrencyCode) and CurrencyRead then
            exit;

        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision();
        CurrencyRead := true;
    end;

    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        ServShipmentHeader: Record "Service Shipment Header";
    begin
        if not ServShipmentHeader.Get("Document No.") then
            ServShipmentHeader.Init();
        if ServShipmentHeader."Prices Including VAT" then
            exit('2,1,' + GetFieldCaption(FieldNumber));
        exit('2,0,' + GetFieldCaption(FieldNumber));
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Service Shipment Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Posting Date", "Document No.");
        NavigateForm.Run();
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetServiceFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetServiceFilter());
            FilterGroup(0);
        end;
    end;

    procedure CopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line");
    begin
        ItemJournalLine."Item No." := Rec."No.";
        ItemJournalLine.Description := Rec.Description;
        ItemJournalLine."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
        ItemJournalLine."Gen. Prod. Posting Group" := Rec."Gen. Prod. Posting Group";
        ItemJournalLine."Inventory Posting Group" := Rec."Posting Group";
        ItemJournalLine."Location Code" := Rec."Location Code";
        ItemJournalLine."Unit of Measure Code" := Rec."Unit of Measure Code";
        ItemJournalLine."Qty. per Unit of Measure" := Rec."Qty. per Unit of Measure";
        ItemJournalLine."Variant Code" := Rec."Variant Code";
        ItemJournalLine."Bin Code" := Rec."Bin Code";
        ItemJournalLine."Shortcut Dimension 1 Code" := Rec."Shortcut Dimension 1 Code";
        ItemJournalLine."Shortcut Dimension 2 Code" := Rec."Shortcut Dimension 2 Code";
        ItemJournalLine."Dimension Set ID" := Rec."Dimension Set ID";
        ItemJournalLine."Entry/Exit Point" := Rec."Exit Point";
        ItemJournalLine."Value Entry Type" := ItemJournalLine."Value Entry Type"::"Direct Cost";
        ItemJournalLine."Transaction Type" := Rec."Transaction Type";
        ItemJournalLine."Transport Method" := Rec."Transport Method";
        ItemJournalLine.Area := Rec.Area;
        ItemJournalLine."Transaction Specification" := Rec."Transaction Specification";
        ItemJournalLine."Qty. per Unit of Measure" := Rec."Qty. per Unit of Measure";
        ItemJournalLine."Item Category Code" := Rec."Item Category Code";
        ItemJournalLine.Nonstock := Rec.Nonstock;
        ItemJournalLine."Return Reason Code" := Rec."Return Reason Code";

        OnAfterCopyToItemJnlLine(ItemJournalLine, Rec);
#if not CLEAN25
        ItemJournalLine.RunOnAfterCopyItemJnlLineFromServShptLine(ItemJournalLine, Rec);
#endif
    end;

    procedure CopyToItemJnlLineUndo(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine."Item No." := Rec."No.";
        ItemJournalLine."Posting Date" := Rec."Posting Date";
        ItemJournalLine."Order Date" := Rec."Order Date";
        ItemJournalLine."Inventory Posting Group" := Rec."Posting Group";
        ItemJournalLine."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
        ItemJournalLine."Gen. Prod. Posting Group" := Rec."Gen. Prod. Posting Group";
        ItemJournalLine."Location Code" := Rec."Location Code";
        ItemJournalLine."Variant Code" := Rec."Variant Code";
        ItemJournalLine."Bin Code" := Rec."Bin Code";
        ItemJournalLine."Entry/Exit Point" := Rec."Exit Point";
        ItemJournalLine."Shortcut Dimension 1 Code" := Rec."Shortcut Dimension 1 Code";
        ItemJournalLine."Shortcut Dimension 2 Code" := Rec."Shortcut Dimension 2 Code";
        ItemJournalLine."Dimension Set ID" := Rec."Dimension Set ID";
        ItemJournalLine."Value Entry Type" := ItemJournalLine."Value Entry Type"::"Direct Cost";
        ItemJournalLine."Item No." := Rec."No.";
        ItemJournalLine.Description := Rec.Description;
        ItemJournalLine."Location Code" := Rec."Location Code";
        ItemJournalLine."Variant Code" := Rec."Variant Code";
        ItemJournalLine."Transaction Type" := Rec."Transaction Type";
        ItemJournalLine."Transport Method" := Rec."Transport Method";
        ItemJournalLine.Area := Rec.Area;
        ItemJournalLine."Transaction Specification" := Rec."Transaction Specification";
        ItemJournalLine."Unit of Measure Code" := Rec."Unit of Measure Code";
        ItemJournalLine."Qty. per Unit of Measure" := Rec."Qty. per Unit of Measure";
        ItemJournalLine."Derived from Blanket Order" := false;
        ItemJournalLine."Item Category Code" := Rec."Item Category Code";
        ItemJournalLine.Nonstock := Rec.Nonstock;
        ItemJournalLine."Return Reason Code" := Rec."Return Reason Code";

        OnAfterCopyToItemJnlLineUndo(ItemJournalLine, Rec);
#if not CLEAN25
        ItemJournalLine.RunOnAfterCopyItemJnlLineFromServShptLineUndo(ItemJournalLine, Rec);
#endif
    end;

    procedure CopyToResJournalLine(var ResJournalLine: Record "Res. Journal Line")
    begin
        ResJournalLine."Posting Date" := Rec."Posting Date";
        ResJournalLine."Resource No." := Rec."No.";
        ResJournalLine.Description := Rec.Description;
        ResJournalLine."Work Type Code" := Rec."Work Type Code";
        ResJournalLine."Unit of Measure Code" := Rec."Unit of Measure Code";
        ResJournalLine."Qty. per Unit of Measure" := Rec."Qty. per Unit of Measure";
        ResJournalLine."Shortcut Dimension 1 Code" := Rec."Shortcut Dimension 1 Code";
        ResJournalLine."Shortcut Dimension 2 Code" := Rec."Shortcut Dimension 2 Code";
        ResJournalLine."Dimension Set ID" := Rec."Dimension Set ID";
        ResJournalLine."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
        ResJournalLine."Gen. Prod. Posting Group" := Rec."Gen. Prod. Posting Group";
        ResJournalLine."Entry Type" := ResJournalLine."Entry Type"::Usage;

        OnAfterCopyToResJournalLine(ResJournalLine, Rec);
    end;

    procedure TransferToItemEntryRelation(var ItemEntryRelation: Record "Item Entry Relation")
    begin
        ItemEntryRelation.SetSource(DATABASE::"Service Shipment Line", 0, Rec."Document No.", Rec."Line No.");
        ItemEntryRelation.SetOrderInfo(Rec."Order No.", Rec."Order Line No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceInvLineInsert(var ToServiceLine: Record "Service Line"; FromServiceLine: Record "Service Line"; ServiceShipmentLine: Record "Service Shipment Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateServiceLineAmounts(var ServiceLine: Record "Service Line"; ServiceOrderLine: Record "Service Line"; ServiceInvHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvLineInsert(var ToServiceLine: Record "Service Line"; FromServiceLine: Record "Service Line"; ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromShptLineOnAfterInsertTextLine(var ServiceLine: Record "Service Line"; ServiceShipmentLine: Record "Service Shipment Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToResJournalLine(var ResJournalLine: Record "Res. Journal Line"; ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToItemJnlLineUndo(var ItemJournalLine: Record "Item Journal Line"; ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;
}
