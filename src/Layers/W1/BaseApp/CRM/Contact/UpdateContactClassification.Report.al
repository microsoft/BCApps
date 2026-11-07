// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Profiling;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 5199 "Update Contact Classification"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Update Contact Classification';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Profile Questionnaire Header"; "Profile Questionnaire Header")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code", Description, "Business Relation Code";
            dataitem("Profile Questionnaire Line"; "Profile Questionnaire Line")
            {
                DataItemLink = "Profile Questionnaire Code" = field(Code);
                DataItemTableView = sorting("Profile Questionnaire Code", "Line No.") where(Type = const(Question), "Auto Contact Classification" = const(true), "Contact Class. Field" = filter(<> Rating));

                trigger OnAfterGetRecord()
                begin
                    Window.Update(3, "Line No.");
                    if NoOfQuestions = 0 then
                        NoOfQuestions := Count;
                    QuestionCount := QuestionCount + 1;
                    Window.Update(4, Round(10000 * QuestionCount / NoOfQuestions, 1));
                    RecCount := 0;

                    TempContactValue.DeleteAll();

                    if (Format("Starting Date Formula") = '') or (Format("Ending Date Formula") = '') then
                        Error(
                          Text005,
                          FieldCaption("Starting Date Formula"),
                          FieldCaption("Ending Date Formula"),
                          "Profile Questionnaire Header".Code,
                          Description);

                    if "Classification Method" = "Classification Method"::" " then
                        Error(
                          Text008,
                          FieldCaption("Classification Method"),
                          "Profile Questionnaire Header".Code,
                          Description);

                    AnswersExists("Profile Questionnaire Line", '', true);
                    TotalValue := 0;

                    case true of
                        "Customer Class. Field" <> "Customer Class. Field"::" ":
                            FindCustomerValues("Profile Questionnaire Line");
                        "Vendor Class. Field" <> "Vendor Class. Field"::" ":
                            FindVendorValues("Profile Questionnaire Line");
                        "Contact Class. Field" <> "Contact Class. Field"::" ":
                            FindContactValues("Profile Questionnaire Line");
                    end;

                    MarkContactByMethod("Profile Questionnaire Line", '');
                end;

                trigger OnPreDataItem()
                begin
                    NoOfQuestions := 0;
                    QuestionCount := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Code);
                if NoOfProfiles = 0 then
                    NoOfProfiles := Count;
                ProfileCount := ProfileCount + 1;
                Window.Update(2, Round(10000 * ProfileCount / NoOfProfiles, 1));
                NoOfQuestions := 0;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                UpdateRating('');
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
                    field(Date; Date)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Date';
                        ToolTip = 'Specifies the date on which you update the contact classification.';
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

    trigger OnInitReport()
    begin
        Date := WorkDate();
    end;

    trigger OnPreReport()
    begin
        Window.Open(
          Text000 +
          Text001 +
          Text002);
    end;

    var
        TempContactValue: Record "Contact Value" temporary;
        Window: Dialog;
        Date: Date;
        NoOfProfiles: Integer;
        ProfileCount: Integer;
        NoOfQuestions: Integer;
        QuestionCount: Integer;
        NoOfRecs: Integer;
        RecCount: Integer;
        TotalValue: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Profile Questionnaire #1######## @2@@@@@@@@@@@@@\\';
        Text001: Label 'Question Line No.     #3######## @4@@@@@@@@@@@@@\';
        Text002: Label 'Finding Values        #5######## @6@@@@@@@@@@@@@\';
        Text003: Label '%1 results in a date before the result of the %2.';
#pragma warning restore AA0470
        Text004: Label 'Two or more questions are causing the rating calculation to loop.';
        Text005: Label 'You must specify %1 and %2 in Profile Questionnaire %3, question %4. To find additional errors, run the Test report.', Comment = '%1 = Starting Date Formula;%2 = Ending Date Formula;%3 = Profile Questionaire Code;%4 = Question Description';
        Text008: Label 'You must specify %1 in Profile Questionnaire %2, question %3. To find additional errors, run the Test report.', Comment = '%1 = Sorting Method;%2 = Profile Questionaire Code;%3 = Question Description';
