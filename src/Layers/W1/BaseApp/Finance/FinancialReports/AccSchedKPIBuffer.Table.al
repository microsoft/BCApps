// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 197 "Acc. Sched. KPI Buffer"
{
    Caption = 'Acc. Sched. KPI Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(3; "Closed Period"; Boolean)
        {
            Caption = 'Closed Period';
            DataClassification = SystemMetadata;
        }
        field(4; "Account Schedule Name"; Code[10])
        {
            Caption = 'Row Definition Name';
            DataClassification = SystemMetadata;
        }
        field(5; "KPI Code"; Code[10])
        {
            Caption = 'KPI Code';
            DataClassification = SystemMetadata;
        }
        field(6; "KPI Name"; Text[50])
        {
            Caption = 'KPI Name';
            DataClassification = SystemMetadata;
        }
        field(7; "Net Change Actual"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Actual';
            DataClassification = SystemMetadata;
        }
        field(8; "Balance at Date Actual"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Actual';
            DataClassification = SystemMetadata;
        }
        field(9; "Net Change Budget"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Budget';
            DataClassification = SystemMetadata;
        }
        field(10; "Balance at Date Budget"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Budget';
            DataClassification = SystemMetadata;
        }
        field(11; "Net Change Actual Last Year"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Actual Last Year';
            DataClassification = SystemMetadata;
        }
        field(12; "Balance at Date Act. Last Year"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Act. Last Year';
            DataClassification = SystemMetadata;
        }
        field(13; "Net Change Budget Last Year"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Budget Last Year';
            DataClassification = SystemMetadata;
        }
        field(14; "Balance at Date Bud. Last Year"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Bud. Last Year';
            DataClassification = SystemMetadata;
        }
        field(15; "Net Change Forecast"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Forecast';
            DataClassification = SystemMetadata;
        }
        field(16; "Balance at Date Forecast"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Forecast';
            DataClassification = SystemMetadata;
        }
        field(17; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Account Schedule Name", "KPI Code", "Dimension Set ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure AddColumnValue(ColumnLayout: Record "Column Layout"; Value: Decimal)
    var
        PreviousFiscalYearFormula: DateFormula;
    begin
        Evaluate(PreviousFiscalYearFormula, '<-1Y>');
        if ColumnLayout."Column Type" = ColumnLayout."Column Type"::"Net Change" then
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    "Net Change Actual Last Year" += Value
                else
                    "Net Change Actual" += Value
            else
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    "Net Change Budget Last Year" += Value
                else
                    "Net Change Budget" += Value
        else
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    "Balance at Date Act. Last Year" += Value
                else
                    "Balance at Date Actual" += Value
            else
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    "Balance at Date Bud. Last Year" += Value
                else
                    "Balance at Date Budget" += Value;
    end;

    procedure GetColumnValue(ColumnLayout: Record "Column Layout") Result: Decimal
    var
        PreviousFiscalYearFormula: DateFormula;
    begin
        Evaluate(PreviousFiscalYearFormula, '<-1Y>');
        if ColumnLayout."Column Type" = ColumnLayout."Column Type"::"Net Change" then
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    Result := "Net Change Actual Last Year"
                else
                    Result := "Net Change Actual"
            else
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    Result := "Net Change Budget Last Year"
                else
                    Result := "Net Change Budget"
        else
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    Result := "Balance at Date Act. Last Year"
                else
                    Result := "Balance at Date Actual"
            else
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    Result := "Balance at Date Bud. Last Year"
                else
                    Result := "Balance at Date Budget";
        exit(Result)
    end;
}
