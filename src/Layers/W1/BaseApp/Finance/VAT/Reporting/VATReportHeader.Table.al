// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using System.DateTime;
using System.Security.AccessControl;

table 740 "VAT Report Header"
{
    Caption = 'VAT Report Header';
    LookupPageID = "VAT Report List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "VAT Report Config. Code"; Enum "VAT Report Configuration")
        {
            Caption = 'VAT Report Config. Code';
            Editable = true;
            TableRelation = "VAT Reports Configuration"."VAT Report Type";

            trigger OnValidate()
            begin
                CheckEditingAllowed();
            end;
        }
        field(3; "VAT Report Type"; Option)
        {
            Caption = 'VAT Report Type';
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
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
                TestField("Start Date");
                HandleDateInput();
            end;
        }
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
                TestField("End Date");
                CheckEndDate();
                HandleDateInput();
            end;
        }
        field(6; Status; Enum "VAT Report Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(8; "No. Series"; Code[20])
        {
            Caption = 'No. Series';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
            end;
        }
        field(9; "Original Report No."; Code[20])
        {
            Caption = 'Original Report No.';

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
        field(10; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionCaption = ' ,,Month,Quarter,Year,Bi-Monthly,Half-Year,Half-Month,Weekly';
            OptionMembers = " ",,Month,Quarter,Year,"Bi-Monthly","Half-Year","Half-Month","Weekly";

            trigger OnValidate()
            begin
                if "Period Type" = "Period Type"::Year then
                    "Period No." := 1;

                HandlePeriodInput();
            end;
        }
        field(11; "Period No."; Integer)
        {
            Caption = 'Period No.';
            TableRelation = "Date Lookup Buffer"."Period No." where("Period Type" = field("Period Type"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                HandlePeriodInput();
            end;
        }
        field(12; "Period Year"; Integer)
        {
            Caption = 'Period Year';

            trigger OnValidate()
            begin
                HandlePeriodInput();
            end;
        }
        field(13; "Message Id"; Text[250])
        {
            Caption = 'Message Id';
        }
        field(14; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            TableRelation = "VAT Statement Template";
        }
        field(15; "Statement Name"; Code[10])
        {
            Caption = 'Statement Name';
            TableRelation = "VAT Statement Name".Name where("Statement Template Name" = field("Statement Template Name"));
        }
        field(16; "VAT Report Version"; Code[10])
        {
            Caption = 'VAT Report Version';
#pragma warning disable AL0603
            TableRelation = "VAT Reports Configuration"."VAT Report Version" where("VAT Report Type" = field("VAT Report Config. Code"));
#pragma warning restore AL0603
        }
        field(17; "Submitted By"; Guid)
        {
            Caption = 'Submitted By';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = User."User Security ID";
        }
        field(18; "Submitted Date"; Date)
        {
            Caption = 'Submitted Date';
        }
        field(19; "Return Period No."; Code[20])
        {
            Caption = 'Return Period No.';
        }
#if not CLEANSCHEMA25
        field(20; "Date Type"; Enum "VAT Date Type")
        {
            Caption = 'Date Type';
            ObsoleteReason = 'Selected VAT Date type no longer supported';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(30; "Additional Information"; Code[50])
        {
            Caption = 'Additional Information';
        }
        field(31; "Created Date-Time"; DateTime)
        {
            Editable = false;
            Caption = 'Created Date-Time';
        }
        field(32; "Country/Region Filter"; Text[250])
        {
            Editable = false;
            Caption = 'Country/Region Filter';
        }
        field(100; "Amounts in Add. Rep. Currency"; Boolean)
        {
            Caption = 'Amounts in Add. Rep. Currency';
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

    procedure AssistEdit(OldVATReportHeader: Record "VAT Report Header"): Boolean
    begin
        if NoSeries.LookupRelatedNoSeries(GetNoSeriesCode(), OldVATReportHeader."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

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

    procedure CheckEditingAllowed()
    begin
        if Status <> Status::Open then
            Error(Text002, Format(Status));
    end;

    procedure CheckDates()
    begin
        TestField("Start Date");
        TestField("End Date");
        CheckEndDate();
    end;

    procedure CheckEndDate()
    begin
        if "End Date" < "Start Date" then
            Error(Text003);
    end;

    procedure CheckIfCanBeSubmitted()
    begin
        TestField(Status, Status::Released);
    end;

    procedure CheckIfCanBeReopened(VATReportHeader: Record "VAT Report Header")
    begin
        if VATReportHeader.Status <> VATReportHeader.Status::Released then
            if VATReportSetup.Get() then
                if not VATReportSetup."Modify Submitted Reports" then
                    Error(Text007, VATReportSetup.TableCaption());
    end;

    procedure CheckIfCanBeReleased(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        VATReportHeader.TestOriginalReportNo();
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var VATReportHeader: Record "VAT Report Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupOriginalReportNo(var VATReportHeader: Record "VAT Report Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var VATReportHeader: Record "VAT Report Header"; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestOriginalReportNo(VATReportHeader: Record "VAT Report Header"; var IsHandled: Boolean)
    begin
    end;
}