#pragma warning restore AA0074

    protected procedure AnswersExists(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; UpdateContNo: Code[20]; DoDelete: Boolean): Boolean
    var
        ContProfileAnswer: Record "Contact Profile Answer";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
    begin
        ContProfileAnswer.SetCurrentKey("Profile Questionnaire Code", "Line No.");
        ContProfileAnswer.SetRange("Profile Questionnaire Code", ProfileQuestionnaireLine."Profile Questionnaire Code");

        ProfileQuestnLine2.Reset();
        ProfileQuestnLine2 := ProfileQuestionnaireLine;
        ProfileQuestnLine2.SetRange(Type, ProfileQuestnLine2.Type::Question);
        ProfileQuestnLine2.SetRange("Profile Questionnaire Code", ProfileQuestionnaireLine."Profile Questionnaire Code");
        if ProfileQuestnLine2.Next() <> 0 then
            ContProfileAnswer.SetRange("Line No.", ProfileQuestionnaireLine."Line No.", ProfileQuestnLine2."Line No.")
        else
            ContProfileAnswer.SetFilter("Line No.", '%1..', ProfileQuestionnaireLine."Line No.");
        if UpdateContNo <> '' then begin
            ContProfileAnswer.SetRange("Contact No.", UpdateContNo);
            ContProfileAnswer.SetCurrentKey("Contact No.", "Profile Questionnaire Code", "Line No.");
        end;

        if DoDelete then
            ContProfileAnswer.DeleteAll()
        else
            exit(not ContProfileAnswer.IsEmpty);
    end;

    local procedure FindCustomerValues(ProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    var
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        ValueEntry: Record "Value Entry";
        CustContactNo: Code[20];
        NoOfInvoices: Integer;
        DaysOverdue: Integer;
        NoOfYears: Decimal;
        DecimalValue: Decimal;
        QuestionsAnsweredPct: Decimal;
        FromDate: Date;
        ToDate: Date;
        UpdateDate: Date;
        IsHandled: Boolean;
    begin
        OnBeforeFindCustomerValues(Cust);
        NoOfRecs := Cust.Count();
        if Cust.Find('-') then
            repeat
                OnFindCustomerValuesOnBeforeCustLoop(ProfileQuestionnaireLine, Cust, Date);
                RecCount := RecCount + 1;
                Window.Update(5, Cust."No.");
                Window.Update(6, Round(10000 * RecCount / NoOfRecs, 1));
                CustContactNo := GetContactNo(ProfileQuestionnaireLine, DATABASE::Customer, Cust."No.");
                if CustContactNo <> '' then begin
                    Cust.Reset();
                    FromDate := CalcDate(ProfileQuestionnaireLine."Starting Date Formula", Date);
                    ToDate := CalcDate(ProfileQuestionnaireLine."Ending Date Formula", Date);
                    if ToDate < FromDate then
                        ProfileQuestionnaireLine.FieldError("Ending Date Formula",
                          StrSubstNo(Text003,
                            ProfileQuestionnaireLine.FieldCaption("Ending Date Formula"),
                            ProfileQuestionnaireLine.FieldCaption("Starting Date Formula")));
                    Cust.SetRange("Date Filter", FromDate, ToDate);
                    OnFindCustomerValuesOnBeforeCustomerClassFieldCase(Cust, CustLedgEntry, CustLedgEntry2);
                    case ProfileQuestionnaireLine."Customer Class. Field" of
                        ProfileQuestionnaireLine."Customer Class. Field"::"Sales (LCY)":
                            begin
                                Cust.CalcFields("Sales (LCY)");
                                InsertContactValue(ProfileQuestionnaireLine, CustContactNo, Cust."Sales (LCY)", 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Customer Class. Field"::"Profit (LCY)":
                            begin
                                Cust.CalcFields("Profit (LCY)");
                                InsertContactValue(ProfileQuestionnaireLine, CustContactNo, Cust."Profit (LCY)", 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Customer Class. Field"::"Sales Frequency (Invoices/Year)":
                            begin
                                CustLedgEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date");
                                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                CustLedgEntry.SetRange("Customer No.", Cust."No.");
                                CustLedgEntry.SetFilter("Posting Date", Cust.GetFilter("Date Filter"));
                                NoOfInvoices := CustLedgEntry.Count();
                                NoOfYears := (ToDate - FromDate + 1) / 365;
                                InsertContactValue(ProfileQuestionnaireLine, CustContactNo, NoOfInvoices / NoOfYears, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Customer Class. Field"::"Avg. Invoice Amount (LCY)":
                            begin
                                CustLedgEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date");
                                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                CustLedgEntry.SetRange("Customer No.", Cust."No.");
                                CustLedgEntry.SetFilter("Posting Date", Cust.GetFilter("Date Filter"));
                                NoOfInvoices := CustLedgEntry.Count();
                                if NoOfInvoices <> 0 then begin
                                    CustLedgEntry.CalcSums("Sales (LCY)");
                                    InsertContactValue(ProfileQuestionnaireLine, CustContactNo, CustLedgEntry."Sales (LCY)" / NoOfInvoices, 0D, 0);
                                end else
                                    InsertContactValue(ProfileQuestionnaireLine, CustContactNo, 0, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Customer Class. Field"::"Discount (%)":
                            begin
                                CustLedgEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date");
                                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                CustLedgEntry.SetRange("Customer No.", Cust."No.");
                                CustLedgEntry.SetFilter("Posting Date", Cust.GetFilter("Date Filter"));
                                if CustLedgEntry.Find('-') then begin
                                    CustLedgEntry.CalcSums("Sales (LCY)");
                                    ValueEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Posting Date");
                                    ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
                                    ValueEntry.SetRange("Source No.", Cust."No.");
                                    ValueEntry.SetFilter("Posting Date", Cust.GetFilter("Date Filter"));
                                    ValueEntry.CalcSums("Discount Amount");
                                    ValueEntry."Discount Amount" := -ValueEntry."Discount Amount";
                                    if (CustLedgEntry."Sales (LCY)" + ValueEntry."Discount Amount") <> 0 then
                                        InsertContactValue(
                                          ProfileQuestionnaireLine, CustContactNo,
                                          100 * ValueEntry."Discount Amount" /
                                          (CustLedgEntry."Sales (LCY)" + ValueEntry."Discount Amount"), 0D, 0)
                                    else
                                        InsertContactValue(ProfileQuestionnaireLine, CustContactNo, 0, 0D, 0);
                                end else
                                    InsertContactValue(ProfileQuestionnaireLine, CustContactNo, 0, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Customer Class. Field"::"Avg. Overdue (Day)":
                            begin
                                CustLedgEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date");
                                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                CustLedgEntry.SetRange("Customer No.", Cust."No.");
                                CustLedgEntry.SetFilter("Posting Date", Cust.GetFilter("Date Filter"));
                                CustLedgEntry.SetRange(Open, false);
                                NoOfInvoices := CustLedgEntry.Count();
                                if NoOfInvoices <> 0 then begin
                                    DaysOverdue := 0;
                                    CustLedgEntry.Find('-');
                                    repeat
                                        if CustLedgEntry."Closed at Date" > CustLedgEntry."Due Date" then
                                            DaysOverdue := DaysOverdue + (CustLedgEntry."Closed at Date" - CustLedgEntry."Due Date")
                                        else
                                            if CustLedgEntry."Closed at Date" = 0D then begin
                                                CustLedgEntry2.Reset();
                                                CustLedgEntry2.SetCurrentKey("Closed by Entry No.");
                                                CustLedgEntry2.SetRange("Document Type", CustLedgEntry2."Document Type"::Payment);
                                                CustLedgEntry2.SetRange("Closed by Entry No.", CustLedgEntry."Entry No.");
                                                if CustLedgEntry2.FindFirst() and
                                                   (CustLedgEntry2."Closed at Date" > CustLedgEntry."Due Date")
                                                then
                                                    DaysOverdue := DaysOverdue + (CustLedgEntry2."Closed at Date" - CustLedgEntry."Due Date");
                                            end;
                                    until CustLedgEntry.Next() = 0;
                                    InsertContactValue(ProfileQuestionnaireLine, CustContactNo, DaysOverdue / NoOfInvoices, 0D, 0);
                                end else begin
                                    IsHandled := false;
                                    OnFindCustomerValuesOnAvgOverdueDayOnZeroInvoices(ProfileQuestionnaireLine, CustLedgEntry, ValueEntry, Cust, CustContactNo, IsHandled);
                                    if not IsHandled then
                                        InsertContactValue(ProfileQuestionnaireLine, CustContactNo, 0, 0D, 0);
                                end;
                            end;
                        else begin
                            IsHandled := false;
                            OnFindCustomerValuesOnElseCustomerClassFieldCase(ProfileQuestionnaireLine, Cust, CustContactNo, DecimalValue, UpdateDate, QuestionsAnsweredPct, IsHandled);
                            if IsHandled then
                                InsertContactValue(ProfileQuestionnaireLine, CustContactNo, DecimalValue, UpdateDate, QuestionsAnsweredPct);
                        end;
                    end;
                    OnFindCustomerValuesOnAfterCustomerClassFieldCase(Cust);
                end;
            until Cust.Next() = 0
    end;

    local procedure FindVendorValues(ProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    var
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        ValueEntry: Record "Value Entry";
        VendContactNo: Code[20];
        NoOfInvoices: Integer;
        DaysOverdue: Integer;
        NoOfYears: Decimal;
        FromDate: Date;
        ToDate: Date;
    begin
        NoOfRecs := Vend.Count();
        if Vend.Find('-') then
            repeat
                RecCount := RecCount + 1;
                Window.Update(5, Vend."No.");
                Window.Update(6, Round(10000 * RecCount / NoOfRecs, 1));
                VendContactNo := GetContactNo(ProfileQuestionnaireLine, DATABASE::Vendor, Vend."No.");
                if VendContactNo <> '' then begin
                    Vend.Reset();
                    FromDate := CalcDate(ProfileQuestionnaireLine."Starting Date Formula", Date);
                    ToDate := CalcDate(ProfileQuestionnaireLine."Ending Date Formula", Date);
                    if ToDate < FromDate then
                        ProfileQuestionnaireLine.FieldError("Ending Date Formula",
                          StrSubstNo(Text003,
                            ProfileQuestionnaireLine.FieldCaption("Ending Date Formula"),
                            ProfileQuestionnaireLine.FieldCaption("Starting Date Formula")));
                    Vend.SetRange("Date Filter", FromDate, ToDate);
                    case ProfileQuestionnaireLine."Vendor Class. Field" of
                        ProfileQuestionnaireLine."Vendor Class. Field"::"Purchase (LCY)":
                            begin
                                Vend.CalcFields("Purchases (LCY)");
                                Vend."Purchases (LCY)" := Vend."Purchases (LCY)";
                                InsertContactValue(ProfileQuestionnaireLine, VendContactNo, Vend."Purchases (LCY)", 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Vendor Class. Field"::"Purchase Frequency (Invoices/Year)":
                            begin
                                VendLedgEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
                                VendLedgEntry.SetRange("Vendor No.", Vend."No.");
                                VendLedgEntry.SetFilter("Posting Date", Vend.GetFilter("Date Filter"));
                                NoOfInvoices := VendLedgEntry.Count();
                                NoOfYears := (ToDate - FromDate + 1) / 365;
                                InsertContactValue(ProfileQuestionnaireLine, VendContactNo, NoOfInvoices / NoOfYears, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Vendor Class. Field"::"Avg. Ticket Size (LCY)":
                            begin
                                VendLedgEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
                                VendLedgEntry.SetRange("Vendor No.", Vend."No.");
                                VendLedgEntry.SetFilter("Posting Date", Vend.GetFilter("Date Filter"));
                                NoOfInvoices := VendLedgEntry.Count();
                                if NoOfInvoices <> 0 then begin
                                    VendLedgEntry.CalcSums("Purchase (LCY)");
                                    VendLedgEntry."Purchase (LCY)" := -VendLedgEntry."Purchase (LCY)";
                                    InsertContactValue(ProfileQuestionnaireLine, VendContactNo, VendLedgEntry."Purchase (LCY)" / NoOfInvoices, 0D, 0);
                                end else
                                    InsertContactValue(ProfileQuestionnaireLine, VendContactNo, 0, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Vendor Class. Field"::"Discount (%)":
                            begin
                                VendLedgEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
                                VendLedgEntry.SetRange("Vendor No.", Vend."No.");
                                VendLedgEntry.SetFilter("Posting Date", Vend.GetFilter("Date Filter"));
                                if VendLedgEntry.Find('-') then begin
                                    VendLedgEntry.CalcSums("Purchase (LCY)");
                                    VendLedgEntry."Purchase (LCY)" := -VendLedgEntry."Purchase (LCY)";
                                    ValueEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Posting Date");
                                    ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Vendor);
                                    ValueEntry.SetRange("Source No.", Vend."No.");
                                    ValueEntry.SetFilter("Posting Date", Vend.GetFilter("Date Filter"));
                                    ValueEntry.CalcSums("Discount Amount");
                                    if (VendLedgEntry."Purchase (LCY)" + ValueEntry."Discount Amount") <> 0 then
                                        InsertContactValue(
                                          ProfileQuestionnaireLine, VendContactNo,
                                          100 * ValueEntry."Discount Amount" /
                                          (VendLedgEntry."Purchase (LCY)" + ValueEntry."Discount Amount"), 0D, 0)
                                    else
                                        InsertContactValue(ProfileQuestionnaireLine, VendContactNo, 0, 0D, 0);
                                end else
                                    InsertContactValue(ProfileQuestionnaireLine, VendContactNo, 0, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Vendor Class. Field"::"Avg. Overdue (Day)":
                            begin
                                VendLedgEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
                                VendLedgEntry.SetRange("Vendor No.", Vend."No.");
                                VendLedgEntry.SetFilter("Posting Date", Vend.GetFilter("Date Filter"));
                                VendLedgEntry.SetRange(Open, false);
                                NoOfInvoices := VendLedgEntry.Count();
                                if NoOfInvoices <> 0 then begin
                                    DaysOverdue := 0;
                                    VendLedgEntry.Find('-');
                                    repeat
                                        if VendLedgEntry."Closed at Date" > VendLedgEntry."Due Date" then
                                            DaysOverdue := DaysOverdue + (VendLedgEntry."Closed at Date" - VendLedgEntry."Due Date")
                                        else
                                            if VendLedgEntry."Closed at Date" = 0D then begin
                                                VendLedgEntry2.Reset();
                                                VendLedgEntry2.SetCurrentKey("Closed by Entry No.");
                                                VendLedgEntry2.SetRange("Document Type", VendLedgEntry2."Document Type"::Payment);
                                                VendLedgEntry2.SetRange("Closed by Entry No.", VendLedgEntry."Entry No.");
                                                if VendLedgEntry2.FindFirst() and
                                                   (VendLedgEntry2."Closed at Date" > VendLedgEntry."Due Date")
                                                then
                                                    DaysOverdue := DaysOverdue + (VendLedgEntry2."Closed at Date" - VendLedgEntry."Due Date");
                                            end;
                                    until VendLedgEntry.Next() = 0;
                                    InsertContactValue(ProfileQuestionnaireLine, VendContactNo, DaysOverdue / NoOfInvoices, 0D, 0);
                                end else
                                    InsertContactValue(ProfileQuestionnaireLine, VendContactNo, 0, 0D, 0);
                            end;
                    end;
                end;
            until Vend.Next() = 0
    end;

    local procedure FindContactValues(ProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    var
        Cont: Record Contact;
        ContNo: Code[20];
        NoOfYears: Decimal;
        WonCount: Integer;
        LostCount: Integer;
        FromDate: Date;
        ToDate: Date;
    begin
        OnBeforeFindContactValues(Cont);
        NoOfRecs := Cont.Count();
        if Cont.Find('-') then
            repeat
                OnFindContactValuesOnBeforeContLoop(ProfileQuestionnaireLine, Cont, Date);
                RecCount := RecCount + 1;
                Window.Update(5, Cont."No.");
                Window.Update(6, Round(10000 * RecCount / NoOfRecs, 1));
                ContNo := GetContactNo(ProfileQuestionnaireLine, DATABASE::Contact, Cont."No.");
                if ContNo <> '' then begin
                    Cont.Reset();
                    FromDate := CalcDate(ProfileQuestionnaireLine."Starting Date Formula", Date);
                    ToDate := CalcDate(ProfileQuestionnaireLine."Ending Date Formula", Date);
                    if ToDate < FromDate then
                        ProfileQuestionnaireLine.FieldError("Ending Date Formula",
                          StrSubstNo(Text003,
                            ProfileQuestionnaireLine.FieldCaption("Ending Date Formula"),
                            ProfileQuestionnaireLine.FieldCaption("Starting Date Formula")));
                    Cont.SetRange("Date Filter", FromDate, ToDate);
                    case ProfileQuestionnaireLine."Contact Class. Field" of
                        ProfileQuestionnaireLine."Contact Class. Field"::"Interaction Quantity":
                            begin
                                Cont.CalcFields("No. of Interactions");
                                InsertContactValue(ProfileQuestionnaireLine, Cont."No.", Cont."No. of Interactions", 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Contact Class. Field"::"Interaction Frequency (No./Year)":
                            begin
                                Cont.CalcFields("No. of Interactions");
                                NoOfYears := (ToDate - FromDate + 1) / 365;
                                InsertContactValue(ProfileQuestionnaireLine, Cont."No.", Cont."No. of Interactions" / NoOfYears, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Contact Class. Field"::"Avg. Interaction Cost (LCY)":
                            begin
                                Cont.CalcFields("No. of Interactions", "Cost (LCY)");
                                if Cont."No. of Interactions" <> 0 then
                                    InsertContactValue(ProfileQuestionnaireLine, Cont."No.", Cont."Cost (LCY)" / Cont."No. of Interactions", 0D, 0)
                                else
                                    InsertContactValue(ProfileQuestionnaireLine, Cont."No.", 0, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Contact Class. Field"::"Avg. Interaction Duration (Min.)":
                            begin
                                Cont.CalcFields("No. of Interactions", "Duration (Min.)");
                                if Cont."No. of Interactions" <> 0 then
                                    InsertContactValue(ProfileQuestionnaireLine, Cont."No.", Cont."Duration (Min.)" / Cont."No. of Interactions", 0D, 0)
                                else
                                    InsertContactValue(ProfileQuestionnaireLine, Cont."No.", 0, 0D, 0);
                            end;
                        ProfileQuestionnaireLine."Contact Class. Field"::"Opportunity Won (%)":
                            begin
                                Cont.SetRange("Action Taken Filter", Cont."Action Taken Filter"::Won);
                                Cont.CalcFields("No. of Opportunities");
                                WonCount := Cont."No. of Opportunities";
                                Cont.SetRange("Action Taken Filter", Cont."Action Taken Filter"::Lost);
                                Cont.CalcFields("No. of Opportunities");
                                LostCount := Cont."No. of Opportunities";
                                if (LostCount + WonCount) <> 0 then
                                    InsertContactValue(ProfileQuestionnaireLine, Cont."No.", 100 * WonCount / (LostCount + WonCount), 0D, 0)
                                else
                                    InsertContactValue(ProfileQuestionnaireLine, Cont."No.", 0, 0D, 0);
                            end;
                    end;
                    OnFindContactValuesOnAfterContactClassFieldCase(Cont);
                end;
            until Cont.Next() = 0
    end;

    local procedure GetContactNo(ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; TableID: Integer; No: Code[20]) ContactNo: Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        ProfileQuestnHeader: Record "Profile Questionnaire Header";
        IsHandled: Boolean;
    begin
        ProfileQuestnHeader.Get(ProfileQuestionnaireLine."Profile Questionnaire Code");
        if TableID = DATABASE::Contact then
            ContactNo := No
        else begin
            ContBusRel.Reset();
            ContBusRel.SetCurrentKey("Link to Table", "No.");
            case TableID of
                DATABASE::Customer:
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                DATABASE::Vendor:
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
            end;
            ContBusRel.SetRange("No.", No);
            if ContBusRel.FindFirst() then
                ContactNo := ContBusRel."Contact No."
            else
                exit('');
        end;

        Cont.Get(ContactNo);

        IsHandled := false;
        OnGetContactNoOnBeforeCheckContactValid(ProfileQuestnHeader, Cont, ContactNo, IsHandled);
        if IsHandled then
            exit(ContactNo);

        if (ProfileQuestnHeader."Contact Type" = ProfileQuestnHeader."Contact Type"::Companies) and
           (Cont.Type <> Cont.Type::Company)
        then
            exit('');

        if ProfileQuestnHeader."Business Relation Code" = '' then
            exit(ContactNo);

        ContBusRel.Reset();
        if TableID = DATABASE::Contact then
            ContBusRel.SetRange("Contact No.", Cont."Company No.")
        else
            ContBusRel.SetRange("Contact No.", ContactNo);
        ContBusRel.SetRange("Business Relation Code", ProfileQuestnHeader."Business Relation Code");
        if not ContBusRel.IsEmpty() then
            exit(ContactNo);
        ContactNo := '';
    end;

    protected procedure InsertContactValue(ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; ContactNo: Code[20]; Value: Decimal; UpdateDate: Date; QuestionsAnsweredPrc: Decimal)
    begin
        TempContactValue.Init();
        TempContactValue."Contact No." := ContactNo;
        if ProfileQuestionnaireLine."Classification Method" = ProfileQuestionnaireLine."Classification Method"::"Defined Value" then
            TempContactValue.Value := Round(Value, 1 / Power(10, ProfileQuestionnaireLine."No. of Decimals"))
        else
            TempContactValue.Value := Value;
        TempContactValue."Last Date Updated" := UpdateDate;
        TempContactValue."Questions Answered (%)" := QuestionsAnsweredPrc;
        TempContactValue.Insert();
        TotalValue := TotalValue + TempContactValue.Value;
    end;

    local procedure MarkByDefinedValue(ProfileQuestnLineQuestion: Record "Profile Questionnaire Line"; ProfileQuestnLineAnswer: Record "Profile Questionnaire Line")
    begin
        TempContactValue.Reset();
        if TempContactValue.Find('-') then
            repeat
                if InRange(TempContactValue.Value, ProfileQuestnLineAnswer."From Value", ProfileQuestnLineAnswer."To Value") then
                    MarkContact(
                      ProfileQuestnLineQuestion, ProfileQuestnLineAnswer, TempContactValue."Contact No.",
                      TempContactValue."Last Date Updated", TempContactValue."Questions Answered (%)")
            until TempContactValue.Next() = 0;
    end;

    local procedure MarkByPercentageOfValue(ProfileQuestnLineQuestion: Record "Profile Questionnaire Line"; ProfileQuestnLineAnswer: Record "Profile Questionnaire Line")
    var
        Prc: Decimal;
    begin
        TempContactValue.Reset();
        TempContactValue.SetCurrentKey(Value);

        if ProfileQuestnLineQuestion."Sorting Method" = ProfileQuestnLineQuestion."Sorting Method"::" " then
            Error(
              Text008,
              ProfileQuestnLineQuestion.FieldCaption("Sorting Method"),
              ProfileQuestnLineQuestion."Profile Questionnaire Code",
              ProfileQuestnLineQuestion.Description);

        case ProfileQuestnLineQuestion."Sorting Method" of
            ProfileQuestnLineQuestion."Sorting Method"::Descending:
                TempContactValue.Ascending(false);
            ProfileQuestnLineQuestion."Sorting Method"::Ascending:
                TempContactValue.Ascending(true);
        end;

        if TempContactValue.FindSet() then
            repeat
                if TotalValue <> 0 then
                    Prc := Round(100 * TempContactValue.Value / TotalValue, 1 / Power(10, ProfileQuestnLineQuestion."No. of Decimals"))
                else
                    Prc := 0;
                if InRange(Prc, ProfileQuestnLineAnswer."From Value", ProfileQuestnLineAnswer."To Value") then
                    MarkContact(
                      ProfileQuestnLineQuestion, ProfileQuestnLineAnswer, TempContactValue."Contact No.",
                      TempContactValue."Last Date Updated", TempContactValue."Questions Answered (%)");
            until TempContactValue.Next() = 0
    end;

    local procedure MarkByPercentageOfContacts(ProfileQuestnLineQuestion: Record "Profile Questionnaire Line"; ProfileQuestnLineAnswer: Record "Profile Questionnaire Line")
    var
        ContactValueCount: Integer;
        RecNo: Integer;
        Prc: Decimal;
    begin
        TempContactValue.Reset();
        TempContactValue.SetCurrentKey(Value);

        if ProfileQuestnLineQuestion."Sorting Method" = ProfileQuestnLineQuestion."Sorting Method"::" " then
            Error(
              Text008,
              ProfileQuestnLineQuestion.FieldCaption("Sorting Method"),
              ProfileQuestnLineQuestion."Profile Questionnaire Code",
              ProfileQuestnLineQuestion.Description);

        case ProfileQuestnLineQuestion."Sorting Method" of
            ProfileQuestnLineQuestion."Sorting Method"::Descending:
                TempContactValue.Ascending(false);
            ProfileQuestnLineQuestion."Sorting Method"::Ascending:
                TempContactValue.Ascending(true);
        end;

        if TempContactValue.Find('-') then begin
            ContactValueCount := TempContactValue.Count();
            RecNo := 0;
            repeat
                RecNo := RecNo + 1;
                Prc := Round(100 * RecNo / ContactValueCount, 1 / Power(10, ProfileQuestnLineQuestion."No. of Decimals"));
                if InRange(Prc, ProfileQuestnLineAnswer."From Value", ProfileQuestnLineAnswer."To Value") then
                    MarkContact(
                      ProfileQuestnLineQuestion, ProfileQuestnLineAnswer, TempContactValue."Contact No.",
                      TempContactValue."Last Date Updated", TempContactValue."Questions Answered (%)")
            until TempContactValue.Next() = 0
        end;
    end;

    local procedure InRange(Value: Decimal; FromValue: Decimal; ToValue: Decimal): Boolean
    var
        Result: Boolean;
    begin
        if (FromValue <> 0) and (ToValue <> 0) and (Value >= FromValue) and (Value <= ToValue) then
            exit(true);
        if (FromValue <> 0) and (ToValue = 0) and (Value >= FromValue) then
            exit(true);
        if (FromValue = 0) and (ToValue <> 0) and (Value <= ToValue) then
            exit(true);

        Result := false;
        OnAfterInRange(Value, FromValue, ToValue, Result);
        exit(Result);
    end;

    local procedure MarkContact(ProfileQuestnLineQuestion: Record "Profile Questionnaire Line"; ProfileQuestnLineAnswer: Record "Profile Questionnaire Line"; ContNo: Code[20]; UpdateDate: Date; QuestionsAnsweredPrc: Decimal)
    var
        Cont: Record Contact;
        ContPers: Record Contact;
        ContProfileAnswer: Record "Contact Profile Answer";
        ProfileQuestnHeader2: Record "Profile Questionnaire Header";
        IsHandled: Boolean;
    begin
        ProfileQuestnHeader2.Get(ProfileQuestnLineQuestion."Profile Questionnaire Code");
        Cont.Get(ContNo);
        IsHandled := false;
        OnBeforeMarkContact(ProfileQuestnHeader2, ProfileQuestnLineQuestion, ProfileQuestnLineAnswer, Cont, UpdateDate, QuestionsAnsweredPrc, IsHandled);
        if IsHandled then
            exit;

        if (Cont.Type = Cont.Type::Company) and
           (ProfileQuestnLineQuestion."Contact Class. Field" = ProfileQuestnLineQuestion."Contact Class. Field"::" ") and
           (ProfileQuestnHeader2."Contact Type" <> ProfileQuestnHeader2."Contact Type"::Companies)
        then begin
            ContPers.Reset();
            ContPers.SetCurrentKey("Company No.");
            ContPers.SetRange("Company No.", Cont."No.");
            ContPers.SetRange(Type, Cont.Type::Person);
            if ContPers.Find('-') then
                repeat
                    MarkContact(ProfileQuestnLineQuestion, ProfileQuestnLineAnswer, ContPers."No.", UpdateDate, QuestionsAnsweredPrc);
                until ContPers.Next() = 0
        end;

        IsHandled := false;
        OnMarkContactOnBeforeCheckContactType(ProfileQuestnHeader2, ProfileQuestnLineQuestion, ProfileQuestnLineAnswer, Cont, UpdateDate, QuestionsAnsweredPrc, IsHandled);
        if IsHandled then
            exit;

        if (ProfileQuestnHeader2."Contact Type" = ProfileQuestnHeader2."Contact Type"::People) and
           (Cont.Type <> Cont.Type::Person)
        then
            exit;
        if (ProfileQuestnHeader2."Contact Type" = ProfileQuestnHeader2."Contact Type"::Companies) and
           (Cont.Type <> Cont.Type::Company)
        then
            exit;

        ContProfileAnswer.Init();
        ContProfileAnswer."Contact No." := Cont."No.";
        ContProfileAnswer."Profile Questionnaire Code" := ProfileQuestnLineAnswer."Profile Questionnaire Code";
        ContProfileAnswer."Line No." := ProfileQuestnLineAnswer."Line No.";
        ContProfileAnswer."Contact Company No." := Cont."Company No.";
        ContProfileAnswer."Profile Questionnaire Priority" := ProfileQuestnHeader2.Priority;
        ContProfileAnswer."Answer Priority" := ProfileQuestnLineAnswer.Priority;
        ContProfileAnswer."Questions Answered (%)" := QuestionsAnsweredPrc;
        if UpdateDate = 0D then
            ContProfileAnswer."Last Date Updated" := Today
        else
            ContProfileAnswer."Last Date Updated" := UpdateDate;
        ContProfileAnswer.Insert();
    end;

    procedure UpdateRating(UpdateContNo: Code[20])
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
        Rating: Record Rating;
        RatingQuestion: Record Rating;
        Cont: Record Contact;
        Leaf: Boolean;
        Changed: Boolean;
        ContNo: Code[20];
        NoOfRatingLines: Integer;
        RatingLineNo: Integer;
        Points: Integer;
        UpdateDate: Date;
        QuestionsAnsweredPrc: Decimal;
    begin
        // Mark all non-calculated rating questions
        ProfileQuestnLine.Reset();
        ProfileQuestnLine.SetRange("Contact Class. Field", ProfileQuestnLine."Contact Class. Field"::Rating);
        if "Profile Questionnaire Header".Code <> '' then
            ProfileQuestnLine.SetRange("Profile Questionnaire Code", "Profile Questionnaire Header".Code);
        if not ProfileQuestnLine.Find('-') then
            exit;
        repeat
            ProfileQuestnLine.Mark(true);
            NoOfRatingLines := NoOfRatingLines + 1;
        until ProfileQuestnLine.Next() = 0;
        ProfileQuestnLine.MarkedOnly(true);

        // Calculate Ratings
        repeat
            Changed := false;
            if ProfileQuestnLine.Find('-') then
                repeat
                    Leaf := true;
                    Rating.SetRange("Profile Questionnaire Code", ProfileQuestnLine."Profile Questionnaire Code");
                    Rating.SetRange("Profile Questionnaire Line No.", ProfileQuestnLine."Line No.");
                    if Rating.Find('-') then
                        repeat
                            ProfileQuestnLine2.Get(Rating."Rating Profile Quest. Code", Rating."Rating Profile Quest. Line No.");
                            RatingQuestion.SetRange("Profile Questionnaire Code", Rating."Rating Profile Quest. Code");
                            RatingQuestion.SetRange("Profile Questionnaire Line No.", ProfileQuestnLine2.FindQuestionLine());
                            if RatingQuestion.FindFirst() then begin
                                ProfileQuestnLine2 := ProfileQuestnLine;
                                ProfileQuestnLine.Get(
                                  RatingQuestion."Profile Questionnaire Code", RatingQuestion."Profile Questionnaire Line No.");
                                if ProfileQuestnLine.Mark() then
                                    Leaf := false;
                                ProfileQuestnLine := ProfileQuestnLine2;
                            end;
                        until (Rating.Next() = 0) or (not Leaf);

                    // Calculate Rating
                    if Leaf then begin
                        if UpdateContNo = '' then begin
                            RatingLineNo := RatingLineNo + 1;
                            Window.Update(1, ProfileQuestnLine."Profile Questionnaire Code");
                            Window.Update(3, ProfileQuestnLine."Line No.");
                            Window.Update(4, Round(10000 * RatingLineNo / NoOfRatingLines, 1));
                            NoOfRecs := Cont.Count();
                            RecCount := 0;
                            TotalValue := 0;
                        end;
                        TempContactValue.DeleteAll();
                        AnswersExists(ProfileQuestnLine, UpdateContNo, true);
                        if UpdateContNo <> '' then
                            Cont.SetRange("No.", UpdateContNo);
                        if Cont.Find('-') then
                            repeat
                                if UpdateContNo = '' then begin
                                    RecCount := RecCount + 1;
                                    Window.Update(5, Cont."No.");
                                    Window.Update(6, Round(10000 * RecCount / NoOfRecs, 1));
                                end;
                                ContNo := GetContactNo(ProfileQuestnLine, DATABASE::Contact, Cont."No.");
                                if ContNo <> '' then begin
                                    Points := FindContactRatingValue(ProfileQuestnLine, Cont, UpdateDate, QuestionsAnsweredPrc);
                                    if QuestionsAnsweredPrc >= ProfileQuestnLine."Min. % Questions Answered" then
                                        InsertContactValue(ProfileQuestnLine, Cont."No.", Points, UpdateDate, QuestionsAnsweredPrc);
                                end;
                            until Cont.Next() = 0;
                        MarkContactByMethod(ProfileQuestnLine, UpdateContNo);
                        ProfileQuestnLine.Mark(false);
                        Changed := true;
                    end;
                until ProfileQuestnLine.Next() = 0;
        until Changed = false;

        if ProfileQuestnLine.Find('-') then
            Error(Text004);
    end;

    local procedure FindContactRatingValue(ProfileQuestnLine: Record "Profile Questionnaire Line"; Cont: Record Contact; var UpdateDate: Date; var QuestionsAnsweredPrc: Decimal) Value: Decimal
    var
        Rating: Record Rating;
        ContProfileAnswer: Record "Contact Profile Answer";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        TempProfileQuestnLine: Record "Profile Questionnaire Line" temporary;
        NoOfAnsweredQuestions: Integer;
    begin
        UpdateDate := Today;
        Rating.SetRange("Profile Questionnaire Code", ProfileQuestnLine."Profile Questionnaire Code");
        Rating.SetRange("Profile Questionnaire Line No.", ProfileQuestnLine."Line No.");
        if Rating.Find('-') then
            repeat
                ProfileQuestionnaireLine.Get(Rating."Rating Profile Quest. Code", Rating."Rating Profile Quest. Line No.");
                ProfileQuestionnaireLine.Get(
                  ProfileQuestionnaireLine."Profile Questionnaire Code", ProfileQuestionnaireLine.FindQuestionLine());
                if not TempProfileQuestnLine.Get(
                     ProfileQuestionnaireLine."Profile Questionnaire Code", ProfileQuestionnaireLine."Line No.")
                then begin
                    TempProfileQuestnLine.Init();
                    TempProfileQuestnLine."Profile Questionnaire Code" := ProfileQuestionnaireLine."Profile Questionnaire Code";
                    TempProfileQuestnLine."Line No." := ProfileQuestionnaireLine."Line No.";
                    TempProfileQuestnLine.Insert();
                    if AnswersExists(ProfileQuestionnaireLine, Cont."No.", false) then
                        NoOfAnsweredQuestions := NoOfAnsweredQuestions + 1;
                end;

                if ContProfileAnswer.Get(
                     Cont."No.", Rating."Rating Profile Quest. Code", Rating."Rating Profile Quest. Line No.")
                then begin
                    Value := Value + Rating.Points;
                    if ContProfileAnswer."Last Date Updated" < UpdateDate then
                        UpdateDate := ContProfileAnswer."Last Date Updated";
                end;
            until Rating.Next() = 0;

        if TempProfileQuestnLine.Count <> 0 then
            QuestionsAnsweredPrc := NoOfAnsweredQuestions / TempProfileQuestnLine.Count * 100
        else
            QuestionsAnsweredPrc := 0;
    end;

    local procedure MarkContactByMethod(ProfileQuestnLine: Record "Profile Questionnaire Line"; UpdateContNo: Code[20])
    var
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
    begin
        ProfileQuestnLine2.Reset();
        ProfileQuestnLine2 := ProfileQuestnLine;
        ProfileQuestnLine2.SetRange("Profile Questionnaire Code", ProfileQuestnLine."Profile Questionnaire Code");
        if ProfileQuestnLine2.Find('>') and
           (ProfileQuestnLine2.Type = ProfileQuestnLine2.Type::Answer)
        then
            repeat
                if UpdateContNo = '' then
                    Window.Update(3, ProfileQuestnLine2."Line No.");
                case ProfileQuestnLine."Classification Method" of
                    ProfileQuestnLine."Classification Method"::"Defined Value":
                        MarkByDefinedValue(ProfileQuestnLine, ProfileQuestnLine2);
                    ProfileQuestnLine."Classification Method"::"Percentage of Value":
                        MarkByPercentageOfValue(ProfileQuestnLine, ProfileQuestnLine2);
                    ProfileQuestnLine."Classification Method"::"Percentage of Contacts":
                        MarkByPercentageOfContacts(ProfileQuestnLine, ProfileQuestnLine2);
                end;
            until (ProfileQuestnLine2.Next() = 0) or
                  (ProfileQuestnLine2.Type = ProfileQuestnLine2.Type::Question);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindContactValues(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindCustomerValues(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindContactValuesOnAfterContactClassFieldCase(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindContactValuesOnBeforeContLoop(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; var Contact: Record Contact; Date: Date)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindCustomerValuesOnBeforeCustLoop(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; var Customer: Record Customer; Date: Date)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindCustomerValuesOnAfterCustomerClassFieldCase(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindCustomerValuesOnBeforeCustomerClassFieldCase(Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgerEntry2: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindCustomerValuesOnAvgOverdueDayOnZeroInvoices(ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; var ValueEntry: Record "Value Entry"; var Customer: Record Customer; var CustContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindCustomerValuesOnElseCustomerClassFieldCase(ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; Customer: Record Customer; ContactNo: Code[20]; var DecimalValue: Decimal; var UpdateDate: Date; var QuestionsAnsweredPrc: Decimal; var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetContactNoOnBeforeCheckContactValid(ProfileQuestnHeader: Record "Profile Questionnaire Header"; Contact: Record Contact; var ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMarkContact(ProfileQuestnHeader: Record "Profile Questionnaire Header"; ProfileQuestnLineQuestion: Record "Profile Questionnaire Line"; ProfileQuestnLineAnswer: Record "Profile Questionnaire Line"; Contact: Record Contact; UpdateDate: Date; QuestionsAnsweredPrc: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMarkContactOnBeforeCheckContactType(ProfileQuestnHeader: Record "Profile Questionnaire Header"; ProfileQuestnLineQuestion: Record "Profile Questionnaire Line"; ProfileQuestnLineAnswer: Record "Profile Questionnaire Line"; Cont: Record Contact; UpdateDate: Date; QuestionsAnsweredPrc: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInRange(Value: Decimal; FromValue: Decimal; ToValue: Decimal; var Result: Boolean)
    begin
    end;
}

