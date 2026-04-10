// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Visualization;

/// <summary>
/// Stores individual line configuration for account schedule chart setups with chart type and measure definitions.
/// Defines which account schedule lines and column layouts appear in charts with their visualization properties.
/// </summary>
/// <remarks>
/// Primary usage: Chart line configuration, measure and dimension setup for business chart visualization.
/// Integration: Links with Account Schedules Chart Setup, Account Schedule Lines, and Business Chart Buffer.
/// Extensibility: Standard table extension patterns for additional chart types and visualization options.
/// </remarks>
table 763 "Acc. Sched. Chart Setup Line"
{
    Caption = 'Acc. Sched. Chart Setup Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// User identifier associating the chart setup line with the owning user account.
        /// </summary>
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Account Schedules Chart Setup"."User ID" where(Name = field(Name));
        }
        /// <summary>
        /// Chart setup name linking this line to the parent chart configuration.
        /// </summary>
        field(2; Name; Text[30])
        {
            Caption = 'Name';
            Editable = false;
            TableRelation = "Account Schedules Chart Setup".Name where("User ID" = field("User ID"));
        }
        /// <summary>
        /// Account schedule name identifying the row definition source for chart data.
        /// </summary>
        field(3; "Account Schedule Name"; Code[10])
        {
            Caption = 'Account Schedule Name';
            ToolTip = 'Specifies the account schedule name.';
            Editable = false;
            TableRelation = "Acc. Schedule Name".Name;
        }
        /// <summary>
        /// Line number within the account schedule identifying the specific row for chart display.
        /// </summary>
        field(4; "Account Schedule Line No."; Integer)
        {
            Caption = 'Account Schedule Line No.';
            ToolTip = 'Specifies the number of the account schedule line that the chart is based on.';
            Editable = false;
            TableRelation = "Acc. Schedule Line"."Line No." where("Schedule Name" = field("Account Schedule Name"));
        }
        /// <summary>
        /// Column layout name identifying the column definition source for chart data.
        /// </summary>
        field(5; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            ToolTip = 'Specifies the name. This field is intended only for internal use.';
            Editable = false;
            TableRelation = "Column Layout Name".Name;
        }
        /// <summary>
        /// Line number within the column layout identifying the specific column for chart display.
        /// </summary>
        field(6; "Column Layout Line No."; Integer)
        {
            Caption = 'Column Layout Line No.';
            ToolTip = 'Specifies the line number. This field is intended only for internal use.';
            Editable = false;
            TableRelation = "Column Layout"."Line No." where("Column Layout Name" = field("Column Layout Name"));
        }
        /// <summary>
        /// Original measure name before user modifications for reference and reset functionality.
        /// </summary>
        field(10; "Original Measure Name"; Text[111])
        {
            Caption = 'Original Measure Name';
            ToolTip = 'Specifies the account schedule columns or lines that you select to include in the Account Schedules Chart Setup window.';
            Editable = false;
        }
        /// <summary>
        /// Display name for the measure used in chart legends and labels.
        /// </summary>
        field(15; "Measure Name"; Text[111])
        {
            Caption = 'Measure Name';
            ToolTip = 'Specifies the account schedule columns or lines that the measures on the y-axis in the specific chart are based on.';

            trigger OnValidate()
            begin
                TestField("Measure Name");
            end;
        }
        /// <summary>
        /// Text representation of the calculated measure value for display purposes.
        /// </summary>
        field(20; "Measure Value"; Text[30])
        {
            Caption = 'Measure Value';
            Editable = false;
        }
        /// <summary>
        /// Chart visualization type determining how this measure is displayed in the chart.
        /// </summary>
        field(40; "Chart Type"; Enum "Account Schedule Chart Type")
        {
            Caption = 'Chart Type';
            ToolTip = 'Specifies how the account schedule values are represented graphically in the chart.';

            trigger OnValidate()
            var
                AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
                AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                BusinessChartBuffer: Record "Business Chart Buffer";
                ActualNumMeasures: Integer;
            begin
                if ("Chart Type" <> "Chart Type"::" ") and IsMeasure() then begin
                    AccountSchedulesChartSetup.Get("User ID", Name);
                    AccountSchedulesChartSetup.SetLinkToMeasureLines(AccSchedChartSetupLine);
                    AccSchedChartSetupLine.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine."Chart Type"::" ");
                    ActualNumMeasures := 0;
                    if AccSchedChartSetupLine.FindSet() then
                        repeat
                            if (AccSchedChartSetupLine."Account Schedule Line No." <> "Account Schedule Line No.") or
                               (AccSchedChartSetupLine."Column Layout Line No." <> "Column Layout Line No.")
                            then
                                ActualNumMeasures += 1;
                        until AccSchedChartSetupLine.Next() = 0;
                    if ActualNumMeasures >= BusinessChartBuffer.GetMaxNumberOfMeasures() then
                        BusinessChartBuffer.RaiseErrorMaxNumberOfMeasuresExceeded();
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "User ID", Name, "Account Schedule Line No.", "Column Layout Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure IsMeasure() Result: Boolean
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        AccountSchedulesChartSetup.Get("User ID", Name);
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                Result := true;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                if "Account Schedule Line No." = 0 then
                    Result := true;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                if "Column Layout Line No." = 0 then
                    Result := true;
        end;
    end;

    /// <summary>
    /// Returns the default chart type for account schedule chart setup lines.
    /// Provides consistent default visualization when creating new chart configurations.
    /// </summary>
    /// <returns>Default chart type enum value for account schedule charts</returns>
    procedure GetDefaultAccSchedChartType(): Enum "Account Schedule Chart Type"
    begin
        exit("Chart Type"::Column);
    end;
}

