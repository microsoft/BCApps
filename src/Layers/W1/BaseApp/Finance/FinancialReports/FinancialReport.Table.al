// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;

/// <summary>
/// Stores financial report definitions with configuration parameters and filter settings.
/// Central table for financial report setup including row/column definitions, period settings, and dimensional filters.
/// </summary>
/// <remarks>
/// Primary configuration table for financial reporting system. Links account schedules and column layouts
/// with report-specific parameters including period types, dimension filters, budget filters, and formatting options.
/// Supports advanced filtering, Excel template integration, and paragraph text management for comprehensive financial reporting.
/// </remarks>
table 88 "Financial Report"
{
    Caption = 'Financial Report';
    DataCaptionFields = Name, Description;
    LookupPageID = "Financial Reports";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique name identifying the financial report.
        /// </summary>
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unique name (code) of the financial report.';
        }
        /// <summary>
        /// Indicates whether to use amounts in additional reporting currency for calculations.
        /// </summary>
        field(3; UseAmountsInAddCurrency; Boolean)
        {
            Caption = 'Use Amounts in Additional Currency';
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA30
        /// <summary>
        /// Period type used for financial report analysis and calculations.
        /// </summary>
        field(4; PeriodType; Enum "Analysis Period Type")
        {
            Caption = 'Period Type';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'This field has been replaced by the PeriodTypeDefault field.';
#if not CLEAN28
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
#endif
        /// <summary>
        /// Controls whether to show account schedule lines marked with Show = No.
        /// </summary>
        field(5; ShowLinesWithShowNo; Boolean)
        {
            Caption = 'Show All Lines';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for Dimension 1 values in financial report calculations.
        /// </summary>
        field(6; Dim1Filter; Text[2048])
        {
            Caption = 'Dimension 1 Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for Dimension 2 values in financial report calculations.
        /// </summary>
        field(7; Dim2Filter; Text[2048])
        {
            Caption = 'Dimension 2 Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for Dimension 3 values in financial report calculations.
        /// </summary>
        field(8; Dim3Filter; Text[2048])
        {
            Caption = 'Dimension 3 Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for Dimension 4 values in financial report calculations.
        /// </summary>
        field(9; Dim4Filter; Text[2048])
        {
            Caption = 'Dimension 4 Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for Cost Center values in financial report calculations.
        /// </summary>
        field(10; CostCenterFilter; Text[2048])
        {
            Caption = 'Cost Center Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for Cost Object values in financial report calculations.
        /// </summary>
        field(11; CostObjectFilter; Text[2048])
        {
            Caption = 'Cost Object Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for Cash Flow values in financial report calculations.
        /// </summary>
        field(12; CashFlowFilter; Text[2048])
        {
            Caption = 'Cash Flow Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for G/L Budget entries in financial report calculations.
        /// </summary>
        field(13; GLBudgetFilter; Text[2048])
        {
            Caption = 'G/L Budget Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter expression for Cost Budget entries in financial report calculations.
        /// </summary>
        field(14; CostBudgetFilter; Text[2048])
        {
            Caption = 'Cost Budget Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date filter expression for financial report period selection.
        /// </summary>
        field(15; DateFilter; Text[2048])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Excel template code for default layout when exporting financial reports.
        /// </summary>
        field(16; "Excel Template Code"; Code[50])
        {
            Caption = 'Default Excel Layout';
            DataClassification = SystemMetadata;
            TableRelation = "Fin. Report Excel Template"."Code" where("Financial Report Name" = field(Name));
            ToolTip = 'Specifies the Excel Layout that will be used when exporting to Excel.';
        }
#if not CLEANSCHEMA30
        /// <summary>
        /// Format specification for displaying negative amounts in the financial report.
        /// </summary>
        field(17; NegativeAmountFormat; Enum "Analysis Negative Format")
        {
            Caption = 'Negative Amount Format';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'This field has been replaced by the NegativeAmountFormatDefault field.';
#if not CLEAN28
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
#endif
        field(18; PeriodTypeDefault; Enum "Financial Report Period Type")
        {
            Caption = 'Period Type';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies by which period amounts are displayed.';
            InitValue = Default;
        }
        field(19; NegativeAmountFormatDefault; Enum "Fin. Report Negative Format")
        {
            Caption = 'Negative Amount Format';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the default negative amount format for this financial report.';
            InitValue = Default;
        }
        // Fields not in "FinancialReportUserFilters"
        /// <summary>
        /// Display title shown on the final financial report output.
        /// </summary>
        field(50; Description; Text[80])
        {
            Caption = 'Display Title';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a title of the financial report. The text is shown as a title on the final report when you run it to get a PDF or to print it.';
        }
        /// <summary>
        /// Account schedule name used as the row definition for this financial report.
        /// </summary>
        field(51; "Financial Report Row Group"; Code[10])
        {
            Caption = 'Financial Report Row Group';
            TableRelation = "Acc. Schedule Name";
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the row definition (code) to be used for this financial report.';
            trigger OnValidate()
            begin
                AccSchedManagement.CheckAnalysisView(Rec."Financial Report Row Group", Rec."Financial Report Column Group", true);
            end;
        }
        /// <summary>
        /// Column layout name used as the column definition for this financial report.
        /// </summary>
        field(52; "Financial Report Column Group"; Code[10])
        {
            Caption = 'Financial Report Column Group';
            TableRelation = "Column Layout Name";
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the column definition (code) to be used for this financial report.';
            trigger OnValidate()
            begin
                AccSchedManagement.CheckAnalysisView(Rec."Financial Report Row Group", Rec."Financial Report Column Group", true);
            end;
        }
        /// <summary>
        /// Internal description for administrative purposes and report management.
        /// </summary>
#if not CLEAN28
#pragma warning disable AS0086
#endif
        field(53; "Internal Description"; Text[500])
#if not CLEAN28
#pragma warning restore AS0086
#endif
        {
            Caption = 'Internal Description';
            ToolTip = 'Specifies the internal description of this financial report.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Introductory paragraph text displayed at the beginning of the financial report.
        /// </summary>
        field(54; "Introductory Paragraph"; Blob)
        {
            Caption = 'Introductory Paragraph';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Closing paragraph text displayed at the end of the financial report.
        /// </summary>
        field(55; "Closing Paragraph"; Blob)
        {
            Caption = 'Closing Paragraph';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Date formula for calculating the start date of the report period.
        /// </summary>
        field(56; StartDateFilterFormula; DateFormula)
        {
            Caption = 'Start Date Filter Formula';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date formula for calculating the end date of the report period.
        /// </summary>
        field(57; EndDateFilterFormula; DateFormula)
        {
            Caption = 'End Date Filter Formula';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Period formula code for date filter calculations.
        /// </summary>
        field(58; DateFilterPeriodFormula; Code[20])
        {
            Caption = 'Date Filter Period Formula';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Language ID for period formula localization.
        /// </summary>
        field(59; DateFilterPeriodFormulaLID; Integer)
        {
            Caption = 'Date Filter Period Formula Lang. ID';
            DataClassification = SystemMetadata;
        }
        field(60; LogoPositionDefault; Enum "Fin. Report Logo Position Def.")
        {
            Caption = 'Logo Position';
            ToolTip = 'Specifies how your company logo is displayed on the financial report.';
            InitValue = Default;
        }
        field(61; DimPerspective; Code[10])
        {
            Caption = 'Dimension Perspective';
            ToolTip = 'Specifies the dimension perspective to be used for the financial report.';
            TableRelation = "Dimension Perspective Name";

            trigger OnValidate()
            begin
                if DimPerspective <> '' then
                    AccSchedManagement.CheckPerspectiveAnalysisView(Rec."Financial Report Row Group", Rec.DimPerspective);
            end;
        }
        field(62; "Last Run by User"; DateTime)
        {
            Caption = 'Your Last Run';
            ToolTip = 'Specifies the last date-time this report was run by you.';
            Fieldclass = FlowField;
            Calcformula = max("Financial Report Audit Log".SystemCreatedAt where(
                "Report Name" = field(Name),
                User = filter('%user')));
            Editable = false;
        }
        field(63; CategoryCode; Code[20])
        {
            Caption = 'Category';
            TableRelation = "Financial Report Category";
            ToolTip = 'Specifies the category code for the financial report.';
            DataClassification = CustomerContent;
        }
        field(64; Status; Code[10])
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            TableRelation = "Financial Report Status";
            ToolTip = 'Specifies the status code for the financial report. The status code helps you organize the lifecycle of your financial reports.';
        }
        field(65; "Status Blocked"; Boolean)
        {
            CalcFormula = exist("Financial Report Status" where("Code" = field(Status), "Blocked" = const(true)));
            Caption = 'Status Blocked';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the status code is a blocked status.';
        }
    }
    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(Brick; CategoryCode, Description, Status, Name, "Last Run by User", "Internal Description") { }
    }

    var
        GLSetup: Record "General Ledger Setup";
        AccSchedManagement: Codeunit AccSchedManagement;
#if not CLEAN28
#pragma warning disable AL0432
        FeatureFinancialReportDef: Codeunit "Feature - Fin. Report Default";
#pragma warning restore AL0432
#endif
        GLSetupRead: Boolean;

    trigger OnInsert()
    begin
        AccSchedManagement.CheckAnalysisView(Rec."Financial Report Row Group", Rec."Financial Report Column Group", true);
    end;

    trigger OnRename()
    var
        GLSetup: Record "General Ledger Setup";
        GLSetupModified: Boolean;
    begin
        if GLSetup.Get() then begin
            if GLSetup."Fin. Rep. for Balance Sheet" = xRec.Name then begin
                GLSetup."Fin. Rep. for Balance Sheet" := Rec.Name;
                GLSetupModified := true;
            end;
            if GLSetup."Fin. Rep. for Income Stmt." = xRec.Name then begin
                GLSetup."Fin. Rep. for Income Stmt." := Rec.Name;
                GLSetupModified := true;
            end;
            if GLSetup."Fin. Rep. for Cash Flow Stmt" = xRec.Name then begin
                GLSetup."Fin. Rep. for Cash Flow Stmt" := Rec.Name;
                GLSetupModified := true;
            end;
            if GLSetup."Fin. Rep. for Retained Earn." = xRec.Name then begin
                GLSetup."Fin. Rep. for Retained Earn." := Rec.Name;
                GLSetupModified := true;
            end;
            if GLSetupModified then
                GLSetup.Modify();
        end;
    end;

    trigger OnDelete()
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
    begin
        FinancialReportSchedule.SetRange("Financial Report Name", Name);
        FinancialReportSchedule.DeleteAll(true);
    end;

    /// <summary>
    /// Retrieves the introductory paragraph text from the BLOB field.
    /// Returns the formatted text content for display in financial reports.
    /// </summary>
    /// <returns>Introductory paragraph text content</returns>
    procedure GetIntroductoryParagraph(): Text
    var
        InStream: InStream;
        TextValue: Text;
    begin
        Rec.CalcFields(Rec."Introductory Paragraph");
        Rec."Introductory Paragraph".CreateInStream(InStream);
        InStream.Read(TextValue);
        exit(TextValue);
    end;

    /// <summary>
    /// Sets the introductory paragraph text in the BLOB field.
    /// Stores formatted text content for inclusion in financial reports.
    /// </summary>
    /// <param name="TextValue">Text content to store as introductory paragraph</param>
    procedure SetIntroductionParagraph(TextValue: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Introductory Paragraph".CreateOutStream(OutStream);
        OutStream.Write(TextValue);
    end;

    /// <summary>
    /// Retrieves the closing paragraph text from the BLOB field.
    /// Returns the formatted text content for display in financial reports.
    /// </summary>
    /// <returns>Closing paragraph text content</returns>
    procedure GetClosingParagraph(): Text
    var
        InStream: InStream;
        TextValue: Text;
    begin
        Rec.CalcFields(Rec."Closing Paragraph");
        Rec."Closing Paragraph".CreateInStream(InStream);
        InStream.Read(TextValue);
        exit(TextValue);
    end;

    /// <summary>
    /// Sets the closing paragraph text in the BLOB field.
    /// Stores formatted text content for financial report footer display.
    /// </summary>
    /// <param name="TextValue">Closing paragraph text to store</param>
    procedure SetClosingParagraph(TextValue: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Closing Paragraph".CreateOutStream(OutStream);
        OutStream.Write(TextValue);
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    procedure GetEffectivePeriodType(): Enum "Analysis Period Type"
    begin
#if not CLEAN28
        if not FeatureFinancialReportDef.IsDefaultsFeatureEnabled() then
            exit(PeriodType);
#endif
        if PeriodTypeDefault <> PeriodTypeDefault::Default then
            exit(Enum::"Analysis Period Type".FromInteger(PeriodTypeDefault.AsInteger()));
        ReadGLSetup();
        exit(Enum::"Analysis Period Type".FromInteger(GLSetup."Fin. Rep. Period Type".AsInteger()));
    end;

    procedure GetEffectiveNegativeAmountFormat(): Enum "Analysis Negative Format"
    begin
#if not CLEAN28
        if not FeatureFinancialReportDef.IsDefaultsFeatureEnabled() then
            exit(NegativeAmountFormat);
#endif
        if NegativeAmountFormatDefault <> NegativeAmountFormatDefault::Default then
            exit(Enum::"Analysis Negative Format".FromInteger(NegativeAmountFormatDefault.AsInteger()));
        ReadGLSetup();
        exit(Enum::"Analysis Negative Format".FromInteger(GLSetup."Fin. Rep. Neg. Amount Format".AsInteger()));
    end;

    procedure GetEffectiveLogoPosition(): Enum "Fin. Report Logo Position"
    begin
        if LogoPositionDefault <> LogoPositionDefault::Default then
            exit(Enum::"Fin. Report Logo Position".FromInteger(LogoPositionDefault.AsInteger()));
        ReadGLSetup();
        exit(Enum::"Fin. Report Logo Position".FromInteger(GLSetup."Fin. Rep. Company Logo Pos.".AsInteger()));
    end;

    procedure SetDefaultStatusFromGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if Rec.Status <> '' then
            exit;
        GLSetup.Get();
        if GLSetup.DefaultFinancialReportStatus <> '' then
            Rec.Status := GLSetup.DefaultFinancialReportStatus;
    end;
}
