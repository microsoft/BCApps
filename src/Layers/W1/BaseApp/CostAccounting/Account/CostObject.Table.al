// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Account;

using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;

table 1113 "Cost Object"
{
    Caption = 'Cost Object';
    DataClassification = CustomerContent;
    LookupPageID = "Chart of Cost Objects";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;

            trigger OnLookup()
            var
                CostAccMgt: Codeunit "Cost Account Mgt";
            begin
                CostAccMgt.LookupCostObjectFromDimValue(Code);
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Cost Type Filter"; Code[20])
        {
            Caption = 'Cost Type Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Type";
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5; "Net Change"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Object Code" = field(Code),
                                                         "Cost Object Code" = field(filter(Totaling)),
                                                         "Cost Type No." = field("Cost Type Filter"),
                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Balance at Date"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Object Code" = field(Code),
                                                         "Cost Object Code" = field(filter(Totaling)),
                                                         "Cost Type No." = field("Cost Type Filter"),
                                                         "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Sorting Order"; Code[10])
        {
            Caption = 'Sorting Order';
        }
        field(8; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(9; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Cost Object,Heading,Total,Begin-Total,End-Total';
            OptionMembers = "Cost Object",Heading,Total,"Begin-Total","End-Total";

            trigger OnValidate()
            begin
                // Change to other type. Entries exist?
                if (("Line Type" <> "Line Type"::"Cost Object") and
                    (xRec."Line Type" = xRec."Line Type"::"Cost Object")) or
                   (("Line Type" <> "Line Type"::"Begin-Total") and
                    (xRec."Line Type" = xRec."Line Type"::"Begin-Total"))
                then
                    ConfirmModifyIfEntriesExist(Rec);

                if "Line Type" <> "Line Type"::"Cost Object" then
                    Blocked := true
                else
                    Totaling := '';
            end;
        }
        field(10; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(11; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(12; "Blank Line"; Boolean)
        {
            Caption = 'Blank Line';
            MinValue = false;
        }
        field(13; Indentation; Integer)
        {
            Caption = 'Indentation';
            Editable = false;
            MinValue = 0;
        }
        field(14; Totaling; Text[250])
        {
            Caption = 'Totaling';

            trigger OnLookup()
            var
                SelectionFilter: Text[1024];
            begin
                if LookupCostObjectFilter(SelectionFilter) then
                    Validate(Totaling, CopyStr(SelectionFilter, 1, MaxStrLen(Totaling)));
            end;

            trigger OnValidate()
            begin
                if not ("Line Type" in ["Line Type"::Total, "Line Type"::"End-Total"]) then
                    FieldError("Line Type");

                CalcFields("Net Change");
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Sorting Order")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    begin
        SetRecFilter();
        ConfirmDeleteIfEntriesExist(Rec, true);
        SetRange(Code);
    end;

    trigger OnInsert()
    begin
        TestField(Code);
    end;

    var
#pragma warning disable AA0074
        Text001: Label 'There are general ledger entries, cost entries, or cost budget entries that are posted to the selected cost object. Are you sure that you want to delete the cost object?';
        Text002: Label 'There are general ledger entries, cost entries, or cost budget entries that are posted to the selected cost object. Are you sure that you want to modify the cost object?';
#pragma warning restore AA0074

    local procedure EntriesExist(var CostObject: Record "Cost Object") EntriesFound: Boolean
    var
        CostAccSetup: Record "Cost Accounting Setup";
        GLEntry: Record "G/L Entry";
        CostEntry: Record "Cost Entry";
        CostBudgetEntry: Record "Cost Budget Entry";
        DimensionMgt: Codeunit DimensionManagement;
        DimFilter: Text;
    begin
        CostAccSetup.Get();
        if CostObject.FindSet() then
            repeat
                DimensionMgt.GetDimSetIDsForFilter(CostAccSetup."Cost Center Dimension", CostObject.Code);
                DimFilter := DimensionMgt.GetDimSetFilter();
                if DimFilter <> '' then begin
                    GLEntry.SetFilter("Dimension Set ID", DimFilter);
                    if not GLEntry.IsEmpty() then
                        EntriesFound := true;
                end;

                if not EntriesFound then begin
                    CostBudgetEntry.SetCurrentKey("Budget Name", "Cost Object Code");
                    CostBudgetEntry.SetRange("Cost Center Code", CostObject.Code);
                    EntriesFound := not CostBudgetEntry.IsEmpty();
                end;

                if not EntriesFound then begin
                    CostEntry.SetCurrentKey("Cost Object Code");
                    CostEntry.SetRange("Cost Object Code", CostObject.Code);
                    EntriesFound := not CostEntry.IsEmpty();
                end;
            until (CostObject.Next() = 0) or EntriesFound;
    end;

    procedure ConfirmDeleteIfEntriesExist(var CostObject: Record "Cost Object"; CalledFromOnInsert: Boolean)
    begin
        if EntriesExist(CostObject) then
            if not Confirm(Text001, true) then
                Error('');
        if not CalledFromOnInsert then
            CostObject.DeleteAll();
    end;

    local procedure ConfirmModifyIfEntriesExist(var CostObject: Record "Cost Object")
    var
        CostObject2: Record "Cost Object";
    begin
        CostObject2 := CostObject;
        CostObject2.SetRecFilter();
        if EntriesExist(CostObject2) then
            if not Confirm(Text002, true) then
                Error('');
    end;

    procedure LookupCostObjectFilter(var Text: Text): Boolean
    var
        ChartOfCostObjects: Page "Chart of Cost Objects";
    begin
        ChartOfCostObjects.LookupMode(true);
        if ChartOfCostObjects.RunModal() = ACTION::LookupOK then begin
            Text := ChartOfCostObjects.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;
}
