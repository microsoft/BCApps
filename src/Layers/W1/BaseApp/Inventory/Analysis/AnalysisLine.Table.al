// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

table 7114 "Analysis Line"
{
    Caption = 'Analysis Line';
    DrillDownPageID = "Inventory Analysis Lines";
    LookupPageID = "Inventory Analysis Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
        }
        field(2; "Analysis Line Template Name"; Code[10])
        {
            Caption = 'Analysis Line Template Name';
            TableRelation = "Analysis Line Template".Name where("Analysis Area" = field("Analysis Area"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Row Ref. No."; Code[20])
        {
            Caption = 'Row Ref. No.';

            trigger OnValidate()
            begin
                if "Row Ref. No." <> xRec."Row Ref. No." then
                    SubstRowRefNo(xRec."Row Ref. No.", "Row Ref. No.");
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Type; Enum "Analysis Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                InventorySetup: Record "Inventory Setup";
                SalesSetup: Record "Sales & Receivables Setup";
            begin
                if Type <> xRec.Type then
                    Range := '';
                Validate(Range);

                case Type of
                    Type::"Item Group":
                        begin
                            InventorySetup.Get();
                            InventorySetup.TestField("Item Group Dimension Code");
                            "Group Dimension Code" := InventorySetup."Item Group Dimension Code";
                        end;
                    Type::"Customer Group":
                        begin
                            SalesSetup.Get();
                            SalesSetup.TestField("Customer Group Dimension Code");
                            "Group Dimension Code" := SalesSetup."Customer Group Dimension Code";
                        end;
                    Type::"Sales/Purchase person":
                        begin
                            SalesSetup.Get();
                            SalesSetup.TestField("Salesperson Dimension Code");
                            "Group Dimension Code" := SalesSetup."Salesperson Dimension Code";
                        end;
                    else
                        "Group Dimension Code" := '';
                end;
            end;
        }
        field(7; Range; Text[250])
        {
            Caption = 'Range';
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const(Customer)) Customer
            else
            if (Type = const(Vendor)) Vendor
            else
            if (Type = const("Item Group")) "Dimension Value".Code where("Dimension Code" = field("Group Dimension Code"), Blocked = const(false))
            else
            if (Type = const("Customer Group")) "Dimension Value".Code where("Dimension Code" = field("Group Dimension Code"), Blocked = const(false))
            else
            if (Type = const("Sales/Purchase person")) "Dimension Value".Code where("Dimension Code" = field("Group Dimension Code"), Blocked = const(false));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Item: Record Item;
                Cust: Record Customer;
                Vend: Record Vendor;
                ItemStatisticBuf: Record "Item Statistics Buffer";
            begin
                case Type of
                    Type::Item:
                        Item.SetFilter("No.", Range);
                    Type::Customer:
                        Cust.SetFilter("No.", Range);
                    Type::Vendor:
                        Vend.SetFilter("No.", Range);
                    Type::"Item Group", Type::"Customer Group", Type::"Sales/Purchase person":
                        ItemStatisticBuf.SetFilter("Dimension 1 Filter", Range);
                    Type::Formula:
                        begin
                            Range := UpperCase(Range);
                            CheckFormula(Range);
                        end;
                end;
            end;
        }
        field(8; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(9; Show; Option)
        {
            Caption = 'Show';
            OptionCaption = 'Yes,No,If Any Column Not Zero';
            OptionMembers = Yes,No,"If Any Column Not Zero";
        }
        field(10; Bold; Boolean)
        {
            Caption = 'Bold';
        }
        field(11; Italic; Boolean)
        {
            Caption = 'Italic';
        }
        field(12; Underline; Boolean)
        {
            Caption = 'Underline';
        }
        field(13; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
        }
        field(14; "Source Type Filter"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type Filter';
            FieldClass = FlowFilter;
        }
        field(15; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(16; "Item Budget Filter"; Code[10])
        {
            Caption = 'Item Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Budget Name".Name where("Analysis Area" = field("Analysis Area"));
        }
        field(17; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(18; "Dimension 1 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(19; "Dimension 2 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Dimension 3 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        field(21; "Dimension 1 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 1 Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(22; "Dimension 2 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(5);
            Caption = 'Dimension 2 Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(23; "Dimension 3 Totaling"; Text[80])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(6);
            Caption = 'Dimension 3 Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(24; "Source No. Filter"; Code[20])
        {
            Caption = 'Source No. Filter';
            FieldClass = FlowFilter;
            TableRelation = if ("Source Type Filter" = const(Customer)) Customer
            else
            if ("Source Type Filter" = const(Vendor)) Vendor
            else
            if ("Source Type Filter" = const(Item)) Item;
        }
        field(25; "Group Dimension Code"; Code[20])
        {
            Caption = 'Group Dimension Code';
            TableRelation = Dimension;
        }
        field(26; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;

            trigger OnValidate()
            begin
                if Indentation < 0 then
                    Indentation := 0;
            end;
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis Line Template Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        LockTable();
        AnalysisLineTemplate.Get("Analysis Area", "Analysis Line Template Name");

        if Indentation < 0 then
            Indentation := 0;
    end;

    trigger OnModify()
    begin
        if Indentation < 0 then
            Indentation := 0;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemAnalysisView: Record "Item Analysis View";
        HasGLSetup: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The parenthesis at position %1 is misplaced.';
        Text002: Label 'You cannot have two consecutive operators. The error occurred at position %1.';
        Text003: Label 'There is an operand missing after position %1.';
#pragma warning restore AA0470
        Text004: Label 'There are more left parentheses than right parentheses.';
        Text005: Label 'There are more right parentheses than left parentheses.';
#pragma warning disable AA0470
        Text009: Label '1,6,,Dimension %1 Filter';
#pragma warning restore AA0470
        Text010: Label ',, Totaling';
#pragma warning disable AA0470
        Text011: Label '1,5,,Dimension %1 Totaling';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CheckFormula(Formula: Code[250])
    var
        i: Integer;
        ParenthesesLevel: Integer;
        HasOperator: Boolean;
    begin
        ParenthesesLevel := 0;
        for i := 1 to StrLen(Formula) do begin
            if Formula[i] = '(' then
                ParenthesesLevel := ParenthesesLevel + 1
            else
                if Formula[i] = ')' then
                    ParenthesesLevel := ParenthesesLevel - 1;
            if ParenthesesLevel < 0 then
                Error(Text001, i);
            if Formula[i] in ['+', '-', '*', '/', '^'] then begin
                if HasOperator then
                    Error(Text002, i);

                HasOperator := true;
                if i = StrLen(Formula) then
                    Error(Text003, i);

                if Formula[i + 1] = ')' then
                    Error(Text003, i);
            end else
                HasOperator := false;
        end;
        if ParenthesesLevel > 0 then
            Error(Text004);

        if ParenthesesLevel < 0 then
            Error(Text005);
    end;

    local procedure SubstRowRefNo(OldRowRefNo: Code[20]; NewRowRefNo: Code[20])
    var
        FormulaAnalysisLine: Record "Analysis Line";
        OriginalRange: Text[250];
        NewRange: Text[250];
        Token: Text[250];
        TheChar: Text[1];
        i: Integer;
        TheLength: Integer;
    begin
        if (OldRowRefNo = '') or (NewRowRefNo = '') then
            exit;
        FormulaAnalysisLine.SetRange("Analysis Area", "Analysis Area");
        FormulaAnalysisLine.SetRange("Analysis Line Template Name", "Analysis Line Template Name");
        FormulaAnalysisLine.SetRange(Type, Type::Formula);
        if not FormulaAnalysisLine.Find('-') then
            exit;
        repeat
            OriginalRange := FormulaAnalysisLine.Range;
            TheLength := StrLen(FormulaAnalysisLine.Range);
            NewRange := '';

            for i := 1 to TheLength do begin
                TheChar := CopyStr(FormulaAnalysisLine.Range, i, 1);
                if TheChar in ['0' .. '9', 'A' .. 'Z'] then begin
                    Token := Token + TheChar;
                    if i = TheLength then begin
                        if Token = OldRowRefNo then
                            NewRange := NewRange + NewRowRefNo
                        else
                            NewRange := NewRange + Token;
                        Token := '';
                    end;
                end else begin
                    if Token = OldRowRefNo then
                        NewRange := NewRange + NewRowRefNo
                    else
                        NewRange := NewRange + Token;
                    NewRange := NewRange + TheChar;
                    Token := '';
                end;
            end;
            if NewRange <> OriginalRange then
                if "Line No." = FormulaAnalysisLine."Line No." then
                    Range := NewRange
                else begin
                    FormulaAnalysisLine.Range := NewRange;
                    FormulaAnalysisLine.Modify();
                end;
        until FormulaAnalysisLine.Next() = 0;
    end;

    procedure LookupTotalingRange(var Text: Text) Result: Boolean
    var
        InventorySetup: Record "Inventory Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ItemList: Page "Item List";
        CustList: Page "Customer List";
        VendList: Page "Vendor List";
    begin
        case Type of
            Type::Item:
                begin
                    ItemList.LookupMode(true);
                    if ItemList.RunModal() = ACTION::LookupOK then begin
                        Text := ItemList.GetSelectionFilter();
                        exit(true);
                    end;
                end;
            Type::Customer:
                begin
                    CustList.LookupMode(true);
                    if CustList.RunModal() = ACTION::LookupOK then begin
                        Text := CustList.GetSelectionFilter();
                        exit(true);
                    end;
                end;
            Type::Vendor:
                begin
                    VendList.LookupMode(true);
                    if VendList.RunModal() = ACTION::LookupOK then begin
                        Text := VendList.GetSelectionFilter();
                        exit(true);
                    end;
                end;
            Type::"Item Group":
                begin
                    InventorySetup.Get();
                    InventorySetup.TestField("Item Group Dimension Code");
                    exit(LookupDimTotalingRange(Text, InventorySetup."Item Group Dimension Code"));
                end;
            Type::"Customer Group":
                begin
                    SalesSetup.Get();
                    SalesSetup.TestField("Customer Group Dimension Code");
                    exit(LookupDimTotalingRange(Text, SalesSetup."Customer Group Dimension Code"));
                end;
            Type::"Sales/Purchase person":
                begin
                    SalesSetup.Get();
                    SalesSetup.TestField("Salesperson Dimension Code");
                    exit(LookupDimTotalingRange(Text, SalesSetup."Salesperson Dimension Code"));
                end;
            else
                OnLookupTotalingRangeOnElse(Rec, Text, Result);
        end;
    end;

    procedure LookupDimTotalingRange(var Text: Text; GroupDimCode: Code[20]): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        DimVal.FilterGroup := 2;
        DimVal.SetRange("Dimension Code", GroupDimCode);
        DimVal.FilterGroup := 0;
        DimValList.SetTableView(DimVal);
        DimValList.LookupMode(true);
        if DimValList.RunModal() = ACTION::LookupOK then begin
            Text := DimValList.GetSelectionFilter();
            exit(true);
        end;
    end;

    procedure GetCaptionClass(DimNo: Integer): Text[250]
    begin
        GetItemAnalysisView();

        case DimNo of
            1:
                if ItemAnalysisView."Dimension 1 Code" <> '' then
                    exit('1,6,' + ItemAnalysisView."Dimension 1 Code");
            2:
                if ItemAnalysisView."Dimension 2 Code" <> '' then
                    exit('1,6,' + ItemAnalysisView."Dimension 2 Code");
            3:
                if ItemAnalysisView."Dimension 3 Code" <> '' then
                    exit('1,6,' + ItemAnalysisView."Dimension 3 Code");
            4:
                if ItemAnalysisView."Dimension 1 Code" <> '' then
                    exit('1,5,' + ItemAnalysisView."Dimension 1 Code" + Text010);
            5:
                if ItemAnalysisView."Dimension 2 Code" <> '' then
                    exit('1,5,' + ItemAnalysisView."Dimension 2 Code" + Text010);
            6:
                if ItemAnalysisView."Dimension 3 Code" <> '' then
                    exit('1,5,' + ItemAnalysisView."Dimension 3 Code" + Text010);
        end;
        if DimNo <= 3 then
            exit(StrSubstNo(Text009, DimNo));
        exit(StrSubstNo(Text011, DimNo - 3));
    end;

    local procedure GetItemAnalysisView()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        if (AnalysisLineTemplate."Analysis Area" = "Analysis Area") and
           (AnalysisLineTemplate.Name = "Analysis Line Template Name")
        then
            exit;

        if AnalysisLineTemplate.Get("Analysis Area", "Analysis Line Template Name") then
            if AnalysisLineTemplate."Item Analysis View Code" <> '' then
                ItemAnalysisView.Get("Analysis Area", AnalysisLineTemplate."Item Analysis View Code")
            else begin
                Clear(ItemAnalysisView);
                if not HasGLSetup then
                    GLSetup.Get();
                HasGLSetup := true;
                ItemAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                ItemAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupTotalingRangeOnElse(var AnalysisLine: Record "Analysis Line"; var Text: Text; var Result: Boolean)
    begin
    end;
}

