// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Budget;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;

table 85 "Acc. Schedule Line"
{
    Caption = 'Acc. Schedule Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            TableRelation = "Acc. Schedule Name";
            ToolTip = 'Specifies the unique name (code) of the financial report row definition. You can use up to 10 characters.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Row No."; Code[10])
        {
            Caption = 'Row No.';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = if ("Totaling Type" = const("Posting Accounts")) "G/L Account"
            else
            if ("Totaling Type" = const("Total Accounts")) "G/L Account"
            else
            if ("Totaling Type" = const("Account Category")) "G/L Account Category"
            else
            if ("Totaling Type" = const("Cash Flow Entry Accounts")) "Cash Flow Account"
            else
            if ("Totaling Type" = const("Cash Flow Total Accounts")) "Cash Flow Account"
            else
            if ("Totaling Type" = const("Cost Type")) "Cost Type"
            else
            if ("Totaling Type" = const("Cost Type Total")) "Cost Type";
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                LookupTotaling();
            end;

            trigger OnValidate()
            var
                GLAccCategory: Record "G/L Account Category";
            begin
                case "Totaling Type" of
                    "Totaling Type"::"Posting Accounts", "Totaling Type"::"Total Accounts":
                        begin
                            GLAcc.SetFilter("No.", Totaling);
                            GLAcc.CalcFields(Balance);
                            if GLAcc.Count() = 1 then begin
                                GLAcc.FindFirst();
                                "Row No." := "Row No." = '' ? CopyStr(GLAcc."No.", 1, MaxStrLen("Row No.")) : "Row No.";
                                Description := Description = '' ? GLAcc.Name : Description;
                            end;
                        end;
                    "Totaling Type"::"Account Category":
                        begin
                            GLAccCategory.SetFilter("Entry No.", Totaling);
                            if GLAccCategory.Count() = 1 then begin
                                GLAccCategory.FindFirst();
                                "Row No." := "Row No." = '' ? CopyStr(Format(GLAccCategory."Entry No."), 1, MaxStrLen("Row No.")) : "Row No.";
                                Description := Description = '' ? GLAccCategory.Description : Description;
                            end;
                        end;
                    "Totaling Type"::Formula, "Totaling Type"::"Set Base For Percent":
                        begin
                            Totaling := UpperCase(Totaling);
                            CheckFormula(Totaling);
                        end;
                    "Totaling Type"::"Cost Type", "Totaling Type"::"Cost Type Total":
                        begin
                            CostType.SetFilter("No.", Totaling);
                            CostType.CalcFields(Balance);
                            if CostType.Count() = 1 then begin
                                CostType.FindFirst();
                                "Row No." := "Row No." = '' ? CopyStr(CostType."No.", 1, MaxStrLen("Row No.")) : "Row No.";
                                Description := Description = '' ? CostType.Name : Description;
                            end;
                        end;
                    "Totaling Type"::"Cash Flow Entry Accounts", "Totaling Type"::"Cash Flow Total Accounts":
                        begin
                            CFAccount.SetFilter("No.", Totaling);
                            CFAccount.CalcFields(Amount);
                            if CFAccount.Count() = 1 then begin
                                CFAccount.FindFirst();
                                "Row No." := "Row No." = '' ? CopyStr(CFAccount."No.", 1, MaxStrLen("Row No.")) : "Row No.";
                                Description := Description = '' ? CFAccount.Name : Description;
                            end;
                        end;
                end;
            end;
        }
        field(6; "Totaling Type"; Enum "Acc. Schedule Line Totaling Type")
        {
            Caption = 'Totaling Type';

            trigger OnValidate()
            begin
                Validate(Totaling);
            end;
        }
        field(7; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(8; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(11; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Dimension 1 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(13; "Dimension 2 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(14; "G/L Budget Filter"; Code[10])
        {
            Caption = 'G/L Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Budget Name";
        }
        field(15; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        field(16; Show; Enum "Acc. Schedule Line Show")
        {
            Caption = 'Show';
        }
        field(17; "Dimension 3 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        field(18; "Dimension 4 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 4 Filter';
            FieldClass = FlowFilter;
        }
        field(19; "Dimension 1 Totaling"; Text[250])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(5);
            Caption = 'Dimension 1 Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(20; "Dimension 2 Totaling"; Text[250])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(6);
            Caption = 'Dimension 2 Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(21; "Dimension 3 Totaling"; Text[250])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(7);
            Caption = 'Dimension 3 Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(22; "Dimension 4 Totaling"; Text[250])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(8);
            Caption = 'Dimension 4 Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(23; Bold; Boolean)
        {
            Caption = 'Bold';
        }
        field(24; Italic; Boolean)
        {
            Caption = 'Italic';
        }
        field(25; Underline; Boolean)
        {
            Caption = 'Underline';

            trigger OnValidate()
            begin
                if "Double Underline" and Underline then begin
                    "Double Underline" := false;
                    Message(ForceUnderLineMsg, FieldCaption("Double Underline"));
                end;
            end;
        }
        field(26; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
        }
        field(27; "Row Type"; Option)
        {
            Caption = 'Row Type';
            OptionCaption = 'Net Change,Balance at Date,Beginning Balance';
            OptionMembers = "Net Change","Balance at Date","Beginning Balance";
        }
        field(28; "Amount Type"; Enum "Account Schedule Amount Type")
        {
            Caption = 'Amount Type';
        }
        field(30; "Double Underline"; Boolean)
        {
            Caption = 'Double Underline';

            trigger OnValidate()
            begin
                if "Double Underline" and Underline then begin
                    Underline := false;
                    Message(ForceUnderLineMsg, FieldCaption(Underline));
                end;
            end;
        }
        field(40; "Hide Currency Symbol"; Boolean)
        {
            Caption = 'Hide Currency Symbol';

            trigger OnValidate()
            begin
                if "Hide Currency Symbol" then
                    TestField("Totaling Type", "Acc. Schedule Line Totaling Type"::Formula);
            end;
        }
        field(41; "Dimension 5 Filter"; Text[250])
        {
            Caption = 'Dimension 5 Filter';
            FieldClass = FlowFilter;
        }
        field(42; "Dimension 6 Filter"; Text[250])
        {
            Caption = 'Dimension 6 Filter';
            FieldClass = FlowFilter;
        }
        field(43; "Dimension 7 Filter"; Text[250])
        {
            Caption = 'Dimension 7 Filter';
            FieldClass = FlowFilter;
        }
        field(45; "Dimension 8 Filter"; Text[250])
        {
            Caption = 'Dimension 8 Filter';
            FieldClass = FlowFilter;
        }
        field(840; "Cash Flow Forecast Filter"; Code[20])
        {
            Caption = 'Cash Flow Forecast Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cash Flow Forecast";
        }
        field(1100; "Cost Center Filter"; Code[20])
        {
            Caption = 'Cost Center Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Center";
        }
        field(1101; "Cost Object Filter"; Code[20])
        {
            Caption = 'Cost Object Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Object";
        }
        field(1102; "Cost Center Totaling"; Text[80])
        {
            Caption = 'Cost Center Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(1103; "Cost Object Totaling"; Text[80])
        {
            Caption = 'Cost Object Totaling';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(1104; "Cost Budget Filter"; Code[10])
        {
            Caption = 'Cost Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Budget Name";
        }
    }

    keys
    {
        key(Key1; "Schedule Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if xRec."Line No." = 0 then
            if not AccSchedName.Get("Schedule Name") then begin
                AccSchedName.Init();
                AccSchedName.Name := "Schedule Name";
                if AccSchedName.Name = '' then
                    AccSchedName.Description := Text000;
                AccSchedName.Insert();
            end;
    end;

    var
        AccSchedName: Record "Acc. Schedule Name";
        GLAcc: Record "G/L Account";
        CFAccount: Record "Cash Flow Account";
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        CostType: Record "Cost Type";
        HasGLSetup: Boolean;

        ForceUnderLineMsg: Label '%1 will be set to false.', Comment = '%1= Field underline ';
#pragma warning disable AA0074
        Text000: Label 'Default Schedule';
#pragma warning disable AA0470
        Text001: Label 'The parenthesis at position %1 is misplaced.';
        Text002: Label 'You cannot have two consecutive operators. The error occurred at position %1.';
        Text003: Label 'There is an operand missing after position %1.';
#pragma warning restore AA0470
        Text004: Label 'There are more left parentheses than right parentheses.';
        Text005: Label 'There are more right parentheses than left parentheses.';
        Text006: Label '1,6,,Dimension 1 Filter';
        Text007: Label '1,6,,Dimension 2 Filter';
        Text008: Label '1,6,,Dimension 3 Filter';
        Text009: Label '1,6,,Dimension 4 Filter';
        Text010: Label ',, Totaling';
        Text011: Label '1,5,,Dimension 1 Totaling';
        Text012: Label '1,5,,Dimension 2 Totaling';
        Text013: Label '1,5,,Dimension 3 Totaling';
        Text014: Label '1,5,,Dimension 4 Totaling';
#pragma warning disable AA0470
        Text015: Label 'The %1 refers to %2 %3, which does not exist. The field %4 on table %5 has now been deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure LookUpDimFilter(DimNo: Integer; var Text: Text) Result: Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
        IsHandled: Boolean;
    begin
        GetAccSchedSetup();

        IsHandled := false;
        OnBeforeLookUpDimFilter(Rec, DimNo, Text, AccSchedName, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case DimNo of
            1:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 1 Code");
            2:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 2 Code");
            3:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 3 Code");
            4:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 4 Code");
        end;

        DimValList.LookupMode(true);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

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

        OnAfterCheckFormula(Formula);
    end;

    procedure GetCaptionClass(AnalysisViewDimType: Integer) Result: Text[250]
    var
        IsHandled: Boolean;
    begin
        GetAccSchedSetup();

        IsHandled := false;
        OnBeforeGetCaptionClass(Rec, AccSchedName, AnalysisViewDimType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(Text006);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(Text007);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(Text008);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(Text009);
                end;
            5:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 1 Code" + Text010);

                    exit(Text011);
                end;
            6:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 2 Code" + Text010);

                    exit(Text012);
                end;
            7:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 3 Code" + Text010);

                    exit(Text013);
                end;
            8:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 4 Code" + Text010);

                    exit(Text014);
                end;
        end;
    end;

    local procedure GetAccSchedSetup()
    begin
        if "Schedule Name" <> AccSchedName.Name then
            AccSchedName.Get("Schedule Name");
        if AccSchedName."Analysis View Name" <> '' then
            if AccSchedName."Analysis View Name" <> AnalysisView.Code then
                if not AnalysisView.Get(AccSchedName."Analysis View Name") then begin
                    Message(
                      Text015,
                      AccSchedName.TableCaption(), AnalysisView.TableCaption(), AccSchedName."Analysis View Name",
                      AccSchedName.FieldCaption("Analysis View Name"), AccSchedName.TableCaption());
                    AccSchedName."Analysis View Name" := '';
                    AccSchedName.Modify();
                end;

        if AccSchedName."Analysis View Name" = '' then begin
            if not HasGLSetup then begin
                GLSetup.Get();
                HasGLSetup := true;
            end;
            Clear(AnalysisView);
            AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
            AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
        end;

        OnAfterGetAccSchedSetup(AnalysisView, AccSchedName);
    end;

    procedure LookupTotaling()
    var
        GLAccList: Page "G/L Account List";
        CostTypeList: Page "Cost Type List";
        CFAccList: Page "Cash Flow Account List";
        GLAccCatList: Page "G/L Account Categories";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupTotaling(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Totaling Type" of
            "Totaling Type"::"Posting Accounts",
            "Totaling Type"::"Total Accounts":
                begin
                    GLAccList.LookupMode(true);
                    if GLAccList.RunModal() = ACTION::LookupOK then
                        Validate(Totaling, GLAccList.GetSelectionFilter());
                end;
            "Totaling Type"::"Cost Type",
            "Totaling Type"::"Cost Type Total":
                begin
                    CostTypeList.LookupMode(true);
                    if CostTypeList.RunModal() = ACTION::LookupOK then
                        Validate(Totaling, CostTypeList.GetSelectionFilter());
                end;
            "Totaling Type"::"Cash Flow Entry Accounts",
            "Totaling Type"::"Cash Flow Total Accounts":
                begin
                    CFAccList.LookupMode(true);
                    if CFAccList.RunModal() = ACTION::LookupOK then
                        Validate(Totaling, CFAccList.GetSelectionFilter());
                end;
            "Totaling Type"::"Account Category":
                begin
                    GLAccCatList.LookupMode(true);
                    if GLAccCatList.RunModal() = ACTION::LookupOK then
                        Validate(Totaling, GLAccCatList.GetSelectionFilter());
                end;
        end;

        OnAfterLookupTotaling(Rec);
    end;

    procedure LookupGLBudgetFilter(var Text: Text): Boolean
    var
        GLBudgetNames: Page "G/L Budget Names";
    begin
        GLBudgetNames.LookupMode(true);
        if GLBudgetNames.RunModal() = ACTION::LookupOK then begin
            Text := GLBudgetNames.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    procedure LookupCostBudgetFilter(var Text: Text): Boolean
    var
        CostBudgetNames: Page "Cost Budget Names";
    begin
        CostBudgetNames.LookupMode(true);
        if CostBudgetNames.RunModal() = ACTION::LookupOK then begin
            Text := CostBudgetNames.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    procedure Indent()
    begin
        if Indentation < 10 then
            Indentation += 1;
    end;

    procedure Outdent()
    begin
        if Indentation > 0 then
            Indentation -= 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFormula(var Formula: Code[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupTotaling(var AccScheduleLine: Record "Acc. Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccSchedSetup(var AnalysisView: Record "Analysis View"; AccScheduleName: Record "Acc. Schedule Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaptionClass(var AccScheduleLine: Record "Acc. Schedule Line"; AccSchedName: Record "Acc. Schedule Name"; AnalysisViewDimType: Integer; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupTotaling(var AccScheduleLine: Record "Acc. Schedule Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpDimFilter(var AccScheduleLine: Record "Acc. Schedule Line"; DimNo: Integer; var Text: Text; AccSchedName: Record "Acc. Schedule Name"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

