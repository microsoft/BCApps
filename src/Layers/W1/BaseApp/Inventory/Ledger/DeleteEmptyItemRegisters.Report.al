// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Inventory.Counting.Journal;
using System.Utilities;

report 799 "Delete Empty Item Registers"
{
    Caption = 'Delete Empty Item Registers';
    Permissions = TableData "Item Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Item Register"; "Item Register")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "Creation Date";

            trigger OnAfterGetRecord()
            begin
                ItemLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                ItemLedgEntry.SetFilter("Item Register No.", '0|%1', "Item Register"."No.");
                ValueEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                ValueEntry.SetFilter("Item Register No.", '0|%1', "Item Register"."No.");
                PhysInvtLedgEntry.SetRange("Entry No.", "From Phys. Inventory Entry No.", "To Phys. Inventory Entry No.");
                PhysInvtLedgEntry.SetFilter("Item Register No.", '0|%1', "Item Register"."No.");
                CapLedgEntry.SetRange("Entry No.", "From Capacity Entry No.", "To Capacity Entry No.");
                CapLedgEntry.SetFilter("Item Register No.", '0|%1', "Item Register"."No.");
                if not ItemLedgEntry.IsEmpty() then
                    CurrReport.Skip();
                if not ValueEntry.IsEmpty() then
                    CurrReport.Skip();
                if not PhysInvtLedgEntry.IsEmpty() then
                    CurrReport.Skip();
                if not CapLedgEntry.IsEmpty() then
                    CurrReport.Skip();
                Window.Update(1, "No.");
                Window.Update(2, "Creation Date");
                Delete();
                NoOfDeleted := NoOfDeleted + 1;
                Window.Update(3, NoOfDeleted);
                if NoOfDeleted >= NoOfDeleted2 + 10 then begin
                    NoOfDeleted2 := NoOfDeleted;
                    Commit();
                end;
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if not SkipConfirm then
                    if not ConfirmManagement.GetResponseOrDefault(DeleteRegistersQst, true) then
                        CurrReport.Break();

                Window.Open(
                  Text001 +
                  Text002 +
                  Text003 +
                  Text004);
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

    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
        CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        Window: Dialog;
        NoOfDeleted: Integer;
        NoOfDeleted2: Integer;
        SkipConfirm: Boolean;

        DeleteRegistersQst: Label 'Do you want to delete the registers?';
#pragma warning disable AA0074
        Text001: Label 'Deleting item registers...\\';
#pragma warning disable AA0470
        Text002: Label 'No.                      #1######\';
        Text003: Label 'Posted on                #2######\\';
        Text004: Label 'No. of registers deleted #3######';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetSkipConfirm()
    begin
        SkipConfirm := true;
    end;
}

