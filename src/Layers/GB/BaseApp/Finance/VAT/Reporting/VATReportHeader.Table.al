// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using System.DateTime;
using System.Security.AccessControl;

/// <summary>
/// Header information for VAT reports including VAT returns and EC sales lists.
/// Manages report lifecycle, period definitions, and status tracking throughout the reporting process.
/// </summary>
table 740 "VAT Report Header"
{
    Caption = 'VAT Report Header';
    LookupPageID = "VAT Report List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the VAT report assigned from number series.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        /// <summary>
        /// Configuration type determining the VAT report format and processing rules.
        /// </summary>
        field(2; "VAT Report Config. Code"; Enum "VAT Report Configuration")
        {
            Caption = 'VAT Report Config. Code';
            ToolTip = 'Specifies the appropriate configuration code for EC Sales List Reports.';
            Editable = true;
            TableRelation = "VAT Reports Configuration"."VAT Report Type";

            trigger OnValidate()
            begin
                CheckEditingAllowed();
            end;
        }
        /// <summary>
        /// Type of VAT report defining submission behavior and validation requirements.
        /// </summary>
        field(3; "VAT Report Type"; Option)
        {
            Caption = 'VAT Report Type';
            ToolTip = 'Specifies if the VAT report is a standard report, or if it is related to a previously submitted VAT report.';
            OptionCaption = 'Standard,Corrective,Supplementary';
            OptionMembers = Standard,Corrective,Supplementary;

            trigger OnValidate()
            begin
                CheckEditingAllowed();

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        "Original Report No." := '';
                    "VAT Report Type"::Corrective, "VAT Report Type"::Supplementary:
                        begin
                            VATReportSetup.Get();
                            if VATReportSetup."Modify Submitted Reports" then
                                Error(Text001, VATReportSetup.FieldCaption("Modify Submitted Reports"), VATReportSetup.TableCaption());
                        end;
                end;
            end;
        }
        /// <summary>
        /// Starting date of the reporting period for VAT calculations.
        /// </summary>
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';
            ToolTip = 'Specifies the first date of the reporting period.';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
                TestField("Start Date");
                HandleDateInput();
            end;
        }
        /// <summary>
        /// Ending date of the reporting period for VAT calculations.
        /// </summary>
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';
            ToolTip = 'Specifies the last date of the reporting period.';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
                TestField("End Date");
                CheckEndDate();
                HandleDateInput();
            end;
        }
        /// <summary>
        /// Current status of the VAT report in the submission workflow.
        /// </summary>
        field(6; Status; Enum "VAT Report Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the report is in progress, is completed, or contains errors.';
            Editable = false;
        }
        /// <summary>
        /// Number series code used for generating the report number.
        /// </summary>
        field(8; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
            end;
        }
        /// <summary>
        /// Reference to the original report number for corrective and supplementary reports.
        /// </summary>
        field(9; "Original Report No."; Code[20])
        {
            Caption = 'Original Report No.';
            ToolTip = 'Specifies the number of the original report.';

            trigger OnLookup()
            var
                LookupVATReportHeader: Record "VAT Report Header";
                VATReportList: Page "VAT Report List";
                ShowLookup: Boolean;
                IsHandled: Boolean;
                TypeFilterText: Text[1024];
            begin
                IsHandled := false;
                OnBeforeLookupOriginalReportNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                TypeFilterText := '';
                ShowLookup := false;

                case "VAT Report Type" of
                    "VAT Report Type"::Corrective, "VAT Report Type"::Supplementary:
                        ShowLookup := true;
                end;

                if ShowLookup then begin
                    LookupVATReportHeader.SetFilter("No.", '<>' + "No.");
                    LookupVATReportHeader.SetRange(Status, Status::Accepted);
                    LookupVATReportHeader.SetFilter("VAT Report Type", TypeFilterText);
                    VATReportList.SetTableView(LookupVATReportHeader);
                    VATReportList.LookupMode(true);
                    if VATReportList.RunModal() = ACTION::LookupOK then begin
                        VATReportList.GetRecord(LookupVATReportHeader);
                        Validate("Original Report No.", LookupVATReportHeader."No.");
                    end;
                end;
            end;

            trigger OnValidate()
            var
                VATReportHeader: Record "VAT Report Header";
            begin
                CheckEditingAllowed();

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        if "Original Report No." <> '' then
                            Error(Text006, "VAT Report Type");
                    "VAT Report Type"::Corrective, "VAT Report Type"::Supplementary:
                        begin
                            TestField("Original Report No.");
                            if "Original Report No." = "No." then
                                Error(Text005);
                            VATReportHeader.Get("VAT Report Config. Code", "Original Report No.");
                            "Start Date" := VATReportHeader."Start Date";
                            "End Date" := VATReportHeader."End Date";
                        end;
                end;
            end;
        }
        /// <summary>
        /// Predefined period type for automatic date calculation (Month, Quarter, Year, etc.).
        /// </summary>
        field(10; "Period Type"; Option)
        {
            Caption = 'Period Type';
            ToolTip = 'Specifies the length of the reporting period.';
            OptionCaption = ' ,,Month,Quarter,Year,Bi-Monthly,Half-Year,Half-Month,Weekly';
            OptionMembers = " ",,Month,Quarter,Year,"Bi-Monthly","Half-Year","Half-Month","Weekly";

            trigger OnValidate()
            begin
                if "Period Type" = "Period Type"::Year then
                    "Period No." := 1;

                HandlePeriodInput();
            end;
        }
        /// <summary>
        /// Sequential number within the period type for date calculation.
        /// </summary>
        field(11; "Period No."; Integer)
        {
            Caption = 'Period No.';
            ToolTip = 'Specifies the specific reporting period to use.';
            TableRelation = "Date Lookup Buffer"."Period No." where("Period Type" = field("Period Type"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                HandlePeriodInput();
            end;
        }
        /// <summary>
        /// Year component for period-based date calculation.
        /// </summary>
        field(12; "Period Year"; Integer)
        {
            Caption = 'Period Year';
            ToolTip = 'Specifies the year of the reporting period.';

            trigger OnValidate()
            begin
                HandlePeriodInput();
            end;
        }
        /// <summary>
        /// Message identifier returned from tax authority submission system.
        /// </summary>
        field(13; "Message Id"; Text[250])
        {
            Caption = 'Message Id';
            ToolTip = 'Specifies the message ID of the report listing sales to other EU countries/regions.';
        }
        /// <summary>
        /// Template name for VAT statement used in report line generation.
        /// </summary>
        field(14; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            ToolTip = 'Specifies the name of the statement template from the EC Sales List Report.';
            TableRelation = "VAT Statement Template";
        }
        /// <summary>
        /// Statement name within the template for VAT line generation rules.
        /// </summary>
        field(15; "Statement Name"; Code[10])
        {
            Caption = 'Statement Name';
            ToolTip = 'Specifies the name of the statement from the EC Sales List Report.';
            TableRelation = "VAT Statement Name".Name where("Statement Template Name" = field("Statement Template Name"));
        }
        /// <summary>
        /// Version of the VAT report format and validation rules.
        /// </summary>
        field(16; "VAT Report Version"; Code[10])
        {
            Caption = 'VAT Report Version';
            ToolTip = 'Specifies version of the report.';
#pragma warning disable AL0603
            TableRelation = "VAT Reports Configuration"."VAT Report Version" where("VAT Report Type" = field("VAT Report Config. Code"));
#pragma warning restore AL0603
        }
        /// <summary>
        /// User security ID of the person who submitted the report.
        /// </summary>
        field(17; "Submitted By"; Guid)
        {
            Caption = 'Submitted By';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = User."User Security ID";
        }
        /// <summary>
        /// Date when the report was submitted to tax authorities.
        /// </summary>
        field(18; "Submitted Date"; Date)
        {
            Caption = 'Submitted Date';
        }
        /// <summary>
        /// Reference to associated VAT return period for automated reporting.
        /// </summary>
        field(19; "Return Period No."; Code[20])
        {
            Caption = 'Return Period No.';
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// Obsolete field for VAT date type selection.
        /// </summary>
        field(20; "Date Type"; Enum "VAT Date Type")
        {
            Caption = 'Date Type';
            ObsoleteReason = 'Selected VAT Date type no longer supported';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        /// <summary>
        /// Additional information text to include with the VAT report submission.
        /// </summary>
        field(30; "Additional Information"; Code[50])
        {
            Caption = 'Additional Information';
            ToolTip = 'Specifies the additional information must be added to VAT report.';
        }
        /// <summary>
        /// Timestamp when the VAT report record was created.
        /// </summary>
        field(31; "Created Date-Time"; DateTime)
        {
            Editable = false;
            Caption = 'Created Date-Time';
            ToolTip = 'Specifies the date when the VAT report lines were created.';
        }
        /// <summary>
        /// Country/region filter applied to VAT entries for report generation.
        /// </summary>
        field(32; "Country/Region Filter"; Text[250])
        {
            Editable = false;
            Caption = 'Country/Region Filter';
            ToolTip = 'Specifies the country/region filter for the report.';
        }
        /// <summary>
        /// Indicates whether report amounts are calculated in additional reporting currency.
        /// </summary>
        field(100; "Amounts in Add. Rep. Currency"; Boolean)
        {
            Caption = 'Amounts in Add. Rep. Currency';
            ToolTip = 'Specifies whether the amounts are in the additional reporting currency.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Report Config. Code", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        TestField(Status, Status::Open);
        VATStatementReportLine.SetRange("VAT Report No.", "No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", "VAT Report Config. Code");
        VATStatementReportLine.DeleteAll();
        VATReportLineRelation.SetRange("VAT Report No.", "No.");
        VATReportLineRelation.DeleteAll();
        RemoveVATReturnPeriodLink();
        RemoveECSLLinesAndRelation();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            if NoSeries.AreRelated(GetNoSeriesCode(), xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := GetNoSeriesCode();
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        InitRecord();
    end;

    trigger OnModify()
    begin
        CheckDates();
    end;

    trigger OnRename()
    begin
        Error(Text004);
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Codeunit "No. Series";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The value of %1 field in the %2 window does not allow this option.';
        Text002: Label 'Editing is not allowed because the report is marked as %1.';
#pragma warning restore AA0470
        Text003: Label 'The end date cannot be earlier than the start date.';
        Text004: Label 'You cannot rename the report because it has been assigned a report number.';
        Text005: Label 'You cannot specify the same report as the reference report.';
#pragma warning disable AA0470
        Text006: Label 'You cannot specify an original report for a report of type %1.';
        Text007: Label 'This is not allowed because of the setup in the %1 window.';
        Text008: Label 'You must specify an original report for a report of type %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    /// <summary>
    /// Gets the appropriate number series code based on VAT report configuration type.
    /// Returns specific series for VAT returns or general series for other report types.
    /// </summary>
    /// <returns>Number series code for report number generation</returns>
    procedure GetNoSeriesCode() Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        VATReportSetup.Get();
        if "VAT Report Config. Code" = "VAT Report Config. Code"::"VAT Return" then begin
            VATReportSetup.TestField("VAT Return No. Series");
            exit(VATReportSetup."VAT Return No. Series");
        end;

        VATReportSetup.TestField("No. Series");
        exit(VATReportSetup."No. Series");
    end;

    /// <summary>
    /// Provides assistance for editing report number with number series lookup.
    /// Allows manual number series selection and generates next available number.
    /// </summary>
    /// <param name="OldVATReportHeader">Previous version of the VAT report header record</param>
    /// <returns>True if assist edit completed successfully, false otherwise</returns>
    procedure AssistEdit(OldVATReportHeader: Record "VAT Report Header"): Boolean
    begin
        if NoSeries.LookupRelatedNoSeries(GetNoSeriesCode(), OldVATReportHeader."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    /// <summary>
    /// Initializes new VAT report record with default period and configuration values.
    /// Sets period to previous month for VAT returns and EC sales lists.
    /// </summary>
    procedure InitRecord()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        date: Date;
    begin
        if ("VAT Report Config. Code" = "VAT Report Config. Code"::"EC Sales List") or
           ("VAT Report Config. Code" = "VAT Report Config. Code"::"VAT Return")
        then begin
            date := CalcDate('<-1M>', WorkDate());
            Validate("Period Year", Date2DMY(date, 3));
            Validate("Period Type", "Period Type"::Month);
            Validate("Period No.", Date2DMY(date, 2));
        end else begin
            "Start Date" := WorkDate();
            "End Date" := WorkDate();
        end;

        VATReportsConfiguration.SetRange("VAT Report Type", "VAT Report Config. Code");
        if VATReportsConfiguration.FindFirst() and (VATReportsConfiguration.Count = 1) then
            "VAT Report Version" := VATReportsConfiguration."VAT Report Version";

        OnAfterInitRecord(Rec);
    end;

    /// <summary>
    /// Validates that the report status allows editing operations.
    /// Prevents modification of reports that are no longer in Open status.
    /// </summary>
    procedure CheckEditingAllowed()
    begin
        if Status <> Status::Open then
            Error(Text002, Format(Status));
    end;

    /// <summary>
    /// Validates that start and end dates are filled and end date is not earlier than start date.
    /// Performs comprehensive date validation for the reporting period.
    /// </summary>
    procedure CheckDates()
    begin
        TestField("Start Date");
        TestField("End Date");
        CheckEndDate();
    end;

    /// <summary>
    /// Validates that the end date is not earlier than the start date.
    /// Ensures logical consistency of the reporting period.
    /// </summary>
    procedure CheckEndDate()
    begin
        if "End Date" < "Start Date" then
            Error(Text003);
    end;

    /// <summary>
    /// Validates that the report is in Released status before submission.
    /// Ensures proper workflow compliance for VAT report submission.
    /// </summary>
    procedure CheckIfCanBeSubmitted()
    begin
        TestField(Status, Status::Released);
    end;

    /// <summary>
    /// Validates that the report can be reopened based on status and setup configuration.
    /// Checks VAT report setup to determine if submitted reports can be modified.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header record to validate</param>
    procedure CheckIfCanBeReopened(VATReportHeader: Record "VAT Report Header")
    begin
        if VATReportHeader.Status <> VATReportHeader.Status::Released then
            if VATReportSetup.Get() then
                if not VATReportSetup."Modify Submitted Reports" then
                    Error(Text007, VATReportSetup.TableCaption());
    end;

    /// <summary>
    /// Validates that the report can be released from Open status with proper original report reference.
    /// Ensures required fields are completed before release.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header record to validate</param>
    procedure CheckIfCanBeReleased(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        VATReportHeader.TestOriginalReportNo();
    end;

    /// <summary>
    /// Validates that original report number is specified for corrective and supplementary reports.
    /// Ensures proper reference for non-standard VAT report types.
    /// </summary>
    internal procedure TestOriginalReportNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestOriginalReportNo(Rec, IsHandled);
        if IsHandled then
            exit;

        if "VAT Report Type" in ["VAT Report Type"::Corrective, "VAT Report Type"::Supplementary] then
            if "Original Report No." = '' then
                Error(Text008, Format("VAT Report Type"));
    end;

    /// <summary>
    /// Converts period type, number, and year fields to specific start and end dates.
    /// Calculates date ranges for various period types including months, quarters, and custom periods.
    /// </summary>
    procedure PeriodToDate()
    var
        StartDay: Integer;
    begin
        if not IsPeriodValid() then
            exit;

        if "Period Type" = "Period Type"::Month then begin
            "Start Date" := DMY2Date(1, "Period No.", "Period Year");
            "End Date" := CalcDate('<1M-1D>', "Start Date");
        end;

        if "Period Type" = "Period Type"::Quarter then begin
            "Start Date" := DMY2Date(1, 1 + ("Period No." - 1) * 3, "Period Year");
            "End Date" := CalcDate('<+3M-1D>', "Start Date");
        end;

        if "Period Type" = "Period Type"::Year then begin
            "Start Date" := DMY2Date(1, 1, "Period Year");
            "End Date" := DMY2Date(31, 12, "Period Year");
        end;

        if "Period Type" = "Period Type"::"Bi-Monthly" then begin
            "Start Date" := DMY2Date(1, "Period No." * 2 - 1, "Period Year");
            "End Date" := CalcDate('<1M+CM>', "Start Date");
        end;

        if "Period Type" = "Period Type"::"Half-Year" then begin
            "Start Date" := DMY2Date(1, "Period No." * 6 - 5, "Period Year");
            "End Date" := CalcDate('<CM + 5M>', "Start Date");
        end;

        if "Period Type" = "Period Type"::"Half-Month" then begin
            if ("Period No." mod 2) = 0 then
                StartDay := 16
            else
                StartDay := 1;

            "Start Date" := DMY2Date(StartDay, Round("Period No." / 2, 1, '>'), "Period Year");
            if ("Period No." mod 2) = 0 then
                "End Date" := CalcDate('<CM>', "Start Date")
            else
                "End Date" := DMY2Date(15, Date2DMY("Start Date", 2), Date2DMY("Start Date", 3));
        end;

        if "Period Type" = "Period Type"::"Weekly" then begin
            "Start Date" := CalcDate('<W' + FORMAT("Period No.") + '>', DMY2Date(1, 1, "Period Year"));
            "End Date" := CalcDate('<CW>', "Start Date");
        end;
    end;

    local procedure HandleDateInput()
    begin
        Clear("Period No.");
        Clear("Period Type");
        Clear("Period Year");
    end;

    local procedure HandlePeriodInput()
    begin
        Clear("Start Date");
        Clear("End Date");

        if not IsPeriodValid() then
            exit;

        PeriodToDate();
    end;

    /// <summary>
    /// Validates period type, number, and year combination for logical consistency.
    /// Checks value ranges for different period types to ensure valid date calculations.
    /// </summary>
    /// <returns>True if period values are valid, false otherwise</returns>
    procedure IsPeriodValid(): Boolean
    begin
        if ("Period Year" = 0) or ("Period Type" = "Period Type"::" ") or ("Period No." = 0) then
            exit(false);

        if ("Period Type" = "Period Type"::Quarter) and
           (("Period No." < 1) or ("Period No." > 4))
        then
            exit(false);

        if ("Period Type" = "Period Type"::Month) and
           (("Period No." < 1) or ("Period No." > 12))
        then
            exit(false);

        if ("Period Type" = "Period Type"::"Bi-Monthly") and
           (("Period No." < 1) or ("Period No." > 6))
        then
            exit(false);

        if ("Period Type" = "Period Type"::"Half-Year") and
           (("Period No." < 1) or ("Period No." > 2))
        then
            exit(false);

        if ("Period Type" = "Period Type"::"Half-Month") and
           (("Period No." < 1) or ("Period No." > 24))
        then
            exit(false);

        if ("Period Type" = "Period Type"::Weekly) and
           (("Period No." < 1) or ("Period No." > 53))
        then
            exit(false);

        exit(true);
    end;

    local procedure RemoveVATReturnPeriodLink()
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        if "Return Period No." <> '' then
            if VATReturnPeriod.Get("Return Period No.") then begin
                VATReturnPeriod.Validate("VAT Return No.", '');
                VATReturnPeriod.Modify(true);
            end;
    end;

    local procedure RemoveECSLLinesAndRelation()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        if "VAT Report Config. Code" <> "VAT Report Config. Code"::"EC Sales List" then
            exit;

        ECSLVATReportLineRelation.SetRange("ECSL Report No.", "No.");
        if not ECSLVATReportLineRelation.IsEmpty() then
            ECSLVATReportLineRelation.DeleteAll(true);

        ECSLVATReportLine.SetRange("Report No.", "No.");
        if not ECSLVATReportLine.IsEmpty() then
            ECSLVATReportLine.DeleteAll(true);
    end;

    /// <summary>
    /// Integration event raised after initializing a new VAT report record.
    /// Allows customization of default values and additional initialization logic.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header being initialized</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var VATReportHeader: Record "VAT Report Header")
    begin
    end;

    /// <summary>
    /// Integration event raised before looking up original report number.
    /// Enables custom lookup logic for original report selection.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header requesting lookup</param>
    /// <param name="IsHandled">Set to true to skip standard lookup processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupOriginalReportNo(var VATReportHeader: Record "VAT Report Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before getting number series code for VAT report.
    /// Allows custom number series logic based on report configuration.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header requesting number series</param>
    /// <param name="Result">Number series code to use</param>
    /// <param name="IsHandled">Set to true to skip standard number series lookup</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var VATReportHeader: Record "VAT Report Header"; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before testing original report number requirement.
    /// Enables custom validation logic for original report number requirements.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header being validated</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestOriginalReportNo(VATReportHeader: Record "VAT Report Header"; var IsHandled: Boolean)
    begin
    end;
}