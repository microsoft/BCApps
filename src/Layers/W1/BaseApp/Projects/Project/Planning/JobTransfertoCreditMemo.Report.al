// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;

report 1092 "Job Transfer to Credit Memo"
{
    Caption = 'Project Transfer to Credit Memo';
    ProcessingOnly = true;

    dataset
    {
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
                    field(CreateNewCreditMemo; NewCreditMemo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create New Credit Memo';
                        ToolTip = 'Specifies if the batch job creates a new sales credit memo.';

                        trigger OnValidate()
                        begin
                            if NewCreditMemo then begin
                                CreditMemoNo := '';
                                if PostingDate = 0D then
                                    PostingDate := WorkDate();
                                if DocumentDate = 0D then
                                    DocumentDate := WorkDate();
                                CrMemoPostingDate := 0D;
                            end;
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the document.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            if PostingDate = 0D then
                                NewCreditMemo := false;
                            SalesReceivablesSetup.SetLoadFields("Link Doc. Date To Posting Date");
                            SalesReceivablesSetup.GetRecordOnce();
                            if SalesReceivablesSetup."Link Doc. Date To Posting Date" then
                                DocumentDate := PostingDate;
                        end;
                    }
                    field("Document Date"; DocumentDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date.';

                        trigger OnValidate()
                        begin
                            if DocumentDate = 0D then
                                NewCreditMemo := false;
                        end;
                    }
                    field(AppendToCreditMemoNo; CreditMemoNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Append to Credit Memo No.';
                        ToolTip = 'Specifies the number of the credit memo that you want to append the lines to if you did not select the Create New Credit Memo field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(SalesHeader);
                            SalesHeader.FilterGroup := 2;
                            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
                            SalesHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
                            SalesHeader.FilterGroup := 0;
                            if PAGE.RunModal(0, SalesHeader) = ACTION::LookupOK then
                                CreditMemoNo := SalesHeader."No.";
                            if CreditMemoNo <> '' then begin
                                SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", CreditMemoNo);
                                CrMemoPostingDate := SalesHeader."Posting Date";
                                NewCreditMemo := false;
                                PostingDate := 0D;
                                DocumentDate := 0D;
                            end;
                            if CreditMemoNo = '' then
                                InitReport();
                        end;

                        trigger OnValidate()
                        begin
                            if CreditMemoNo <> '' then begin
                                SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", CreditMemoNo);
                                CrMemoPostingDate := SalesHeader."Posting Date";
                                NewCreditMemo := false;
                                PostingDate := 0D;
                                DocumentDate := 0D;
                            end;
                            if CreditMemoNo = '' then
                                InitReport();
                        end;
                    }
                    field(CrMemoPostingDate; CrMemoPostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Cr. Memo Posting Date';
                        Editable = false;
                        ToolTip = 'Specifies the posting date of that credit memo if you filled the Append to Credit Memo No. field.';

                        trigger OnValidate()
                        begin
                            if PostingDate = 0D then
                                NewCreditMemo := false;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            InitReport();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Done := false;
    end;

    trigger OnPostReport()
    begin
        Done := true;
    end;

    var
        SalesHeader: Record "Sales Header";
        BillToCustomerNo: Code[20];
        PostingDate: Date;
        DocumentDate: Date;
        CrMemoPostingDate: Date;
        Done: Boolean;

    protected var
        Job: Record Job;
        CreditMemoNo: Code[20];
        NewCreditMemo: Boolean;

    procedure GetCreditMemoNo(var Done2: Boolean; var NewCreditMemo2: Boolean; var PostingDate2: Date; var DocumentDate2: Date; var CreditMemoNo2: Code[20])
    begin
        Done2 := Done;
        NewCreditMemo2 := NewCreditMemo;
        PostingDate2 := PostingDate;
        CreditMemoNo2 := CreditMemoNo;
        DocumentDate2 := DocumentDate;
    end;

    procedure InitReport()
    begin
        PostingDate := WorkDate();
        DocumentDate := WorkDate();
        NewCreditMemo := true;
        CreditMemoNo := '';
        CrMemoPostingDate := 0D;
    end;

    procedure SetCustomer(JobNo: Code[20])
    begin
        Job.Get(JobNo);
    end;

    procedure SetCustomer(JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        Job.Get(JobPlanningLine."Job No.");

        IsHandled := false;
        OnBeforeSetCustomer(JobPlanningLine, BillToCustomerNo, IsHandled);
        if IsHandled then
            exit;

        BillToCustomerNo := Job."Bill-to Customer No.";

        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            exit;

        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        if (JobTask."Bill-to Customer No." <> '') and (JobTask."Bill-to Customer No." <> Job."Bill-to Customer No.") then
            BillToCustomerNo := JobTask."Bill-to Customer No.";
    end;

    procedure SetPostingDate(PostingDate2: Date)
    begin
        PostingDate := PostingDate2;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCustomer(var JobPlanningLine: Record "Job Planning Line"; var BillToCustomerNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

