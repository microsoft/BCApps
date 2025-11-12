// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 99 "Delete Empty G/L Registers"
{
    Caption = 'Delete Empty G/L Registers';
    Permissions = TableData "G/L Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                GLEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                if GLEntry.FindFirst() then
                    CurrReport.Skip();
                CustLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                if CustLedgEntry.FindFirst() then
                    CurrReport.Skip();
                VendLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                if VendLedgEntry.FindFirst() then
                    CurrReport.Skip();
                VATEntry.SetRange("Entry No.", "From VAT Entry No.", "To VAT Entry No.");
                if VATEntry.FindFirst() then
                    CurrReport.Skip();
                BankAccLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                if BankAccLedgEntry.FindFirst() then
                    CurrReport.Skip();

                FAReg.SetCurrentKey(SystemCreatedAt);
                if RequestFilterDate <> 0D then
                    FAReg.SetRange(SystemCreatedAt, CreateDateTime(RequestFilterDate, 000000T), CreateDateTime(RequestFilterDate, 235959T));
                FAReg.SetRange("G/L Register No.", "No.");
                if FAReg.FindFirst() then begin
                    FALedgEntry.SetRange("Entry No.", FAReg."From Entry No.", FAReg."To Entry No.");
                    if FALedgEntry.FindFirst() then
                        CurrReport.Skip();
                    MaintLedgEntry.SetRange("Entry No.", FAReg."From Maintenance Entry No.", FAReg."To Maintenance Entry No.");
                    if MaintLedgEntry.FindFirst() then
                        CurrReport.Skip();
                end;

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
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        FAReg: Record "FA Register";
        FALedgEntry: Record "FA Ledger Entry";
        MaintLedgEntry: Record "Maintenance Ledger Entry";
        Window: Dialog;
        NoOfDeleted: Integer;
        NoOfDeleted2: Integer;
        SkipConfirm: Boolean;

#pragma warning disable AA0074
        Text001: Label 'Deleting empty G/L registers...\\';
#pragma warning disable AA0470
        Text002: Label 'No.                      #1######\';
        Text003: Label 'Posted on                #2######\\';
        Text004: Label 'No. of registers deleted #3######';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DeleteRegistersQst: Label 'Do you want to delete the registers?';
        RequestFilterDate: Date;

    procedure SetSkipConfirm()
    begin
        SkipConfirm := true;
    end;
}

