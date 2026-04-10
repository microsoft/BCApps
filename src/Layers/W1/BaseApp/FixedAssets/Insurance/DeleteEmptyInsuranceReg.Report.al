// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using System.Utilities;

report 5695 "Delete Empty Insurance Reg."
{
    Caption = 'Delete Empty Insurance Reg.';
    Permissions = TableData "Insurance Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Insurance Register"; "Insurance Register")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "Creation Date";

            trigger OnAfterGetRecord()
            begin
                InsCoverageLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                if InsCoverageLedgEntry.FindFirst() then
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
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        Window: Dialog;
        NoOfDeleted: Integer;
        NoOfDeleted2: Integer;
        SkipConfirm: Boolean;

        DeleteRegistersQst: Label 'Do you want to delete the registers?';
#pragma warning disable AA0074
        Text001: Label 'Deleting empty insurance registers...\\';
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

