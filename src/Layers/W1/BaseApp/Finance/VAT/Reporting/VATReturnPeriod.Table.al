// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;
using System.Utilities;

table 737 "VAT Return Period"
{
    Caption = 'VAT Return Period';
    LookupPageID = "VAT Return Period List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        field(3; "Period Key"; Code[10])
        {
            Caption = 'Period Key';
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(7; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Closed';
            OptionMembers = Open,Closed;
        }
        field(8; "Received Date"; Date)
        {
            Caption = 'Received Date';
        }
        field(20; "VAT Return No."; Code[20])
        {
            Caption = 'VAT Return No.';
            Editable = false;
            TableRelation = if ("VAT Return No." = filter(<> '')) "VAT Report Header"."No." where("VAT Report Config. Code" = const("VAT Return"),
                                                                                                "No." = field("VAT Return No."));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                Rec.DrillDownVATReturn();
            end;
        }
        field(21; "VAT Return Status"; Enum "VAT Return Status")
        {
            CalcFormula = lookup("VAT Report Header".Status where("VAT Report Config. Code" = const("VAT Return"),
                                                                   "No." = field("VAT Return No.")));
            Caption = 'VAT Return Status';
            Editable = false;
            FieldClass = FlowField;
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
        VATReportHeader: Record "VAT Report Header";
    begin
        if VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", "VAT Return No.") then
            Error(DeleteExistingVATRetErr);
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            if NoSeries.AreRelated(GetNoSeriesCode(), xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := GetNoSeriesCode();
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportSetupGot: Boolean;

        DeleteExistingVATRetErr: Label 'You cannot delete a VAT return period that has a linked VAT return.';
        OverdueTxt: Label 'Your VAT return is overdue since %1 (%2 days)', Comment = '%1 - date; %2 - days count';
        OpenTxt: Label 'Your VAT return is due %1 (in %2 days)', Comment = '%1 - date; %2 - days count';

    local procedure GetNoSeriesCode(): Code[20]
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.TestField("VAT Return Period No. Series");
        exit(VATReportSetup."VAT Return Period No. Series");
    end;

    procedure CopyToVATReturn(var VATReportHeader: Record "VAT Report Header")
    begin
        TestField("Start Date");
        TestField("End Date");
        VATReportHeader."Return Period No." := "No.";
        VATReportHeader."Period Year" := Date2DMY("End Date", 3);
        VATReportHeader."Start Date" := "Start Date";
        VATReportHeader."End Date" := "End Date";
        ParseDatePeriod(VATReportHeader);
    end;

    local procedure ParseDatePeriod(var VATReportHeader: Record "VAT Report Header")
    var
        Date: Record Date;
    begin
        Date.SetRange("Period Start", VATReportHeader."Start Date");
        Date.SetRange("Period End", ClosingDate(VATReportHeader."End Date"));
        if Date.FindFirst() then begin
            case Date."Period Type" of
                Date."Period Type"::Month:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Month;
                Date."Period Type"::Quarter:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Quarter;
                Date."Period Type"::Year:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Year;
            end;
            VATReportHeader."Period No." := Date."Period No.";
        end else begin
            VATReportHeader."Period Type" := VATReportHeader."Period Type"::" ";
            VATReportHeader."Period No." := 0;
        end;
    end;

    internal procedure FindVATPeriodByDate(VATReportingDate: Date): Boolean
    begin
        Rec.SetFilter("End Date", '>=%1', VATReportingDate);
        Rec.SetFilter("Start Date", '<=%1', VATReportingDate);
        exit(Rec.FindFirst());
    end;

    procedure FindVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"; StartDate: Date; EndDate: Date): Boolean
    begin
        VATReturnPeriod.SetRange("Start Date", StartDate);
        VATReturnPeriod.SetRange("End Date", EndDate);
        exit(VATReturnPeriod.FindFirst());
    end;

    procedure DiffersFromVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"): Boolean
    begin
        exit(
          ("Due Date" <> VATReturnPeriod."Due Date") or
          (Status <> VATReturnPeriod.Status) or
          ("Received Date" <> VATReturnPeriod."Received Date") or
          ("Period Key" <> VATReturnPeriod."Period Key"));
    end;

    procedure DrillDownVATReturn()
    var
        VATReportMgt: Codeunit "VAT Report Mgt.";
    begin
        if (Status = Status::Open) or ("VAT Return No." <> '') then
            VATReportMgt.OpenVATReturnCardFromVATPeriod(Rec);
    end;

    local procedure GetVATReportSetup()
    begin
        if VATReportSetupGot then
            exit;

        VATReportSetup.Get();
        VATReportSetupGot := true;
    end;

    procedure CheckOpenOrOverdue(): Text
    begin
        GetVATReportSetup();
        if (Status = Status::Open) and ("Due Date" <> 0D) then
            case true of
                // Overdue
                ("Due Date" < WorkDate()):
                    exit(StrSubstNo(OverdueTxt, "Due Date", WorkDate() - "Due Date"));
                // Open
                VATReportSetup.IsPeriodReminderCalculation() and
              ("Due Date" >= WorkDate()) and
              ("Due Date" <= CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate())):
                    exit(StrSubstNo(OpenTxt, "Due Date", "Due Date" - WorkDate()));
            end;
    end;
}
