// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;

report 1095 "Update Job Item Cost"
{
    AdditionalSearchTerms = 'Update Job Item Cost';
    ApplicationArea = Jobs;
    Caption = 'Update Project Item Cost';
    Permissions = TableData "Job Ledger Entry" = rm,
                  TableData "Value Entry" = rm;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = sorting("No.") where(Status = filter(Planning | Quote | Open));
            RequestFilterFields = "No.";
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemLink = "Job No." = field("No.");
                DataItemTableView = sorting(Type, "Entry Type", "Country/Region Code", "Source Code", "Posting Date") where(Type = filter(= Item), "Entry Type" = filter(= Usage));
                RequestFilterFields = "Posting Date";
                dataitem("Item Ledger Entry"; "Item Ledger Entry")
                {
                    DataItemLink = "Entry No." = field("Ledger Entry No.");
                    DataItemTableView = sorting("Entry No.");
                    dataitem("Job Planning Line"; "Job Planning Line")
                    {
                        DataItemLink = "Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Ledger Entry No." = field("Entry No.");
                        DataItemTableView = sorting("Job No.", "Job Task No.", "Line No.");

                        trigger OnAfterGetRecord()
                        begin
                            CalcFields("Qty. Transferred to Invoice");
                            if ("Qty. Transferred to Invoice" <> 0) or not "System-Created Entry" or ("Ledger Entry Type" <> "Ledger Entry Type"::Item) then
                                CurrReport.Skip();

                            Validate("Unit Cost (LCY)", "Job Ledger Entry"."Unit Cost (LCY)");
                            Validate("Line Discount Amount (LCY)", "Job Ledger Entry"."Line Discount Amount (LCY)");
                            Modify();
                            "Job Ledger Entry".Validate("Unit Price", "Unit Price");
                            "Job Ledger Entry".Validate("Unit Price (LCY)", "Unit Price (LCY)");
                            "Job Ledger Entry".Validate("Total Price", "Total Price");
                            "Job Ledger Entry".Validate("Total Price (LCY)", "Total Price (LCY)");
                            "Job Ledger Entry".Validate("Line Amount (LCY)", "Line Amount (LCY)");
                            "Job Ledger Entry".Validate("Line Amount", "Line Amount");
                            "Job Ledger Entry".Modify();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if NoOfJobLedgEntry = 0 then
                                CurrReport.Break();
                            LockTable();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        ValueEntry: Record "Value Entry";
                        ValueEntry2: Record "Value Entry";
                        Item: Record Item;
                        JobLedgerEntryCostValue: Decimal;
                        JobLedgerEntryCostValueACY: Decimal;
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnItemLedgerEntryOnAfterGetRecord("Item Ledger Entry", IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        SetValueEntryFilters(ValueEntry, "Item Ledger Entry", "Job Ledger Entry");

                        if ValueEntry.IsEmpty() then begin
                            Item.Get("Item No.");
                            if Item.Type = Item.Type::Inventory then begin
                                CalcFields("Cost Amount (Expected)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                                JobLedgerEntryCostValue := "Cost Amount (Expected)" + "Cost Amount (Actual)";
                                JobLedgerEntryCostValueACY := "Cost Amount (Expected) (ACY)" + "Cost Amount (Actual) (ACY)";
                            end else begin
                                CalcFields("Cost Amount (Non-Invtbl.)", "Cost Amount (Non-Invtbl.)(ACY)");
                                JobLedgerEntryCostValue := "Cost Amount (Non-Invtbl.)";
                                JobLedgerEntryCostValueACY := "Cost Amount (Non-Invtbl.)(ACY)";
                            end;
                        end else begin
                            ValueEntry.SetRange(Adjustment, false);
                            if ValueEntry.FindFirst() then begin
                                AddJobCostValue(JobLedgerEntryCostValue, JobLedgerEntryCostValueACY, ValueEntry, ValueEntry.Inventoriable);

                                ValueEntry2.SetRange("Item Ledger Entry No.", "Entry No.");
                                ValueEntry2.SetRange("Document No.", ValueEntry."Document No.");
                                ValueEntry2.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.");
                                ValueEntry2.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
                                ValueEntry2.SetRange(Adjustment, true);

                                if ValueEntry.Inventoriable then
                                    ValueEntry2.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)")
                                else
                                    ValueEntry2.CalcSums("Cost Amount (Non-Invtbl.)", "Cost Amount (Non-Invtbl.)(ACY)");

                                AddJobCostValue(JobLedgerEntryCostValue, JobLedgerEntryCostValueACY, ValueEntry2, ValueEntry.Inventoriable);

                                ValueEntry2.SetRange("Job Ledger Entry No.", 0);

                                ModifyAllValueEntries(ValueEntry2, ValueEntry);
                            end;
                        end;
                        PostTotalCostAdjustment("Job Ledger Entry", JobLedgerEntryCostValue, JobLedgerEntryCostValueACY);
                    end;

                    trigger OnPreDataItem()
                    begin
                        LockTable();
                    end;
                }

                trigger OnPreDataItem()
                begin
                    LockTable();
                end;
            }

            trigger OnPostDataItem()
            begin
                OnBeforeOnPostDataItemJob(NoOfJobLedgEntry, HideResult);
                if not HideResult then
                    if NoOfJobLedgEntry <> 0 then
                        Message(StrSubstNo(Text001, NoOfJobLedgEntry))
                    else
                        Message(Text003);
            end;

            trigger OnPreDataItem()
            begin
                NoOfJobLedgEntry := 0;
                LockTable();
            end;
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

    trigger OnPreReport()
    begin
        OnAfterOnPreReport();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The project ledger entry item costs have now been updated to equal the related item ledger entry actual costs.\\The number of project ledger entries modified = %1.', Comment = 'The Project Ledger Entry item costs have now been updated to equal the related item ledger entry actual costs.\\Number of Project Ledger Entries modified = 2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NoOfJobLedgEntry: Integer;
#pragma warning disable AA0074
        Text003: Label 'There were no project ledger entries that needed to be updated.';
#pragma warning restore AA0074
        HideResult: Boolean;

    procedure SetProperties(SuppressSummary: Boolean)
    begin
        HideResult := SuppressSummary;
    end;

    local procedure SetValueEntryFilters(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry"; JobLedgEntry: Record "Job Ledger Entry");
    begin
        ValueEntry.SetRange("Job No.", JobLedgEntry."Job No.");
        ValueEntry.SetRange("Job Task No.", JobLedgEntry."Job Task No.");
        ValueEntry.SetRange("Job Ledger Entry No.", JobLedgEntry."Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");

        OnAfterSetValueEntryFilters(ValueEntry, ItemLedgEntry, JobLedgEntry);
    end;

    local procedure ModifyAllValueEntries(var ToValueEntry: Record "Value Entry"; var FromValueEntry: Record "Value Entry")
    begin
        ToValueEntry.ModifyAll("Job No.", FromValueEntry."Job No.");
        ToValueEntry.ModifyAll("Job Task No.", FromValueEntry."Job Task No.");
        ToValueEntry.ModifyAll("Job Ledger Entry No.", FromValueEntry."Job Ledger Entry No.");

        OnAfterModifyAllValueEntries(ToValueEntry, FromValueEntry);
    end;

    protected procedure UpdatePostedTotalCost(var JobLedgerEntry: Record "Job Ledger Entry"; AdjustJobCost: Decimal; AdjustJobCostLCY: Decimal)
    var
        JobUsageLink: Record "Job Usage Link";
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobUsageLink.SetRange("Entry No.", JobLedgerEntry."Entry No.");
        if JobUsageLink.FindSet() then
            repeat
                JobPlanningLine.Get(JobUsageLink."Job No.", JobUsageLink."Job Task No.", JobUsageLink."Line No.");
                JobPlanningLine.UpdatePostedTotalCost(AdjustJobCost, AdjustJobCostLCY);
                JobPlanningLine.Modify();
            until JobUsageLink.Next() = 0;
    end;

    local procedure PostTotalCostAdjustment(var JobLedgEntry: Record "Job Ledger Entry"; JobLedgerEntryCostValue: Decimal; JobLedgerEntryCostValueACY: Decimal)
    var
        AdjustJobCost: Decimal;
        AdjustJobCostLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostTotalCostAdjustment(
            JobLedgEntry, "Item Ledger Entry", JobLedgerEntryCostValue, JobLedgerEntryCostValueACY, AdjustJobCost, AdjustJobCostLCY, NoOfJobLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if JobLedgEntry."Total Cost (LCY)" <> -JobLedgerEntryCostValue then begin
            // Update Total Costs
            AdjustJobCostLCY := -JobLedgerEntryCostValue - JobLedgEntry."Total Cost (LCY)";
            JobLedgEntry."Total Cost (LCY)" := -JobLedgerEntryCostValue;
            if JobLedgEntry."Currency Code" = '' then begin
                AdjustJobCost := -JobLedgerEntryCostValue - JobLedgEntry."Total Cost";
                JobLedgEntry."Total Cost" := -JobLedgerEntryCostValue
            end else begin
                AdjustJobCost := -JobLedgerEntryCostValue * JobLedgEntry."Currency Factor" - JobLedgEntry."Total Cost";
                JobLedgEntry."Total Cost" := -JobLedgerEntryCostValue * JobLedgEntry."Currency Factor";
            end;
            if JobLedgerEntryCostValueACY <> 0 then
                JobLedgEntry."Additional-Currency Total Cost" := -JobLedgerEntryCostValueACY;

            // Update Unit Costs
            if JobLedgEntry.Quantity = 0 then begin
                JobLedgEntry."Unit Cost (LCY)" := JobLedgEntry."Total Cost (LCY)";
                JobLedgEntry."Unit Cost" := JobLedgEntry."Total Cost";
            end else begin
                JobLedgEntry."Unit Cost (LCY)" := JobLedgEntry."Total Cost (LCY)" / JobLedgEntry.Quantity;
                JobLedgEntry."Unit Cost" := JobLedgEntry."Total Cost" / JobLedgEntry.Quantity;
            end;

            JobLedgEntry.Adjusted := true;
            JobLedgEntry."DateTime Adjusted" := CurrentDateTime;

            OnPostTotalCostAdjustmentOnBeforeJobLedgEntryModify(JobLedgEntry, "Item Ledger Entry");
            JobLedgEntry.Modify();

            UpdatePostedTotalCost(JobLedgEntry, AdjustJobCost, AdjustJobCostLCY);

            NoOfJobLedgEntry += 1;
        end;
    end;

    local procedure AddJobCostValue(var JobLedgerEntryCostValue: Decimal; var JobLedgerEntryCostValueACY: Decimal; ValueEntry: Record "Value Entry"; InventoriableItem: Boolean)
    begin
        if InventoriableItem then begin
            JobLedgerEntryCostValue += ValueEntry."Cost Amount (Actual)";
            JobLedgerEntryCostValueACY += ValueEntry."Cost Amount (Actual) (ACY)";
        end else begin
            JobLedgerEntryCostValue += ValueEntry."Cost Amount (Non-Invtbl.)";
            JobLedgerEntryCostValueACY += ValueEntry."Cost Amount (Non-Invtbl.)(ACY)";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyAllValueEntries(var ToValueEntry: Record "Value Entry"; FromValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetValueEntryFilters(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry"; JobLedgEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostTotalCostAdjustment(var JobLedgEntry: Record "Job Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var JobLedgerEntryCostValue: Decimal; var JobLedgerEntryCostValueACY: Decimal; var AdjustJobCost: Decimal; var AdjustJobCostLCY: Decimal; var NoOfJobLedgEntry: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPostDataItemJob(NoOfJobLedgEntry: Integer; var HideResult: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostTotalCostAdjustmentOnBeforeJobLedgEntryModify(var JobLedgerEntry: Record "Job Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLedgerEntryOnAfterGetRecord(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

