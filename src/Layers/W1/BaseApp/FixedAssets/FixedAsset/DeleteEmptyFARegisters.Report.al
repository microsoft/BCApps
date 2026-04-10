// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.FixedAssets.Maintenance;
using System.Utilities;

report 5693 "Delete Empty FA Registers"
{
    Caption = 'Delete Empty FA Registers';
    Permissions = TableData "FA Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("FA Register"; "FA Register")
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                FALedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                if FALedgEntry.FindFirst() then
                    CurrReport.Skip();
                MaintenanceLedgEntry.SetRange("Entry No.", "From Maintenance Entry No.", "To Maintenance Entry No.");
                if MaintenanceLedgEntry.FindFirst() then
                    CurrReport.Skip();
                Window.Update(1, "No.");
                Window.Update(2, SystemCreatedAt);

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

                if RequestFilterDate <> 0D then
                    SetRange(SystemCreatedAt, CreateDateTime(RequestFilterDate, 000000T), CreateDateTime(RequestFilterDate, 235959T));
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(RequestFilterDate; RequestFilterDate)
                    {
                        Caption = 'Creation Date';
                        ToolTip = 'Creation Date of the G/L Register.';
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

    var
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        Window: Dialog;
        NoOfDeleted: Integer;
        NoOfDeleted2: Integer;
        SkipConfirm: Boolean;

        DeleteRegistersQst: Label 'Do you want to delete the registers?';
#pragma warning disable AA0074
        Text001: Label 'Deleting empty FA registers...\\';
#pragma warning disable AA0470
        Text002: Label 'No.                      #1######\';
        Text003: Label 'Posted on                #2######\\';
        Text004: Label 'No. of registers deleted #3######';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RequestFilterDate: Date;

    procedure SetSkipConfirm()
    begin
        SkipConfirm := true;
    end;
}

