// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Segment;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using System.Utilities;

report 5198 "Add Contacts"
{
    Caption = 'Add Contacts';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Segment Header"; "Segment Header")
        {
            DataItemTableView = sorting("No.");
        }
        dataitem(Contact; Contact)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", Type, "Salesperson Code", "Post Code", "Country/Region Code", "Territory Code";
            dataitem("Contact Profile Answer"; "Contact Profile Answer")
            {
                DataItemLink = "Contact No." = field("No.");
                DataItemTableView = sorting("Contact No.", "Profile Questionnaire Code", "Line No.");
                RequestFilterFields = "Profile Questionnaire Code", "Line No.";

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
                dataitem("Value Entry"; "Value Entry")
                {
                    DataItemTableView = sorting("Source Type", "Source No.", "Item No.", "Posting Date");
                    RequestFilterFields = "Item No.", "Variant Code", "Posting Date", "Inventory Posting Group";

                    trigger OnAfterGetRecord()
                    begin
                        if Contact.Type = Contact.Type::Person then
                            ContactOK := FindContInPostDocuments(Contact."No.", "Value Entry")
                        else
                            ContactOK := true;

                        if ContactOK then
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
                RecordNo := RecordNo + 1;
                if RecordNo = 1 then begin
                    Window.Open(Text000);
                    NoOfRecords := Count;
                    OldDateTime := CurrentDateTime;
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

                ContactOK := true;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AllowExistingContact; AllowExistingContact)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Allow Existing Contacts';
                        ToolTip = 'Specifies if existing contacts are included in the segment.';
                    }
                    field(ExpandCompanies; ExpandCompanies)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Expand Companies';
                        ToolTip = 'Specifies if you want the segment to include all person contacts who are working for the company that you want to add to the segment.';
                    }
                    field(AllowRelatedCompaines; AllowCoRepdByContPerson)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Allow Related Companies';
                        Importance = Additional;
                        MultiLine = true;
                        ToolTip = 'Specifies if companies represented by person contacts are included in the segment.';
                    }
                    field(IgnoreExclusion; IgnoreExclusion)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Ignore Exclusion';
                        Importance = Additional;
                        ToolTip = 'Specifies if contacts are excluded for which the Exclude from Segment field has been selected on the contact card.';
                    }
                }
            }
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
        if ExpandCompanies then
            AddPeople();
        if AllowCoRepdByContPerson then
            AddCompanies();

        OnPostReportOnBeforeUpdateSegLines("Segment Header");

        UpdateSegLines();
    end;

    trigger OnPreReport()
    begin
        ItemFilters := "Value Entry".HasFilter;

        SegCriteriaManagement.InsertCriteriaAction(
          "Segment Header".GetFilter("No."), REPORT::"Add Contacts",
          AllowExistingContact, ExpandCompanies, AllowCoRepdByContPerson, IgnoreExclusion, false);
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
        Cont: Record Contact;
        SegLine: Record "Segment Line";
        SegmentHistoryMgt: Codeunit SegHistoryManagement;
        Window: Dialog;
        NextLineNo: Integer;
        ItemFilters: Boolean;
        AllowExistingContact: Boolean;
        ExpandCompanies: Boolean;
        AllowCoRepdByContPerson: Boolean;
        IgnoreExclusion: Boolean;
        SkipItemLedgerEntry: Boolean;
        NoOfRecords: Integer;
        RecordNo: Integer;
        OldDateTime: DateTime;
        NewDateTime: DateTime;
        OldProgress: Integer;
        NewProgress: Integer;

#pragma warning disable AA0074
        Text000: Label 'Inserting contacts @1@@@@@@@@@@@@@';
