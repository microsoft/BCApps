// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;

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
            OptionCaption = ' ,VIES';
            OptionMembers = " ",VIES;
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
            OptionCaption = 'Standard,Corrective';
            OptionMembers = Standard,Corrective;

            trigger OnValidate()
            begin
                CheckEditingAllowed();
                CheckIfFilterCanBeChanged();

                if "VAT Report Type" = "VAT Report Type"::Standard then
                    "Original Report No." := '';
            end;
        }
        /// <summary>
        /// Starting date of the reporting period for VAT calculations.
        /// </summary>
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';
            ToolTip = 'Specifies the first date of the reporting period.';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Original Report No.", '');
                CheckEditingAllowed();
            end;
        }
        /// <summary>
        /// Ending date of the reporting period for VAT calculations.
        /// </summary>
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';
            ToolTip = 'Specifies the last date of the reporting period.';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Original Report No.", '');
                CheckEditingAllowed();
                CheckEndDate();
                if "End Date" <> xRec."End Date" then
                    Validate("Processing Date", "End Date");
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
            OptionCaption = 'Open,Released,Exported,Submitted';
            OptionMembers = Open,Released,Exported,Submitted;
        }
        field(7; "VAT Registration No."; Code[20])
        {
            Caption = 'VAT Registration No.';
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
            TableRelation = "VAT Report Header"."No." where("VAT Report Type" = const(Standard),
                                                             Status = const(Submitted));

            trigger OnLookup()
            var
                LookupVATReportHeader: Record "VAT Report Header";
                VATReportList: Page "VAT Report List";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupOriginalReportNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                LookupVATReportHeader.SetFilter("No.", '<>' + "No.");
                LookupVATReportHeader.SetRange(Status, Status::Submitted);
                LookupVATReportHeader.SetRange("VAT Report Type", "VAT Report Type"::Standard);
                VATReportList.SetTableView(LookupVATReportHeader);
                VATReportList.LookupMode(true);
                if VATReportList.RunModal() = ACTION::LookupOK then begin
                    VATReportList.GetRecord(LookupVATReportHeader);
                    Validate("Original Report No.", LookupVATReportHeader."No.");
                end;
            end;

            trigger OnValidate()
            var
                VATReportHeader: Record "VAT Report Header";
            begin
                CheckEditingAllowed();
                CheckIfFilterCanBeChanged();

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        if "Original Report No." <> '' then
                            Error(CannotSpecifyOriginalReportErr, "VAT Report Type");
                    "VAT Report Type"::Corrective:
                        begin
                            TestField("Original Report No.");
                            CheckOriginalReport("Original Report No.");
                            if "Original Report No." = "No." then
                                Error(CannotSpecifySameReportErr);
                            VATReportHeader.Get("Original Report No.");
                            VATReportHeader.TestField(Status, Status::Submitted);
                            "Start Date" := VATReportHeader."Start Date";
                            "End Date" := VATReportHeader."End Date";
                            "Report Period Type" := VATReportHeader."Report Period Type";
                            "Report Period No." := VATReportHeader."Report Period No.";
                            "Report Year" := VATReportHeader."Report Year";
                            "Trade Type" := VATReportHeader."Trade Type";
                            "EU Goods/Services" := VATReportHeader."EU Goods/Services";
                        end;
                end;
            end;
        }
        /// <summary>
        /// Predefined period type for automatic date calculation (Month, Quarter, Year, etc.).
        /// </summary>
        field(10; "Report Period Type"; Option)
        {
            ToolTip = 'Specifies the length of the reporting period.';
            Caption = 'Report Period Type';
            OptionCaption = ' ,Month,Quarter,Year,Bi-Monthly';
            OptionMembers = " ",Month,Quarter,Year,"Bi-Monthly";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Original Report No.", '');
                if "Report Period Type" <> xRec."Report Period Type" then begin
                    if LineExists() then
                        Error(CannotChangeWithLinesErr, FieldCaption("Report Period No."));
                    SetPeriod();
                end;
            end;
        }
        /// <summary>
        /// Sequential number within the period type for date calculation.
        /// </summary>
        field(11; "Report Period No."; Integer)
        {
            ToolTip = 'Specifies the specific reporting period to use.';
            Caption = 'Report Period No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Original Report No.", '');
                TestField("Report Period Type");
                if "Report Period No." <> xRec."Report Period No." then begin
                    if LineExists() then
                        Error(CannotChangeWithLinesErr, FieldCaption("Report Period No."));
                    SetPeriod();
                end;
            end;
        }
        /// <summary>
        /// Year component for period-based date calculation.
        /// </summary>
        field(12; "Report Year"; Integer)
        {
            ToolTip = 'Specifies the year of the reporting period.';
            Caption = 'Report Year';
            MinValue = 2000;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Original Report No.", '');
                if "Report Year" <> xRec."Report Year" then begin
                    if LineExists() then
                        Error(CannotChangeWithLinesErr, FieldCaption("Report Year"));
                    SetPeriod();
                end;
            end;
        }
        field(16; "Processing Date"; Date)
        {
            Caption = 'Processing Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Processing Date" < "End Date" then
                    Error(DateCannotBeEarlierErr, FieldCaption("Processing Date"), FieldCaption("End Date"));

                case true of
                    Date2DWY("Processing Date", 1) = 6:
                        "Processing Date" := CalcDate('<+2D>', "Processing Date");
                    Date2DWY("Processing Date", 1) = 7:
                        "Processing Date" := CalcDate('<+1D>', "Processing Date");
                end;
            end;
        }
        field(19; "Test Export"; Boolean)
        {
            Caption = 'Test Export';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(20; Notice; Boolean)
        {
            Caption = 'Notice';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if Notice and Revocation then
                    Error(NoticeAndRevocationMutuallyExclusiveErr);
            end;
        }
        field(21; Revocation; Boolean)
        {
            Caption = 'Revocation';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if Revocation and Notice then
                    Error(NoticeAndRevocationMutuallyExclusiveErr);
            end;
        }
#if not CLEANSCHEMA25
        field(22; "Date Type"; Enum "VAT Date Type")
        {
            Caption = 'Date Type';
            ObsoleteReason = 'Selected VAT Date type no longer supported';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(28; "Trade Type"; Option)
        {
            Caption = 'Trade Type';
            InitValue = Sales;
            OptionCaption = 'Purchases,Sales,Both';
            OptionMembers = Purchases,Sales,Both;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                CheckIfFilterCanBeChanged();
            end;
        }
        field(29; "EU Goods/Services"; Option)
        {
            Caption = 'EU Goods/Services';
            OptionCaption = 'Both,Goods,Services';
            OptionMembers = Both,Goods,Services;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                CheckIfFilterCanBeChanged();
            end;
        }
        field(31; "Total Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Report Line".Base where("VAT Report No." = field("No."),
                                                            "Line Type" = filter(New | Correction)));
            Caption = 'Total Base';
            Editable = false;
            ToolTip = 'Specifies the date when the VAT report lines were created.';
            FieldClass = FlowField;
        }
        field(32; "Total Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Report Line".Amount where("VAT Report No." = field("No."),
                                                              "Line Type" = filter(New | Correction)));
            Caption = 'Total Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Total Number of Supplies"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Report Line"."Number of Supplies" where("VAT Report No." = field("No."),
                                                                            "Line Type" = filter(New | Correction)));
            Caption = 'Total Number of Supplies';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "Total Number of Lines"; Integer)
        {
            CalcFormula = count("VAT Report Line" where("VAT Report No." = field("No."),
                                                         "Line Type" = filter(New | Correction)));
            Caption = 'Total Number of Lines';
            Editable = false;
            ToolTip = 'Specifies the country/region filter for the report.';
            FieldClass = FlowField;
        }
        field(40; "Company Name"; Text[100])
        {
            Caption = 'Company Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(41; "Company Address"; Text[30])
        {
            Caption = 'Company Address';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(42; "Country/Region Name"; Text[30])
        {
            Caption = 'Country/Region Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(43; "ISO Country/Region Code"; Code[2])
        {
            Caption = 'ISO Country/Region Code';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(48; City; Text[30])
        {
            Caption = 'City';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(49; "Post Code"; Code[20])
        {
            Caption = 'Post Code';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(50; "Tax Office ID"; Code[20])
        {
            Caption = 'Tax Office ID';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(51; "Sign-off Place"; Text[30])
        {
            Caption = 'Sign-off Place';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(52; "Sign-off Date"; Date)
        {
            Caption = 'Sign-off Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(53; "Signed by Employee No."; Code[20])
        {
            Caption = 'Signed by Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(54; "Created by Employee No."; Code[20])
        {
            Caption = 'Created by Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
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
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "VAT Report Config. Code")
        {
        }
        key(Key3; "VAT Report Type", Status)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        TestField(Status, Status::Open);
        VATReportLine.SetRange("VAT Report No.", "No.");
        VATReportLine.DeleteAll();
        VATReportLineRelation.SetRange("VAT Report No.", "No.");
        VATReportLineRelation.DeleteAll();
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
        CheckEditingAllowed();
        CheckDates();
    end;

    trigger OnRename()
    begin
        Error(CannotRenameReportErr);
    end;

    var
        NoSeries: Codeunit "No. Series";

        EditingNotAllowedErr: Label 'Editing is not allowed because the report is marked as %1.', Comment = '%1 - Status';
        DateCannotBeEarlierErr: Label 'The %1 cannot be earlier than the %2.', Comment = '%1 - First date field, %2 - Second date field';
        CannotRenameReportErr: Label 'You cannot rename the report because it has been assigned a report number.';
        CannotSpecifySameReportErr: Label 'You cannot specify the same report as the reference report.';
        CannotSpecifyOriginalReportErr: Label 'You cannot specify an original report for a report of type %1.', Comment = '%1 - VAT Report Type';
        NotAllowedDueToSetupErr: Label 'This is not allowed because of the setup in the %1 window.', Comment = '%1 - Table caption';
        MustSpecifyOriginalReportErr: Label 'You must specify an original report for a report of type %1.', Comment = '%1 - VAT Report Type';
        CannotChangeWithLinesErr: Label 'You cannot change %1 because you already have declaration lines.', Comment = '%1 - Field caption';
        FieldValueRangeErr: Label 'The field %1 can take values from 1 to %2.', Comment = '%1 - Field caption, %2 - Maximum value';
        DeletionNotAllowedErr: Label 'Deletion is not allowed because the report is marked as %1.', Comment = '%1 - Status';
        ReportTypeChangeErr: Label 'You cannot change this field when the report has existing VAT Report lines.';
        NoticeAndRevocationMutuallyExclusiveErr: Label 'You cannot enable both Notice and Revocation at the same time.';
        ISOCodeMustBeTwoCharsErr: Label 'The ISO Code for country/region %1 must be exactly 2 characters.', Comment = '%1 - Country/Region Code';

    /// <summary>
    /// Gets the appropriate number series code based on VAT report configuration type.
    /// Returns specific series for VAT returns or general series for other report types.
    /// </summary>
    /// <returns>Number series code for report number generation</returns>
    procedure GetNoSeriesCode() Result: Code[20]
    var
        VATReportSetup: Record "VAT Report Setup";
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
        "VAT Report Config. Code" := "VAT Report Config. Code"::VIES;
        "Report Period Type" := "Report Period Type"::Month;
        "Report Period No." := Date2DMY(WorkDate(), 2);
        Validate("Report Year", Date2DMY(WorkDate(), 3));

        FillCompanyInfo();

        OnAfterInitRecord(Rec);
    end;

    /// <summary>
    /// Validates that the report status allows editing operations.
    /// Prevents modification of reports that are no longer in Open status.
    /// </summary>
    procedure CheckEditingAllowed()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        if (not VATReportSetup."Modify Submitted Reports") and (Status <> Status::Open) then
            Error(EditingNotAllowedErr, Format(Status));
    end;

    [Scope('OnPrem')]
    procedure CheckDeleteAllowed()
    begin
        if Status <> Status::Open then
            Error(DeletionNotAllowedErr, Format(Status));
    end;

    [Scope('OnPrem')]
    procedure CheckIfFilterCanBeChanged()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", "No.");
        if VATReportLine.Count <> 0 then
            Error(ReportTypeChangeErr);
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
            Error(DateCannotBeEarlierErr, "End Date", "Start Date");
    end;

    /// <summary>
    /// Validates that the report is in Released status before submission.
    /// Ensures proper workflow compliance for VAT report submission.
    /// </summary>
    procedure CheckIfCanBeSubmitted()
    begin
        TestField(Status, Status::Exported);
    end;

    /// <summary>
    /// Validates that the report can be reopened based on status and setup configuration.
    /// Checks VAT report setup to determine if submitted reports can be modified.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header record to validate</param>
    procedure CheckIfCanBeReopened(VATReportHeader: Record "VAT Report Header")
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Submitted:
                begin
                    VATReportSetup.Get();
                    if not VATReportSetup."Modify Submitted Reports" then
                        Error(NotAllowedDueToSetupErr, VATReportSetup.TableCaption());
                end
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

        if "VAT Report Type" in ["VAT Report Type"::Corrective] then
            if "Original Report No." = '' then
                Error(MustSpecifyOriginalReportErr, Format("VAT Report Type"));
    end;

    local procedure CheckPeriodNo()
    var
        MaxPeriodNo: Integer;
    begin
        case "Report Period Type" of
            "Report Period Type"::Month:
                MaxPeriodNo := 12;
            "Report Period Type"::Quarter,
          "Report Period Type"::"Bi-Monthly":
                MaxPeriodNo := 4;
            "Report Period Type"::Year:
                MaxPeriodNo := 1;
        end;
        if not ("Report Period No." in [1 .. MaxPeriodNo]) then
            Error(FieldValueRangeErr, FieldCaption("Report Period No."), MaxPeriodNo);
    end;

    local procedure SetPeriod()
    begin
        if "Report Period No." <> 0 then
            CheckPeriodNo();
        if "Report Period Type" = "Report Period Type"::Year then
            "Report Period No." := 1;

        if ("Report Period No." = 0) or ("Report Year" = 0) then begin
            Validate("Start Date", 0D);
            Validate("End Date", 0D);
        end else
            case "Report Period Type" of
                "Report Period Type"::Month:
                    begin
                        Validate("Start Date", DMY2Date(1, "Report Period No.", "Report Year"));
                        Validate("End Date", CalcDate('<CM>', "Start Date"));
                    end;
                "Report Period Type"::Quarter:
                    begin
                        Validate("Start Date", DMY2Date(1, "Report Period No." * 3 - 2, "Report Year"));
                        Validate("End Date", CalcDate('<CQ>', "Start Date"));
                    end;
                "Report Period Type"::Year:
                    begin
                        Validate("Start Date", DMY2Date(1, 1, "Report Year"));
                        Validate("End Date", DMY2Date(31, 12, "Report Year"));
                    end;
                "Report Period Type"::"Bi-Monthly":
                    begin
                        Validate("Start Date", DMY2Date(1, "Report Period No." * 3 - 2, "Report Year"));
                        Validate("End Date", CalcDate('<CM + 1M>', "Start Date"));
                    end;
            end;
        CheckPeriod();
    end;

    local procedure CheckPeriod()
    begin
        if ("Start Date" = 0D) or ("End Date" = 0D) then
            exit;

        CheckEndDate();
    end;

    procedure LineExists(): Boolean
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.Reset();
        VATReportLine.SetRange("VAT Report No.", "No.");
        exit(not VATReportLine.IsEmpty);
    end;

    procedure FillCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        VATReportSetup: Record "VAT Report Setup";
    begin
        CompanyInfo.Get();
        VATReportSetup.Get();
        CompanyInfo.TestField("Country/Region Code");

        CountryRegion.Get(CompanyInfo."Country/Region Code");
        if StrLen(CountryRegion."ISO Code") <> 2 then
            Error(ISOCodeMustBeTwoCharsErr, CompanyInfo."Country/Region Code");

        Validate("VAT Registration No.", CompanyInfo."VAT Registration No.");
        Validate("Company Name", GetCompanyName(CompanyInfo, VATReportSetup));
        Validate("Company Address", GetCompanyAddress(CompanyInfo, VATReportSetup));
        Validate("Country/Region Name", CountryRegion.Name);
        Validate("ISO Country/Region Code", CountryRegion."ISO Code");
        Validate(City, GetCompanyCity(CompanyInfo, VATReportSetup));
        Validate("Post Code", CompanyInfo."Post Code");
        Validate("Tax Office ID", CompanyInfo."Tax Office Number");
    end;

    procedure CheckOriginalReport(VATReportNo: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.Get(VATReportNo);
        VATReportHeader.TestField("VAT Report Type", VATReportHeader."VAT Report Type"::Standard);
        VATReportHeader.TestField(Status, VATReportHeader.Status::Submitted);
    end;

    local procedure GetCompanyName(CompanyInformation: Record "Company Information"; VATReportSetup: Record "VAT Report Setup"): Text[100]
    begin
        if VATReportSetup."Company Name" <> '' then
            exit(VATReportSetup."Company Name");

        exit(CompanyInformation.Name);
    end;

    local procedure GetCompanyAddress(CompanyInformation: Record "Company Information"; VATReportSetup: Record "VAT Report Setup"): Text[30]
    begin
        if VATReportSetup."Company Address" <> '' then
            exit(VATReportSetup."Company Address");

        exit(CopyStr(CompanyInformation.Address, 1, 30));
    end;

    local procedure GetCompanyCity(CompanyInformation: Record "Company Information"; VATReportSetup: Record "VAT Report Setup"): Text[30]
    begin
        if VATReportSetup."Company City" <> '' then
            exit(VATReportSetup."Company City");

        exit(CompanyInformation.City);
    end;

    local procedure RemoveECSLLinesAndRelation()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        if "VAT Report Config. Code" <> "VAT Report Config. Code"::VIES then
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