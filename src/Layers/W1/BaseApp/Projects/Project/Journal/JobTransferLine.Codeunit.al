// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;

codeunit 1004 "Job Transfer Line"
{

    trigger OnRun()
    begin
    end;

    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        LCYCurrency: Record Currency;
        CurrencyRoundingRead: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 %2 does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        JobPlanningLineNotFoundErr: Label 'Could not find any lines on the %1 page that are related to the %2 where the value in the %3 field is %4, and value in the %5 field is %6.', Comment = '%1=page caption, %2=table caption, %3,%5=field caption, %4,%6=field value';
        DuplicateJobplanningLinesErr: Label 'We found more than one %1s where the value in the %2 field is %3. The value in the %2 field must be unique.', Comment = '%1=table caption, %2=field caption, %3=field value';

    procedure FromJnlLineToLedgEntry(JobJnlLine2: Record "Job Journal Line"; var JobLedgEntry: Record "Job Ledger Entry")
    begin
        JobLedgEntry."Job No." := JobJnlLine2."Job No.";
        JobLedgEntry."Job Task No." := JobJnlLine2."Job Task No.";
        JobLedgEntry."Job Posting Group" := JobJnlLine2."Posting Group";
        JobLedgEntry."Posting Date" := JobJnlLine2."Posting Date";
        JobLedgEntry."Document Date" := JobJnlLine2."Document Date";
        JobLedgEntry."Document No." := JobJnlLine2."Document No.";
        JobLedgEntry."External Document No." := JobJnlLine2."External Document No.";
        JobLedgEntry.Type := JobJnlLine2.Type;
        JobLedgEntry."No." := JobJnlLine2."No.";
        JobLedgEntry.Description := JobJnlLine2.Description;
        JobLedgEntry."Resource Group No." := JobJnlLine2."Resource Group No.";
        JobLedgEntry."Unit of Measure Code" := JobJnlLine2."Unit of Measure Code";
        JobLedgEntry."Location Code" := JobJnlLine2."Location Code";
        JobLedgEntry."Global Dimension 1 Code" := JobJnlLine2."Shortcut Dimension 1 Code";
        JobLedgEntry."Global Dimension 2 Code" := JobJnlLine2."Shortcut Dimension 2 Code";
        JobLedgEntry."Dimension Set ID" := JobJnlLine2."Dimension Set ID";
        JobLedgEntry."Work Type Code" := JobJnlLine2."Work Type Code";
        JobLedgEntry."Source Code" := JobJnlLine2."Source Code";
        JobLedgEntry."Entry Type" := JobJnlLine2."Entry Type";
        JobLedgEntry."Gen. Bus. Posting Group" := JobJnlLine2."Gen. Bus. Posting Group";
        JobLedgEntry."Gen. Prod. Posting Group" := JobJnlLine2."Gen. Prod. Posting Group";
        JobLedgEntry."Journal Batch Name" := JobJnlLine2."Journal Batch Name";
        JobLedgEntry."Reason Code" := JobJnlLine2."Reason Code";
        JobLedgEntry."Variant Code" := JobJnlLine2."Variant Code";
        JobLedgEntry."Bin Code" := JobJnlLine2."Bin Code";
        JobLedgEntry."Line Type" := JobJnlLine2."Line Type";
        JobLedgEntry."Currency Code" := JobJnlLine2."Currency Code";
        JobLedgEntry."Description 2" := JobJnlLine2."Description 2";
        if JobJnlLine2."Currency Code" = '' then
            JobLedgEntry."Currency Factor" := 1
        else
            JobLedgEntry."Currency Factor" := JobJnlLine2."Currency Factor";
        JobLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobLedgEntry."User ID"));
        JobLedgEntry."Customer Price Group" := JobJnlLine2."Customer Price Group";

        JobLedgEntry."Transport Method" := JobJnlLine2."Transport Method";
        JobLedgEntry."Transaction Type" := JobJnlLine2."Transaction Type";
        JobLedgEntry."Transaction Specification" := JobJnlLine2."Transaction Specification";
        JobLedgEntry."Entry/Exit Point" := JobJnlLine2."Entry/Exit Point";
        JobLedgEntry.Area := JobJnlLine2.Area;
        JobLedgEntry."Country/Region Code" := JobJnlLine2."Country/Region Code";
        JobLedgEntry."Shpt. Method Code" := JobJnlLine2."Shpt. Method Code";

        JobLedgEntry."Unit Price (LCY)" := JobJnlLine2."Unit Price (LCY)";
        JobLedgEntry."Additional-Currency Total Cost" :=
          -JobJnlLine2."Source Currency Total Cost";
        JobLedgEntry."Add.-Currency Total Price" :=
          -JobJnlLine2."Source Currency Total Price";
        JobLedgEntry."Add.-Currency Line Amount" :=
          -JobJnlLine2."Source Currency Line Amount";

        // Amounts
        JobLedgEntry."Qty. per Unit of Measure" := JobJnlLine2."Qty. per Unit of Measure";

        JobLedgEntry."Direct Unit Cost (LCY)" := JobJnlLine2."Direct Unit Cost (LCY)";
        JobLedgEntry."Unit Cost (LCY)" := JobJnlLine2."Unit Cost (LCY)";
        JobLedgEntry."Unit Cost" := JobJnlLine2."Unit Cost";
        JobLedgEntry."Unit Price" := JobJnlLine2."Unit Price";

        JobLedgEntry."Line Discount %" := JobJnlLine2."Line Discount %";

        OnAfterFromJnlLineToLedgEntry(JobLedgEntry, JobJnlLine2);
    end;

    procedure FromJnlToPlanningLine(JobJnlLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine."Job No." := JobJnlLine."Job No.";
        JobPlanningLine."Job Task No." := JobJnlLine."Job Task No.";
        JobPlanningLine."Planning Date" := JobJnlLine."Posting Date";
        JobPlanningLine."Currency Date" := JobJnlLine."Posting Date";
        JobPlanningLine.Type := JobJnlLine.Type;
        JobPlanningLine."No." := JobJnlLine."No.";
        JobPlanningLine."Document No." := JobJnlLine."Document No.";
        JobPlanningLine.Description := JobJnlLine.Description;
        JobPlanningLine."Description 2" := JobJnlLine."Description 2";
        JobPlanningLine."Unit of Measure Code" := JobJnlLine."Unit of Measure Code";
        JobPlanningLine.Validate("Line Type", JobPlanningLine.ConvertFromJobLineType(JobJnlLine."Line Type"));
        JobPlanningLine."Currency Code" := JobJnlLine."Currency Code";
        JobPlanningLine."Currency Factor" := JobJnlLine."Currency Factor";
        JobPlanningLine."Resource Group No." := JobJnlLine."Resource Group No.";
        JobPlanningLine."Location Code" := JobJnlLine."Location Code";
        JobPlanningLine."Work Type Code" := JobJnlLine."Work Type Code";
        JobPlanningLine."Customer Price Group" := JobJnlLine."Customer Price Group";
        JobPlanningLine."Country/Region Code" := JobJnlLine."Country/Region Code";
        JobPlanningLine."Gen. Bus. Posting Group" := JobJnlLine."Gen. Bus. Posting Group";
        JobPlanningLine."Gen. Prod. Posting Group" := JobJnlLine."Gen. Prod. Posting Group";
        JobPlanningLine."Document Date" := JobJnlLine."Document Date";
        JobPlanningLine."Variant Code" := JobJnlLine."Variant Code";
        JobPlanningLine."Bin Code" := JobJnlLine."Bin Code";
        JobPlanningLine.CopyTrackingFromJobJnlLine(JobJnlLine);
        JobPlanningLine."Ledger Entry Type" := JobJnlLine."Ledger Entry Type";
        JobPlanningLine."Ledger Entry No." := JobJnlLine."Ledger Entry No.";
        JobPlanningLine."System-Created Entry" := true;

        // Amounts
        JobPlanningLine.Quantity := JobJnlLine.Quantity;
        JobPlanningLine."Quantity (Base)" := JobJnlLine."Quantity (Base)";
        if JobPlanningLine."Usage Link" then begin
            JobPlanningLine."Remaining Qty." := JobJnlLine.Quantity;
            JobPlanningLine."Remaining Qty. (Base)" := JobJnlLine."Quantity (Base)";
        end;
        JobPlanningLine."Qty. per Unit of Measure" := JobJnlLine."Qty. per Unit of Measure";

        JobPlanningLine."Direct Unit Cost (LCY)" := JobJnlLine."Direct Unit Cost (LCY)";
        JobPlanningLine."Unit Cost (LCY)" := JobJnlLine."Unit Cost (LCY)";
        JobPlanningLine."Unit Cost" := JobJnlLine."Unit Cost";

        JobPlanningLine."Total Cost (LCY)" := JobJnlLine."Total Cost (LCY)";
        JobPlanningLine."Total Cost" := JobJnlLine."Total Cost";

        JobPlanningLine."Unit Price (LCY)" := JobJnlLine."Unit Price (LCY)";
        JobPlanningLine."Unit Price" := JobJnlLine."Unit Price";

        JobPlanningLine."Total Price (LCY)" := JobJnlLine."Total Price (LCY)";
        JobPlanningLine."Total Price" := JobJnlLine."Total Price";

        JobPlanningLine."Line Amount (LCY)" := JobJnlLine."Line Amount (LCY)";
        JobPlanningLine."Line Amount" := JobJnlLine."Line Amount";

        JobPlanningLine."Line Discount %" := JobJnlLine."Line Discount %";

        JobPlanningLine."Line Discount Amount (LCY)" := JobJnlLine."Line Discount Amount (LCY)";
        JobPlanningLine."Line Discount Amount" := JobJnlLine."Line Discount Amount";

        OnAfterFromJnlToPlanningLine(JobPlanningLine, JobJnlLine);
    end;

    procedure FromPlanningSalesLineToJnlLine(JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var JobJnlLine: Record "Job Journal Line"; EntryType: Enum "Job Journal Line Entry Type")
    var
        SourceCodeSetup: Record "Source Code Setup";
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        OnBeforeFromPlanningSalesLineToJnlLine(JobPlanningLine, SalesHeader, SalesLine, JobJnlLine, EntryType);

        JobJnlLine."Line No." := SalesLine."Line No.";
        JobJnlLine."Job No." := JobPlanningLine."Job No.";
        JobJnlLine."Job Task No." := JobPlanningLine."Job Task No.";
        JobJnlLine.Type := JobPlanningLine.Type;
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        JobJnlLine."Posting Date" := SalesHeader."Posting Date";
        JobJnlLine."Document Date" := SalesHeader."Document Date";
        JobJnlLine."Document No." := SalesLine."Document No.";
        JobJnlLine."Entry Type" := EntryType;
        JobJnlLine."Posting Group" := SalesLine."Posting Group";
        JobJnlLine."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        JobJnlLine.CopyTrackingFromJobPlanningLine(JobPlanningLine);
        JobJnlLine."No." := JobPlanningLine."No.";
        JobJnlLine.Description := SalesLine.Description;
        JobJnlLine."Description 2" := SalesLine."Description 2";
        JobJnlLine."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        JobJnlLine.Validate("Qty. per Unit of Measure", SalesLine."Qty. per Unit of Measure");
        JobJnlLine."Work Type Code" := JobPlanningLine."Work Type Code";
        JobJnlLine."Variant Code" := JobPlanningLine."Variant Code";
        JobJnlLine."Line Type" := JobPlanningLine.ConvertToJobLineType();
        JobJnlLine."Currency Code" := JobPlanningLine."Currency Code";
        JobJnlLine."Currency Factor" := JobPlanningLine."Currency Factor";
        JobJnlLine."Resource Group No." := JobPlanningLine."Resource Group No.";
        JobJnlLine."Customer Price Group" := JobPlanningLine."Customer Price Group";
        JobJnlLine."Location Code" := SalesLine."Location Code";
        JobJnlLine."Bin Code" := SalesLine."Bin Code";
        SourceCodeSetup.Get();
        JobJnlLine."Source Code" := SourceCodeSetup.Sales;
        JobJnlLine."Reason Code" := SalesHeader."Reason Code";
        JobJnlLine."External Document No." := SalesHeader."External Document No.";

        JobJnlLine."Transport Method" := SalesLine."Transport Method";
        JobJnlLine."Transaction Type" := SalesLine."Transaction Type";
        JobJnlLine."Transaction Specification" := SalesLine."Transaction Specification";
        JobJnlLine."Entry/Exit Point" := SalesLine."Exit Point";
        JobJnlLine.Area := SalesLine.Area;
        JobJnlLine."Country/Region Code" := JobPlanningLine."Country/Region Code";

        JobJnlLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        JobJnlLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        JobJnlLine."Dimension Set ID" := SalesLine."Dimension Set ID";

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                JobJnlLine.Validate(Quantity, SalesLine.Quantity);
            SalesHeader."Document Type"::"Credit Memo":
                JobJnlLine.Validate(Quantity, -SalesLine.Quantity);
        end;

        IsHandled := false;
        OnFromPlanningSalesLineToJnlLineOnBeforeInitAmounts(JobJnlLine, SalesLine, SalesHeader, JobPlanningLine, IsHandled);
        if not IsHandled then begin
            JobJnlLine."Direct Unit Cost (LCY)" := JobPlanningLine."Direct Unit Cost (LCY)";
            if (JobPlanningLine."Currency Code" = '') and (SalesHeader."Currency Factor" <> 0) then begin
                GetCurrencyRounding(SalesHeader."Currency Code");
                ValidateUnitCostAndPrice(
                  JobJnlLine, SalesLine, SalesLine."Unit Cost (LCY)",
                  JobPlanningLine."Unit Price");
            end else
                ValidateUnitCostAndPrice(JobJnlLine, SalesLine, SalesLine."Unit Cost", JobPlanningLine."Unit Price");
            JobJnlLine.Validate("Line Discount %", SalesLine."Line Discount %");
        end;

        OnAfterFromPlanningSalesLineToJnlLine(JobJnlLine, JobPlanningLine, SalesHeader, SalesLine, EntryType);
    end;

    procedure FromPlanningLineToJnlLine(JobPlanningLine: Record "Job Planning Line"; PostingDate: Date; JobJournalTemplateName: Code[10]; JobJournalBatchName: Code[10]; var JobJnlLine: Record "Job Journal Line")
    var
        JobTask: Record "Job Task";
        JobJnlLine2: Record "Job Journal Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobSetup: Record "Jobs Setup";
        NoSeries: Codeunit "No. Series";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        JobPlanningLine.TestField("Qty. to Transfer to Journal");

        if not JobJournalTemplate.Get(JobJournalTemplateName) then
            Error(Text001, JobJournalTemplate.TableCaption(), JobJournalTemplateName);
        if not JobJournalBatch.Get(JobJournalTemplateName, JobJournalBatchName) then
            Error(Text001, JobJournalBatch.TableCaption(), JobJournalBatchName);
        if PostingDate = 0D then
            PostingDate := WorkDate();

        JobJnlLine.Init();
        JobJnlLine.Validate("Journal Template Name", JobJournalTemplate.Name);
        JobJnlLine.Validate("Journal Batch Name", JobJournalBatch.Name);
        JobJnlLine2.SetRange("Journal Template Name", JobJournalTemplate.Name);
        JobJnlLine2.SetRange("Journal Batch Name", JobJournalBatch.Name);
        if JobJnlLine2.FindLast() then
            JobJnlLine.Validate("Line No.", JobJnlLine2."Line No." + 10000)
        else
            JobJnlLine.Validate("Line No.", 10000);

        JobJnlLine."Job No." := JobPlanningLine."Job No.";
        JobJnlLine."Job Task No." := JobPlanningLine."Job Task No.";

        if JobPlanningLine."Usage Link" then begin
            JobJnlLine."Job Planning Line No." := JobPlanningLine."Line No.";
            JobJnlLine."Line Type" := JobPlanningLine.ConvertToJobLineType();
        end;

        JobTask.SetLoadFields("Job Posting Group");
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        JobJnlLine."Posting Group" := JobTask."Job Posting Group";
        JobJnlLine."Posting Date" := PostingDate;
        JobJnlLine."Document Date" := PostingDate;
        JobSetup.Get();
        if JobJournalBatch."No. Series" <> '' then
            JobJnlLine."Document No." := NoSeries.PeekNextNo(JobJournalBatch."No. Series", PostingDate)
        else
            if JobSetup."Document No. Is Job No." then
                JobJnlLine."Document No." := JobPlanningLine."Job No."
            else
                JobJnlLine."Document No." := JobPlanningLine."Document No.";

        JobJnlLine.Type := JobPlanningLine.Type;
        JobJnlLine."No." := JobPlanningLine."No.";
        JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
        JobJnlLine."Gen. Bus. Posting Group" := JobPlanningLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := JobPlanningLine."Gen. Prod. Posting Group";
        JobJnlLine.CopyTrackingFromJobPlanningLine(JobPlanningLine);
        JobJnlLine.Description := JobPlanningLine.Description;
        JobJnlLine."Description 2" := JobPlanningLine."Description 2";
        JobJnlLine.Validate("Unit of Measure Code", JobPlanningLine."Unit of Measure Code");
        JobJnlLine."Currency Code" := JobPlanningLine."Currency Code";
        JobJnlLine."Currency Factor" := JobPlanningLine."Currency Factor";
        JobJnlLine."Resource Group No." := JobPlanningLine."Resource Group No.";
        JobJnlLine."Location Code" := JobPlanningLine."Location Code";
        JobJnlLine."Work Type Code" := JobPlanningLine."Work Type Code";
        JobJnlLine."Customer Price Group" := JobPlanningLine."Customer Price Group";
        JobJnlLine."Variant Code" := JobPlanningLine."Variant Code";
        JobJnlLine."Bin Code" := JobPlanningLine."Bin Code";
        JobJnlLine."Country/Region Code" := JobPlanningLine."Country/Region Code";
        JobJnlLine."Source Code" := JobJournalTemplate."Source Code";

        IsHandled := false;
        OnFromPlanningLineToJnlLineOnBeforeCopyItemTracking(JobJnlLine, JobPlanningLine, IsHandled);
        if not IsHandled then
            ItemTrackingMgt.CopyItemTracking(JobPlanningLine.RowID1(), JobJnlLine.RowID1(), false);

        JobJnlLine.Validate(Quantity, JobPlanningLine."Qty. to Transfer to Journal");
        JobJnlLine.Validate("Qty. per Unit of Measure", JobPlanningLine."Qty. per Unit of Measure");
        JobJnlLine."Direct Unit Cost (LCY)" := JobPlanningLine."Direct Unit Cost (LCY)";
        JobJnlLine.Validate("Unit Cost", JobPlanningLine."Unit Cost");
        JobJnlLine.Validate("Unit Price", JobPlanningLine."Unit Price");
        JobJnlLine.Validate("Line Discount %", JobPlanningLine."Line Discount %");
        JobJnlLine."Assemble to Order" := JobPlanningLine."Assemble to Order";

        OnAfterFromPlanningLineToJnlLine(JobJnlLine, JobPlanningLine);

        JobJnlLine.UpdateDimensions();
        JobJnlLine.Insert(true);
    end;

    // Create 'Job Journal Line' from 'Warehouse Activity Line'
    procedure FromWarehouseActivityLineToJnlLine(WarehouseActivityLine: Record "Warehouse Activity Line"; PostingDate: Date; JobJournalTemplateName: Code[10]; JobJournalBatchName: Code[10]; var JobJnlLine: Record "Job Journal Line")
    var
        JobTask: Record "Job Task";
        JobJnlLine2: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        JobPlanningLines: Page "Job Planning Lines";
    begin
        WarehouseActivityLine.TestField("Qty. to Handle");

        if JobJournalTemplateName <> '' then begin
            if not JobJournalTemplate.Get(JobJournalTemplateName) then
                Error(Text001, JobJournalTemplate.TableCaption(), JobJournalTemplateName);
            if not JobJournalBatch.Get(JobJournalTemplateName, JobJournalBatchName) then
                Error(Text001, JobJournalBatch.TableCaption(), JobJournalBatchName);
        end;
        if PostingDate = 0D then
            PostingDate := WorkDate();

        JobPlanningLine.SetLoadFields(
            "Job No.", "Job Task No.", "Usage Link", "Line No.", "Line Type", Type, "No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
            "Serial No.", "Lot No.", "Package No.", Description, "Description 2", "Unit of Measure Code", "Currency Code", "Currency Factor", "Resource Group No.",
            "Location Code", "Work Type Code", "Customer Price Group", "Variant Code", "Bin Code", "Country/Region Code",
            "Qty. per Unit of Measure", "Direct Unit Cost (LCY)", "Unit Cost", "Unit Price", "Line Discount %", "Document No.", "Assemble to Order");
        JobPlanningLine.SetRange("Job No.", WarehouseActivityLine."Source No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", WarehouseActivityLine."Source Line No.");
        OnFromWarehouseActivityLineToJnlLineOnAfterSetJobPlanningLineFilters(JobPlanningLine, WarehouseActivityLine);
        if JobPlanningLine.IsEmpty() then
            Error(JobPlanningLineNotFoundErr, JobPlanningLines.Caption(), WarehouseActivityLine.TableCaption(), WarehouseActivityLine.FieldCaption("Source No."),
                    WarehouseActivityLine."Source No.", WarehouseActivityLine.FieldCaption("Source Line No."), WarehouseActivityLine."Source Line No.");

        if JobPlanningLine.Count() > 1 then
            Error(DuplicateJobplanningLinesErr, JobPlanningLine.TableCaption(), JobPlanningLine.FieldCaption("Job Contract Entry No."), JobPlanningLine."Job Contract Entry No.");

        JobPlanningLine.FindFirst();

        JobJnlLine.Init();
        JobJnlLine.Validate("Journal Template Name", JobJournalTemplate.Name);
        JobJnlLine.Validate("Journal Batch Name", JobJournalBatch.Name);

        JobJnlLine2.SetLoadFields("Line No.");
        JobJnlLine2.SetRange("Journal Template Name", JobJournalTemplate.Name);
        JobJnlLine2.SetRange("Journal Batch Name", JobJournalBatch.Name);
        if JobJnlLine2.FindLast() then
            JobJnlLine.Validate("Line No.", JobJnlLine2."Line No." + 10000)
        else
            JobJnlLine.Validate("Line No.", 10000);

        JobJnlLine."Job No." := JobPlanningLine."Job No.";
        JobJnlLine."Job Task No." := JobPlanningLine."Job Task No.";

        if JobPlanningLine."Usage Link" then begin
            JobJnlLine."Job Planning Line No." := JobPlanningLine."Line No.";
            JobJnlLine."Line Type" := JobPlanningLine.ConvertToJobLineType();
        end;

        JobTask.SetLoadFields("Job Posting Group");
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        JobJnlLine."Posting Group" := JobTask."Job Posting Group";
        JobJnlLine."Posting Date" := PostingDate;
        JobJnlLine."Document Date" := PostingDate;

        JobJnlLine."Document No." := JobPlanningLine."Job No.";
        if JobPlanningLine."Document No." <> '' then
            JobJnlLine."Document No." := JobPlanningLine."Document No.";

        JobJnlLine.Type := JobPlanningLine.Type;
        JobJnlLine."No." := JobPlanningLine."No.";
        JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
        JobJnlLine."Gen. Bus. Posting Group" := JobPlanningLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := JobPlanningLine."Gen. Prod. Posting Group";
        JobJnlLine.CopyTrackingFromJobPlanningLine(JobPlanningLine);
        JobJnlLine.Description := WarehouseActivityLine.Description;
        JobJnlLine."Description 2" := WarehouseActivityLine."Description 2";
        JobJnlLine.Validate("Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
        JobJnlLine."Currency Code" := JobPlanningLine."Currency Code";
        JobJnlLine."Currency Factor" := JobPlanningLine."Currency Factor";
        JobJnlLine."Resource Group No." := JobPlanningLine."Resource Group No.";
        JobJnlLine."Location Code" := WarehouseActivityLine."Location Code";
        JobJnlLine."Work Type Code" := JobPlanningLine."Work Type Code";
        JobJnlLine."Customer Price Group" := JobPlanningLine."Customer Price Group";
        JobJnlLine."Variant Code" := WarehouseActivityLine."Variant Code";
        JobJnlLine."Bin Code" := WarehouseActivityLine."Bin Code";
        JobJnlLine."Country/Region Code" := JobPlanningLine."Country/Region Code";
        JobJnlLine."Source Code" := JobJournalTemplate."Source Code";
        JobJnlLine."Serial No." := WarehouseActivityLine."Serial No.";
        JobJnlLine."Lot No." := WarehouseActivityLine."Lot No.";
        JobJnlLine."Package No." := WarehouseActivityLine."Package No.";

        JobJnlLine.Validate(Quantity, WarehouseActivityLine."Qty. to Handle");
        JobJnlLine."Assemble to Order" := WarehouseActivityLine."Assemble to Order";
        JobJnlLine.Validate("Qty. per Unit of Measure", WarehouseActivityLine."Qty. per Unit of Measure");
        JobJnlLine."Direct Unit Cost (LCY)" := JobPlanningLine."Direct Unit Cost (LCY)";
        JobJnlLine.Validate("Unit Cost", JobPlanningLine."Unit Cost");
        JobJnlLine.Validate("Unit Price", JobPlanningLine."Unit Price");
        JobJnlLine.Validate("Line Discount %", JobPlanningLine."Line Discount %");

        JobJnlLine.UpdateDimensions();
        ItemTrackingMgt.CopyItemTracking(JobPlanningLine.RowID1(), JobJnlLine.RowID1(), false);

        OnFromWarehouseActivityLineToJnlLineOnBeforeJobJnlLineInsert(JobJnlLine, JobPlanningLine, WarehouseActivityLine);
        JobJnlLine.Insert(true);
        OnFromWarehouseActivityLineToJnlLineOnAfterJobJnlLineInsert(JobJnlLine, JobPlanningLine, WarehouseActivityLine);
    end;

    procedure FromGenJnlLineToJnlLine(GenJnlLine: Record "Gen. Journal Line"; var JobJnlLine: Record "Job Journal Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
    begin
        OnBeforeFromGenJnlLineToJnlLine(JobJnlLine, GenJnlLine);

        JobJnlLine."Job No." := GenJnlLine."Job No.";
        JobJnlLine."Job Task No." := GenJnlLine."Job Task No.";
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        JobTask.Get(GenJnlLine."Job No.", GenJnlLine."Job Task No.");

        JobJnlLine."Posting Date" := GenJnlLine."Posting Date";
        JobJnlLine."Document Date" := GenJnlLine."Document Date";
        JobJnlLine."Document No." := GenJnlLine."Document No.";

        JobJnlLine."Currency Code" := GenJnlLine."Job Currency Code";
        JobJnlLine."Currency Factor" := GenJnlLine."Job Currency Factor";
        JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
        JobJnlLine."Line Type" := GenJnlLine."Job Line Type";
        JobJnlLine.Type := JobJnlLine.Type::"G/L Account";
        JobJnlLine."No." := GenJnlLine."Account No.";
        JobJnlLine.Description := GenJnlLine.Description;
        JobJnlLine."Unit of Measure Code" := GenJnlLine."Job Unit Of Measure Code";
        JobJnlLine."Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        JobJnlLine."Source Code" := GenJnlLine."Source Code";
        JobJnlLine."Reason Code" := GenJnlLine."Reason Code";
        Job.SetLoadFields("Customer Price Group");
        Job.Get(JobJnlLine."Job No.");
        JobJnlLine."Customer Price Group" := Job."Customer Price Group";
        JobJnlLine."External Document No." := GenJnlLine."External Document No.";
        JobJnlLine."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        JobJnlLine."Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        JobJnlLine."Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        JobJnlLine."Dimension Set ID" := GenJnlLine."Dimension Set ID";

        JobJnlLine.Quantity := GenJnlLine."Job Quantity";
        JobJnlLine."Quantity (Base)" := GenJnlLine."Job Quantity";
        JobJnlLine."Qty. per Unit of Measure" := 1; // MP ??
        JobJnlLine."Job Planning Line No." := GenJnlLine."Job Planning Line No.";
        JobJnlLine."Remaining Qty." := GenJnlLine."Job Remaining Qty.";
        JobJnlLine."Remaining Qty. (Base)" := GenJnlLine."Job Remaining Qty.";

        JobJnlLine."Direct Unit Cost (LCY)" := GenJnlLine."Job Unit Cost (LCY)";
        JobJnlLine."Unit Cost (LCY)" := GenJnlLine."Job Unit Cost (LCY)";
        JobJnlLine."Unit Cost" := GenJnlLine."Job Unit Cost";

        JobJnlLine."Total Cost (LCY)" := GenJnlLine."Job Total Cost (LCY)";
        JobJnlLine."Total Cost" := GenJnlLine."Job Total Cost";

        NonDeductibleVAT.CopyNonDedVATFromGenJnlLineToJobJnlLine(JobJnlLine, GenJnlLine);

        JobJnlLine."Unit Price (LCY)" := GenJnlLine."Job Unit Price (LCY)";
        JobJnlLine."Unit Price" := GenJnlLine."Job Unit Price";

        JobJnlLine."Total Price (LCY)" := GenJnlLine."Job Total Price (LCY)";
        JobJnlLine."Total Price" := GenJnlLine."Job Total Price";

        JobJnlLine."Line Amount (LCY)" := GenJnlLine."Job Line Amount (LCY)";
        JobJnlLine."Line Amount" := GenJnlLine."Job Line Amount";

        JobJnlLine."Line Discount Amount (LCY)" := GenJnlLine."Job Line Disc. Amount (LCY)";
        JobJnlLine."Line Discount Amount" := GenJnlLine."Job Line Discount Amount";

        JobJnlLine."Line Discount %" := GenJnlLine."Job Line Discount %";

        OnAfterFromGenJnlLineToJnlLine(JobJnlLine, GenJnlLine);
    end;

    procedure FromJobLedgEntryToPlanningLine(JobLedgEntry: Record "Job Ledger Entry"; var JobPlanningLine: Record "Job Planning Line")
    var
        PriceType: Enum "Price Type";
    begin
        JobPlanningLine."Job No." := JobLedgEntry."Job No.";
        JobPlanningLine."Job Task No." := JobLedgEntry."Job Task No.";
        JobPlanningLine."Planning Date" := JobLedgEntry."Posting Date";
        JobPlanningLine."Currency Date" := JobLedgEntry."Posting Date";
        JobPlanningLine."Document Date" := JobLedgEntry."Document Date";
        JobPlanningLine."Document No." := JobLedgEntry."Document No.";
        JobPlanningLine.Description := JobLedgEntry.Description;
        JobPlanningLine.Type := JobLedgEntry.Type;
        JobPlanningLine."No." := JobLedgEntry."No.";
        JobPlanningLine."Unit of Measure Code" := JobLedgEntry."Unit of Measure Code";
        JobPlanningLine.Validate("Line Type", JobPlanningLine.ConvertFromJobLineType(JobLedgEntry."Line Type"));
        JobPlanningLine."Currency Code" := JobLedgEntry."Currency Code";
        if JobLedgEntry."Currency Code" = '' then
            JobPlanningLine."Currency Factor" := 0
        else
            JobPlanningLine."Currency Factor" := JobLedgEntry."Currency Factor";
        JobPlanningLine."Resource Group No." := JobLedgEntry."Resource Group No.";
        JobPlanningLine."Location Code" := JobLedgEntry."Location Code";
        JobPlanningLine."Work Type Code" := JobLedgEntry."Work Type Code";
        JobPlanningLine."Gen. Bus. Posting Group" := JobLedgEntry."Gen. Bus. Posting Group";
        JobPlanningLine."Gen. Prod. Posting Group" := JobLedgEntry."Gen. Prod. Posting Group";
        JobPlanningLine."Variant Code" := JobLedgEntry."Variant Code";
        JobPlanningLine."Bin Code" := JobLedgEntry."Bin Code";
        JobPlanningLine."Customer Price Group" := JobLedgEntry."Customer Price Group";
        JobPlanningLine."Country/Region Code" := JobLedgEntry."Country/Region Code";
        JobPlanningLine."Description 2" := JobLedgEntry."Description 2";
        JobPlanningLine.CopyTrackingFromJobLedgEntry(JobLedgEntry);
        JobPlanningLine."Job Ledger Entry No." := JobLedgEntry."Entry No.";
        JobPlanningLine."Ledger Entry Type" := JobLedgEntry."Ledger Entry Type";
        JobPlanningLine."Ledger Entry No." := JobLedgEntry."Ledger Entry No.";
        JobPlanningLine."System-Created Entry" := true;

        // Function call to retrieve cost factor. Prices will be overwritten.
        JobPlanningLine.ApplyPrice(PriceType::Sale, JobTransferMarkerFieldNo());

        // Amounts
        JobPlanningLine.Quantity := JobLedgEntry.Quantity;
        JobPlanningLine."Quantity (Base)" := JobLedgEntry."Quantity (Base)";
        if JobPlanningLine."Usage Link" then begin
            JobPlanningLine."Remaining Qty." := JobLedgEntry.Quantity;
            JobPlanningLine."Remaining Qty. (Base)" := JobLedgEntry."Quantity (Base)";
        end;
        JobPlanningLine."Qty. per Unit of Measure" := JobLedgEntry."Qty. per Unit of Measure";

        JobPlanningLine."Direct Unit Cost (LCY)" := JobLedgEntry."Direct Unit Cost (LCY)";
        JobPlanningLine."Unit Cost (LCY)" := JobLedgEntry."Unit Cost (LCY)";
        JobPlanningLine."Unit Cost" := JobLedgEntry."Unit Cost";

        JobPlanningLine."Total Cost (LCY)" := JobLedgEntry."Total Cost (LCY)";
        JobPlanningLine."Total Cost" := JobLedgEntry."Total Cost";

        JobPlanningLine."Unit Price (LCY)" := JobLedgEntry."Unit Price (LCY)";
        JobPlanningLine."Unit Price" := JobLedgEntry."Unit Price";

        JobPlanningLine."Total Price (LCY)" := JobLedgEntry."Total Price (LCY)";
        JobPlanningLine."Total Price" := JobLedgEntry."Total Price";

        JobPlanningLine."Line Amount (LCY)" := JobLedgEntry."Line Amount (LCY)";
        JobPlanningLine."Line Amount" := JobLedgEntry."Line Amount";

        JobPlanningLine."Line Discount %" := JobLedgEntry."Line Discount %";

        JobPlanningLine."Line Discount Amount (LCY)" := JobLedgEntry."Line Discount Amount (LCY)";
        JobPlanningLine."Line Discount Amount" := JobLedgEntry."Line Discount Amount";

        OnAfterFromJobLedgEntryToPlanningLine(JobPlanningLine, JobLedgEntry);
    end;

    procedure JobTransferMarkerFieldNo(): Integer;
    begin
        // returns a negative integer (non existing field number) - a marker of job transfer price calculation
        exit(-Database::"Job Ledger Entry")
    end;

    procedure FromPurchaseLineToJnlLine(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10]; var JobJnlLine: Record "Job Journal Line")
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchLineCurrency: Record "Currency";
        UOMMgt: Codeunit "Unit of Measure Management";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        Factor: Decimal;
        NonDeductibleVATAmount: Decimal;
        NonDeductibleBaseAmount: Decimal;
        NonDeductibleVATAmtPerUnit: Decimal;
        NondeductibleVATAmtPerUnitLCY: Decimal;
        NDVATAmountRounding: Decimal;
        NDVATBaseRounding: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromPurchaseLineToJnlLine(PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchLine, SourceCode, JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Validate("Job Planning Line No.");

        JobJnlLine.DontCheckStdCost();
        JobJnlLine.Validate("Job No.", PurchLine."Job No.");
        JobJnlLine.Validate("Job Task No.", PurchLine."Job Task No.");
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        JobTask.Get(PurchLine."Job No.", PurchLine."Job Task No.");
        JobJnlLine.Validate("Posting Date", PurchHeader."Posting Date");
        JobJournalLineValidateType(JobJnlLine, PurchLine);
        OnFromPurchaseLineToJnlLineOnBeforeValidateNo(JobJnlLine, PurchLine);
        JobJnlLine.Validate("No.", PurchLine."No.");
        JobJnlLine.Validate("Variant Code", PurchLine."Variant Code");
        if UpdateBaseQtyForPurchLine(Item, PurchLine) then begin
            JobJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
            JobJnlLine.Validate(
                Quantity,
                UOMMgt.CalcBaseQty(
                PurchLine."No.", PurchLine."Variant Code", PurchLine."Unit of Measure Code", PurchLine."Qty. to Invoice", PurchLine."Qty. per Unit of Measure"));
        end else begin
            JobJnlLine.Validate("Unit of Measure Code", PurchLine."Unit of Measure Code");
            JobJnlLine."Qty. per Unit of Measure" := PurchLine."Qty. per Unit of Measure";
            JobJnlLine.Validate(Quantity, PurchLine."Qty. to Invoice");
        end;

        if PurchHeader."Document Type" in [PurchHeader."Document Type"::"Return Order",
                                            PurchHeader."Document Type"::"Credit Memo"]
        then begin
            JobJnlLine."Document No." := PurchCrMemoHeader."No.";
            JobJnlLine."External Document No." := PurchCrMemoHeader."Vendor Cr. Memo No.";
        end else begin
            JobJnlLine."Document No." := PurchInvHeader."No.";
            JobJnlLine."External Document No." := PurchHeader."Vendor Invoice No.";
        end;

        NonDeductibleVAT.Calculate(NonDeductibleBaseAmount, NonDeductibleVATAmount, NonDeductibleVATAmtPerUnit, NonDeductibleVATAmtPerUnitLCY, NDVATAmountRounding, NDVATBaseRounding, PurchHeader, PurchLine);
        GetCurrencyRounding(JobJnlLine."Currency Code");

        JobJnlLine."Unit Cost (LCY)" := PurchLine."Unit Cost (LCY)" / PurchLine."Qty. per Unit of Measure";
        JobJnlLine."Unit Cost" := PurchLine."Unit Cost" / PurchLine."Qty. per Unit of Measure";

        if NonDeductibleVAT.UseNonDeductibleVATAmountForJobCost() then begin
            GetNonDeductibleVATAmtPerUnitCost(JobJnlLine, NonDeductibleVATAmtPerUnitLCY, NonDeductibleVATAmtPerUnit);
            JobJnlLine."Unit Cost (LCY)" += NonDeductibleVATAmtPerUnitLCY;
            JobJnlLine."Unit Cost" += NonDeductibleVATAmtPerUnit;
        end;

        OnFromPurchaseLineToJnlLineOnAfterCalcUnitCostLCY(JobJnlLine, PurchLine);

        if PurchLine.Type = PurchLine.Type::Item then
            if Item."Inventory Value Zero" then begin
                JobJnlLine."Unit Cost (LCY)" := 0;
                JobJnlLine."Unit Cost" := 0;
            end else
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    JobJnlLine."Unit Cost (LCY)" := Item."Standard Cost";
                    JobJnlLine."Unit Cost" := Item."Standard Cost";
                    if NonDeductibleVAT.UseNonDeductibleVATAmountForJobCost() then begin
                        JobJnlLine."Unit Cost (LCY)" += NonDeductibleVATAmtPerUnitLCY;
                        JobJnlLine."Unit Cost" += NonDeductibleVATAmtPerUnit;
                    end;
                end;

        JobJnlLine."Unit Cost (LCY)" := Round(JobJnlLine."Unit Cost (LCY)", LCYCurrency."Unit-Amount Rounding Precision");

        if (JobJnlLine."Currency Code" = '') and (PurchLine."Currency Code" <> '') then begin
            PurchLineCurrency.Get(PurchLine."Currency Code");
            JobJnlLine."Total Cost" :=
                Round(
                    CurrencyExchRate.ExchangeAmtFCYToLCY(
                        PurchHeader."Posting Date",
                        PurchLine."Currency Code",
                        Round(JobJnlLine."Unit Cost" * JobJnlLine.Quantity, PurchLineCurrency."Amount Rounding Precision"),
                        PurchHeader."Currency Factor"),
                    Currency."Amount Rounding Precision");
            JobJnlLine."Total Cost (LCY)" := JobJnlLine."Total Cost";
        end;

        case JobJnlLine."Currency Code" of
            '':
                JobJnlLine."Unit Cost" := JobJnlLine."Unit Cost (LCY)";
            PurchLine."Currency Code":
                JobJnlLine."Unit Cost" := PurchLine."Unit Cost" / PurchLine."Qty. per Unit of Measure";
            else
                JobJnlLine."Unit Cost" :=
                    Round(
                    CurrencyExchRate.ExchangeAmtLCYToFCY(
                        PurchHeader."Posting Date",
                        JobJnlLine."Currency Code",
                        JobJnlLine."Unit Cost (LCY)",
                        JobJnlLine."Currency Factor"), Currency."Unit-Amount Rounding Precision");
        end;

        if not ((JobJnlLine."Currency Code" = '') and (PurchLine."Currency Code" <> '')) then
            JobJnlLine."Total Cost" := Round(JobJnlLine."Unit Cost" * JobJnlLine.Quantity, Currency."Amount Rounding Precision");

        if (PurchLine.Type = PurchLine.Type::Item) and Item."Inventory Value Zero" then
            JobJnlLine."Total Cost (LCY)" := 0
        else
            if not ((JobJnlLine."Currency Code" = '') and (PurchLine."Currency Code" <> '')) then
                JobJnlLine."Total Cost (LCY)" :=
                    Round(JobJnlLine."Unit Cost (LCY)" * JobJnlLine.Quantity, LCYCurrency."Amount Rounding Precision");

        if PurchLine."Currency Code" = '' then
            JobJnlLine."Direct Unit Cost (LCY)" := PurchLine."Direct Unit Cost"
        else
            JobJnlLine."Direct Unit Cost (LCY)" :=
                CurrencyExchRate.ExchangeAmtFCYToLCY(
                PurchHeader."Posting Date",
                PurchLine."Currency Code",
                PurchLine."Direct Unit Cost",
                PurchHeader."Currency Factor");

        JobJnlLine."Unit Price (LCY)" :=
            Round(PurchLine."Job Unit Price (LCY)" / PurchLine."Qty. per Unit of Measure", LCYCurrency."Unit-Amount Rounding Precision");
        JobJnlLine."Unit Price" :=
            Round(PurchLine."Job Unit Price" / PurchLine."Qty. per Unit of Measure", Currency."Unit-Amount Rounding Precision");
        JobJnlLine."Line Discount %" := PurchLine."Job Line Discount %";

        if PurchLine.Quantity <> 0 then begin
            GetCurrencyRounding(PurchHeader."Currency Code");

            Factor := PurchLine."Qty. to Invoice" / PurchLine.Quantity;
            JobJnlLine."Total Price (LCY)" :=
                Round(PurchLine."Job Total Price (LCY)" * Factor, LCYCurrency."Amount Rounding Precision");
            JobJnlLine."Total Price" :=
                Round(PurchLine."Job Total Price" * Factor, Currency."Amount Rounding Precision");
            JobJnlLine."Line Amount (LCY)" :=
                Round(PurchLine."Job Line Amount (LCY)" * Factor, LCYCurrency."Amount Rounding Precision");
            JobJnlLine."Line Amount" :=
                Round(PurchLine."Job Line Amount" * Factor, Currency."Amount Rounding Precision");
            JobJnlLine."Line Discount Amount (LCY)" :=
                Round(PurchLine."Job Line Disc. Amount (LCY)" * Factor, LCYCurrency."Amount Rounding Precision");
            JobJnlLine."Line Discount Amount" :=
                Round(PurchLine."Job Line Discount Amount" * Factor, Currency."Amount Rounding Precision");
        end;

        JobJnlLine."Job Planning Line No." := PurchLine."Job Planning Line No.";
        if PurchLine.Type <> PurchLine.Type::"G/L Account" then begin
            JobJnlLine."Remaining Qty." := PurchLine."Job Remaining Qty.";
            JobJnlLine."Remaining Qty. (Base)" := PurchLine."Job Remaining Qty. (Base)";
        end;
        JobJnlLine."Location Code" := PurchLine."Location Code";
        JobJnlLine."Bin Code" := PurchLine."Bin Code";
        JobJnlLine."Line Type" := PurchLine."Job Line Type";
        JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
        JobJnlLine.Description := PurchLine.Description;
        JobJnlLine."Description 2" := PurchLine."Description 2";
        JobJnlLine."Gen. Bus. Posting Group" := PurchLine."Gen. Bus. Posting Group";
        JobJnlLine."Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        JobJnlLine."Source Code" := SourceCode;
        JobJnlLine."Reason Code" := PurchHeader."Reason Code";
        JobJnlLine."Document Date" := PurchHeader."Document Date";
        JobJnlLine."Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        JobJnlLine."Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        JobJnlLine."Dimension Set ID" := PurchLine."Dimension Set ID";

        OnAfterFromPurchaseLineToJnlLine(JobJnlLine, PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchLine, SourceCode);
    end;

    local procedure JobJournalLineValidateType(var JobJournalLine: Record "Job Journal Line"; PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobJournalLineValidateType(JobJournalLine, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine.Type = PurchaseLine.Type::"G/L Account" then
            JobJournalLine.Validate(Type, JobJournalLine.Type::"G/L Account")
        else
            JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
    end;

    procedure FromSalesHeaderToPlanningLine(SalesLine: Record "Sales Line"; CurrencyFactor: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        if JobPlanningLine.FindFirst() then begin
            // Update Prices
            if JobPlanningLine."Currency Code" <> '' then begin
                JobPlanningLine."Unit Price (LCY)" := SalesLine."Unit Price" / CurrencyFactor;
                JobPlanningLine."Total Price (LCY)" := JobPlanningLine."Unit Price (LCY)" * JobPlanningLine.Quantity;
                JobPlanningLine."Line Amount (LCY)" := JobPlanningLine."Total Price (LCY)";
                JobPlanningLine."Unit Price" := JobPlanningLine."Unit Price (LCY)";
                JobPlanningLine."Total Price" := JobPlanningLine."Total Price (LCY)";
                JobPlanningLine."Line Amount" := JobPlanningLine."Total Price (LCY)";
            end else begin
                JobPlanningLine."Unit Price (LCY)" := SalesLine."Unit Price" / CurrencyFactor;
                JobPlanningLine."Total Price (LCY)" := JobPlanningLine."Unit Price (LCY)" * JobPlanningLine.Quantity;
                JobPlanningLine."Line Amount (LCY)" := JobPlanningLine."Total Price (LCY)";
            end;
            OnAfterFromSalesHeaderToPlanningLine(JobPlanningLine, SalesLine, CurrencyFactor);
            JobPlanningLine.Modify();
        end;
    end;

    procedure GetCurrencyRounding(CurrencyCode: Code[10])
    begin
        if CurrencyRoundingRead then
            exit;
        CurrencyRoundingRead := true;
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
        LCYCurrency.InitRoundingPrecision();
    end;

    local procedure DoUpdateUnitCost(SalesLine: Record "Sales Line"): Boolean
    var
        Item: Record Item;
    begin
        if SalesLine.Type = SalesLine.Type::Item then begin
            Item.Get(SalesLine."No.");
            if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsCreatedFromJob(SalesLine) then
                exit(false); // Do not update Unit Cost in Job Journal Line, it is correct.
        end;

        exit(true);
    end;

    local procedure IsCreatedFromJob(var SalesLine: Record "Sales Line") Result: Boolean
    begin
        Result := (SalesLine."Job No." <> '') and (SalesLine."Job Task No." <> '') and (SalesLine."Job Contract Entry No." <> 0);
        OnAfterIsCreatedFromJob(SalesLine, Result);
    end;

    procedure ValidateUnitCostAndPrice(var JobJournalLine: Record "Job Journal Line"; SalesLine: Record "Sales Line"; UnitCost: Decimal; UnitPrice: Decimal)
    begin
        if DoUpdateUnitCost(SalesLine) then begin
            JobJournalLine.DontCheckStdCost();
            JobJournalLine.Validate("Unit Cost", UnitCost);
        end;
        JobJournalLine.Validate("Unit Price", UnitPrice);
    end;

    local procedure UpdateBaseQtyForPurchLine(var Item: Record Item; PurchLine: Record "Purchase Line"): Boolean
    begin
        if PurchLine.Type = PurchLine.Type::Item then begin
            Item.Get(PurchLine."No.");
            Item.TestField("Base Unit of Measure");
            exit(PurchLine."Unit of Measure Code" <> Item."Base Unit of Measure");
        end;
        exit(false);
    end;

    local procedure GetNonDeductibleVATAmtPerUnitCost(JobJnlLine: Record "Job Journal Line"; var NonDeductibleVATAmtPerUnitLCY: Decimal; var NonDeductibleVATAmtPerUnit: Decimal)
    begin
        if JobJnlLine."Unit Cost" > 0 then begin
            NonDeductibleVATAmtPerUnit := Abs(NonDeductibleVATAmtPerUnit);
            NonDeductibleVATAmtPerUnitLCY := Abs(NonDeductibleVATAmtPerUnitLCY);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCreatedFromJob(var SalesLine: Record "Sales Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromJnlLineToLedgEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromJnlToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromPlanningSalesLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; EntryType: Enum "Job Journal Line Entry Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromPlanningLineToJnlLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromGenJnlLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromJobLedgEntryToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobLedgEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromPurchaseLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromSalesHeaderToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; SalesLine: Record "Sales Line"; CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromPlanningSalesLineToJnlLine(var JobPlanningLine: Record "Job Planning Line"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobJnlLine: Record "Job Journal Line"; var EntryType: Enum "Job Journal Line Entry Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromPurchaseLineToJnlLine(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10]; var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobJournalLineValidateType(var JobJournalLine: Record "Job Journal Line"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromPurchaseLineToJnlLineOnBeforeValidateNo(var JobJnlLine: Record "Job Journal Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromPurchaseLineToJnlLineOnAfterCalcUnitCostLCY(var JobJnlLine: Record "Job Journal Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromPlanningLineToJnlLineOnBeforeCopyItemTracking(var JobJournalLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromWarehouseActivityLineToJnlLineOnAfterJobJnlLineInsert(var JobJournalLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromWarehouseActivityLineToJnlLineOnBeforeJobJnlLineInsert(var JobJournalLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFromPlanningSalesLineToJnlLineOnBeforeInitAmounts(var JobJournalLine: Record "Job Journal Line"; var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromGenJnlLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromWarehouseActivityLineToJnlLineOnAfterSetJobPlanningLineFilters(var JobPlanningLine: Record "Job Planning Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
}

