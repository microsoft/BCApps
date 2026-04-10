// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;
using System.Reflection;

/// <summary>
/// Configuration settings for VAT reporting functionality including number series, automation, and submission parameters.
/// Controls VAT return processing behavior, period management automation, and reporting validation rules.
/// </summary>
table 743 "VAT Report Setup"
{
    Caption = 'VAT Report Setup';
    LookupPageID = "VAT Report Setup";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Single record primary key for VAT report setup configuration.
        /// </summary>
        field(1; "Primary key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary key';
        }
        /// <summary>
        /// Number series for generating VAT report numbers for general report types.
        /// </summary>
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Allows modification of submitted VAT reports when enabled.
        /// </summary>
        field(3; "Modify Submitted Reports"; Boolean)
        {
            Caption = 'Allow Modification';
            ToolTip = 'Specifies if users can modify VAT reports that have been submitted to the tax authorities. If the field is left blank, users must create a corrective or supplementary VAT report instead.';
        }
        /// <summary>
        /// Number series specifically for VAT return report generation.
        /// </summary>
        field(4; "VAT Return No. Series"; Code[20])
        {
            Caption = 'VAT Return No. Series';
            ToolTip = 'Specifies the number series that is used for VAT return records.';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Number series for generating VAT return period records.
        /// </summary>
        field(20; "VAT Return Period No. Series"; Code[20])
        {
            Caption = 'VAT Return Period No. Series';
            ToolTip = 'Specifies the number series that is used for the VAT return period records.';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Version of the VAT report format configuration to use for new reports.
        /// </summary>
        field(21; "Report Version"; Code[10])
        {
            Caption = 'Report Version';
            ToolTip = 'Specifies the VAT report version that is used for the VAT reporting periods.';
            TableRelation = "VAT Reports Configuration"."VAT Report Version" where("VAT Report Type" = const("VAT Return"));
        }
        /// <summary>
        /// Frequency for automatic VAT return period updates via job queue processing.
        /// </summary>
        field(23; "Update Period Job Frequency"; Option)
        {
            Caption = 'Update Period Job Frequency';
            ToolTip = 'Specifies the job frequency for an automatic update of the VAT return periods.';
            OptionCaption = 'Never,Daily,Weekly';
            OptionMembers = Never,Daily,Weekly;

            trigger OnValidate()
            var
                VATReportMgt: Codeunit "VAT Report Mgt.";
            begin
                VATReportMgt.CreateAndStartAutoUpdateVATReturnPeriodJob(Rec);
            end;
        }
        /// <summary>
        /// Codeunit ID for manual VAT return period retrieval processing.
        /// </summary>
        field(24; "Manual Receive Period CU ID"; Integer)
        {
            Caption = 'Manual Receive Period CU ID';
            ToolTip = 'Specifies the codeunit ID associated with a manual receipt of the VAT return periods.';
            TableRelation = "CodeUnit Metadata".ID;
        }
        /// <summary>
        /// Caption of the manual receive period codeunit for display purposes.
        /// </summary>
        field(25; "Manual Receive Period CU Cap"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Manual Receive Period CU ID")));
            Caption = 'Manual Receive Period CU Cap';
            ToolTip = 'Specifies the codeunit caption associated with a manual receipt of the VAT return periods.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Codeunit ID for automatic VAT return period retrieval via job queue.
        /// </summary>
        field(26; "Auto Receive Period CU ID"; Integer)
        {
            Caption = 'Auto Receive Period CU ID';
            ToolTip = 'Specifies the codeunit ID associated with an automatic receipt of the VAT return periods. You can only edit this field if the Update Period Job Frequency field contains Never.';
            TableRelation = "CodeUnit Metadata".ID;

            trigger OnValidate()
            var
                VATReportMgt: Codeunit "VAT Report Mgt.";
            begin
                VATReportMgt.CreateAndStartAutoUpdateVATReturnPeriodJob(Rec);
            end;
        }
        /// <summary>
        /// Caption of the automatic receive period codeunit for display purposes.
        /// </summary>
        field(27; "Auto Receive Period CU Cap"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Auto Receive Period CU ID")));
            Caption = 'Auto Receive Period CU Cap';
            ToolTip = 'Specifies the codeunit caption associated with an automatic receipt of the VAT return periods.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Codeunit ID for receiving submitted VAT return information from tax authorities.
        /// </summary>
        field(28; "Receive Submitted Return CU ID"; Integer)
        {
            Caption = 'Receive Submitted Return CU ID';
            ToolTip = 'Specifies the codeunit ID associated with a receipt of the submitted VAT returns.';
            TableRelation = "CodeUnit Metadata".ID;
        }
        /// <summary>
        /// Caption of the receive submitted return codeunit for display purposes.
        /// </summary>
        field(29; "Receive Submitted Return CUCap"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Receive Submitted Return CU ID")));
            Caption = 'Receive Submitted Return CUCap';
            ToolTip = 'Specifies the codeunit caption associated with a receipt of the submitted VAT returns.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Date formula for calculating VAT return period reminder notifications.
        /// </summary>
        field(30; "Period Reminder Calculation"; DateFormula)
        {
            Caption = 'Period Reminder Calculation';
            ToolTip = 'Specifies a formula that is used to notify about an open VAT report period with an upcoming due date.';

            trigger OnValidate()
            begin
                if not CheckPositivePeriodReminderCalculation() then
                    Error(PositivePeriodReminderCalcErr);
            end;
        }
        /// <summary>
        /// Indicates whether VAT base amounts should be included in VAT reports.
        /// </summary>
        field(31; "Report VAT Base"; Boolean)
        {
            Caption = 'Report VAT Base';
            ToolTip = 'Specifies if the VAT base must be calculated and shown to the user in the VAT reports.';
        }
        /// <summary>
        /// Indicates whether VAT notes should be included in VAT reports.
        /// </summary>
        field(32; "Report VAT Note"; Boolean)
        {
            Caption = 'Report VAT Note';
            ToolTip = 'Specifies if the VAT report must include the contents of the Note field on the relevant report statement lines.';
        }
    }

    keys
    {
        key(Key1; "Primary key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PositivePeriodReminderCalcErr: Label 'The Period Reminder Calculation should be a positive formula. For example, "1M" should be used instead of "-1M".';

    /// <summary>
    /// Checks whether a period reminder calculation formula has been configured.
    /// Used to determine if reminder processing should be enabled.
    /// </summary>
    /// <returns>True if period reminder calculation is configured, false otherwise</returns>
    procedure IsPeriodReminderCalculation(): Boolean
    var
        DummyDateFormula: DateFormula;
    begin
        exit("Period Reminder Calculation" <> DummyDateFormula);
    end;

    local procedure CheckPositivePeriodReminderCalculation(): Boolean
    begin
        if not IsPeriodReminderCalculation() then
            exit(true);

        exit(CalcDate("Period Reminder Calculation", WorkDate()) - WorkDate() >= 0);
    end;
}