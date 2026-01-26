// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Stores aggregated financial data for analysis views with dimension breakdown.
/// Contains pre-calculated amounts from G/L entries and cash flow entries for optimized reporting performance.
/// </summary>
/// <remarks>
/// Analysis view entries are created and updated by the UpdateAnalysisView process. Each record represents
/// aggregated transaction data for a specific account, business unit, date, and dimension combination.
/// Supports both G/L Account and Cash Flow Account sources with up to 4 dimensions.
/// </remarks>
table 365 "Analysis View Entry"
{
    Caption = 'Analysis View Entry';
    DrillDownPageID = "Analysis View Entries";
    LookupPageID = "Analysis View Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Code of the analysis view that owns this entry.
        /// </summary>
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Analysis View" where("Account Source" = field("Account Source"));
        }
        /// <summary>
        /// Business unit code for consolidation and multi-company analysis.
        /// </summary>
        field(2; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// Account number (G/L Account or Cash Flow Account) that this entry represents.
        /// </summary>
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Source" = const("G/L Account")) "G/L Account"
            else
            if ("Account Source" = const("Cash Flow Account")) "Cash Flow Account";
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                GLAccount: Record "G/L Account";
                CashFlowAccount: Record "Cash Flow Account";
                GLAccountList: Page "G/L Account List";
                CashFlowAccountList: Page "Cash Flow Account List";
                IsHandled: Boolean;
            begin
                OnLookupAccountNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                case "Account Source" of
                    "Account Source"::"G/L Account":
                        begin
                            GLAccountList.LookupMode(true);
                            if GLAccountList.RunModal() = ACTION::LookupOK then begin
                                GLAccountList.GetRecord(GLAccount);
                                Rec.Validate("Account No.", GLAccount."No.");
                            end;
                        end;
                    "Account Source"::"Cash Flow Account":
                        begin
                            CashFlowAccountList.LookupMode(true);
                            if CashFlowAccountList.RunModal() = ACTION::LookupOK then begin
                                CashFlowAccountList.GetRecord(CashFlowAccount);
                                Rec.Validate("Account No.", CashFlowAccount."No.");
                            end;
                        end;
                end;
            end;
        }
        /// <summary>
        /// First dimension value code for multi-dimensional analysis and reporting.
        /// </summary>
        field(4; "Dimension 1 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Value Code';
        }
        /// <summary>
        /// Second dimension value code for multi-dimensional analysis and reporting.
        /// </summary>
        field(5; "Dimension 2 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Value Code';
        }
        /// <summary>
        /// Third dimension value code for extended multi-dimensional analysis and reporting.
        /// </summary>
        field(6; "Dimension 3 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Value Code';
        }
        /// <summary>
        /// Fourth dimension value code for comprehensive multi-dimensional analysis and reporting.
        /// </summary>
        field(7; "Dimension 4 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 4 Value Code';
        }
        /// <summary>
        /// Posting date of the transactions aggregated in this entry.
        /// </summary>
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Unique entry number for this analysis view entry record.
        /// </summary>
        field(9; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Net amount (debit minus credit) aggregated from the underlying transactions.
        /// </summary>
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnLookup()
            begin
                DrillDown();
            end;
        }
        /// <summary>
        /// Total debit amounts aggregated from the underlying transactions.
        /// </summary>
        field(11; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Debit Amount';
        }
        /// <summary>
        /// Total credit amounts aggregated from the underlying transactions.
        /// </summary>
        field(12; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Credit Amount';
        }
        /// <summary>
        /// Additional currency amount when using additional reporting currency.
        /// </summary>
        field(13; "Add.-Curr. Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Amount';
        }
        /// <summary>
        /// Additional currency debit amount for multi-currency analysis and reporting.
        /// Provides debit amounts in additional reporting currency for global financial analysis.
        /// </summary>
        field(14; "Add.-Curr. Debit Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Debit Amount';
        }
        /// <summary>
        /// Additional currency credit amount for multi-currency analysis and reporting.
        /// Provides credit amounts in additional reporting currency for global financial analysis.
        /// </summary>
        field(15; "Add.-Curr. Credit Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Credit Amount';
        }
        /// <summary>
        /// Source type indicating whether this entry originates from G/L accounts or Cash Flow accounts.
        /// Determines the account structure and available dimensions for analysis view processing.
        /// </summary>
        field(16; "Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Account Source';
        }
        /// <summary>
        /// Cash flow forecast number for cash flow analysis view entries.
        /// Links to specific cash flow forecast for cash flow account source entries.
        /// </summary>
        field(17; "Cash Flow Forecast No."; Code[20])
        {
            Caption = 'Cash Flow Forecast No.';
            TableRelation = "Cash Flow Forecast";
        }
        field(10720; "Old G/L Account No."; Code[20])
        {
            Caption = 'Old G/L Account No.';
        }
        field(10721; Updated; Boolean)
        {
            Caption = 'Updated';
        }
    }

    keys
    {
        key(Key1; "Analysis View Code", "Account No.", "Account Source", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Dimension 4 Value Code", "Business Unit Code", "Posting Date", "Entry No.", "Old G/L Account No.")
        {
            Clustered = true;
        }
        key(Key2; "Analysis View Code", "Account No.", "Account Source", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Dimension 4 Value Code", "Business Unit Code", "Posting Date", "Cash Flow Forecast No.")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Add.-Curr. Amount", "Add.-Curr. Debit Amount", "Add.-Curr. Credit Amount";
        }
    }

    fieldgroups
    {
    }

    var
        AnalysisView: Record "Analysis View";

#pragma warning disable AA0074
        Text000: Label '1,5,,Dimension 1 Value Code';
        Text001: Label '1,5,,Dimension 2 Value Code';
        Text002: Label '1,5,,Dimension 3 Value Code';
        Text003: Label '1,5,,Dimension 4 Value Code';
#pragma warning restore AA0074

    /// <summary>
    /// Gets the caption class for dimension fields based on analysis view configuration.
    /// Provides dynamic field captions based on the analysis view's dimension setup and naming.
    /// </summary>
    /// <param name="AnalysisViewDimType">Dimension number (1-4) to get caption class for</param>
    /// <returns>Caption class string for dynamic field captioning based on analysis view setup</returns>
    procedure GetCaptionClass(AnalysisViewDimType: Integer) Result: Text[250]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCaptionClass(Rec, AnalysisViewDimType, AnalysisView, Result, IsHandled);
        if IsHandled then
            exit;

        if AnalysisView.Code <> "Analysis View Code" then
            AnalysisView.Get("Analysis View Code");
        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 1 Code");

                    exit(Text000);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 2 Code");

                    exit(Text001);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 3 Code");

                    exit(Text002);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 4 Code");

                    exit(Text003);
                end;
        end;

        OnAfterGetCaptionClass(AnalysisView, AnalysisViewDimType, Result);
    end;

    [Scope('OnPrem')]
    procedure DrillDown()
    var
        TempGLEntry: Record "G/L Entry" temporary;
        TempCFForecastEntry: Record "Cash Flow Forecast Entry" temporary;
        AnalysisViewEntryToGLEntries: Codeunit AnalysisViewEntryToGLEntries;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrilldown(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Account Source" = "Account Source"::"G/L Account" then begin
            TempGLEntry.Reset();
            TempGLEntry.DeleteAll();
            AnalysisViewEntryToGLEntries.GetGLEntries(Rec, TempGLEntry);
            PAGE.RunModal(PAGE::"General Ledger Entries", TempGLEntry);
        end else begin
            TempCFForecastEntry.Reset();
            TempCFForecastEntry.DeleteAll();
            AnalysisViewEntryToGLEntries.GetCFLedgEntries(Rec, TempCFForecastEntry);
            PAGE.RunModal(PAGE::"Cash Flow Forecast Entries", TempCFForecastEntry);
        end;

        OnAfterDrillDown(Rec);
    end;

    /// <summary>
    /// Copies dimension filters from account schedule line to analysis view entry.
    /// Transfers filter criteria for dimension-based analysis and reporting in account schedules.
    /// </summary>
    /// <param name="AccSchedLine">Account schedule line containing dimension filters to copy</param>
    procedure CopyDimFilters(var AccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.CopyFilter("Dimension 1 Filter", "Dimension 1 Value Code");
        AccSchedLine.CopyFilter("Dimension 2 Filter", "Dimension 2 Value Code");
        AccSchedLine.CopyFilter("Dimension 3 Filter", "Dimension 3 Value Code");
        AccSchedLine.CopyFilter("Dimension 4 Filter", "Dimension 4 Value Code");
    end;

    /// <summary>
    /// Sets dimension filters on analysis view entry using text filter expressions.
    /// Applies filter criteria for all four dimensions in analysis view queries and reports.
    /// </summary>
    /// <param name="DimFilter1">Filter expression for dimension 1 value code</param>
    /// <param name="DimFilter2">Filter expression for dimension 2 value code</param>
    /// <param name="DimFilter3">Filter expression for dimension 3 value code</param>
    /// <param name="DimFilter4">Filter expression for dimension 4 value code</param>
    procedure SetDimFilters(DimFilter1: Text; DimFilter2: Text; DimFilter3: Text; DimFilter4: Text)
    begin
        SetFilter("Dimension 1 Value Code", DimFilter1);
        SetFilter("Dimension 2 Value Code", DimFilter2);
        SetFilter("Dimension 3 Value Code", DimFilter3);
        SetFilter("Dimension 4 Value Code", DimFilter4);
    end;

    /// <summary>
    /// Integration event raised after calculating caption class for analysis view dimension fields.
    /// Enables customization of dimension field captions based on analysis view configuration.
    /// </summary>
    /// <param name="AnalysisView">Analysis view record containing dimension setup</param>
    /// <param name="AnalysisViewDimType">Dimension number (1-4) being processed</param>
    /// <param name="Result">Caption class result that can be modified by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCaptionClass(var AnalysisView: Record "Analysis View"; AnalysisViewDimType: Integer; var Result: Text[250])
    begin
    end;

    /// <summary>
    /// Integration event raised after drilldown operation completes on analysis view entries.
    /// Enables additional processing after viewing detailed entries for analysis view records.
    /// </summary>
    /// <param name="AnalysisViewEntry">Analysis view entry record that was drilled down</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterDrillDown(var AnalysisViewEntry: Record "Analysis View Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating caption class for analysis view dimension fields.
    /// Enables custom logic to override standard caption class calculation.
    /// </summary>
    /// <param name="AnalysisViewEntry">Analysis view entry record being processed</param>
    /// <param name="AnalysisViewDimType">Dimension number (1-4) being processed</param>
    /// <param name="AnalysisView">Analysis view record with dimension configuration</param>
    /// <param name="Result">Caption class result that can be set by subscribers</param>
    /// <param name="IsHandled">Set to true to skip standard caption class processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaptionClass(var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisViewDimType: Integer; var AnalysisView: Record "Analysis View"; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before drilldown operation on analysis view entries.
    /// Enables custom drilldown logic to override standard G/L or Cash Flow entry display.
    /// </summary>
    /// <param name="AnalysisViewEntry">Analysis view entry record being drilled down</param>
    /// <param name="IsHandled">Set to true to skip standard drilldown processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrilldown(var AnalysisViewEntry: Record "Analysis View Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised when looking up account numbers in analysis view entries.
    /// Enables custom lookup logic for G/L accounts or Cash Flow accounts based on account source.
    /// </summary>
    /// <param name="AnalysisViewEntry">Analysis view entry record with account information</param>
    /// <param name="IsHandled">Set to true to skip standard account lookup processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupAccountNo(var AnalysisViewEntry: Record "Analysis View Entry"; var IsHandled: Boolean)
    begin
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;
}
