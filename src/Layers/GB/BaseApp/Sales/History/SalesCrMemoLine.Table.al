// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Intercompany.Partner;
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
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Reflection;
using System.Security.User;

table 115 "Sales Cr.Memo Line"
{
    Caption = 'Sales Cr.Memo Line';
    DrillDownPageID = "Posted Sales Credit Memo Lines";
    LookupPageID = "Posted Sales Credit Memo Lines";
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
            TableRelation = "Sales Cr.Memo Header";
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
            CaptionClass = GetCaptionClass(FieldNo("No."));
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
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
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
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
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
            TableRelation = "Sales Cr.Memo Line"."Line No." where("Document No." = field("Document No."));
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
        field(84; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
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
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
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
        field(97; "Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const("Blanket Order"));
        }
        field(98; "Blanket Order Line No."; Integer)
        {
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
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Difference';
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
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
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';
        }
        field(180; "Line Discount Calculation"; Option)
        {
            Caption = 'Line Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
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
            Editable = false;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1002; "Job Contract Entry No."; Integer)
        {
            Caption = 'Project Contract Entry No.';
            Editable = false;
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";
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
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
        }
        field(6600; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
            Editable = false;
        }
        field(6601; "Return Receipt Line No."; Integer)
        {
            Caption = 'Return Receipt Line No.';
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
#if not CLEANSCHEMA30
        field(10500; "Reverse Charge Item"; Boolean)
        {
            Caption = 'Reverse Charge Item';
            Editable = false;
            ObsoleteReason = 'Moved to Reverse Charge VAT GB app';
#if CLEAN27
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#endif
        }
        field(10501; "Reverse Charge"; Decimal)
        {
            Caption = 'Reverse Charge';
            ObsoleteReason = 'Moved to Reverse Charge VAT GB app';
#if CLEAN27
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#endif
        }
#endif
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
        }
        key(Key2; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key3; "Sell-to Customer No.")
        {
        }
        key(Key4; "Return Receipt No.", "Return Receipt Line No.")
        {
        }
        key(Key5; "Job Contract Entry No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
        key(Key7; "Order No.", "Order Line No.", "Posting Date")
        {
        }
        key(Key8; "Document No.", "Location Code")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "Amount Including VAT", "Inv. Discount Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        SalesDocLineComments: Record "Sales Comment Line";
        PostedDeferralHeader: Record "Posted Deferral Header";
    begin
        SalesDocLineComments.SetRange("Document Type", SalesDocLineComments."Document Type"::"Posted Credit Memo");
        SalesDocLineComments.SetRange("No.", "Document No.");
        SalesDocLineComments.SetRange("Document Line No.", "Line No.");
        if not SalesDocLineComments.IsEmpty() then
            SalesDocLineComments.DeleteAll();

        PostedDeferralHeader.DeleteHeader(
            "Deferral Document Type"::Sales.AsInteger(), '', '',
            SalesDocLineComments."Document Type"::"Posted Credit Memo".AsInteger(), "Document No.", "Line No.");
    end;

    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Currency: Record Currency;
        DimMgt: Codeunit DimensionManagement;
        DeferralUtilities: Codeunit "Deferral Utilities";

    procedure GetCurrencyCode(): Code[10]
    begin
        GetHeader();
        exit(SalesCrMemoHeader."Currency Code");
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(RowID1());
    end;

    procedure CalcVATAmountLines(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcVATAmountLines(Rec, SalesCrMemoHeader, TempVATAmountLine, IsHandled);
        if IsHandled then
            exit;

        TempVATAmountLine.DeleteAll();
        SetRange("Document No.", SalesCrMemoHeader."No.");
        if Find('-') then
            repeat
                TempVATAmountLine.Init();
                TempVATAmountLine.CopyFromSalesCrMemoLine(Rec);
                TempVATAmountLine.InsertLine();
            until Next() = 0;
    end;

    procedure GetLineAmountExclVAT(): Decimal
    begin
        GetHeader();
        if not SalesCrMemoHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    procedure GetLineAmountInclVAT(): Decimal
    begin
        GetHeader();
        if SalesCrMemoHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" * (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    procedure GetCreditMemoHeader(): Record "Sales Cr.Memo Header"
    begin
        GetHeader();
        exit(SalesCrMemoHeader);
    end;

    local procedure GetHeader()
    begin
        if SalesCrMemoHeader."No." = "Document No." then
            exit;
        if not SalesCrMemoHeader.Get("Document No.") then
            SalesCrMemoHeader.Init();

        if SalesCrMemoHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            if not Currency.Get(SalesCrMemoHeader."Currency Code") then
                Currency.InitRoundingPrecision();
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Sales Cr.Memo Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    begin
        GetHeader();
        case FieldNumber of
            FieldNo("No."):
                exit(StrSubstNo('3,%1', GetFieldCaption(FieldNumber)));
            else begin
                if SalesCrMemoHeader."Prices Including VAT" then
                    exit('2,1,' + GetFieldCaption(FieldNumber));
                exit('2,0,' + GetFieldCaption(FieldNumber));
            end
        end;
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Sales Cr.Memo Line",
            0, "Document No.", '', 0, "Line No."));
    end;

    procedure GetReturnRcptLines(var TempReturnReceiptLine: Record "Return Receipt Line" temporary)
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        TempReturnReceiptLine.Reset();
        TempReturnReceiptLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_No, "Document No.");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Credit Memo");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Line_No, "Line No.");
        ValueItemLedgerEntries.SetFilter(Value_Entry_Invoiced_Qty, '<>0');
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Return Receipt");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if ReturnReceiptLine.Get(ValueItemLedgerEntries.Item_Ledg_Document_No, ValueItemLedgerEntries.Item_Ledg_Document_Line_No) then begin
                TempReturnReceiptLine.Init();
                TempReturnReceiptLine := ReturnReceiptLine;
                if TempReturnReceiptLine.Insert() then;
            end;
    end;

    procedure GetItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SetQuantity: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        if SetQuantity then begin
            TempItemLedgEntry.Reset();
            TempItemLedgEntry.DeleteAll();

            if Type <> Type::Item then
                exit;
        end;

        FilterPstdDocLineValueEntries(ValueEntry);
        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
        if ValueEntry.FindSet() then
            repeat
                ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                TempItemLedgEntry := ItemLedgEntry;
                if SetQuantity then begin
                    TempItemLedgEntry.Quantity := ValueEntry."Invoiced Quantity";
                    if Abs(TempItemLedgEntry."Shipped Qty. Not Returned") > Abs(TempItemLedgEntry.Quantity) then
                        TempItemLedgEntry."Shipped Qty. Not Returned" := TempItemLedgEntry.Quantity;
                end;
                OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(TempItemLedgEntry, ValueEntry, SetQuantity);
                if TempItemLedgEntry.Insert() then;
            until ValueEntry.Next() = 0;
    end;

    internal procedure GetSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        CheckApplFromItemLedgEntry(ItemLedgerEntry);

        if ItemLedgerEntry."Entry No." = 0 then
            FindItemLedgerEntryFromItemApplicationEntry(ItemLedgerEntry);

        ValueEntry.SetLoadFields("Item Ledger Entry No.", "Item Ledger Entry Type", "Document Type", "Document No.", "Document Line No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        if ValueEntry.FindFirst() then
            SalesInvoiceLine.Get(ValueEntry."Document No.", ValueEntry."Document Line No.");
    end;

    local procedure CheckApplFromItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        if "Appl.-from Item Entry" = 0 then
            exit;

        TestField(Type, Type::Item);
        TestField(Quantity);
        ItemLedgerEntry.Get("Appl.-from Item Entry");
        ItemLedgerEntry.TestField(Positive, false);
        ItemLedgerEntry.TestField("Item No.", "No.");
        ItemLedgerEntry.TestField("Variant Code", "Variant Code");
        ItemLedgerEntry.CheckTrackingDoesNotExist(RecordId, FieldCaption("Appl.-from Item Entry"));
    end;

    procedure FilterPstdDocLineValueEntries(var ValueEntry: Record "Value Entry")
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", "Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo");
        ValueEntry.SetRange("Document Line No.", "Line No.");
    end;

    procedure ShowItemReturnRcptLines()
    var
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
    begin
        if Type = Type::Item then begin
            GetReturnRcptLines(TempReturnRcptLine);
            PAGE.RunModal(0, TempReturnRcptLine);
        end;
    end;

    procedure ShowLineComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.ShowComments(SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), "Document No.", "Line No.");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure InitFromSalesLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesLine: Record "Sales Line")
    begin
        Init();
        TransferFields(SalesLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := SalesCrMemoHeader."Posting Date";
        "Document No." := SalesCrMemoHeader."No.";
        Quantity := SalesLine."Qty. to Invoice";
        "Quantity (Base)" := SalesLine."Qty. to Invoice (Base)";

        OnAfterInitFromSalesLine(Rec, SalesCrMemoHeader, SalesLine);
    end;

    procedure ShowDeferrals()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, IsHandled);
        if IsHandled then
            exit;

        DeferralUtilities.OpenLineScheduleView(
            "Deferral Code", "Deferral Document Type"::Sales.AsInteger(), '', '',
            GetDocumentType(), "Document No.", "Line No.");
    end;

    procedure GetDocumentType(): Integer
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        exit(SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger())
    end;

    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
    end;

    procedure FormatType(): Text
    var
        SalesLine: Record "Sales Line";
    begin
        if Type = Type::" " then
            exit(SalesLine.FormatType());

        exit(Format(Type));
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

    local procedure FindItemLedgerEntryFromItemApplicationEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
        TempItemLedEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingDocMgmt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgmt.RetrieveEntriesFromPostedInvoice(TempItemLedEntry, RowID1());
        if TempItemLedEntry.IsEmpty then
            exit;

        TempItemLedEntry.FindFirst();
        if ItemApplicationEntry.AppliedFromEntryExists(TempItemLedEntry."Entry No.") then
            ItemLedgerEntry.Get(ItemApplicationEntry."Outbound Item Entry No.");
    end;

    internal procedure GetVATPct() VATPct: Decimal
    begin
        VATPct := "VAT %";
        OnAfterGetVATPct(Rec, VATPct);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATAmountLines(SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; ValueEntry: Record "Value Entry"; SetQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPct(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var VATPct: Decimal)
    begin
    end;
}
