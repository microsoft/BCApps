// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;

table 5802 "Value Entry"
{
    Caption = 'Value Entry';
    DrillDownPageID = "Value Entries";
    LookupPageID = "Value Entries";
    Permissions = TableData "Value Entry" = ri;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Item Ledger Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Item Ledger Entry Type';
        }
        field(5; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(9; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(10; "Source Posting Group"; Code[20])
        {
            Caption = 'Source Posting Group';
            TableRelation = if ("Source Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Source Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Source Type" = const(Item)) "Inventory Posting Group";
        }
        field(11; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(12; "Valued Quantity"; Decimal)
        {
            Caption = 'Valued Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Item Ledger Entry Quantity"; Decimal)
        {
            Caption = 'Item Ledger Entry Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Cost per Unit"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Cost per Unit';
        }
        field(17; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales Amount (Actual)';
        }
        field(20; "Item Register No."; Integer)
        {
            Caption = 'Item Register No.';
            Editable = false;
            TableRelation = "Item Register";
        }
        field(21; "SIFT Bucket No."; Integer)
        {
            Caption = 'SIFT Bucket No.';
            ToolTip = 'Specifies an automatically generated number that is used by the system to enable better concurrency.';
            Editable = false;
        }
        field(22; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(23; "Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Discount Amount';
        }
        field(24; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(25; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(28; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';
        }
        field(33; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(34; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(41; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
        }
        field(43; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount (Actual)';
        }
        field(45; "Cost Posted to G/L"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Posted to G/L';
        }
        field(46; "Reason Code"; Code[10])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(47; "Drop Shipment"; Boolean)
        {
            Caption = 'Drop Shipment';
        }
        field(48; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(57; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(58; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(68; "Cost Amount (Actual) (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Cost Amount (Actual) (ACY)';
        }
        field(70; "Cost Posted to G/L (ACY)"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Cost Posted to G/L (ACY)';
        }
        field(72; "Cost per Unit (ACY)"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Cost per Unit (ACY)';
        }
        field(79; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
        }
        field(80; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(86; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            Editable = false;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            Editable = false;
        }
        field(98; "Expected Cost"; Boolean)
        {
            Caption = 'Expected Cost';
        }
        field(99; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            TableRelation = "Item Charge";
        }
        field(100; "Valued By Average Cost"; Boolean)
        {
            Caption = 'Valued By Average Cost';
        }
        field(102; "Partial Revaluation"; Boolean)
        {
            Caption = 'Partial Revaluation';
        }
        field(103; Inventoriable; Boolean)
        {
            Caption = 'Inventoriable';
        }
        field(104; "Valuation Date"; Date)
        {
            Caption = 'Valuation Date';
        }
        field(105; "Entry Type"; Enum "Cost Entry Type")
        {
            Caption = 'Entry Type';
            Editable = false;
        }
        field(106; "Variance Type"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type';
            Editable = false;
        }
        field(148; "Purchase Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Purchase Amount (Actual)';
        }
        field(149; "Purchase Amount (Expected)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatType = 1;
            Caption = 'Purchase Amount (Expected)';
        }
        field(150; "Sales Amount (Expected)"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            AutoFormatType = 1;
            Caption = 'Sales Amount (Expected)';
        }
        field(151; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount (Expected)';
        }
        field(152; "Cost Amount (Non-Invtbl.)"; Decimal)
        {
            AccessByPermission = TableData "Item Charge" = R;
            AutoFormatType = 1;
            Caption = 'Cost Amount (Non-Invtbl.)';
        }
        field(156; "Cost Amount (Expected) (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Cost Amount (Expected) (ACY)';
        }
        field(157; "Cost Amount (Non-Invtbl.)(ACY)"; Decimal)
        {
            AccessByPermission = TableData "Item Charge" = R;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Cost Amount (Non-Invtbl.)(ACY)';
        }
        field(158; "Expected Cost Posted to G/L"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Cost Posted to G/L';
        }
        field(159; "Exp. Cost Posted to G/L (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Exp. Cost Posted to G/L (ACY)';
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
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(1000; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No.";
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1002; "Job Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Project Ledger Entry No.';
            TableRelation = "Job Ledger Entry"."Entry No.";
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5818; Adjustment; Boolean)
        {
            Caption = 'Adjustment';
            Editable = false;
        }
        field(5819; "Average Cost Exception"; Boolean)
        {
            Caption = 'Average Cost Exception';
        }
        field(5831; "Capacity Ledger Entry No."; Integer)
        {
            Caption = 'Capacity Ledger Entry No.';
            TableRelation = Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        }
        field(5832; Type; Enum Microsoft.Manufacturing.Capacity."Capacity Type Journal")
        {
            Caption = 'Type';
        }
        field(5834; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Resource)) Resource;
        }
        field(6602; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(6603; "Item Description"; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Caption = 'Item Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item Ledger Entry No.", "Entry Type")
        {
            IncludedFields = "Invoiced Quantity", "Sales Amount (Expected)", "Sales Amount (Actual)", "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)", "Cost Amount (Non-Invtbl.)(ACY)", "Purchase Amount (Actual)", "Purchase Amount (Expected)", "Discount Amount", "Item Charge No.", "Variance Type", "Applies-to Entry", Inventoriable;
        }
        key(Key3; "Item Ledger Entry No.", "Document No.", "Document Line No.")
        {
            IncludedFields = "Invoiced Quantity", "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)", "Entry Type", "Expected Cost", "Item Charge No.";
        }
        key(Key5; "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type", "Item Charge No.", "Location Code", "Variant Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Source Type", "Source No.", "SIFT Bucket No.")
        {
            SumIndexFields = "Invoiced Quantity", "Sales Amount (Expected)", "Sales Amount (Actual)", "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)", "Purchase Amount (Actual)", "Expected Cost Posted to G/L", "Cost Posted to G/L", "Item Ledger Entry Quantity";
        }
        key(Key6; "Document No.")
        {
        }
        key(Key7; "Item No.", "Valuation Date", "Location Code", "Variant Code", "SIFT Bucket No.")
        {
            IncludedFields = "Item Ledger Entry Type";
            SumIndexFields = "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)", "Item Ledger Entry Quantity", "Invoiced Quantity";
        }
        key(Key8; "Source Type", "Source No.", "Item No.", "Posting Date", "Entry Type", Adjustment, "Item Ledger Entry Type")
        {
            IncludedFields = "Discount Amount", "Cost Amount (Non-Invtbl.)", "Cost Amount (Actual)", "Cost Amount (Expected)", "Sales Amount (Actual)", "Sales Amount (Expected)", "Invoiced Quantity";
        }
        key(Key9; "Item Charge No.", "Inventory Posting Group", "Item No.")
        {
        }
        key(Key10; "Capacity Ledger Entry No.", "Entry Type")
        {
            IncludedFields = "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)";
        }
        key(Key11; "Order Type", "Order No.", "Order Line No.")
        {
            IncludedFields = "Item No.", "Valuation Date", "Item Ledger Entry Type", "Variant Code", "Location Code";
        }
        key(Key13; "Job No.", "Job Task No.", "Document No.")
        {
        }
        key(Key14; "Item Ledger Entry Type", "Posting Date", "Item No.", "Inventory Posting Group", "Dimension Set ID")
        {
            IncludedFields = "Invoiced Quantity", "Sales Amount (Actual)", "Purchase Amount (Actual)";
        }
        key(Key15; "Item Ledger Entry No.", "Valuation Date", "Posting Date")
        {
            IncludedFields = "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)", "Valued Quantity", "Expected Cost", "Entry Type";
        }
        key(Key16; "Location Code", "Inventory Posting Group")
        {
        }
        key(Key17; "Item Ledger Entry Type", "Order No.", "Valuation Date")
        {
        }
        key(Key18; "Item No.", "Item Ledger Entry Type", "Order Type", "Order No.", "Order Line No.")
        {
        }
        key(Key19; "Document No.", "Document Line No.", "Document Type")
        {
            IncludedFields = "Cost Amount (Actual)", "Entry Type";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Item Ledger Entry Type", "Item Ledger Entry No.", "Item No.", "Posting Date", "Source No.", "Document No.")
        {
        }
    }

    var
        GLSetup: Record "General Ledger Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
        GLSetupRead: Boolean;

    trigger OnInsert()
    begin
        Rec."SIFT Bucket No." := Rec."Item Register No." mod 5;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Value Entry", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Value Entry"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Value Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure GetValuationDate(): Date
    begin
        if "Valuation Date" < "Posting Date" then
            exit("Posting Date");
        exit("Valuation Date");
    end;

    procedure AddCost(InvtAdjmtBuffer: Record "Inventory Adjustment Buffer")
    begin
        OnBeforeAddCost(Rec, InvtAdjmtBuffer);

        "Cost Amount (Expected)" := "Cost Amount (Expected)" + InvtAdjmtBuffer."Cost Amount (Expected)";
        "Cost Amount (Expected) (ACY)" := "Cost Amount (Expected) (ACY)" + InvtAdjmtBuffer."Cost Amount (Expected) (ACY)";
        "Cost Amount (Actual)" := "Cost Amount (Actual)" + InvtAdjmtBuffer."Cost Amount (Actual)";
        "Cost Amount (Actual) (ACY)" := "Cost Amount (Actual) (ACY)" + InvtAdjmtBuffer."Cost Amount (Actual) (ACY)";
    end;

    procedure SumCostsTillValuationDate(var ValueEntry: Record "Value Entry")
    var
        AccountingPeriod: Record "Accounting Period";
        PrevValueEntrySum: Record "Value Entry";
        Item: Record Item;
        FromDate: Date;
        ToDate: Date;
        CostCalcIsChanged: Boolean;
        QtyFactor: Decimal;
    begin
        Item.Get(ValueEntry."Item No.");
        OnSumCostsTillValuationDateOnAfterGetItem(Item, ValueEntry);
        if Item."Costing Method" = Item."Costing Method"::Average then
            ToDate := GetAvgToDate(ValueEntry."Valuation Date")
        else
            ToDate := ValueEntry."Valuation Date";

        repeat
            if Item."Costing Method" = Item."Costing Method"::Average then
                FromDate := GetAvgFromDate(ToDate, AccountingPeriod, CostCalcIsChanged)
            else
                FromDate := 0D;

            QtyFactor := 1;
            Reset();
            SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code");
            SetRange("Item No.", ValueEntry."Item No.");
            SetRange("Valuation Date", FromDate, ToDate);
            OnSumCostsTillValuationDateOnAfterSetFilters(Rec, ValueEntry, Item);
            CheckApplyLocationVariantFilters(AccountingPeriod, ValueEntry, Item, CostCalcIsChanged, QtyFactor, FromDate, ToDate);

            CalcSums(
              "Item Ledger Entry Quantity", "Invoiced Quantity",
              "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)",
              "Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");
            OnSumCostsTillValuationDateOnAfterCalcSums(Rec);

            "Item Ledger Entry Quantity" :=
              Round("Item Ledger Entry Quantity" * QtyFactor, UOMMgt.QtyRndPrecision()) + PrevValueEntrySum."Item Ledger Entry Quantity";
            "Invoiced Quantity" :=
              Round("Invoiced Quantity" * QtyFactor, UOMMgt.QtyRndPrecision()) + PrevValueEntrySum."Invoiced Quantity";
            "Cost Amount (Actual)" :=
              "Cost Amount (Actual)" * QtyFactor + PrevValueEntrySum."Cost Amount (Actual)";
            "Cost Amount (Expected)" :=
              "Cost Amount (Expected)" * QtyFactor + PrevValueEntrySum."Cost Amount (Expected)";
            "Cost Amount (Expected) (ACY)" :=
              "Cost Amount (Expected) (ACY)" * QtyFactor + PrevValueEntrySum."Cost Amount (Expected) (ACY)";
            "Cost Amount (Actual) (ACY)" :=
              "Cost Amount (Actual) (ACY)" * QtyFactor + PrevValueEntrySum."Cost Amount (Actual) (ACY)";
            OnSumCostsTillValuationDateOnAfterSetCostAmounts(Rec, PrevValueEntrySum, QtyFactor);
            PrevValueEntrySum := Rec;

            if FromDate <> 0D then
                ToDate := CalcDate('<-1D>', FromDate);
        until FromDate = 0D;
    end;

    local procedure CheckApplyLocationVariantFilters(AccountingPeriod: Record "Accounting Period"; var ValueEntry: Record "Value Entry"; Item: Record Item; CostCalcIsChanged: Boolean; var QtyFactor: Decimal; FromDate: Date; ToDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckApplyLocationVariantFilters(Rec, AccountingPeriod, ValueEntry, IsHandled, Item, CostCalcIsChanged, QtyFactor, FromDate, ToDate);
        if IsHandled then
            exit;

        if (AccountingPeriod."Average Cost Calc. Type" =
            AccountingPeriod."Average Cost Calc. Type"::"Item & Location & Variant") or
           (Item."Costing Method" <> Item."Costing Method"::Average)
        then begin
            SetRange("Location Code", ValueEntry."Location Code");
            SetRange("Variant Code", ValueEntry."Variant Code");
        end else
            if CostCalcIsChanged then
                QtyFactor := ValueEntry.CalcQtyFactor(FromDate, ToDate);
    end;

    procedure CalcItemLedgEntryCost(ItemLedgEntryNo: Integer; Expected: Boolean)
    var
        ItemLedgEntryQty: Decimal;
        CostAmtActual: Decimal;
        CostAmtActualACY: Decimal;
        CostAmtExpected: Decimal;
        CostAmtExpectedACY: Decimal;
        IsHandled: Boolean;
    begin
        Ishandled := false;
        OnBeforeCalcItemLedgEntryCost(Rec, ItemLedgEntryNo, Expected, IsHandled);
        if IsHandled then
            exit;

        Reset();
        SetCurrentKey("Item Ledger Entry No.");
        SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if Find('-') then
            repeat
                if "Expected Cost" = Expected then begin
                    ItemLedgEntryQty := ItemLedgEntryQty + "Item Ledger Entry Quantity";
                    CostAmtActual := CostAmtActual + "Cost Amount (Actual)";
                    CostAmtActualACY := CostAmtActualACY + "Cost Amount (Actual) (ACY)";
                    CostAmtExpected := CostAmtExpected + "Cost Amount (Expected)";
                    CostAmtExpectedACY := CostAmtExpectedACY + "Cost Amount (Expected) (ACY)";
                end;
            until Next() = 0;

        "Item Ledger Entry Quantity" := ItemLedgEntryQty;
        "Cost Amount (Actual)" := CostAmtActual;
        "Cost Amount (Actual) (ACY)" := CostAmtActualACY;
        "Cost Amount (Expected)" := CostAmtExpected;
        "Cost Amount (Expected) (ACY)" := CostAmtExpectedACY;
    end;

    procedure NotInvdRevaluationExists(ItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        SetRange("Entry Type", "Entry Type"::Revaluation);
        SetRange("Applies-to Entry", 0);
        exit(FindSet());
    end;

    procedure CalcQtyFactor(FromDate: Date; ToDate: Date) QtyFactor: Decimal
    var
        ValueEntry2: Record "Value Entry";
    begin
        ValueEntry2.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry2.SetRange("Item No.", "Item No.");
        ValueEntry2.SetRange("Valuation Date", FromDate, ToDate);
        ValueEntry2.SetRange("Location Code", "Location Code");
        ValueEntry2.SetRange("Variant Code", "Variant Code");
        ValueEntry2.CalcSums("Item Ledger Entry Quantity");
        QtyFactor := ValueEntry2."Item Ledger Entry Quantity";

        if QtyFactor = 0 then
            exit(QtyFactor);

        ValueEntry2.SetRange("Location Code");
        ValueEntry2.SetRange("Variant Code");
        ValueEntry2.CalcSums("Item Ledger Entry Quantity");
        if ValueEntry2."Item Ledger Entry Quantity" <> 0 then
            QtyFactor := QtyFactor / ValueEntry2."Item Ledger Entry Quantity";

        exit(QtyFactor);
    end;

    procedure ShowGL()
    var
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
        GLEntry: Record "G/L Entry";
        TempGLEntry: Record "G/L Entry" temporary;
    begin
        GLItemLedgRelation.SetCurrentKey("Value Entry No.");
        GLItemLedgRelation.SetRange("Value Entry No.", "Entry No.");
        if GLItemLedgRelation.FindSet() then
            repeat
                OnShowGLOnBeforeCopyToTempGLEntry(GLEntry, GLItemLedgRelation);
                GLEntry.Get(GLItemLedgRelation."G/L Entry No.");
                TempGLEntry.Init();
                TempGLEntry := GLEntry;
                TempGLEntry.Insert();
            until GLItemLedgRelation.Next() = 0;

        PAGE.RunModal(0, TempGLEntry);
    end;

#if not CLEAN27
    [Obsolete('Moved to the Inventory Adjustment codeunit', '27.0')]
    procedure IsAvgCostException(IsAvgCostCalcTypeItem: Boolean): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        SearchedItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        if "Partial Revaluation" then
            exit(true);
        if "Item Charge No." <> '' then
            exit(true);

        ItemLedgEntry.Get("Item Ledger Entry No.");
        if ItemLedgEntry.Positive then
            exit(false);

        SearchedItemLedgerEntry.SetRange("Item No.", "Item No.");
        SearchedItemLedgerEntry.SetRange(Positive, true);
        if IsAvgCostCalcTypeItem then begin
            SearchedItemLedgerEntry.SetRange("Location Code", "Location Code");
            SearchedItemLedgerEntry.SetRange("Variant Code", "Variant Code");
        end;
        ItemApplnEntry.SetSearchedItemLedgerEntry(SearchedItemLedgerEntry);
        ItemApplnEntry.GetVisitedEntries(ItemLedgEntry, TempItemLedgEntry, true);
        TempItemLedgEntry.CopyFilters(SearchedItemLedgerEntry);
        exit(not TempItemLedgEntry.IsEmpty());
    end;
#endif

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo('%1 %2', TableCaption(), "Entry No."), 1, 250));
    end;

    procedure GetAvgToDate(ToDate: Date): Date
    var
        CalendarPeriod: Record Date;
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        CalendarPeriod."Period Start" := ToDate;
        AvgCostEntryPointHandler.GetValuationPeriod(CalendarPeriod, ToDate);
        exit(CalendarPeriod."Period End");
    end;

    procedure GetAvgFromDate(ToDate: Date; var AccountingPeriod: Record "Accounting Period"; var CostCalcIsChanged: Boolean) FromDate: Date
    var
        PrevAccountingPeriod: Record "Accounting Period";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        if PrevAccountingPeriod.IsEmpty() then begin
            AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, ToDate);
            FromDate := 0D;
            exit;
        end;

        FromDate := ToDate;
        AccountingPeriod.SetRange("Starting Date", 0D, ToDate);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        if not AccountingPeriod.Find('+') then begin
            AccountingPeriod.SetRange("Starting Date");
            AccountingPeriod.Find('-');
        end;

        while (FromDate = ToDate) and (FromDate <> 0D) do begin
            PrevAccountingPeriod := AccountingPeriod;
            case true of
                AccountingPeriod."Average Cost Calc. Type" = AccountingPeriod."Average Cost Calc. Type"::Item:
                    FromDate := 0D;
                AccountingPeriod.Next(-1) = 0:
                    FromDate := 0D;
                AccountingPeriod."Average Cost Calc. Type" <> PrevAccountingPeriod."Average Cost Calc. Type":
                    begin
                        AccountingPeriod := PrevAccountingPeriod;
                        FromDate := PrevAccountingPeriod."Starting Date";
                        CostCalcIsChanged := true;
                        exit;
                    end;
            end;
        end;
        AccountingPeriod := PrevAccountingPeriod;
    end;

    procedure FindFirstValueEntryByItemLedgerEntryNo(ItemLedgerEntryNo: Integer)
    begin
        Reset();
        SetCurrentKey("Item Ledger Entry No.", "Entry No.");
        SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        FindFirst();
    end;

    procedure IsInbound(): Boolean
    begin
        if (("Item Ledger Entry Type" in
             ["Item Ledger Entry Type"::Purchase,
              "Item Ledger Entry Type"::"Positive Adjmt.",
              "Item Ledger Entry Type"::"Assembly Output"]) or
            ("Item Ledger Entry Type" = "Item Ledger Entry Type"::Output) and ("Invoiced Quantity" > 0))
        then
            exit(true);
        exit(false);
    end;

/// <summary>
/// Returns true if EntryNo parameter and Rec."Entry No." both are positive or negative.
/// Used in scenarios where we posting preview entries are negative
/// </summary>
/// <param name="EntryNo">The entry no. of the entry we are comparing to</param>
/// <returns>Boolean</returns>
    internal procedure EntryNoHasSameSign(EntryNo: integer): Boolean
    begin
        if (Rec."Entry No." >= 0) and (EntryNo >= 0) then
            exit(true);
        if (Rec."Entry No." < 0) and (EntryNo < 0) then
            exit(true);
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApplyLocationVariantFilters(var RecValueEntry: Record "Value Entry"; AccountingPeriod: Record "Accounting Period"; ValueEntry: Record "Value Entry"; var IsHandled: Boolean; Item: Record Item; CostCalcIsChanged: Boolean; var QtyFactor: Decimal; FromDate: Date; ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumCostsTillValuationDateOnAfterCalcSums(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumCostsTillValuationDateOnAfterGetItem(var Item: Record Item; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumCostsTillValuationDateOnAfterSetFilters(var ValueEntryRec: Record "Value Entry"; var ValueEntry: Record "Value Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumCostsTillValuationDateOnAfterSetCostAmounts(var ValueEntry: Record "Value Entry"; PrevValueEntrySum: Record "Value Entry"; QtyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowGLOnBeforeCopyToTempGLEntry(var GLEntry: Record "G/L Entry"; var GLItemLedgRelation: Record "G/L - Item Ledger Relation");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItemLedgEntryCost(var ValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer; Expected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddCost(var ValueEntry: Record "Value Entry"; InvtAdjmtBuffer: Record "Inventory Adjustment Buffer")
    begin
    end;
}
