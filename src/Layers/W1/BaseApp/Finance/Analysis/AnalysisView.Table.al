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

/// <summary>
/// Defines configurable analysis views for multi-dimensional financial reporting and analysis.
/// Provides pre-aggregated data from G/L entries, cash flow entries, and budget entries with customizable dimension tracking.
/// </summary>
/// <remarks>
/// Core configuration table for the Analysis system. Supports G/L Account and Cash Flow Account sources with up to 4 dimensions.
/// Analysis view entries are created through the UpdateAnalysisView process for optimized reporting performance.
/// Extensibility: OnBeforeValidate events for dimension codes and validation logic customization.
/// </remarks>
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
        /// <summary>
        /// Unique identifier for the analysis view configuration.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for this entry.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the analysis view displayed in user interface and reports.
        /// </summary>
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name.';
        }
        /// <summary>
        /// Source of accounts to include in the analysis view (G/L Account or Cash Flow Account).
        /// </summary>
        field(3; "Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Account Source';
            ToolTip = 'Specifies an account that you can use as a filter to define what is displayed in the Analysis by Dimensions window.';

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
        /// <summary>
        /// Last G/L entry number processed during analysis view update.
        /// </summary>
        field(4; "Last Entry No."; Integer)
        {
            Caption = 'Last Entry No.';
            ToolTip = 'Specifies the number of the last general ledger entry you posted, prior to updating the analysis view.';
        }
        /// <summary>
        /// Last budget entry number processed during analysis view update.
        /// </summary>
        field(5; "Last Budget Entry No."; Integer)
        {
            Caption = 'Last Budget Entry No.';
            ToolTip = 'Specifies the number of the last item budget entry you entered prior to updating the analysis view.';
        }
        /// <summary>
        /// Date when the analysis view was last updated with transaction data.
        /// </summary>
        field(6; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
            ToolTip = 'Specifies the date on which the analysis view was last updated.';
        }
        /// <summary>
        /// Specifies whether the analysis view should be updated automatically when transactions are posted.
        /// </summary>
        field(7; "Update on Posting"; Boolean)
        {
            Caption = 'Update on Posting';
            ToolTip = 'Specifies if the analysis view is updated every time that you post a general ledger entry.';
            Editable = false;

            trigger OnValidate()
            begin
                VerificationForCashFlow();
            end;
        }
        /// <summary>
        /// Indicates whether the analysis view is blocked from updates and modifications.
        /// </summary>
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';

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
        /// <summary>
        /// Filter criteria for selecting which accounts to include in the analysis view based on the account source.
        /// </summary>
        field(9; "Account Filter"; Code[250])
        {
            Caption = 'Account Filter';
            ToolTip = 'Specifies which accounts are shown in the analysis view.';
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
        /// <summary>
        /// Filter criteria for selecting business units to include in the analysis view.
        /// </summary>
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
        /// <summary>
        /// Starting date for transactions to include in the analysis view data.
        /// </summary>
        field(11; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the starting date of the campaign analysis.';

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
        /// <summary>
        /// Date compression method for aggregating transactions in analysis view entries.
        /// </summary>
        field(12; "Date Compression"; Option)
        {
            Caption = 'Date Compression';
            ToolTip = 'Specifies the period that the program will combine entries for, in order to create a single entry for that time period.';
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
        /// <summary>
        /// Primary dimension code to track in the analysis view for multi-dimensional reporting.
        /// </summary>
        field(13; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                OnBeforeValidateDimension1Code(Rec, xRec);
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 1 Code", Enum::"Dim Type Checked".FromInteger(13), '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr());
                if ClearDimTotalingLines("Dimension 1 Code", xRec."Dimension 1 Code", 1) then begin
                    ModifyDim(FieldCaption("Dimension 1 Code"), "Dimension 1 Code", xRec."Dimension 1 Code");
                    Modify();
                end else
                    "Dimension 1 Code" := xRec."Dimension 1 Code";
            end;
        }
        /// <summary>
        /// Secondary dimension code to track in the analysis view for multi-dimensional reporting.
        /// </summary>
        field(14; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                OnBeforeValidateDimension2Code(Rec, xRec);
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 2 Code", Enum::"Dim Type Checked".FromInteger(14), '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr());
                if ClearDimTotalingLines("Dimension 2 Code", xRec."Dimension 2 Code", 2) then begin
                    ModifyDim(FieldCaption("Dimension 2 Code"), "Dimension 2 Code", xRec."Dimension 2 Code");
                    Modify();
                end else
                    "Dimension 2 Code" := xRec."Dimension 2 Code";
            end;
        }
        /// <summary>
        /// Third dimension code to track in the analysis view for extended multi-dimensional reporting.
        /// </summary>
        field(15; "Dimension 3 Code"; Code[20])
        {
            Caption = 'Dimension 3 Code';
            ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                OnBeforeValidateDimension3Code(Rec, xRec);
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 3 Code", Enum::"Dim Type Checked".FromInteger(15), '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr());
                if ClearDimTotalingLines("Dimension 3 Code", xRec."Dimension 3 Code", 3) then begin
                    ModifyDim(FieldCaption("Dimension 3 Code"), "Dimension 3 Code", xRec."Dimension 3 Code");
                    Modify();
                end else
                    "Dimension 3 Code" := xRec."Dimension 3 Code";
            end;
        }
        /// <summary>
        /// Fourth dimension code to track in the analysis view for comprehensive multi-dimensional reporting.
        /// </summary>
        field(16; "Dimension 4 Code"; Code[20])
        {
            Caption = 'Dimension 4 Code';
            ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                OnBeforeValidateDimension4Code(Rec, xRec);
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 4 Code", Enum::"Dim Type Checked".FromInteger(16), '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr());
                if ClearDimTotalingLines("Dimension 4 Code", xRec."Dimension 4 Code", 4) then begin
                    ModifyDim(FieldCaption("Dimension 4 Code"), "Dimension 4 Code", xRec."Dimension 4 Code");
                    Modify();
                end else
                    "Dimension 4 Code" := xRec."Dimension 4 Code";
            end;
        }
        /// <summary>
        /// Specifies whether budget data should be included in the analysis view for budget vs. actual comparisons.
        /// </summary>
        field(17; "Include Budgets"; Boolean)
        {
            AccessByPermission = TableData "G/L Budget Name" = R;
            Caption = 'Include Budgets';
            ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';

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
        /// <summary>
        /// Indicates that the analysis view should be refreshed when it is unblocked.
        /// </summary>
        field(18; "Refresh When Unblocked"; Boolean)
        {
            Caption = 'Refresh When Unblocked';
        }
        /// <summary>
        /// Indicates that the analysis view data needs to be reset and updated.
        /// </summary>
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

    /// <summary>
    /// Resets the analysis view by clearing all analysis view entries and resetting tracking fields.
    /// </summary>
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

    /// <summary>
    /// Checks if a specified dimension code is tracked by any of the four dimension code fields in the analysis view.
    /// </summary>
    /// <param name="DimensionCode">Dimension code to check for tracking</param>
    /// <returns>True if the dimension is tracked in any of the four dimension code fields</returns>
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

    /// <summary>
    /// Validates that required dimensions are retained for specified objects in analysis views.
    /// </summary>
    /// <param name="ObjectType">Type of object to validate dimensions for</param>
    /// <param name="ObjectID">ID of object to validate dimensions for</param>
    /// <param name="OnlyIfIncludeBudgets">Whether to check only analysis views that include budgets</param>
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

    /// <summary>
    /// Checks if all analysis views are updated with the latest transaction data and prompts for update if needed.
    /// </summary>
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

    /// <summary>
    /// Updates all analysis views in the system, optionally showing a progress window.
    /// </summary>
    /// <param name="ShowWindow">Whether to display a progress window during the update process</param>
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

    /// <summary>
    /// Updates the last entry number for all non-blocked analysis views to the latest G/L entry number.
    /// </summary>
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

    /// <summary>
    /// Validates that the user confirms deletion of analysis view data when modifying configuration fields.
    /// </summary>
    /// <param name="FieldName">Name of the field being modified that requires confirmation</param>
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

    /// <summary>
    /// Resets the analysis view budget entries by deleting all budget entries and resetting the last budget entry number.
    /// </summary>
    procedure AnalysisViewBudgetReset()
    var
        AnalysisViewBudgetEntry2: Record "Analysis View Budget Entry";
    begin
        AnalysisViewBudgetEntry2.SetRange("Analysis View Code", Code);
        AnalysisViewBudgetEntry2.DeleteAll();
        "Last Budget Entry No." := 0;
    end;

    /// <summary>
    /// Validates that the user confirms modification of analysis view data when changing configuration fields.
    /// </summary>
    /// <param name="FieldName">Name of the field being modified that requires confirmation</param>
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

    /// <summary>
    /// Copies analysis view dimension filters to selected dimensions for a specified object.
    /// </summary>
    /// <param name="ObjectType">Type of object to copy filters to</param>
    /// <param name="ObjectID">ID of object to copy filters to</param>
    /// <param name="AnalysisViewCode">Code of analysis view to copy filters from</param>
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

    /// <summary>
    /// Checks if the analysis view has been configured with last entry tracking or last date updated.
    /// </summary>
    /// <returns>True if last entry number or last date updated is set, depending on account source</returns>
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

    /// <summary>
    /// Sets the Update on Posting field for all analysis views to the specified value.
    /// </summary>
    /// <param name="NewUpdateOnPosting">New value for the Update on Posting field</param>
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

    /// <summary>
    /// Sets a flag to skip confirmation dialogues during analysis view operations.
    /// </summary>
    procedure SetSkipConfirmationDialogue()
    begin
        SkipConfirmationDialogue := true;
    end;

    /// <summary>
    /// Opens the Analysis by Dimensions page for the current analysis view.
    /// </summary>
    procedure RunAnalysisByDimensionPage()
    var
        TempAnalysisByDimParameters: Record "Analysis by Dim. Parameters" temporary;
    begin
        TempAnalysisByDimParameters."Analysis View Code" := Code;
        TempAnalysisByDimParameters.Insert();
        PAGE.RUN(PAGE::"Analysis by Dimensions", TempAnalysisByDimParameters);
    end;

    /// <summary>
    /// Shows a notification to the user indicating that the analysis view needs to be reset.
    /// </summary>
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

    /// <summary>
    /// Integration event raised after analysis view reset operations are completed.
    /// </summary>
    /// <param name="AnalysisView">Analysis view record that was reset</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAnalysisViewReset(var AnalysisView: Record "Analysis View")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying analysis view filters to selected dimensions.
    /// </summary>
    /// <param name="AnalysisView">Analysis view record with filters being copied</param>
    /// <param name="ObjectType">Type of object receiving the filters</param>
    /// <param name="ObjectID">ID of object receiving the filters</param>
    /// <param name="AnalysisViewCode">Code of analysis view being copied from</param>
    /// <param name="GLAcc">G/L Account record for filter context</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyAnalysisViewFilters(var AnalysisView: Record "Analysis View"; ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var GLAcc: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Integration event raised before validating Dimension 1 Code field changes.
    /// </summary>
    /// <param name="Rec">Analysis view record being validated</param>
    /// <param name="xRec">Previous analysis view record values</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimension1Code(var Rec: Record "Analysis View"; var xRec: Record "Analysis View")
    begin
    end;

    /// <summary>
    /// Integration event raised before validating Dimension 2 Code field changes.
    /// </summary>
    /// <param name="Rec">Analysis view record being validated</param>
    /// <param name="xRec">Previous analysis view record values</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimension2Code(var Rec: Record "Analysis View"; var xRec: Record "Analysis View")
    begin
    end;

    /// <summary>
    /// Integration event raised before validating Dimension 3 Code field changes.
    /// </summary>
    /// <param name="Rec">Analysis view record being validated</param>
    /// <param name="xRec">Previous analysis view record values</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimension3Code(var Rec: Record "Analysis View"; var xRec: Record "Analysis View")
    begin
    end;

    /// <summary>
    /// Integration event raised before validating Dimension 4 Code field changes.
    /// </summary>
    /// <param name="Rec">Analysis view record being validated</param>
    /// <param name="xRec">Previous analysis view record values</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimension4Code(var Rec: Record "Analysis View"; var xRec: Record "Analysis View")
    begin
    end;

    /// <summary>
    /// Integration event raised before validating Date Compression field changes.
    /// </summary>
    /// <param name="Rec">Analysis view record being validated</param>
    /// <param name="xRec">Previous analysis view record values</param>
    /// <param name="IsHandled">Set to true to skip default validation logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDateCompression(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating the Blocked field on Analysis View records.
    /// Enables custom validation logic and the ability to bypass standard validation.
    /// </summary>
    /// <param name="Rec">Current Analysis View record being validated</param>
    /// <param name="xRec">Previous Analysis View record values</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBlocked(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating the Starting Date field on Analysis View records.
    /// Enables custom validation logic and the ability to bypass standard validation.
    /// </summary>
    /// <param name="Rec">Current Analysis View record being validated</param>
    /// <param name="xRec">Previous Analysis View record values</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStartingDate(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating the Include Budgets field on Analysis View records.
    /// Enables custom validation logic and the ability to bypass standard validation.
    /// </summary>
    /// <param name="Rec">Current Analysis View record being validated</param>
    /// <param name="xRec">Previous Analysis View record values</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIncludeBudgets(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating the Account Filter field on Analysis View records.
    /// Enables custom validation logic and the ability to bypass standard validation.
    /// </summary>
    /// <param name="Rec">Current Analysis View record being validated</param>
    /// <param name="xRec">Previous Analysis View record values</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAccountFilter(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating the Business Unit Filter field on Analysis View records.
    /// Enables custom validation logic and the ability to bypass standard validation.
    /// </summary>
    /// <param name="Rec">Current Analysis View record being validated</param>
    /// <param name="xRec">Previous Analysis View record values</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBusinessUnitFilter(var Rec: Record "Analysis View"; var xRec: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking if Last Entry or Date field is set on Analysis View records.
    /// Enables custom logic for determining analysis view update requirements.
    /// </summary>
    /// <param name="Rec">Current Analysis View record being checked</param>
    /// <param name="Result">Result of the check operation</param>
    /// <param name="IsHandled">Set to true to skip standard check logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfLastEntryOrDateIsSet(var Rec: Record "Analysis View"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before setting the Update on Posting field on Analysis View records.
    /// Enables custom logic for managing automatic analysis view updates.
    /// </summary>
    /// <param name="Rec">Current Analysis View record being modified</param>
    /// <param name="NewUpdateOnPosting">New value for Update on Posting field</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpdateOnPosting(var Rec: Record "Analysis View"; NewUpdateOnPosting: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised when validating account filter on Analysis View records.
    /// Enables additional validation or processing during account filter validation.
    /// </summary>
    /// <param name="AnalysisView">Current Analysis View record being validated</param>
    /// <param name="xRecAnalysisView">Previous Analysis View record values</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAccountFilter(var AnalysisView: Record "Analysis View"; var xRecAnalysisView: Record "Analysis View")
    begin
    end;

    /// <summary>
    /// Integration event raised when performing account filter lookup on Analysis View records.
    /// Enables custom lookup behavior for account filter field.
    /// </summary>
    /// <param name="Handled">Set to true if custom lookup was performed</param>
    /// <param name="AccountFilter">Account filter value being looked up</param>
    /// <param name="AnalysisView">Analysis View record with account filter</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupAccountFilter(var Handled: Boolean; var AccountFilter: Text; var AnalysisView: Record "Analysis View")
    begin
    end;

    /// <summary>
    /// Integration event for determining if an Analysis View is supported by custom implementations.
    /// Enables extensibility for additional analysis view types beyond standard G/L and Cash Flow.
    /// </summary>
    /// <param name="AnalysisView">Analysis View record to validate support for</param>
    /// <param name="IsSupported">Set to true if the analysis view type is supported</param>
    [IntegrationEvent(false, false)]
    internal procedure OnGetAnalysisViewSupported(var AnalysisView: Record "Analysis View"; var IsSupported: Boolean)
    begin
    end;
}

