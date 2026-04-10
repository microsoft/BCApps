// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;

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
        field(2; "VAT Report Config. Code"; Option)
        {
            Caption = 'VAT Report Config. Code';
            ToolTip = 'Specifies the appropriate configuration code for EC Sales List Reports.';
            Editable = true;
            OptionCaption = ' ,VAT Transactions Report,Datifattura';
            OptionMembers = " ","VAT Transactions Report",Datifattura;

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
            OptionCaption = 'Standard,Corrective,,,,,,,,,Cancellation ';
            OptionMembers = Standard,Corrective,,,,,,,,,"Cancellation ";

            trigger OnValidate()
            var
                VATReportLine: Record "VAT Report Line";
            begin
                CheckEditingAllowed();

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        "Original Report No." := '';
                    "VAT Report Type"::"Cancellation ":
                        begin
                            VATReportLine.SetRange("VAT Report No.", "No.");
                            if not VATReportLine.IsEmpty() then
                                if Confirm(DeleteReportLinesQst) then
                                    VATReportLine.DeleteAll()
                                else
                                    Error('');
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
            end;
        }
        /// <summary>
        /// Current status of the VAT report in the submission workflow.
        /// </summary>
        field(6; Status; Option)
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the report is in progress, is completed, or contains errors.';
            Editable = false;
            OptionCaption = 'Open,Released,Submitted';
            OptionMembers = Open,Released,Submitted;
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
                    "VAT Report Type"::Corrective, "VAT Report Type"::"Cancellation ":
                        begin
                            ShowLookup := true;
                            TypeFilterText := '<>' + Format("VAT Report Type"::"Cancellation ");
                        end;
                end;

                if ShowLookup then begin
                    LookupVATReportHeader.SetFilter("No.", '<>' + "No.");
                    LookupVATReportHeader.SetRange(Status, Status::Submitted);
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
                    "VAT Report Type"::Corrective, "VAT Report Type"::"Cancellation ":
                        begin
                            TestField("Original Report No.");
                            if "Original Report No." = "No." then
                                Error(Text005);
                            VATReportHeader.Get("Original Report No.");
                            VATReportHeader.TestField(Status, VATReportHeader.Status::Submitted);
                            "Start Date" := VATReportHeader."Start Date";
                            "End Date" := VATReportHeader."End Date";
                        end;
                end;
            end;
        }
        field(32; "Country/Region Filter"; Text[250])
        {
            ToolTip = 'Specifies the country/region filter for the report.';
            Editable = false;
            Caption = 'Country/Region Filter';
        }
        field(100; "Amounts in Add. Rep. Currency"; Boolean)
        {
            ToolTip = 'Specifies whether the amounts are in the additional reporting currency.';
            Caption = 'Amounts in Add. Rep. Currency';
            Editable = false;
        }
        field(12100; "Tax Auth. Receipt No."; Code[17])
        {
            Caption = 'Tax Auth. Receipt No.';

            trigger OnValidate()
            begin
                if Status = Status::Submitted then
                    Error(Text002, Format(Status));
            end;
        }
        field(12102; "Tax Auth. Document No."; Code[18])
        {
            Caption = 'Tax Auth. Document No.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        TestField(Status, Status::Open);
        VATReportLine.SetRange("VAT Report No.", "No.");
        VATReportLine.DeleteAll();
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
        Text002: Label 'Editing is not allowed because the report is marked as %1.';
        Text003: Label 'The end date cannot be earlier than the start date.';
        Text004: Label 'You cannot rename the report because it has been assigned a report number.';
        Text005: Label 'You cannot specify the same report as the reference report.';
        Text006: Label 'You cannot specify an original report for a report of type %1.';
        Text007: Label 'This is not allowed because of the setup in the %1 window.';
        Text008: Label 'You must specify an original report for a report of type %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

        DeleteReportLinesQst: Label 'All existing report lines will be deleted. Do you want to continue?';

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
    begin
        "VAT Report Config. Code" := "VAT Report Config. Code"::"VAT Transactions Report";
        "Start Date" := WorkDate();
        "End Date" := WorkDate();

        OnAfterInitRecord(Rec);
    end;

    /// <summary>
    /// Validates that the report status allows editing operations.
    /// Prevents modification of reports that are no longer in Open status.
    /// </summary>
    procedure CheckEditingAllowed()
    begin
        if Status in [Status::Released, Status::Submitted] then
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
        TestField("Tax Auth. Receipt No.");
        TestField("Tax Auth. Document No.");
    end;

    /// <summary>
    /// Validates that the report can be reopened based on status and setup configuration.
    /// Checks VAT report setup to determine if submitted reports can be modified.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header record to validate</param>
    procedure CheckIfCanBeReopened(VATReportHeader: Record "VAT Report Header")
    begin
        if VATReportHeader.Status = VATReportHeader.Status::Submitted then begin
            VATReportSetup.Get();
            if not VATReportSetup."Modify Submitted Reports" then
                Error(Text007, VATReportSetup.TableCaption());
        end;
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

        if "VAT Report Type" in ["VAT Report Type"::Corrective, "VAT Report Type"::"Cancellation "] then
            if "Original Report No." = '' then
                Error(Text008, Format("VAT Report Type"));
    end;

    procedure IsDatifattura(): Boolean
    begin
        exit("VAT Report Config. Code" = "VAT Report Config. Code"::Datifattura);
    end;

    local procedure RemoveECSLLinesAndRelation()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        if "VAT Report Config. Code" <> "VAT Report Config. Code"::"VAT Transactions Report" then
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