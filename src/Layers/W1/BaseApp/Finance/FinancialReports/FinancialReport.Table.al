// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Enums;
using Microsoft.Finance.GeneralLedger.Setup;

table 88 "Financial Report"
{
    Caption = 'Financial Report';
    DataCaptionFields = Name, Description;
    LookupPageID = "Financial Reports";
    DataClassification = CustomerContent;

    fields
    {
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unique name (code) of the financial report.';
        }
        field(3; UseAmountsInAddCurrency; Boolean)
        {
            Caption = 'Use Amounts in Additional Currency';
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA30
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
        field(5; ShowLinesWithShowNo; Boolean)
        {
            Caption = 'Show All Lines';
            DataClassification = SystemMetadata;
        }
        field(6; Dim1Filter; Text[2048])
        {
            Caption = 'Dimension 1 Filter';
            DataClassification = SystemMetadata;
        }
        field(7; Dim2Filter; Text[2048])
        {
            Caption = 'Dimension 2 Filter';
            DataClassification = SystemMetadata;
        }
        field(8; Dim3Filter; Text[2048])
        {
            Caption = 'Dimension 3 Filter';
            DataClassification = SystemMetadata;
        }
        field(9; Dim4Filter; Text[2048])
        {
            Caption = 'Dimension 4 Filter';
            DataClassification = SystemMetadata;
        }
        field(10; CostCenterFilter; Text[2048])
        {
            Caption = 'Cost Center Filter';
            DataClassification = SystemMetadata;
        }
        field(11; CostObjectFilter; Text[2048])
        {
            Caption = 'Cost Object Filter';
            DataClassification = SystemMetadata;
        }
        field(12; CashFlowFilter; Text[2048])
        {
            Caption = 'Cash Flow Filter';
            DataClassification = SystemMetadata;
        }
        field(13; GLBudgetFilter; Text[2048])
        {
            Caption = 'G/L Budget Filter';
            DataClassification = SystemMetadata;
        }
        field(14; CostBudgetFilter; Text[2048])
        {
            Caption = 'Cost Budget Filter';
            DataClassification = SystemMetadata;
        }
        field(15; DateFilter; Text[2048])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        field(16; "Excel Template Code"; Code[50])
        {
            Caption = 'Default Excel Layout';
            DataClassification = SystemMetadata;
            TableRelation = "Fin. Report Excel Template"."Code" where("Financial Report Name" = field(Name));
            ToolTip = 'Specifies the Excel Layout that will be used when exporting to Excel.';
        }
#if not CLEANSCHEMA30
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
        }
        field(19; NegativeAmountFormatDefault; Enum "Fin. Report Negative Format")
        {
            Caption = 'Negative Amount Format';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the default negative amount format for this financial report.';
        }
        // Fields not in "FinancialReportUserFilters"
        field(50; Description; Text[80])
        {
            Caption = 'Display Title';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a title of the financial report. The text is shown as a title on the final report when you run it to get a PDF or to print it.';
        }
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
        field(53; "Internal Description"; Text[250])
        {
            Caption = 'Internal Description';
            ToolTip = 'Specifies the internal description of this financial report.';
            DataClassification = CustomerContent;
        }
        field(54; "Introductory Paragraph"; Blob)
        {
            Caption = 'Introductory Paragraph';
            DataClassification = CustomerContent;
        }
        field(55; "Closing Paragraph"; Blob)
        {
            Caption = 'Closing Paragraph';
            DataClassification = CustomerContent;
        }
        field(56; StartDateFilterFormula; DateFormula)
        {
            Caption = 'Start Date Filter Formula';
            DataClassification = SystemMetadata;
        }
        field(57; EndDateFilterFormula; DateFormula)
        {
            Caption = 'End Date Filter Formula';
            DataClassification = SystemMetadata;
        }
        field(58; DateFilterPeriodFormula; Code[20])
        {
            Caption = 'Date Filter Period Formula';
            DataClassification = SystemMetadata;
        }
        field(59; DateFilterPeriodFormulaLID; Integer)
        {
            Caption = 'Date Filter Period Formula Lang. ID';
            DataClassification = SystemMetadata;
        }
        field(60; LogoPositionDefault; Enum "Fin. Report Logo Position Def.")
        {
            Caption = 'Logo Position';
            ToolTip = 'Specifies how your company logo is displayed on the financial report.';
        }
        field(61; SheetDefinition; Code[10])
        {
            Caption = 'Sheet Definition';
            TableRelation = "Sheet Definition Name";

            trigger OnValidate()
            begin
                if SheetDefinition <> '' then
                    AccSchedManagement.CheckSheetAnalysisView(Rec."Financial Report Row Group", Rec.SheetDefinition);
            end;
        }
    }
    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
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

    trigger OnDelete()
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
    begin
        FinancialReportSchedule.SetRange("Financial Report Name", Name);
        FinancialReportSchedule.DeleteAll(true);
    end;

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

    procedure SetIntroductionParagraph(TextValue: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Introductory Paragraph".CreateOutStream(OutStream);
        OutStream.Write(TextValue);
    end;

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
}
