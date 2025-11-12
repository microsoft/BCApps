// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Utilities;

table 363 "Analysis View"
{
    Caption = 'Analysis View';
    DataCaptionFields = "Code", Name;
    LookupPageID = "Analysis View List";
    Permissions = TableData "Analysis View Entry" = rimd,
                  TableData "Analysis View Budget Entry" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Account Source';

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and ("Account Source" <> xRec."Account Source") then
                    ValidateDelete(FieldCaption("Account Source"));
                VerificationForCashFlow();
                AnalysisViewReset();
                "Account Filter" := '';
            end;
        }
        field(4; "Last Entry No."; Integer)
        {
            Caption = 'Last Entry No.';
        }
        field(5; "Last Budget Entry No."; Integer)
        {
            Caption = 'Last Budget Entry No.';
        }
        field(6; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
        }
        field(7; "Update on Posting"; Boolean)
        {
            Caption = 'Update on Posting';
            Editable = false;

            trigger OnValidate()
            begin
                VerificationForCashFlow();
            end;
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBlocked(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if not Blocked and "Refresh When Unblocked" then begin
                    ValidateDelete(FieldCaption(Blocked));
                    AnalysisViewReset();
                    "Refresh When Unblocked" := false;
                end;
            end;
        }
        field(9; "Account Filter"; Code[250])
        {
            Caption = 'Account Filter';
            TableRelation = if ("Account Source" = const("G/L Account")) "G/L Account"
            else
            if ("Account Source" = const("Cash Flow Account")) "Cash Flow Account";
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                GLAccList: Page "G/L Account List";
                CFAccList: Page "Cash Flow Account List";
                Handled: Boolean;
                AccountFilter: Text;
            begin
                case Rec."Account Source" of
                    Rec."Account Source"::"G/L Account":
                        begin
                            GLAccList.LookupMode(true);
                            if not (GLAccList.RunModal() = ACTION::LookupOK) then
                                exit;

                            Rec.Validate("Account Filter", GLAccList.GetSelectionFilter());
                        end;
                    Rec."Account Source"::"Cash Flow Account":
                        begin
                            CFAccList.LookupMode(true);
                            if not (CFAccList.RunModal() = ACTION::LookupOK) then
                                exit;

                            Rec.Validate("Account Filter", CFAccList.GetSelectionFilter());
                        end;
                    else begin
                        OnLookupAccountFilter(Handled, AccountFilter, Rec);
                        if Handled then
                            Rec.Validate("Account Filter", AccountFilter);
                    end;
                end;
            end;

            trigger OnValidate()
            var
                AnalysisViewEntry: Record "Analysis View Entry";
                AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
                GLAcc: Record "G/L Account";
                CFAccount: Record "Cash Flow Account";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAccountFilter(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Blocked, false);
                case "Account Source" of
                    "Account Source"::"G/L Account":
                        begin
                            if ("Last Entry No." <> 0) and (xRec."Account Filter" = '') and ("Account Filter" <> '')
                                                    then begin
                                ValidateModify(FieldCaption("Account Filter"));
                                GLAcc.SetFilter("No.", "Account Filter");
                                if GLAcc.Find('-') then
                                    repeat
                                        GLAcc.Mark := true;
                                    until GLAcc.Next() = 0;
                                GLAcc.SetRange("No.");
                                if GLAcc.Find('-') then
                                    repeat
                                        if not GLAcc.Mark() then begin
                                            AnalysisViewEntry.SetRange("Analysis View Code", Code);
                                            AnalysisViewEntry.SetRange("Account No.", GLAcc."No.");
                                            AnalysisViewEntry.DeleteAll();
                                            AnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                                            AnalysisViewBudgetEntry.SetRange("G/L Account No.", GLAcc."No.");
                                            AnalysisViewBudgetEntry.DeleteAll();
                                        end;
                                    until GLAcc.Next() = 0;
                            end;
                            if ("Last Entry No." <> 0) and ("Account Filter" <> xRec."Account Filter") and (xRec."Account Filter" <> '')
                            then begin
                                ValidateDelete(FieldCaption("Account Filter"));
                                AnalysisViewReset();
                            end;
                        end;
                    "Account Source"::"Cash Flow Account":
                        begin
                            if ("Last Date Updated" <> 0D) and (xRec."Account Filter" = '') and ("Account Filter" <> '')
                                then begin
                                ValidateModify(FieldCaption("Account Filter"));
                                CFAccount.SetFilter("No.", "Account Filter");
                                if CFAccount.Find('-') then
                                    repeat
                                        CFAccount.Mark := true;
                                    until CFAccount.Next() = 0;
                                CFAccount.SetRange("No.");
                                if CFAccount.Find('-') then
                                    repeat
                                        if not CFAccount.Mark() then begin
                                            AnalysisViewEntry.SetRange("Analysis View Code", Code);
                                            AnalysisViewEntry.SetRange("Account No.", CFAccount."No.");
                                            AnalysisViewEntry.DeleteAll();
                                        end;
                                    until CFAccount.Next() = 0;
                            end;
                            if ("Last Date Updated" <> 0D) and ("Account Filter" <> xRec."Account Filter") and
                            (xRec."Account Filter" <> '')
                            then begin
                                ValidateDelete(FieldCaption("Account Filter"));
                                AnalysisViewReset();
                            end;
                        end;
                    else
                        OnValidateAccountFilter(Rec, xRec);
                end;
            end;
        }
        field(10; "Business Unit Filter"; Code[250])
        {
            Caption = 'Business Unit Filter';
            TableRelation = "Business Unit";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                BusUnit: Record "Business Unit";
                AnalysisViewEntry: Record "Analysis View Entry";
                AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
                TempBusUnit: Record "Business Unit" temporary;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBusinessUnitFilter(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Business Unit Filter" = '') and
                   ("Business Unit Filter" <> xRec."Business Unit Filter")
                then begin
                    ValidateModify(FieldCaption("Business Unit Filter"));
                    if BusUnit.Find('-') then
                        repeat
                            TempBusUnit := BusUnit;
                            TempBusUnit.Insert();
                        until BusUnit.Next() = 0;
                    TempBusUnit.Init();
                    TempBusUnit.Code := '';
                    TempBusUnit.Insert();
                    TempBusUnit.SetFilter(Code, "Business Unit Filter");
                    TempBusUnit.DeleteAll();
                    TempBusUnit.SetRange(Code);
                    if TempBusUnit.Find('-') then
                        repeat
                            AnalysisViewEntry.SetRange("Analysis View Code", Code);
                            AnalysisViewEntry.SetRange("Business Unit Code", TempBusUnit.Code);
                            AnalysisViewEntry.DeleteAll();
                            AnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                            AnalysisViewBudgetEntry.SetRange("Business Unit Code", TempBusUnit.Code);
                            AnalysisViewBudgetEntry.DeleteAll();
                        until TempBusUnit.Next() = 0
                end;
                if ("Last Entry No." <> 0) and (xRec."Business Unit Filter" <> '') and
                   ("Business Unit Filter" <> xRec."Business Unit Filter")
                then begin
                    ValidateDelete(FieldCaption("Business Unit Filter"));
                    AnalysisViewReset();
                end;
            end;
        }
        field(11; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStartingDate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Blocked, false);
                if CheckIfLastEntryOrDateIsSet() and ("Starting Date" <> xRec."Starting Date") then begin
                    ValidateDelete(FieldCaption("Starting Date"));
                    AnalysisViewReset();
                end;
            end;
        }
        field(12; "Date Compression"; Option)
        {
            Caption = 'Date Compression';
            InitValue = Day;
            OptionCaption = 'None,Day,Week,Month,Quarter,Year,Period';
            OptionMembers = "None",Day,Week,Month,Quarter,Year,Period;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDateCompression(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Blocked, false);
                if CheckIfLastEntryOrDateIsSet() and ("Date Compression" <> xRec."Date Compression") then begin
                    ValidateDelete(FieldCaption("Date Compression"));
                    AnalysisViewReset();
                end;
            end;
        }
        field(13; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                OnBeforeValidateDimension1Code(Rec, xRec);
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 1 Code", 13, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr());
                if ClearDimTotalingLines("Dimension 1 Code", xRec."Dimension 1 Code", 1) then begin
                    ModifyDim(FieldCaption("Dimension 1 Code"), "Dimension 1 Code", xRec."Dimension 1 Code");
                    Modify();
                end else
                    "Dimension 1 Code" := xRec."Dimension 1 Code";
            end;
        }
        field(14; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                OnBeforeValidateDimension2Code(Rec, xRec);
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 2 Code", 14, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr());
                if ClearDimTotalingLines("Dimension 2 Code", xRec."Dimension 2 Code", 2) then begin
                    ModifyDim(FieldCaption("Dimension 2 Code"), "Dimension 2 Code", xRec."Dimension 2 Code");
                    Modify();
                end else
                    "Dimension 2 Code" := xRec."Dimension 2 Code";
            end;
        }
        field(15; "Dimension 3 Code"; Code[20])
        {
            Caption = 'Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                OnBeforeValidateDimension3Code(Rec, xRec);
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 3 Code", 15, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr());
                if ClearDimTotalingLines("Dimension 3 Code", xRec."Dimension 3 Code", 3) then begin
                    ModifyDim(FieldCaption("Dimension 3 Code"), "Dimension 3 Code", xRec."Dimension 3 Code");
                    Modify();
                end else
                    "Dimension 3 Code" := xRec."Dimension 3 Code";
            end;
        }
        field(16; "Dimension 4 Code"; Code[20])
        {
            Caption = 'Dimension 4 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                OnBeforeValidateDimension4Code(Rec, xRec);
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 4 Code", 16, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr());
                if ClearDimTotalingLines("Dimension 4 Code", xRec."Dimension 4 Code", 4) then begin
                    ModifyDim(FieldCaption("Dimension 4 Code"), "Dimension 4 Code", xRec."Dimension 4 Code");
                    Modify();
                end else
                    "Dimension 4 Code" := xRec."Dimension 4 Code";
            end;
        }
        field(17; "Include Budgets"; Boolean)
        {
            AccessByPermission = TableData "G/L Budget Name" = R;
            Caption = 'Include Budgets';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateIncludeBudgets(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                VerificationForCashFlow();

                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Include Budgets" = true) and ("Include Budgets" = false)
                then begin
                    ValidateDelete(FieldCaption("Include Budgets"));
                    AnalysisviewBudgetReset();
                end;
            end;
        }
        field(18; "Refresh When Unblocked"; Boolean)
        {
            Caption = 'Refresh When Unblocked';
        }
        field(19; "Reset Needed"; Boolean)
        {
            Caption = 'Data update needed';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Account Source")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AnalysisViewFilter: Record "Analysis View Filter";
    begin
        AnalysisViewReset();
        AnalysisViewFilter.SetRange("Analysis View Code", Code);
        AnalysisViewFilter.DeleteAll();
    end;

    var
        AnalysisViewEntry: Record "Analysis View Entry";
        NewAnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        NewAnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        Dim: Record Dimension;
        SkipConfirmationDialogue: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1\You cannot use the same dimension twice in the same analysis view.';
        Text001: Label 'The dimension %1 is used in the analysis view %2 %3.';
#pragma warning restore AA0470
        Text002: Label ' You must therefore retain the dimension to keep consistency between the analysis view and the G/L entries.';
        Text004: Label 'All analysis views must be updated with the latest G/L entries and G/L budget entries.';
        Text005: Label ' Both blocked and unblocked analysis views must be updated.';
        Text007: Label ' Note, you must remove the checkmark in the blocked field before updating the blocked analysis views.\';
#pragma warning disable AA0470
        Text008: Label 'Currently, %1 analysis views are not updated.';
#pragma warning restore AA0470
        Text009: Label ' Do you wish to update these analysis views?';
        Text010: Label 'All analysis views must be updated with the latest G/L entries.';
#pragma warning disable AA0470
        Text011: Label 'If you change the contents of the %1 field, the analysis view entries will be deleted.';
        Text012: Label '\You will have to update again.\\Do you want to enter a new value in the %1 field?';
#pragma warning restore AA0470
        Text013: Label 'The update has been interrupted in response to the warning.';
#pragma warning disable AA0470
        Text014: Label 'If you change the contents of the %1 field, the analysis view entries will be changed as well.\\';
        Text015: Label 'Do you want to enter a new value in the %1 field?';
        Text016: Label '%1 is not applicable for source type %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Text017Msg: Label 'Enabling the %1 feature immediately updates the analysis view with the latest entries. Do you want to start using the feature, and update the analysis view now?', Comment = '%1 = The name of the feature that is being enabled';
        Text018Msg: Label 'If you enable the %1 feature it can take significantly more time to post documents, such as sales or purchase orders and invoices. Do you want to continue?', Comment = '%1 = The name of the feature that is being enabled';
        ClearDimTotalingConfirmTxt: Label 'Changing dimension will clear dimension totaling columns of Account Schedule Lines using current Analysis Vew. \Do you want to continue?';
        ResetNeededMsg: Label 'The data in the analysis view needs to be updated because a dimension has been changed. To update the data, choose Reset.';

    local procedure ModifyDim(DimFieldName: Text[100]; DimValue: Code[20]; xDimValue: Code[20])
    var
        SetDimensionFilters: Boolean;
    begin
        if CheckIfLastEntryOrDateIsSet() and (DimValue <> xDimValue) then begin
            if DimValue <> '' then begin
                ValidateDelete(DimFieldName);
                AnalysisViewReset();
            end;
            if DimValue = '' then begin
                SetDimensionFilters := "Account Source" = "Account Source"::"G/L Account";

                ValidateModify(DimFieldName);
                case DimFieldName of
                    FieldCaption("Dimension 1 Code"):
                        begin
                            AnalysisViewEntry.SetFilter("Dimension 1 Value Code", '<>%1', '');
                            if SetDimensionFilters then
                                AnalysisViewBudgetEntry.SetFilter("Dimension 1 Value Code", '<>%1', '');
                        end;
                    FieldCaption("Dimension 2 Code"):
                        begin
                            AnalysisViewEntry.SetFilter("Dimension 2 Value Code", '<>%1', '');
                            if SetDimensionFilters then
                                AnalysisViewBudgetEntry.SetFilter("Dimension 2 Value Code", '<>%1', '');
                        end;
                    FieldCaption("Dimension 3 Code"):
                        begin
                            AnalysisViewEntry.SetFilter("Dimension 3 Value Code", '<>%1', '');
                            if SetDimensionFilters then
                                AnalysisViewBudgetEntry.SetFilter("Dimension 3 Value Code", '<>%1', '');
                        end;
                    FieldCaption("Dimension 4 Code"):
                        begin
                            AnalysisViewEntry.SetFilter("Dimension 4 Value Code", '<>%1', '');
                            if SetDimensionFilters then
                                AnalysisViewBudgetEntry.SetFilter("Dimension 4 Value Code", '<>%1', '');
                        end;
                end;
                AnalysisViewEntry.SetRange("Analysis View Code", Code);
                if "Account Source" = "Account Source"::"G/L Account" then
                    AnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                if AnalysisViewEntry.Find('-') then
                    repeat
                        AnalysisViewEntry.Delete();
                        NewAnalysisViewEntry := AnalysisViewEntry;
                        case DimFieldName of
                            FieldCaption("Dimension 1 Code"):
                                NewAnalysisViewEntry."Dimension 1 Value Code" := '';
                            FieldCaption("Dimension 2 Code"):
                                NewAnalysisViewEntry."Dimension 2 Value Code" := '';
                            FieldCaption("Dimension 3 Code"):
                                NewAnalysisViewEntry."Dimension 3 Value Code" := '';
                            FieldCaption("Dimension 4 Code"):
                                NewAnalysisViewEntry."Dimension 4 Value Code" := '';
                        end;
                        InsertAnalysisViewEntry();
                    until AnalysisViewEntry.Next() = 0;
                if "Account Source" = "Account Source"::"G/L Account" then
                    if AnalysisViewBudgetEntry.Find('-') then
                        repeat
                            AnalysisViewBudgetEntry.Delete();
                            NewAnalysisViewBudgetEntry := AnalysisViewBudgetEntry;
                            case DimFieldName of
                                FieldCaption("Dimension 1 Code"):
                                    NewAnalysisViewBudgetEntry."Dimension 1 Value Code" := '';
                                FieldCaption("Dimension 2 Code"):
                                    NewAnalysisViewBudgetEntry."Dimension 2 Value Code" := '';
                                FieldCaption("Dimension 3 Code"):
                                    NewAnalysisViewBudgetEntry."Dimension 3 Value Code" := '';
                                FieldCaption("Dimension 4 Code"):
                                    NewAnalysisViewBudgetEntry."Dimension 4 Value Code" := '';
                            end;
                            InsertAnalysisViewBudgetEntry();
                        until AnalysisViewBudgetEntry.Next() = 0;
            end;
        end;
    end;

    local procedure InsertAnalysisViewEntry()
    begin
        if not NewAnalysisViewEntry.Insert() then begin
            NewAnalysisViewEntry.Find();
            NewAnalysisViewEntry.Amount := NewAnalysisViewEntry.Amount + AnalysisViewEntry.Amount;
            if "Account Source" = "Account Source"::"G/L Account" then begin
                NewAnalysisViewEntry."Debit Amount" :=
                  NewAnalysisViewEntry."Debit Amount" + AnalysisViewEntry."Debit Amount";
                NewAnalysisViewEntry."Credit Amount" :=
                  NewAnalysisViewEntry."Credit Amount" + AnalysisViewEntry."Credit Amount";
                NewAnalysisViewEntry."Add.-Curr. Debit Amount" :=
                  NewAnalysisViewEntry."Add.-Curr. Debit Amount" + AnalysisViewEntry."Add.-Curr. Debit Amount";
                NewAnalysisViewEntry."Add.-Curr. Credit Amount" :=
                  NewAnalysisViewEntry."Add.-Curr. Credit Amount" + AnalysisViewEntry."Add.-Curr. Credit Amount";
            end;
            NewAnalysisViewEntry.Modify();
        end;
    end;

    local procedure InsertAnalysisViewBudgetEntry()
    begin
        if not NewAnalysisViewBudgetEntry.Insert() then begin
            NewAnalysisViewBudgetEntry.Find();
            NewAnalysisViewBudgetEntry.Amount := NewAnalysisViewBudgetEntry.Amount + AnalysisViewBudgetEntry.Amount;
            NewAnalysisViewBudgetEntry.Modify();
        end;
    end;

    procedure AnalysisViewReset()
    var
        AnalysisViewEntry2: Record "Analysis View Entry";
    begin
        AnalysisviewBudgetReset();

        Rec."Last Entry No." := 0;
        Rec."Last Date Updated" := 0D;
        Rec."Reset Needed" := false;
        Rec.Modify();

        AnalysisViewEntry2.SetRange("Analysis View Code", Code);
        AnalysisViewEntry2.DeleteAll();

        OnAfterAnalysisViewReset(Rec);
    end;

    local procedure ClearDimTotalingLines(DimValue: Code[20]; xDimValue: Code[20]; DimNumber: Integer): Boolean
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ConfirmManagement: Codeunit "Confirm Management";
        AskedUser: Boolean;
        ClearTotaling: Boolean;
    begin
        if DimValue <> xDimValue then begin
            ClearTotaling := true;
            AccScheduleName.SetRange("Analysis View Name", Code);
            if AccScheduleName.FindSet() then
                repeat
                    if not AccScheduleName.DimTotalingLinesAreEmpty(DimNumber) and ClearTotaling then begin
                        if not AskedUser then begin
                            ClearTotaling := ConfirmManagement.GetResponseOrDefault(ClearDimTotalingConfirmTxt, true);
                            AskedUser := true;
                        end;
                        if ClearTotaling then
                            AccScheduleName.ClearDimTotalingLines(DimNumber);
                    end;
                until AccScheduleName.Next() = 0;
        end;
        exit(ClearTotaling);
    end;

    procedure CheckDimensionIsTracked(DimensionCode: Code[20]): Boolean
    begin
        if Rec."Dimension 1 Code" = DimensionCode then
            exit(true);

        if Rec."Dimension 2 Code" = DimensionCode then
            exit(true);

        if Rec."Dimension 3 Code" = DimensionCode then
            exit(true);

        if Rec."Dimension 4 Code" = DimensionCode then
            exit(true);

        exit(false);
    end;

    procedure CheckDimensionsAreRetained(ObjectType: Integer; ObjectID: Integer; OnlyIfIncludeBudgets: Boolean)
    begin
        Reset();
        if OnlyIfIncludeBudgets then
            SetRange("Include Budgets", true);
        if Find('-') then
            repeat
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 1 Code", Code, Name);
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 2 Code", Code, Name);
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 3 Code", Code, Name);
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 4 Code", Code, Name);
            until Next() = 0;
    end;

    local procedure CheckDimIsRetained(ObjectType: Integer; ObjectID: Integer; DimCode: Code[20]; AnalysisViewCode: Code[10]; AnalysisViewName: Text[50])
    var
        SelectedDim: Record "Selected Dimension";
    begin
        if DimCode <> '' then
            if not SelectedDim.Get(UserId, ObjectType, ObjectID, '', DimCode) then
                Error(
                  Text001 +
                  Text002,
                  DimCode, AnalysisViewCode, AnalysisViewName);
    end;

    procedure CheckViewsAreUpdated()
    var
        GLEntry: Record "G/L Entry";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        ConfirmManagement: Codeunit "Confirm Management";
        NoNotUpdated: Integer;
        RunCheck: Boolean;
    begin
        if "Account Source" = "Account Source"::"G/L Account" then
            RunCheck := GLEntry.FindLast() or GLBudgetEntry.FindLast()
        else
            RunCheck := not CFForecastEntry.IsEmpty();

        if RunCheck then begin
            NoNotUpdated := 0;
            Reset();
            if Find('-') then
                repeat
                    if ("Account Source" = "Account Source"::"Cash Flow Account") or
                       (("Last Entry No." < GLEntry."Entry No.") or
                        "Include Budgets" and ("Last Budget Entry No." < GLBudgetEntry."Entry No."))
                    then
                        NoNotUpdated := NoNotUpdated + 1;
                until Next() = 0;
            if NoNotUpdated > 0 then
                if ConfirmManagement.GetResponseOrDefault(
                         Text004 +
                         Text005 +
                         Text007 +
                         StrSubstNo(Text008, NoNotUpdated) +
                         Text009, true)
                    then begin
                    if Find('-') then
                        repeat
                            if Blocked then begin
                                "Refresh When Unblocked" := true;
                                "Last Budget Entry No." := 0;
                                Modify();
                            end else
                                UpdateAnalysisView.Update(Rec, 2, true);
                        until Next() = 0;
                end else
                    Error(Text010);
        end;
    end;

    procedure UpdateAllAnalysisViews(ShowWindow: Boolean)
    var
        AnalysisView: Record "Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        if AnalysisView.FindSet() then
            repeat
                if AnalysisView.Blocked then begin
                    AnalysisView."Refresh When Unblocked" := true;
                    AnalysisView."Last Budget Entry No." := 0;
                    AnalysisView.Modify();
                end else
                    UpdateAnalysisView.Update(AnalysisView, 2, ShowWindow);
            until Next() = 0;
    end;

    procedure UpdateLastEntryNo()
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast() then begin
            SetRange(Blocked, false);
            if Find('-') then
                repeat
                    "Last Entry No." := GLEntry."Entry No.";
                    Modify();
                until Next() = 0;
            SetRange(Blocked);
        end;
    end;

    procedure ValidateDelete(FieldName: Text)
    var
        Question: Text;
    begin
        Question := StrSubstNo(
            Text011 +
            Text012, FieldName);
        if SkipConfirmationDialogue then
            exit;
        if not DIALOG.Confirm(Question, true) then
            Error(Text013);
    end;

    procedure AnalysisViewBudgetReset()
    var
        AnalysisViewBudgetEntry2: Record "Analysis View Budget Entry";
    begin
        AnalysisViewBudgetEntry2.SetRange("Analysis View Code", Code);
        AnalysisViewBudgetEntry2.DeleteAll();
        "Last Budget Entry No." := 0;
    end;

    procedure ValidateModify(FieldName: Text)
    var
        Question: Text;
    begin
        Question := StrSubstNo(
            Text014 +
            Text015, FieldName);
        if SkipConfirmationDialogue then
            exit;

        if not DIALOG.Confirm(Question, true) then
            Error(Text013);
    end;

    procedure CopyAnalysisViewFilters(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10])
    var
        SelectedDim: Record "Selected Dimension";
        GLAcc: Record "G/L Account";
        CFAcc: Record "Cash Flow Account";
        BusUnit: Record "Business Unit";
        DimensionCode: Text[30];
    begin
        if Get(AnalysisViewCode) then begin
            if "Account Filter" <> '' then begin
                if "Account Source" = "Account Source"::"G/L Account" then
                    DimensionCode := GLAcc.TableCaption
                else
                    DimensionCode := CFAcc.TableCaption();

                if SelectedDim.Get(
                     UserId, ObjectType, ObjectID, AnalysisViewCode, DimensionCode)
                then begin
                    if SelectedDim."Dimension Value Filter" = '' then begin
                        SelectedDim."Dimension Value Filter" := "Account Filter";
                        SelectedDim.Modify();
                    end;
                end else begin
                    SelectedDim.Init();
                    SelectedDim."User ID" := CopyStr(UserId(), 1, MaxStrLen(SelectedDim."User ID"));
                    SelectedDim."Object Type" := ObjectType;
                    SelectedDim."Object ID" := ObjectID;
                    SelectedDim."Analysis View Code" := AnalysisViewCode;
                    SelectedDim."Dimension Code" := DimensionCode;
                    SelectedDim."Dimension Value Filter" := "Account Filter";
                    SelectedDim.Insert();
                end;
            end;
            if "Business Unit Filter" <> '' then
                if SelectedDim.Get(
                     UserId, ObjectType, ObjectID, AnalysisViewCode, BusUnit.TableCaption())
                then begin
                    if SelectedDim."Dimension Value Filter" = '' then begin
                        SelectedDim."Dimension Value Filter" := "Business Unit Filter";
                        SelectedDim.Modify();
                    end;
                end else begin
                    SelectedDim.Init();
                    SelectedDim."User ID" := CopyStr(UserId(), 1, MaxStrLen(SelectedDim."User ID"));
                    SelectedDim."Object Type" := ObjectType;
                    SelectedDim."Object ID" := ObjectID;
                    SelectedDim."Analysis View Code" := AnalysisViewCode;
                    SelectedDim."Dimension Code" := BusUnit.TableCaption();
                    SelectedDim."Dimension Value Filter" := "Business Unit Filter";
                    SelectedDim.Insert();
                end;
        end;
        OnAfterCopyAnalysisViewFilters(Rec, ObjectType, ObjectID, AnalysisViewCode, GLAcc);
    end;

    local procedure VerificationForCashFlow()
    begin
        if "Account Source" <> "Account Source"::"Cash Flow Account" then
            exit;

        if "Include Budgets" then
            Error(Text016, FieldCaption("Include Budgets"), "Account Source");

        if "Update on Posting" then
            Error(Text016, FieldCaption("Update on Posting"), "Account Source");
    end;

    procedure CheckIfLastEntryOrDateIsSet(): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfLastEntryOrDateIsSet(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Account Source" = "Account Source"::"G/L Account" then
            exit("Last Entry No." <> 0);

        exit("Last Date Updated" <> 0D);
    end;

    procedure SetUpdateOnPosting(NewUpdateOnPosting: Boolean)
    begin
        OnBeforeSetUpdateOnPosting(Rec, NewUpdateOnPosting);

        if "Update on Posting" = NewUpdateOnPosting then
            exit;

        if not "Update on Posting" and NewUpdateOnPosting then begin
            if not Confirm(StrSubstNo(Text018Msg, FieldCaption("Update on Posting")), false) then
                exit;
            if not Confirm(StrSubstNo(Text017Msg, FieldCaption("Update on Posting")), false) then
                exit;
        end;

        "Update on Posting" := NewUpdateOnPosting;
        if "Update on Posting" then begin
            Modify();
            CODEUNIT.Run(CODEUNIT::"Update Analysis View", Rec);
            Find();
        end;
    end;

    procedure SetSkipConfirmationDialogue()
    begin
        SkipConfirmationDialogue := true;
    end;

    procedure RunAnalysisByDimensionPage()
    var
        TempAnalysisByDimParameters: Record "Analysis by Dim. Parameters" temporary;
    begin
        TempAnalysisByDimParameters."Analysis View Code" := Code;
        TempAnalysisByDimParameters.Insert();
        PAGE.RUN(PAGE::"Analysis by Dimensions", TempAnalysisByDimParameters);
    end;

    procedure ShowResetNeededNotification()
    var
        ResetNeededNotification: Notification;
    begin
        if not Rec."Reset Needed" then
            exit;

        ResetNeededNotification.Id := '3e4b333c-858d-40d1-871c-7a54d486b484';
        ResetNeededNotification.Recall();
        ResetNeededNotification.Message := ResetNeededMsg;
        ResetNeededNotification.Scope := NotificationScope::LocalScope;
        ResetNeededNotification.Send();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAnalysisViewReset(var AnalysisView: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyAnalysisViewFilters(var AnalysisView: Record "Analysis View"; ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var GLAcc: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimension1Code(var Rec: Record "Analysis View"; var xRec: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimension2Code(var Rec: Record "Analysis View"; var xRec: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimension3Code(var Rec: Record "Analysis View"; var xRec: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimension4Code(var Rec: Record "Analysis View"; var xRec: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDateCompression(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBlocked(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStartingDate(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIncludeBudgets(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAccountFilter(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBusinessUnitFilter(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfLastEntryOrDateIsSet(var Rec: Record "Analysis View"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpdateOnPosting(var Rec: Record "Analysis View"; NewUpdateOnPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAccountFilter(var AnalysisView: Record "Analysis View"; var xRecAnalysisView: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAccountFilter(var Handled: Boolean; var AccountFilter: Text; var AnalysisView: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetAnalysisViewSupported(var AnalysisView: Record "Analysis View"; var IsSupported: Boolean)
    begin
    end;
}