#pragma warning restore AA0074

    protected var
        TempCont: Record Contact temporary;
        TempCont2: Record Contact temporary;
        SegCriteriaManagement: Codeunit SegCriteriaManagement;
        ContactOK: Boolean;

    procedure SetOptions(OptionAllowExistingContact: Boolean; OptionExpandCompanies: Boolean; OptionAllowCoRepdByContPerson: Boolean; OptionIgnoreExclusion: Boolean)
    begin
        AllowExistingContact := OptionAllowExistingContact;
        ExpandCompanies := OptionExpandCompanies;
        AllowCoRepdByContPerson := OptionAllowCoRepdByContPerson;
        IgnoreExclusion := OptionIgnoreExclusion;
    end;

    procedure InsertContact(var CheckedCont: Record Contact)
    begin
        TempCont := CheckedCont;
        if TempCont.Insert() then;
    end;

    local procedure AddCompanies()
    begin
        TempCont.Reset();
        if TempCont.Find('-') then
            repeat
                TempCont2 := TempCont;
                if TempCont2.Insert() then;
                if TempCont."Company No." <> '' then begin
                    Cont.Get(TempCont."Company No.");
                    TempCont2 := Cont;
                    if TempCont2.Insert() then;
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

    local procedure AddPeople()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddPeople(TempCont, TempCont2, Cont, "Contact Mailing Group", IsHandled);
        if IsHandled then
            exit;

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
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSegLines("Segment Header", IsHandled);
        if IsHandled then
            exit;

        SegLine.SetRange("Segment No.", "Segment Header"."No.");
        if SegLine.FindLast() then
            NextLineNo := SegLine."Line No." + 10000
        else
            NextLineNo := 10000;

        TempCont.Reset();
        TempCont.SetCurrentKey("Company Name", "Company No.", Type, Name);
        if not IgnoreExclusion then
            TempCont.SetRange("Exclude from Segment", false);
        if TempCont.Find('-') then
            repeat
                ContactOK := true;
                if not AllowExistingContact then begin
                    SegLine.SetCurrentKey("Contact No.", "Segment No.");
                    SegLine.SetRange("Contact No.", TempCont."No.");
                    SegLine.SetRange("Segment No.", "Segment Header"."No.");
                    if SegLine.FindFirst() then
                        ContactOK := false;
                end;

                OnBeforeInsertSegmentLine(
                  TempCont, AllowExistingContact, ExpandCompanies, AllowCoRepdByContPerson, IgnoreExclusion, ContactOK);

                if ContactOK then begin
                    SegLine.Init();
                    SegLine."Line No." := NextLineNo;
                    SegLine.Validate("Segment No.", "Segment Header"."No.");
                    SegLine.Validate("Contact No.", TempCont."No.");
                    SegLine.Insert(true);
                    SegmentHistoryMgt.InsertLine(
                      SegLine."Segment No.", SegLine."Contact No.", SegLine."Line No.");
                    NextLineNo := SegLine."Line No." + 10000;
                end;
            until TempCont.Next() = 0;
    end;

    procedure FindContInPostDocuments(ContactNo: Code[20]; ValueEntry: Record "Value Entry"): Boolean
    var
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReturnShptHeader: Record "Return Shipment Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        case ValueEntry."Source Type" of
            ValueEntry."Source Type"::Customer:
                begin
                    if SalesInvHeader.ReadPermission then
                        if SalesInvHeader.Get(ValueEntry."Document No.") then
                            if (SalesInvHeader."Sell-to Contact No." = ContactNo) or
                               (SalesInvHeader."Bill-to Contact No." = ContactNo)
                            then
                                exit(true);
                    if SalesShptHeader.ReadPermission then
                        if SalesShptHeader.Get(ValueEntry."Document No.") then
                            if (SalesShptHeader."Sell-to Contact No." = ContactNo) or
                               (SalesShptHeader."Bill-to Contact No." = ContactNo)
                            then
                                exit(true);
                    if SalesCrMemoHeader.ReadPermission then
                        if SalesCrMemoHeader.Get(ValueEntry."Document No.") then
                            if (SalesCrMemoHeader."Sell-to Contact No." = ContactNo) or
                               (SalesCrMemoHeader."Bill-to Contact No." = ContactNo)
                            then
                                exit(true);
                    if ReturnRcptHeader.ReadPermission then
                        if ReturnRcptHeader.Get(ValueEntry."Document No.") then
                            if (ReturnRcptHeader."Sell-to Contact No." = ContactNo) or
                               (ReturnRcptHeader."Bill-to Contact No." = ContactNo)
                            then
                                exit(true);
                end;
            ValueEntry."Source Type"::Vendor:
                begin
                    if PurchInvHeader.ReadPermission then
                        if PurchInvHeader.Get(ValueEntry."Document No.") then
                            if (PurchInvHeader."Buy-from Contact No." = ContactNo) or
                               (PurchInvHeader."Pay-to Contact No." = ContactNo)
                            then
                                exit(true);
                    if ReturnShptHeader.ReadPermission then
                        if ReturnShptHeader.Get(ValueEntry."Document No.") then
                            if (ReturnShptHeader."Buy-from Contact No." = ContactNo) or
                               (ReturnShptHeader."Pay-to Contact No." = ContactNo)
                            then
                                exit(true);
                    if PurchCrMemoHeader.ReadPermission then
                        if PurchCrMemoHeader.Get(ValueEntry."Document No.") then
                            if (PurchCrMemoHeader."Buy-from Contact No." = ContactNo) or
                               (PurchCrMemoHeader."Pay-to Contact No." = ContactNo)
                            then
                                exit(true);
                    if PurchRcptHeader.ReadPermission then
                        if PurchRcptHeader.Get(ValueEntry."Document No.") then
                            if (PurchRcptHeader."Buy-from Contact No." = ContactNo) or
                               (PurchRcptHeader."Pay-to Contact no." = ContactNo)
                            then
                                exit(true);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPeople(var TempContact: Record Contact temporary; var TempContact2: Record Contact temporary; Contact: Record Contact; ContactMailingGroup: Record "Contact Mailing Group"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSegmentLine(var TempContact: Record Contact temporary; AllowExistingContact: Boolean; ExpandCompanies: Boolean; AllowCoRepdByContPerson: Boolean; IgnoreExclusion: Boolean; var ContactOK: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSegLines(var SegmentHeader: Record "Segment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeUpdateSegLines(var SegmentHeader: Record "Segment Header")
    begin
    end;
}

