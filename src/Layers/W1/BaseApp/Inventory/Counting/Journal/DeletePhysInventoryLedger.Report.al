// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Setup;
using System.Utilities;

report 789 "Delete Phys. Inventory Ledger"
{
    Caption = 'Delete Phys. Inventory Ledger';
    Permissions = TableData "Date Compr. Register" = rimd,
                  TableData "Phys. Inventory Ledger Entry" = rimd,
                  TableData "Inventory Period Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Phys. Inventory Ledger Entry"; "Phys. Inventory Ledger Entry")
        {
            RequestFilterFields = "Item No.", "Inventory Posting Group";

            trigger OnAfterGetRecord()
            var
                InvtPeriodEntry: Record "Inventory Period Entry";
                InvtPeriod: Record "Inventory Period";
            begin
                if not InvtPeriod.IsValidDate("Posting Date") then
                    InvtPeriod.ShowError("Posting Date");

                PhysInvtLedgEntry2 := "Phys. Inventory Ledger Entry";
                PhysInvtLedgEntry2.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Posting Date");
                PhysInvtLedgEntry2.CopyFilters("Phys. Inventory Ledger Entry");
                PhysInvtLedgEntry2.SetRange("Item No.", PhysInvtLedgEntry2."Item No.");
                PhysInvtLedgEntry2.SetFilter("Posting Date", DateComprMgt.GetDateFilter(PhysInvtLedgEntry2."Posting Date", EntrdDateComprReg, true));
                PhysInvtLedgEntry2.SetRange("Inventory Posting Group", PhysInvtLedgEntry2."Inventory Posting Group");
                PhysInvtLedgEntry2.SetRange("Entry Type", PhysInvtLedgEntry2."Entry Type");

                Window.Update(1);
                Window.Update(2);

                PhysInvtLedgEntry2.Delete();

                InvtPeriodEntry.RemoveItemRegNo(PhysInvtLedgEntry2."Entry No.", true);

                NoOfDeleted := NoOfDeleted + 1;
                Window.Update(3);

                if NoOfDeleted >= LastNoOfDeleted + 10 then begin
                    LastNoOfDeleted := NoOfDeleted;
                    Commit();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007,
                  "Item No.",
                  "Posting Date",
                  NoOfDeleted);

                LastEntryNo := PhysInvtLedgEntry2.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; EntrdDateComprReg."Starting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date of the period from which the program will suggest physical inventory ledger entries. The batch job will include all entries from this date to the ending date.';
                    }
                    field(EndingDate; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date of the period from which the program will suggest physical inventory ledger entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            ConfirmManagement: Codeunit "Confirm Management";
        begin
            if CloseAction = Action::Cancel then
                exit;
            if not ConfirmManagement.GetResponseOrDefault(DeleteEntriesQst, true) then
                CurrReport.Break();
        end;

        trigger OnOpenPage()
        begin
            if EntrdDateComprReg."Ending Date" = 0D then
                EntrdDateComprReg."Ending Date" := Today;
        end;
    }

    labels
    {
    }

    var
        EntrdDateComprReg: Record "Date Compr. Register";
        PhysInvtLedgEntry2: Record "Phys. Inventory Ledger Entry";
        DateComprMgt: Codeunit DateComprMgt;
        Window: Dialog;
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        LastNoOfDeleted: Integer;

        DeleteEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text004: Label 'Deleting phys. inventory ledger entries...\\';
#pragma warning disable AA0470
        Text005: Label 'Item No.             #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of entries del.  #3######';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

