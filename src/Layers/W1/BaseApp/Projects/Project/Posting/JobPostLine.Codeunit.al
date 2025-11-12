// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 1001 "Job Post-Line"
{
    Permissions = TableData "Job Ledger Entry" = rm,
                  TableData "Job Planning Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        TempSalesLineJob: Record "Sales Line" temporary;
        TempPurchaseLineJob: Record "Purchase Line" temporary;
        TempJobJournalLine: Record "Job Journal Line" temporary;
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        UOMMgt: Codeunit "Unit of Measure Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'has been changed (initial a %1: %2= %3, %4= %5)';
#pragma warning restore AA0470
        Text003: Label 'You cannot change the sales line because it is linked to\';
#pragma warning disable AA0470
        Text004: Label ' %1: %2= %3, %4= %5.';
        Text005: Label 'You must post more usage or credit the sale of %1 %2 in %3 %4 before you can post purchase credit memo %5 %6 = %7.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure InsertPlLineFromLedgEntry(var JobLedgEntry: Record "Job Ledger Entry")
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertPlLineFromLedgEntry(JobLedgEntry, IsHandled);
        if not IsHandled then begin
            if JobLedgEntry."Line Type" = JobLedgEntry."Line Type"::" " then
                exit;
            ClearAll();
            JobPlanningLine."Job No." := JobLedgEntry."Job No.";
            JobPlanningLine."Job Task No." := JobLedgEntry."Job Task No.";
            JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
            JobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
            if JobPlanningLine.FindLast() then;
            JobPlanningLine."Line No." := JobPlanningLine."Line No." + 10000;
            JobPlanningLine.Init();
            JobPlanningLine.Reset();
            Clear(JobTransferLine);
            JobTransferLine.FromJobLedgEntryToPlanningLine(JobLedgEntry, JobPlanningLine);
            PostPlanningLine(JobPlanningLine);
        end;

        OnAfterInsertPlLineFromLedgEntry(JobLedgEntry, JobPlanningLine);
    end;

    procedure PostPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
    begin
        OnBeforePostPlanningLine(JobPlanningLine);

        if JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::"Both Budget and Billable" then begin
            Job.Get(JobPlanningLine."Job No.");
            if not Job."Allow Schedule/Contract Lines" or
               (JobPlanningLine.Type = JobPlanningLine.Type::"G/L Account")
            then begin
                JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Budget);
                JobPlanningLine.Insert(true);
                InsertJobUsageLink(JobPlanningLine);
                JobPlanningLine.Validate("Qty. to Transfer to Journal", 0);
                JobPlanningLine.Modify(true);
                JobPlanningLine."Job Contract Entry No." := 0;
                JobPlanningLine."Line No." := JobPlanningLine."Line No." + 10000;
                JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
            end;
        end;
        if (JobPlanningLine.Type = JobPlanningLine.Type::"G/L Account") and
           (JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::Billable)
        then
            ChangeGLAccNo(JobPlanningLine);
        OnPostPlanningLineOnBeforeJobPlanningLineInsert(JobPlanningLine);
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Qty. to Transfer to Journal", 0);
        JobPlanningLine.Modify(true);
        if JobPlanningLine."Line Type" in
           [JobPlanningLine."Line Type"::Budget, JobPlanningLine."Line Type"::"Both Budget and Billable"]
        then
            InsertJobUsageLink(JobPlanningLine);
    end;

    local procedure InsertJobUsageLink(var JobPlanningLine: Record "Job Planning Line")
    var
        JobUsageLink: Record "Job Usage Link";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if not JobPlanningLine."Usage Link" then
            exit;
        JobLedgerEntry.Get(JobPlanningLine."Job Ledger Entry No.");
        if UsageLinkExist(JobLedgerEntry) then
            exit;
        JobUsageLink.Create(JobPlanningLine, JobLedgerEntry);

        JobPlanningLine.Use(
            UOMMgt.CalcQtyFromBase(
                JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code",
                JobLedgerEntry."Quantity (Base)", JobPlanningLine."Qty. per Unit of Measure"),
            JobLedgerEntry."Total Cost", JobLedgerEntry."Line Amount", JobLedgerEntry."Posting Date", JobLedgerEntry."Currency Factor");
    end;

    local procedure UsageLinkExist(JobLedgEntry: Record "Job Ledger Entry"): Boolean
    var
        JobUsageLink: Record "Job Usage Link";
    begin
        JobUsageLink.SetRange("Job No.", JobLedgEntry."Job No.");
        JobUsageLink.SetRange("Job Task No.", JobLedgEntry."Job Task No.");
        JobUsageLink.SetRange("Entry No.", JobLedgEntry."Entry No.");
        if not JobUsageLink.IsEmpty then
            exit(true);
    end;

    procedure PostInvoiceContractLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        DummyJobLedgEntryNo: Integer;
        JobLineChecked: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostInvoiceContractLine(SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        OnPostInvoiceContractLineOnBeforeJobPlanningLineFindFirst(SalesHeader, SalesLine, JobPlanningLine);
        JobPlanningLine.FindFirst();
        Job.Get(JobPlanningLine."Job No.");

        CheckCurrency(Job, SalesHeader, JobPlanningLine);

        IsHandled := false;
        OnPostInvoiceContractLineOnBeforeCheckBillToCustomer(SalesHeader, SalesLine, JobPlanningLine, IsHandled);
        if not IsHandled then
            if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
                SalesHeader.TestField("Bill-to Customer No.", Job."Bill-to Customer No.")
            else begin
                JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
                SalesHeader.TestField("Bill-to Customer No.", JobTask."Bill-to Customer No.");
            end;

        OnPostInvoiceContractLineBeforeCheckJobLine(SalesHeader, SalesLine, JobPlanningLine, JobLineChecked);
        if not JobLineChecked then begin
            JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
            if JobPlanningLine.Type <> JobPlanningLine.Type::Text then
                JobPlanningLine.TestField("Qty. Transferred to Invoice");
        end;

        ValidateRelationship(SalesHeader, SalesLine, JobPlanningLine);

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                if JobPlanningLineInvoice.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.",
                     JobPlanningLineInvoice."Document Type"::Invoice, SalesHeader."No.", SalesLine."Line No.")
                then begin
                    JobPlanningLineInvoice.Delete(true);
                    JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Posted Invoice";
                    JobPlanningLineInvoice."Document No." := SalesLine."Document No.";
                    JobPlanningLineInvoice.Insert(true);

                    JobPlanningLineInvoice."Invoiced Date" := SalesHeader."Posting Date";
                    JobPlanningLineInvoice."Invoiced Amount (LCY)" :=
                      CalcLineAmountLCY(JobPlanningLine, JobPlanningLineInvoice."Quantity Transferred");
                    JobPlanningLineInvoice."Invoiced Cost Amount (LCY)" :=
                      JobPlanningLineInvoice."Quantity Transferred" * JobPlanningLine."Unit Cost (LCY)";
                    JobPlanningLineInvoice.Modify();
                end;
            SalesHeader."Document Type"::"Credit Memo":
                if JobPlanningLineInvoice.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.",
                     JobPlanningLineInvoice."Document Type"::"Credit Memo", SalesHeader."No.", SalesLine."Line No.")
                then begin
                    JobPlanningLineInvoice.Delete(true);
                    JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Posted Credit Memo";
                    JobPlanningLineInvoice."Document No." := SalesLine."Document No.";
                    JobPlanningLineInvoice.Insert(true);

                    JobPlanningLineInvoice."Invoiced Date" := SalesHeader."Posting Date";
                    JobPlanningLineInvoice."Invoiced Amount (LCY)" :=
                      CalcLineAmountLCY(JobPlanningLine, JobPlanningLineInvoice."Quantity Transferred");
                    JobPlanningLineInvoice."Invoiced Cost Amount (LCY)" :=
                      JobPlanningLineInvoice."Quantity Transferred" * JobPlanningLine."Unit Cost (LCY)";
                    JobPlanningLineInvoice.Modify();
                end;
        end;

        OnBeforeJobPlanningLineUpdateQtyToInvoice(SalesHeader, SalesLine, JobPlanningLine, JobPlanningLineInvoice, DummyJobLedgEntryNo);

        JobPlanningLine.UpdateQtyToInvoice();
        JobPlanningLine.Modify();

        OnAfterJobPlanningLineModify(JobPlanningLine);

        IsHandled := false;
        OnPostInvoiceContractLineOnBeforePostJobOnSalesLine(JobPlanningLine, JobPlanningLineInvoice, SalesHeader, SalesLine, IsHandled);
        if not IsHandled then
            if JobPlanningLine.Type <> JobPlanningLine.Type::Text then
                PostJobOnSalesLine(JobPlanningLine, SalesHeader, SalesLine, "Job Journal Line Entry Type"::Sale);

        OnAfterPostInvoiceContractLine(SalesHeader, SalesLine);
    end;

    local procedure ValidateRelationship(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        Txt: Text[500];
        IsHandled, UnitCostLCYDifferenceExists : Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateRelationship(SalesHeader, SalesLine, JobPlanningLine, IsHandled);
        if IsHandled then
            exit;

        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        Txt := StrSubstNo(Text000,
            JobTask.TableCaption(), JobTask.FieldCaption("Job No."), JobTask."Job No.",
            JobTask.FieldCaption("Job Task No."), JobTask."Job Task No.");

        if JobPlanningLine.Type = JobPlanningLine.Type::Text then
            if SalesLine.Type <> SalesLine.Type::" " then
                SalesLine.FieldError(Type, Txt);
        if JobPlanningLine.Type = JobPlanningLine.Type::Resource then
            if SalesLine.Type <> SalesLine.Type::Resource then
                SalesLine.FieldError(Type, Txt);
        if JobPlanningLine.Type = JobPlanningLine.Type::Item then
            if SalesLine.Type <> SalesLine.Type::Item then
                SalesLine.FieldError(Type, Txt);
        if JobPlanningLine.Type = JobPlanningLine.Type::"G/L Account" then
            if SalesLine.Type <> SalesLine.Type::"G/L Account" then
                SalesLine.FieldError(Type, Txt);

        if SalesLine."No." <> JobPlanningLine."No." then
            SalesLine.FieldError("No.", Txt);
        if SalesLine."Location Code" <> JobPlanningLine."Location Code" then
            SalesLine.FieldError("Location Code", Txt);
        if SalesLine."Work Type Code" <> JobPlanningLine."Work Type Code" then
            SalesLine.FieldError("Work Type Code", Txt);
        if SalesLine."Unit of Measure Code" <> JobPlanningLine."Unit of Measure Code" then
            SalesLine.FieldError("Unit of Measure Code", Txt);
        if SalesLine."Variant Code" <> JobPlanningLine."Variant Code" then
            SalesLine.FieldError("Variant Code", Txt);
        if SalesLine."Gen. Prod. Posting Group" <> JobPlanningLine."Gen. Prod. Posting Group" then
            SalesLine.FieldError("Gen. Prod. Posting Group", Txt);

        IsHandled := false;
        OnValidateRelationshipOnBeforeCheckLineDiscount(SalesLine, JobPlanningLine, IsHandled);
        if not IsHandled then
            if SalesLine."Line Discount %" <> JobPlanningLine."Line Discount %" then
                SalesLine.FieldError("Line Discount %", Txt);

        UnitCostLCYDifferenceExists := SalesLine."Unit Cost (LCY)" <> JobPlanningLine."Unit Cost (LCY)";
        OnValidateRelationshipOnUnitCostLCYDifferenceError(SalesLine, JobPlanningLine, UnitCostLCYDifferenceExists);
        if UnitCostLCYDifferenceExists then
            SalesLine.FieldError("Unit Cost (LCY)", Txt);
        if SalesLine.Type = SalesLine.Type::" " then
            if SalesLine."Line Amount" <> 0 then
                SalesLine.FieldError("Line Amount", Txt);
        if SalesHeader."Prices Including VAT" then
            if JobPlanningLine."VAT %" <> SalesLine."VAT %" then
                SalesLine.FieldError("VAT %", Txt);
    end;

    procedure PostJobOnSalesLine(JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; EntryType: Enum "Job Journal Line Entry Type")
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        JobTransferLine.FromPlanningSalesLineToJnlLine(JobPlanningLine, SalesHeader, SalesLine, JobJnlLine, EntryType);
        if SalesLine.Type = SalesLine.Type::"G/L Account" then begin
            TempSalesLineJob := SalesLine;
            TempSalesLineJob.Insert();
            InsertTempJobJournalLine(JobJnlLine, TempSalesLineJob."Line No.");
        end else
            PostSalesJobJournalLine(JobJnlLine);
    end;

    procedure CalcLineAmountLCY(JobPlanningLine: Record "Job Planning Line"; Qty: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        TotalPrice: Decimal;
        UnitPriceLCY: Decimal;
    begin
        if JobPlanningLine."Currency Code" <> '' then
            UnitPriceLCY :=
              CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                JobPlanningLine."Currency Date", JobPlanningLine."Currency Code",
                JobPlanningLine."Unit Price", JobPlanningLine."Currency Factor")
        else
            UnitPriceLCY := JobPlanningLine."Unit Price";

        TotalPrice := Round(Qty * UnitPriceLCY, 0.01);
        exit(TotalPrice - Round(TotalPrice * JobPlanningLine."Line Discount %" / 100, 0.01));
    end;

    procedure PostGenJnlLine(GenJnlLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry")
    var
        JobJnlLine: Record "Job Journal Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        SourceCodeSetup: Record "Source Code Setup";
        JobTransferLine: Codeunit "Job Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGenJnlLine(JobJnlLine, GenJnlLine, GLEntry, IsHandled, JobJnlPostLine);
        if IsHandled then
            exit;

        OnPostGenJnlLineOnBeforeGenJnlCheck(JobJnlLine, GenJnlLine, GLEntry, IsHandled);
        if not IsHandled then begin
            if GenJnlLine."System-Created Entry" then
                exit;
            if GenJnlLine."Job No." = '' then
                exit;
            SourceCodeSetup.Get();
            if GenJnlLine."Source Code" = SourceCodeSetup."Job G/L WIP" then
                exit;
            GenJnlLine.TestField("Job Task No.");
            GenJnlLine.TestField("Job Quantity");
            Job.LockTable();
            JobTask.LockTable();
            Job.Get(GenJnlLine."Job No.");
            GenJnlLine.TestField("Job Currency Code", Job."Currency Code");
            JobTask.Get(GenJnlLine."Job No.", GenJnlLine."Job Task No.");
            JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
        end;
        JobTransferLine.FromGenJnlLineToJnlLine(GenJnlLine, JobJnlLine);
        OnPostGenJnlLineOnAfterTransferToJnlLine(JobJnlLine, GenJnlLine, JobJnlPostLine);

        JobJnlPostLine.SetGLEntryNo(GLEntry."Entry No.");
        JobJnlPostLine.RunWithCheck(JobJnlLine);
        JobJnlPostLine.SetGLEntryNo(0);
    end;

    procedure PostJobOnPurchaseLine(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10])
    var
        JobJnlLine: Record "Job Journal Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        IsHandled: Boolean;
        ShouldSkipLine: Boolean;
    begin
        IsHandled := false;
        OnBeforePostJobOnPurchaseLine(
            PurchHeader, PurchInvHeader, PurchCrMemoHdr, PurchLine, JobJnlLine, IsHandled,
            TempPurchaseLineJob, TempJobJournalLine, SourceCode);
        if IsHandled then
            exit;

        ShouldSkipLine := (PurchLine.Type <> PurchLine.Type::Item) and (PurchLine.Type <> PurchLine.Type::"G/L Account");
        OnPostJobOnPurchaseLineOnAfterCalcShouldSkipLine(PurchLine, ShouldSkipLine);
        if ShouldSkipLine then
            exit;
        Clear(JobJnlLine);
        PurchLine.TestField("Job No.");
        PurchLine.TestField("Job Task No.");
        Job.LockTable();
        JobTask.LockTable();
        Job.Get(PurchLine."Job No.");
        PurchLine.TestField("Job Currency Code", Job."Currency Code");
        JobTask.Get(PurchLine."Job No.", PurchLine."Job Task No.");
        JobTransferLine.FromPurchaseLineToJnlLine(
          PurchHeader, PurchInvHeader, PurchCrMemoHdr, PurchLine, Sourcecode, JobJnlLine);
        OnPostJobOnPurchaseLineOnAfterJobTransferLineFromPurchaseLineToJnlLine(PurchHeader, PurchInvHeader, PurchCrMemoHdr, PurchLine, JobJnlLine);
        JobJnlLine."Job Posting Only" := true;

        if PurchLine.Type = PurchLine.Type::"G/L Account" then begin
            TempPurchaseLineJob := PurchLine;
            TempPurchaseLineJob.Insert();
            InsertTempJobJournalLine(JobJnlLine, TempPurchaseLineJob."Line No.");
        end else begin
            JobJnlPostLine.SetCalledFromPurchase(true);
            JobJnlPostLine.RunWithCheck(JobJnlLine);
        end;
    end;

    procedure TestSalesLine(var SalesLine: Record "Sales Line")
    var
        JT: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Txt: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."Job Contract Entry No." = 0 then
            exit;
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        if JobPlanningLine.FindFirst() then begin
            JT.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
            Txt := Text003 + StrSubstNo(Text004,
                JT.TableCaption(), JT.FieldCaption("Job No."), JT."Job No.",
                JT.FieldCaption("Job Task No."), JT."Job Task No.");
            Error(Txt);
        end;
    end;

    procedure ChangeGLAccNo(var JobPlanningLine: Record "Job Planning Line")
    var
        GLAcc: Record "G/L Account";
        Job: Record Job;
        JT: Record "Job Task";
        JobPostingGr: Record "Job Posting Group";
        Cust: Record Customer;
    begin
        JT.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        Job.Get(JobPlanningLine."Job No.");
        GetBillToCustomer(Job, JobPlanningLine, Cust);
        if JT."Job Posting Group" <> '' then
            JobPostingGr.Get(JT."Job Posting Group")
        else begin
            Job.TestField("Job Posting Group");
            JobPostingGr.Get(Job."Job Posting Group");
        end;
        if JobPostingGr."G/L Expense Acc. (Contract)" = '' then
            exit;
        GLAcc.Get(JobPostingGr."G/L Expense Acc. (Contract)");
        GLAcc.CheckGLAcc();
        JobPlanningLine."No." := GLAcc."No.";
        JobPlanningLine."Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        JobPlanningLine."Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
    end;

    local procedure GetBillToCustomer(Job: Record Job; var JobPlanningLine: Record "Job Planning Line"; var Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBillToCustomer(JobPlanningLine, Cust, IsHandled);
        if IsHandled then
            exit;

        Cust.Get(Job."Bill-to Customer No.");
    end;

    procedure CheckItemQuantityPurchCredit(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemQuantityPurchCredit(PurchaseHeader, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine.IsNonInventoriableItem() then
            exit;

        Job.Get(PurchaseLine."Job No.");
        if Job.GetQuantityAvailable(PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine."Variant Code", 0, 2) <
           -PurchaseLine."Return Qty. to Ship (Base)"
        then
            Error(
              Text005, Item.TableCaption(), PurchaseLine."No.", Job.TableCaption(),
              PurchaseLine."Job No.", PurchaseHeader."No.",
              PurchaseLine.FieldCaption("Line No."), PurchaseLine."Line No.");
    end;

    procedure PostJobPurchaseLines(JobLineFilters: Text; GLEntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        TempPurchaseLineJob.Reset();
        TempPurchaseLineJob.SetView(JobLineFilters);
        if TempPurchaseLineJob.FindSet() then begin
            repeat
                TempJobJournalLine.Reset();
                TempJobJournalLine.SetRange("Line No.", TempPurchaseLineJob."Line No.");
                TempJobJournalLine.FindFirst();
                JobJnlPostLine.SetGLEntryNo(GLEntryNo);
                IsHandled := false;
                OnPostJobPurchaseLinesOnBeforeJobJnlPostLine(TempJobJournalLine, TempPurchaseLineJob, IsHandled);
                if not IsHandled then
                    JobJnlPostLine.RunWithCheck(TempJobJournalLine);
                OnPostJobPurchaseLinesOnAfterJobJnlPostLine(TempJobJournalLine, TempPurchaseLineJob);
            until TempPurchaseLineJob.Next() = 0;
            TempPurchaseLineJob.DeleteAll();
        end;

        OnAfterPostJobPurchaseLines(TempPurchaseLineJob, JobJnlPostLine, GLEntryNo);
        TempPurchaseLineJob.DeleteAll();
    end;

    procedure PostJobSalesLines(JobLineFilters: Text; GLEntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        TempSalesLineJob.Reset();
        TempSalesLineJob.SetView(JobLineFilters);
        if TempSalesLineJob.FindSet() then begin
            repeat
                TempJobJournalLine.Reset();
                TempJobJournalLine.SetRange("Line No.", TempSalesLineJob."Line No.");
                TempJobJournalLine.FindFirst();
                JobJnlPostLine.SetGLEntryNo(GLEntryNo);
                IsHandled := false;
                OnPostJobSalesLinesOnBeforeJobJnlPostLine(TempJobJournalLine, TempSalesLineJob, IsHandled);
                if not IsHandled then
                    PostSalesJobJournalLine(TempJobJournalLine);
            until TempSalesLineJob.Next() = 0;
            TempSalesLineJob.DeleteAll();
        end;
    end;

    local procedure InsertTempJobJournalLine(JobJournalLine: Record "Job Journal Line"; LineNo: Integer)
    begin
        TempJobJournalLine := JobJournalLine;
        TempJobJournalLine."Line No." := LineNo;
        TempJobJournalLine.Insert();
    end;

    local procedure CheckCurrency(Job: Record Job; SalesHeader: Record "Sales Header"; JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        JobInvCurr: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCurrency(Job, SalesHeader, JobPlanningLine, IsHandled);
        if IsHandled then
            exit;

        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            JobInvCurr := Job."Invoice Currency Code"
        else begin
            JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
            JobInvCurr := JobTask."Invoice Currency Code";
        end;

        if JobInvCurr = '' then begin
            Job.TestField("Currency Code", SalesHeader."Currency Code");
            Job.TestField("Currency Code", JobPlanningLine."Currency Code");
            SalesHeader.TestField("Currency Code", JobPlanningLine."Currency Code");
            SalesHeader.TestField("Currency Factor", JobPlanningLine."Currency Factor");
        end else begin
            Job.TestField("Currency Code", '');
            JobPlanningLine.TestField("Currency Code", '');
        end;
    end;

    local procedure PostSalesJobJournalLine(var JobJournalLine: Record "Job Journal Line")
    var
        JobLedgerEntryNo: Integer;
    begin
        JobLedgerEntryNo := JobJnlPostLine.RunWithCheck(JobJournalLine);
        UpdateJobLedgerEntryNoOnJobPlanLineInvoice(JobJournalLine, JobLedgerEntryNo);
    end;

    local procedure UpdateJobLedgerEntryNoOnJobPlanLineInvoice(JobJournalLine: Record "Job Journal Line"; JobLedgerEntryNo: Integer)
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", JobJournalLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobJournalLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Document No.", JobJournalLine."Document No.");
        JobPlanningLineInvoice.SetRange("Line No.", JobJournalLine."Line No.");
        if JobPlanningLineInvoice.FindFirst() then begin
            JobPlanningLineInvoice."Job Ledger Entry No." := JobLedgerEntryNo;
            JobPlanningLineInvoice.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvoiceContractLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;


    [IntegrationEvent(true, false)]
    local procedure OnAfterPostJobPurchaseLines(var TempPurchaseLineJob: Record "Purchase Line" temporary; var JobJnlPostLine: Codeunit "Job Jnl.-Post Line"; GLEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemQuantityPurchCredit(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBillToCustomer(var JobPlanningLine: Record "Job Planning Line"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGenJnlLine(var JobJournalLine: Record "Job Journal Line"; GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; var IsHandled: Boolean; var JobJnlPostLine: Codeunit "Job Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPlLineFromLedgEntry(var JobLedgerEntry: Record "Job Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobPlanningLineUpdateQtyToInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; JobLedgerEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoiceContractLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoiceContractLineOnBeforeJobPlanningLineFindFirst(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJobOnPurchaseLine(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line"; var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean; var TempPurchaseLineJob: Record "Purchase Line"; var TempJobJournalLine: Record "Job Journal Line"; var Sourcecode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesLine(var SalesLine: Record "Sales Line"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRelationship(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobPlanningLineModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGenJnlLineOnAfterTransferToJnlLine(var JobJnlLine: Record "Job Journal Line"; GenJnlLine: Record "Gen. Journal Line"; var JobJnlPostLine: Codeunit "Job Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoiceContractLineBeforeCheckJobLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var JobLineChecked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoiceContractLineOnBeforeCheckBillToCustomer(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnPostJobPurchaseLinesOnAfterJobJnlPostLine(var TempJobJournalLine: Record "Job Journal Line" temporary; TempJobPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostJobPurchaseLinesOnBeforeJobJnlPostLine(var TempJobJournalLine: Record "Job Journal Line" temporary; TempJobPurchaseLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnPostJobSalesLinesOnBeforeJobJnlPostLine(var TempJobJournalLine: Record "Job Journal Line" temporary; var TempJobSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostJobOnPurchaseLineOnAfterCalcShouldSkipLine(PurchaseLine: Record "Purchase Line"; var ShouldSkipLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostJobOnPurchaseLineOnAfterJobTransferLineFromPurchaseLineToJnlLine(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRelationshipOnBeforeCheckLineDiscount(var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCurrency(Job: Record Job; SalesHeader: Record "Sales Header"; JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostGenJnlLineOnBeforeGenJnlCheck(var JobJournalLine: Record "Job Journal Line"; GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPlanningLineOnBeforeJobPlanningLineInsert(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoiceContractLineOnBeforePostJobOnSalesLine(JobPlanningLine: Record "Job Planning Line"; JobPlanningLineInvoice: Record "Job Planning Line Invoice"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPlLineFromLedgEntry(JobLedgerEntry: Record "Job Ledger Entry"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateRelationshipOnUnitCostLCYDifferenceError(var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var UnitCostLCYDifferenceExists: Boolean)
    begin
    end;
}
