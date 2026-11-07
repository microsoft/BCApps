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
using System.Security.AccessControl;
using System.Security.User;

table 1112 "Cost Center"
{
    Caption = 'Cost Center';
    DataClassification = CustomerContent;
    LookupPageID = "Chart of Cost Centers";

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
                CostAccMgt.LookupCostCenterFromDimValue(Code);
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Cost Subtype"; Enum "Cost Center Subtype")
        {
            Caption = 'Cost Subtype';
        }
        field(4; "Cost Type Filter"; Code[20])
        {
            Caption = 'Cost Type Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Type";
        }
        field(5; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(6; "Net Change"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Center Code" = field(Code),
                                                         "Cost Center Code" = field(filter(Totaling)),
                                                         "Cost Type No." = field("Cost Type Filter"),
                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Balance at Date"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Center Code" = field(Code),
                                                         "Cost Center Code" = field(filter(Totaling)),
                                                         "Cost Type No." = field("Cost Type Filter"),
                                                         "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Balance to Allocate"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Center Code" = field(Code),
                                                         "Cost Center Code" = field(filter(Totaling)),
                                                         "Cost Type No." = field("Cost Type Filter"),
                                                         "Posting Date" = field("Date Filter"),
                                                         Allocated = const(false)));
            Caption = 'Balance to Allocate';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Responsible Person"; Code[50])
        {
            Caption = 'Responsible Person';
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("Responsible Person");
            end;
        }
        field(10; "Sorting Order"; Code[10])
        {
            Caption = 'Sorting Order';
        }
        field(11; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(12; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Cost Center,Heading,Total,Begin-Total,End-Total';
            OptionMembers = "Cost Center",Heading,Total,"Begin-Total","End-Total";

            trigger OnValidate()
            begin
                // Change to other type than cost type. Entries exist?
                if (("Line Type" <> "Line Type"::"Cost Center") and
                    (xRec."Line Type" = xRec."Line Type"::"Cost Center")) or
                   (("Line Type" <> "Line Type"::"Begin-Total") and
                    (xRec."Line Type" = xRec."Line Type"::"Begin-Total"))
                then
                    ConfirmModifyIfEntriesExist(Rec);

                if "Line Type" <> "Line Type"::"Cost Center" then begin
                    Blocked := true;
                    "Cost Subtype" := "Cost Subtype"::" ";
                end else
                    Totaling := '';
            end;
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(15; "Blank Line"; Boolean)
        {
            Caption = 'Blank Line';
            MinValue = false;
        }
        field(16; Indentation; Integer)
        {
            Caption = 'Indentation';
            Editable = false;
            MinValue = 0;
        }
        field(17; Totaling; Text[250])
        {
            Caption = 'Totaling';

            trigger OnLookup()
            var
                SelectionFilter: Text;
            begin
                if LookupCostCenterFilter(SelectionFilter) then
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
        key(Key2; "Cost Subtype")
        {
        }
        key(Key3; "Sorting Order")
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
        SetCurrentKey("Sorting Order");
    end;

    trigger OnInsert()
    begin
        TestField(Code);
    end;

    var
        ConfirmDeleteQst: Label 'There are general ledger entries, cost entries, or cost budget entries that are posted to the selected cost center. Are you sure that you want to delete the cost center?';
        ConfirmModifyQst: Label 'There are general ledger entries, cost entries, or cost budget entries that are posted to the selected cost center. Are you sure that you want to modify the cost center?';

    local procedure EntriesExist(var CostCenter: Record "Cost Center") EntriesFound: Boolean
    var
        CostAccSetup: Record "Cost Accounting Setup";
        GLEntry: Record "G/L Entry";
        CostEntry: Record "Cost Entry";
        CostBudgetEntry: Record "Cost Budget Entry";
        DimensionMgt: Codeunit DimensionManagement;
        DimFilter: Text;
    begin
        CostAccSetup.Get();
        if CostCenter.FindSet() then
            repeat
                DimensionMgt.GetDimSetIDsForFilter(CostAccSetup."Cost Center Dimension", CostCenter.Code);
                DimFilter := DimensionMgt.GetDimSetFilter();
                if DimFilter <> '' then begin
                    GLEntry.SetFilter("Dimension Set ID", DimFilter);
                    if not GLEntry.IsEmpty() then
                        EntriesFound := true;
                end;

                if not EntriesFound then begin
                    CostBudgetEntry.SetCurrentKey("Budget Name", "Cost Center Code");
                    CostBudgetEntry.SetRange("Cost Center Code", CostCenter.Code);
                    EntriesFound := not CostBudgetEntry.IsEmpty();
                end;

                if not EntriesFound then begin
                    CostEntry.SetCurrentKey("Cost Center Code");
                    CostEntry.SetRange("Cost Center Code", CostCenter.Code);
                    EntriesFound := not CostEntry.IsEmpty();
                end;
            until (CostCenter.Next() = 0) or EntriesFound;
    end;

    procedure ConfirmDeleteIfEntriesExist(var CostCenter: Record "Cost Center"; CalledFromOnInsert: Boolean)
    begin
        if EntriesExist(CostCenter) then
            if not Confirm(ConfirmDeleteQst, true) then
                Error('');
        if not CalledFromOnInsert then
            CostCenter.DeleteAll();
    end;

    local procedure ConfirmModifyIfEntriesExist(var CostCenter: Record "Cost Center")
    var
        CostCenter2: Record "Cost Center";
    begin
        CostCenter2 := CostCenter;
        CostCenter2.SetRecFilter();
        if EntriesExist(CostCenter2) then
            if not Confirm(ConfirmModifyQst, true) then
                Error('');
    end;

    procedure LookupCostCenterFilter(var Text: Text): Boolean
    var
        ChartOfCostCenters: Page "Chart of Cost Centers";
    begin
        ChartOfCostCenters.LookupMode(true);
        if ChartOfCostCenters.RunModal() = ACTION::LookupOK then begin
            Text := ChartOfCostCenters.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;
}
