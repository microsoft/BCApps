// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.IO;
using System.Security.User;

table 6661 "Return Receipt Line"
{
    Caption = 'Return Receipt Line';
    LookupPageID = "Posted Return Receipt Lines";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Return Receipt Header";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge";
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if (Type = const(Item)) "Inventory Posting Group"
            else
            if (Type = const("Fixed Asset")) "FA Posting Group";
        }
        field(10; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
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
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
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
        field(39; "Item Rcpt. Entry No."; Integer)
        {
            Caption = 'Item Rcpt. Entry No.';
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
            TableRelation = "Customer Price Group";
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
            TableRelation = "Return Receipt Line"."Line No." where("Document No." = field("Document No."));
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
            CalcFormula = lookup("Return Receipt Header"."Currency Code" where("No." = field("Document No.")));
            Caption = 'Currency Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Blanket Order No."; Code[20])
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Blanket Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const("Blanket Order"));
        }
        field(98; "Blanket Order Line No."; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Blanket Order Line No.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = const("Blanket Order"),
                                                           "Document No." = field("Blanket Order No."));
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(131; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
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
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1002; "Job Contract Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Project Contract Entry No.';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"),
                                            "Item Filter" = field("No."),
                                            "Variant Filter" = field("Variant Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
            ValidateTableRelation = true;
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = if (Type = const(Item)) "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure (Item Ref.)';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        field(5805; "Return Qty. Rcd. Not Invd."; Decimal)
        {
            Caption = 'Return Qty. Rcd. Not Invd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;
        }
        field(5812; "Item Charge Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Item Charge Base Amount';
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
            Editable = false;
        }
        field(6602; "Return Order No."; Code[20])
        {
            Caption = 'Return Order No.';
            Editable = false;
        }
        field(6603; "Return Order Line No."; Integer)
        {
            Caption = 'Return Order Line No.';
            Editable = false;
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
            InitValue = true;
        }
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        field(7012; "Sell-to Customer Name"; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Sell-to Customer No.")));
            Caption = 'Sell-to Customer Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12145; "Automatically Generated"; Boolean)
        {
            Caption = 'Automatically Generated';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Return Order No.", "Return Order Line No.")
        {
        }
        key(Key3; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key4; "Item Rcpt. Entry No.")
        {
        }
        key(Key5; "Bill-to Customer No.")
        {
        }
        key(Key6; "Sell-to Customer No.")
        {
        }
        key(Key7; "Appl.-from Item Entry")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        SalesDocLineComments: Record "Sales Comment Line";
    begin
        SalesDocLineComments.SetRange("Document Type", SalesDocLineComments."Document Type"::"Posted Return Receipt");
        SalesDocLineComments.SetRange("No.", "Document No.");
        SalesDocLineComments.SetRange("Document Line No.", "Line No.");
        if not SalesDocLineComments.IsEmpty() then
            SalesDocLineComments.DeleteAll();
    end;

    var
        Currency: Record Currency;
        ReturnRcptHeader: Record "Return Receipt Header";
        TranslationHelper: Codeunit "Translation Helper";
        CurrencyRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Return Receipt No. %1:';
#pragma warning restore AA0470
        Text001: Label 'The program cannot find this purchase line.';
#pragma warning restore AA0074

    procedure GetCurrencyCode(): Code[10]
    begin
        if "Document No." = ReturnRcptHeader."No." then
            exit(ReturnRcptHeader."Currency Code");
        if ReturnRcptHeader.Get("Document No.") then
            exit(ReturnRcptHeader."Currency Code");
        exit('');
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Return Receipt Line", 0, "Document No.", '', 0, "Line No.");
    end;

    procedure InsertInvLineFromRetRcptLine(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExtTextLine: Boolean;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInsertInvLineFromRetRcptLine(Rec, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SetRange("Document No.", "Document No.");

        TempSalesLine := SalesLine;
        if SalesLine.Find('+') then
            NextLineNo := SalesLine."Line No." + 10000
        else
            NextLineNo := 10000;

        IsHandled := false;
        OnInsertInvLineFromRetRcptLineOnBeforeSalesHeaderGet(SalesHeader, Rec, TempSalesLine, IsHandled);
        if not IsHandled then
            if SalesHeader."No." <> TempSalesLine."Document No." then
                SalesHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.");

        OnInsertInvLineFromRetRcptLineOnAfterSalesHeaderGet(Rec, SalesHeader, SalesLine);

        if SalesLine."Return Receipt No." <> "Document No." then begin
            OnInsertInvLineFromRetRcptLineOnBeforeInitSalesLine(Rec, SalesLine);
            SalesLine.Init();
            SalesLine."Line No." := NextLineNo;
            SalesLine."Document Type" := TempSalesLine."Document Type";
            SalesLine."Document No." := TempSalesLine."Document No.";
            TranslationHelper.SetGlobalLanguageByCode(SalesHeader."Language Code");
            SalesLine.Description := StrSubstNo(Text000, "Document No.");
            TranslationHelper.RestoreGlobalLanguage();
            IsHandled := false;
            OnBeforeInsertInvLineFromRetRcptLineBeforeInsertTextLine(Rec, SalesLine, NextLineNo, IsHandled);
            if not IsHandled then begin
                SalesLine.Insert();
                OnAfterDescriptionSalesLineInsert(SalesLine, Rec, NextLineNo);
                NextLineNo := NextLineNo + 10000;
            end;
        end;

        TransferOldExtLines.ClearLineNumbers();
        SalesSetup.Get();
        repeat
            ExtTextLine := (Type = Type::" ") and ("Attached to Line No." <> 0) and (Quantity = 0);
            if ExtTextLine then
                TransferOldExtLines.GetNewLineNumber("Attached to Line No.")
            else
                "Attached to Line No." := 0;

            if not SalesOrderLine.Get(
                 SalesOrderLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.")
            then begin
                if ExtTextLine then begin
                    SalesOrderLine.Init();
                    SalesOrderLine."Line No." := "Return Order Line No.";
                    SalesOrderLine.Description := Description;
                    SalesOrderLine."Description 2" := "Description 2";
                end else begin
                    OnInsertInvLineFromRetRcptLineOnBeforeNoExtTextLineError(Rec);
                    Error(Text001);
                end
            end else begin
                if (SalesHeader2."Document Type" <> SalesOrderLine."Document Type"::"Return Order") or
                   (SalesHeader2."No." <> SalesOrderLine."Document No.")
                then
                    SalesHeader2.Get(SalesOrderLine."Document Type"::"Return Order", "Return Order No.");

                InitCurrency("Currency Code");

                if SalesHeader."Prices Including VAT" then begin
                    if not SalesHeader2."Prices Including VAT" then
                        SalesOrderLine."Unit Price" :=
                          Round(
                            SalesOrderLine."Unit Price" * (1 + SalesOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                end else
                    if SalesHeader2."Prices Including VAT" then
                        SalesOrderLine."Unit Price" :=
                          Round(
                            SalesOrderLine."Unit Price" / (1 + SalesOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
            end;
            OnInsertInvLineFromRetRcptLineOnAfterCalcUnitPrice(Rec, SalesHeader, SalesHeader2, SalesLine, SalesOrderLine, Currency);

            SalesLine := SalesOrderLine;
            SalesLine."Line No." := NextLineNo;
            SalesLine."Document Type" := TempSalesLine."Document Type";
            SalesLine."Document No." := TempSalesLine."Document No.";
            SalesLine."Variant Code" := "Variant Code";
            SalesLine."Location Code" := "Location Code";
            SalesLine."Return Reason Code" := "Return Reason Code";
            SalesLine."Quantity (Base)" := 0;
            SalesLine.Quantity := 0;
            SalesLine."Outstanding Qty. (Base)" := 0;
            SalesLine."Outstanding Quantity" := 0;
            SalesLine."Return Qty. Received" := 0;
            SalesLine."Return Qty. Received (Base)" := 0;
            SalesLine."Quantity Invoiced" := 0;
            SalesLine."Qty. Invoiced (Base)" := 0;
            SalesLine."Drop Shipment" := false;
            SalesLine."Return Receipt No." := "Document No.";
            SalesLine."Return Receipt Line No." := "Line No.";
            SalesLine."Appl.-to Item Entry" := 0;
            SalesLine."Appl.-from Item Entry" := 0;
            OnAfterCopyFieldsFromReturnReceiptLine(Rec, SalesLine);

            if not ExtTextLine then begin
                IsHandled := false;
                OnInsertInvLineFromRetRcptLineOnBeforeValidateSalesLineQuantity(Rec, SalesLine, IsHandled, SalesHeader);
                if not IsHandled then
                    SalesLine.Validate(Quantity, Quantity - "Quantity Invoiced");

                CopySalesLinePriceAndDiscountFromSalesOrderLine(SalesLine, SalesOrderLine);
                OnOnInsertInvLineFromRetRcptLineOnAfterCopySalesLinePriceAndDiscount(SalesLine, SalesOrderLine, Rec, SalesHeader);
            end;
            SalesLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                SalesOrderLine."Line No.",
                NextLineNo,
                "Attached to Line No.");
            SalesLine."Shortcut Dimension 1 Code" := SalesOrderLine."Shortcut Dimension 1 Code";
            SalesLine."Shortcut Dimension 2 Code" := SalesOrderLine."Shortcut Dimension 2 Code";
            SalesLine."Dimension Set ID" := SalesOrderLine."Dimension Set ID";

            IsHandled := false;
            OnBeforeInsertInvLineFromRetRcptLine(SalesLine, SalesOrderLine, Rec, IsHandled, NextLineNo);
            if not IsHandled then
                SalesLine.Insert();
            IsHandled := false;
            OnAftertInsertInvLineFromRetRcptLine(SalesLine, SalesOrderLine, Rec, IsHandled);
            if not IsHandled then
                ItemTrackingMgt.CopyHandledItemTrkgToInvLine(SalesOrderLine, SalesLine);

            NextLineNo := NextLineNo + 10000;
            if "Attached to Line No." = 0 then begin
                SetRange("Attached to Line No.", "Line No.");
                SetRange(Type, Type::" ");
            end;

        until (Next() = 0) or ("Attached to Line No." = 0);

        IsHandled := false;
        OnInsertInvLineFromRetRcptLineOnAfterInsertAllLines(Rec, SalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, "Return Order No.") then
            if not SalesOrderHeader."Get Shipment Used" then begin
                SalesOrderHeader."Get Shipment Used" := true;
                SalesOrderHeader.Modify();
            end;
    end;

    local procedure CopySalesLinePriceAndDiscountFromSalesOrderLine(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesLinePriceAndDiscountFromSalesOrderLine(SalesLine, SalesOrderLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate("Unit Price", SalesOrderLine."Unit Price");
        SalesLine."Allow Line Disc." := SalesOrderLine."Allow Line Disc.";
        SalesLine."Allow Invoice Disc." := SalesOrderLine."Allow Invoice Disc.";
        SalesLine.Validate("Line Discount %", SalesOrderLine."Line Discount %");
        if SalesOrderLine.Quantity = 0 then
            SalesLine.Validate("Inv. Discount Amount", 0)
        else
            SalesLine.Validate(
              "Inv. Discount Amount",
              Round(
                SalesOrderLine."Inv. Discount Amount" * SalesLine.Quantity / SalesOrderLine.Quantity,
                Currency."Amount Rounding Precision"));
    end;

    procedure GetSalesCrMemoLines(var TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        TempSalesCrMemoLine.Reset();
        TempSalesCrMemoLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_No, "Document No.");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Return Receipt");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Line_No, "Line No.");
        ValueItemLedgerEntries.SetFilter(Item_Ledg_Invoice_Quantity, '<>0');
        ValueItemLedgerEntries.SetRange(Value_Entry_Type, Enum::"Cost Entry Type"::"Direct Cost");
        ValueItemLedgerEntries.SetFilter(Value_Entry_Invoiced_Qty, '<>0');
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Credit Memo");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if SalesCrMemoLine.Get(ValueItemLedgerEntries.Value_Entry_Doc_No, ValueItemLedgerEntries.Value_Entry_Doc_Line_No) then begin
                TempSalesCrMemoLine.Init();
                TempSalesCrMemoLine := SalesCrMemoLine;
                if TempSalesCrMemoLine.Insert() then;
            end;
    end;

    procedure FilterPstdDocLnItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Document No.");
        ItemLedgEntry.SetRange("Document No.", "Document No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Return Receipt");
        ItemLedgEntry.SetRange("Document Line No.", "Line No.");
    end;

    procedure ShowItemSalesCrMemoLines()
    var
        TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary;
    begin
        if Type = Type::Item then begin
            GetSalesCrMemoLines(TempSalesCrMemoLine);
            PAGE.RunModal(0, TempSalesCrMemoLine);
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

    procedure ShowLineComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.ShowComments(
            SalesCommentLine."Document Type"::"Posted Return Receipt".AsInteger(), "Document No.", "Line No.");
    end;

    procedure InitFromSalesLine(ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line")
    begin
        Init();
        TransferFields(SalesLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := ReturnRcptHeader."Posting Date";
        "Document No." := ReturnRcptHeader."No.";
        Quantity := SalesLine."Return Qty. to Receive";
        "Quantity (Base)" := SalesLine."Return Qty. to Receive (Base)";
        if Abs(SalesLine."Qty. to Invoice") > Abs(SalesLine."Return Qty. to Receive") then begin
            "Quantity Invoiced" := SalesLine."Return Qty. to Receive";
            "Qty. Invoiced (Base)" := SalesLine."Return Qty. to Receive (Base)";
        end else begin
            "Quantity Invoiced" := SalesLine."Qty. to Invoice";
            "Qty. Invoiced (Base)" := SalesLine."Qty. to Invoice (Base)";
        end;
        "Return Qty. Rcd. Not Invd." :=
          Quantity - "Quantity Invoiced";
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then begin
            "Return Order No." := SalesLine."Document No.";
            "Return Order Line No." := SalesLine."Line No.";
        end;

        OnAfterInitFromSalesLine(ReturnRcptHeader, SalesLine, Rec);
    end;

    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
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

        if UserSetupMgt.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter());
            FilterGroup(0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line"; var ReturnRcptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAftertInsertInvLineFromRetRcptLine(var SalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line"; var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesLinePriceAndDiscountFromSalesOrderLine(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromRetRcptLine(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean; NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromRetRcptLineBeforeInsertTextLine(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnBeforeInitSalesLine(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnAfterInsertAllLines(ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnBeforeValidateSalesLineQuantity(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDescriptionSalesLineInsert(var SalesLine: Record "Sales Line"; ReturnReceiptLine: Record "Return Receipt Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnInsertInvLineFromRetRcptLineOnAfterCopySalesLinePriceAndDiscount(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnAfterSalesHeaderGet(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnBeforeNoExtTextLineError(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnAfterCalcUnitPrice(var ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnBeforeSalesHeaderGet(var SalesHeader: Record "Sales Header"; ReturnReceiptLine: Record "Return Receipt Line"; var TempSalesLine: Record "Sales Line" temporary; var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemTrackingLines(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;
}
