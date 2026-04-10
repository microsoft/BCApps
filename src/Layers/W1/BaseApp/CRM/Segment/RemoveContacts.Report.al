// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Profiling;
using Microsoft.Inventory.Ledger;
using System.Utilities;

report 5186 "Remove Contacts"
{
    Caption = 'Remove Contacts';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Segment Header"; "Segment Header")
        {
            DataItemTableView = sorting("No.");
            dataitem("Segment Line"; "Segment Line")
            {
                DataItemLink = "Segment No." = field("No.");
                DataItemTableView = sorting("Segment No.", "Line No.");
                dataitem(Contact; Contact)
                {
                    DataItemTableView = sorting("No.");
                    RequestFilterFields = "No.", "Search Name", Type, "Salesperson Code", "Post Code", "Country/Region Code", "Territory Code";
                    dataitem("Contact Profile Answer"; "Contact Profile Answer")
                    {
                        DataItemLink = "Contact No." = field("No.");
                        RequestFilterHeading = 'Profile';

                        trigger OnAfterGetRecord()
                        begin
                            ContactOK := true;
                            CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if ContactOK and (GetFilters <> '') then
                                ContactOK := false
                            else
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Contact Mailing Group"; "Contact Mailing Group")
                    {
                        DataItemLink = "Contact No." = field("No.");
                        DataItemTableView = sorting("Contact No.", "Mailing Group Code");
                        RequestFilterFields = "Mailing Group Code";
                        RequestFilterHeading = 'Mailing Group';

                        trigger OnAfterGetRecord()
                        begin
                            ContactOK := true;
                            CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if ContactOK and (GetFilters <> '') then
                                ContactOK := false
                            else
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Interaction Log Entry"; "Interaction Log Entry")
                    {
                        DataItemLink = "Contact Company No." = field("Company No."), "Contact No." = field("No.");
                        DataItemTableView = sorting("Contact Company No.", "Contact No.", Date);
                        RequestFilterFields = Date, "Segment No.", "Campaign No.", Evaluation, "Interaction Template Code", "Salesperson Code";

                        trigger OnAfterGetRecord()
                        begin
                            ContactOK := true;
                            CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if ContactOK and (GetFilters <> '') then
                                ContactOK := false
                            else
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Contact Job Responsibility"; "Contact Job Responsibility")
                    {
                        DataItemLink = "Contact No." = field("No.");
                        DataItemTableView = sorting("Contact No.", "Job Responsibility Code");
                        RequestFilterFields = "Job Responsibility Code";
                        RequestFilterHeading = 'Job Responsibility';

                        trigger OnAfterGetRecord()
                        begin
                            ContactOK := true;
                            CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if ContactOK and (GetFilters <> '') then
                                ContactOK := false
                            else
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Contact Industry Group"; "Contact Industry Group")
                    {
                        DataItemLink = "Contact No." = field("Company No.");
                        DataItemTableView = sorting("Contact No.", "Industry Group Code");
                        RequestFilterFields = "Industry Group Code";
                        RequestFilterHeading = 'Industry Group';

                        trigger OnAfterGetRecord()
                        begin
                            ContactOK := true;
                            CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if ContactOK and (GetFilters <> '') then
                                ContactOK := false
                            else
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Contact Business Relation"; "Contact Business Relation")
                    {
                        DataItemLink = "Contact No." = field("Company No.");
                        DataItemTableView = sorting("Contact No.", "Business Relation Code");
                        RequestFilterFields = "Business Relation Code";
                        RequestFilterHeading = 'Business Relation';
                        dataitem("Value Entry"; "Value Entry")
                        {
                            DataItemTableView = sorting("Source Type", "Source No.", "Item No.", "Posting Date");
                            RequestFilterFields = "Item No.", "Variant Code", "Posting Date", "Inventory Posting Group";

                            trigger OnAfterGetRecord()
                            begin
                                ContactOK := true;
                                CurrReport.Break();
                            end;

                            trigger OnPreDataItem()
                            begin
                                if SkipItemLedgerEntry then
                                    CurrReport.Break();

                                case "Contact Business Relation"."Link to Table" of
                                    "Contact Business Relation"."Link to Table"::Customer:
                                        begin
                                            SetRange("Source Type", "Source Type"::Customer);
                                            SetRange("Source No.", "Contact Business Relation"."No.");
                                        end;
                                    "Contact Business Relation"."Link to Table"::Vendor:
                                        begin
                                            SetRange("Source Type", "Source Type"::Vendor);
                                            SetRange("Source No.", "Contact Business Relation"."No.");
                                        end
                                    else
                                        CurrReport.Break();
                                end;
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            SkipItemLedgerEntry := false;
                            if not ItemFilters then begin
                                ContactOK := true;
                                SkipItemLedgerEntry := true;
                                CurrReport.Break();
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if ContactOK and ((GetFilters <> '') or ItemFilters) then
                                ContactOK := false
                            else
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Integer"; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnAfterGetRecord()
                        begin
                            if ContactOK then
                                InsertContact(Contact);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if EntireCompanies then begin
                            if TempCheckCont.Get("No.") then
                                CurrReport.Skip();
                            TempCheckCont := Contact;
                            TempCheckCont.Insert();
                        end;

                        ContactOK := true;
                    end;

                    trigger OnPreDataItem()
                    begin
                        FilterGroup(4);
                        SetRange("Company No.", "Segment Line"."Contact Company No.");
                        if not EntireCompanies then
                            SetRange("No.", "Segment Line"."Contact No.");
                        FilterGroup(0);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    RecordNo := RecordNo + 1;
                    if RecordNo = 1 then begin
                        OldDateTime := CurrentDateTime;
                        case MainReportNo of
                            REPORT::"Remove Contacts - Reduce":
                                Window.Open(Text000);
                            REPORT::"Remove Contacts - Refine":
                                Window.Open(Text001);
                        end;
                        NoOfRecords := Count;
                    end;
                    NewDateTime := CurrentDateTime;
                    if (NewDateTime - OldDateTime > 100) or (NewDateTime < OldDateTime) then begin
                        NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
                        if NewProgress <> OldProgress then begin
                            Window.Update(1, NewProgress * 100);
                            OldProgress := NewProgress;
                        end;
                        OldDateTime := CurrentDateTime;
                    end;
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if EntireCompanies then
            AddPeople();

        UpdateSegLines();
    end;

    trigger OnPreReport()
    begin
        ItemFilters := "Value Entry".HasFilter;

        SegCriteriaManagement.InsertCriteriaAction(
          "Segment Header".GetFilter("No."), MainReportNo,
          false, false, false, false, EntireCompanies);
        SegCriteriaManagement.InsertCriteriaFilters(
          "Segment Header".GetFilter("No."), DATABASE::Contact,
          Contact.GetFilters, Contact.GetView(false));
        SegCriteriaManagement.InsertCriteriaFilters(
          "Segment Header".GetFilter("No."), DATABASE::"Contact Profile Answer",
          "Contact Profile Answer".GetFilters, "Contact Profile Answer".GetView(false));
        SegCriteriaManagement.InsertCriteriaFilters(
          "Segment Header".GetFilter("No."), DATABASE::"Contact Mailing Group",
          "Contact Mailing Group".GetFilters, "Contact Mailing Group".GetView(false));
        SegCriteriaManagement.InsertCriteriaFilters(
          "Segment Header".GetFilter("No."), DATABASE::"Interaction Log Entry",
          "Interaction Log Entry".GetFilters, "Interaction Log Entry".GetView(false));
        SegCriteriaManagement.InsertCriteriaFilters(
          "Segment Header".GetFilter("No."), DATABASE::"Contact Job Responsibility", "Contact Job Responsibility".GetFilters,
          "Contact Job Responsibility".GetView(false));
        SegCriteriaManagement.InsertCriteriaFilters(
          "Segment Header".GetFilter("No."), DATABASE::"Contact Industry Group",
          "Contact Industry Group".GetFilters, "Contact Industry Group".GetView(false));
        SegCriteriaManagement.InsertCriteriaFilters(
          "Segment Header".GetFilter("No."), DATABASE::"Contact Business Relation",
          "Contact Business Relation".GetFilters, "Contact Business Relation".GetView(false));
        SegCriteriaManagement.InsertCriteriaFilters(
          "Segment Header".GetFilter("No."), DATABASE::"Value Entry",
          "Value Entry".GetFilters, "Value Entry".GetView(false));
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Reducing Contacts @1@@@@@@@@@@@@@';
        Text001: Label 'Refining Contacts @1@@@@@@@@@@@@@';
#pragma warning restore AA0074
        TempCont: Record Contact temporary;
        TempCont2: Record Contact temporary;
        TempCheckCont: Record Contact temporary;
        Cont: Record Contact;
        SegLine: Record "Segment Line";
        SegmentHistoryMgt: Codeunit SegHistoryManagement;
        Window: Dialog;
        MainReportNo: Integer;
        ItemFilters: Boolean;
        EntireCompanies: Boolean;
        SkipItemLedgerEntry: Boolean;
        NoOfRecords: Integer;
        RecordNo: Integer;
        OldDateTime: DateTime;
        NewDateTime: DateTime;
        OldProgress: Integer;
        NewProgress: Integer;

    protected var
        SegCriteriaManagement: Codeunit SegCriteriaManagement;
        ContactOK: Boolean;

    procedure SetOptions(CalledFromReportNo: Integer; OptionEntireCompanies: Boolean)
    begin
        MainReportNo := CalledFromReportNo;
        EntireCompanies := OptionEntireCompanies;
    end;

    local procedure InsertContact(var CheckedCont: Record Contact)
    begin
        TempCont := CheckedCont;
        if TempCont.Insert() then;
    end;

    local procedure AddPeople()
    begin
        TempCont.Reset();
        if TempCont.Find('-') then
            repeat
                if TempCont."Company No." <> '' then begin
                    Cont.SetCurrentKey("Company No.");
                    Cont.SetRange("Company No.", TempCont."Company No.");
                    if Cont.Find('-') then
                        repeat
                            TempCont2 := Cont;
                            if TempCont2.Insert() then;
                        until Cont.Next() = 0
                end else begin
                    TempCont2 := TempCont;
                    TempCont2.Insert();
                end;
            until TempCont.Next() = 0;

        TempCont.DeleteAll();
        if TempCont2.Find('-') then
            repeat
                TempCont := TempCont2;
                TempCont.Insert();
            until TempCont2.Next() = 0;
        TempCont2.DeleteAll();
    end;

    local procedure UpdateSegLines()
    begin
        SegLine.Reset();
        SegLine.SetRange("Segment No.", "Segment Header"."No.");
        if SegLine.Find('-') then
            repeat
                case MainReportNo of
                    REPORT::"Remove Contacts - Reduce":
                        if TempCont.Get(SegLine."Contact No.") then begin
                            SegLine.Delete(true);
                            SegmentHistoryMgt.DeleteLine(
                              SegLine."Segment No.", SegLine."Contact No.", SegLine."Line No.");
                        end;
                    REPORT::"Remove Contacts - Refine":
                        if not TempCont.Get(SegLine."Contact No.") then begin
                            SegLine.Delete(true);
                            SegmentHistoryMgt.DeleteLine(
                              SegLine."Segment No.", SegLine."Contact No.", SegLine."Line No.");
                        end;
                end;
            until SegLine.Next() = 0;
    end;
}

