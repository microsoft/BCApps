// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 12177 "Suggest Vendor Bills"
{
    Caption = 'Suggest Vendor Bills';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.") order(ascending);
            RequestFilterFields = "Vendor No.", "Due Date";

            trigger OnAfterGetRecord()
            var
                Vendor: Record Vendor;
            begin
                Vendor.Get("Vendor No.");
                if Vendor.Blocked <> Vendor.Blocked::" " then
                    CurrReport.Skip();
                CalcFields(Amount, "Remaining Amount");
                if UseSameABICode then begin
                    if "Recipient Bank Account" <> '' then begin
                        VendBankAcc.Get("Vendor No.", "Recipient Bank Account");
                        if BankAccount.ABI = VendBankAcc.ABI then
                            CreateLine();
                    end
                end else
                    CreateLine();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Currency Code", VendorBillHeader."Currency Code");
                SetRange("Payment Method Code", VendorBillHeader."Payment Method Code");
                SetRange("Vendor Bill List", '');
                SetRange("Vendor Bill No.", '');
                SetRange(Open, true);
                SetRange("Document Type", "Document Type"::Invoice);
                SetRange("On Hold", '');
                BankAccount.Get(VendorBillHeader."Bank Account No.");

                VendorBillLine.LockTable();
                VendorBillLine.Reset();
                VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
                if not VendorBillLine.FindLast() then
                    NextLineNo := 10000
                else
                    NextLineNo := VendorBillLine."Line No." + 10000;
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
                    field(UseSameABICode; UseSameABICode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Same ABI Code';
                        ToolTip = 'Specifies if you want to use the same ABI code.';
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
        BankAccount: Record "Bank Account";
        VendBankAcc: Record "Vendor Bank Account";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendBillLine2: Record "Vendor Bill Line";
        NextLineNo: Integer;
        UseSameABICode: Boolean;

    procedure InitValues(var VendBillHeader: Record "Vendor Bill Header")
    begin
        VendorBillHeader := VendBillHeader;
    end;

    [Scope('OnPrem')]
    procedure CreateLine()
    var
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        Dimension: Code[20];
    begin
        VendBillLine2.Reset();
        VendBillLine2.SetRange("Vendor Entry No.", "Vendor Ledger Entry"."Entry No.");

        if not VendBillLine2.FindFirst() then begin
            VendBillLine2.Reset();
            VendBillLine2.SetRange("Vendor No.", "Vendor Ledger Entry"."Vendor No.");
            VendBillLine2.SetRange("Document No.", "Vendor Ledger Entry"."Document No.");
            VendBillLine2.SetRange("Document Occurrence", "Vendor Ledger Entry"."Document Occurrence");
            VendBillLine2.SetRange("Document Date", "Vendor Ledger Entry"."Document Date");
            if not VendBillLine2.FindFirst() then begin
                VendorBillLine.Init();
                VendorBillLine."Vendor Bill List No." := VendorBillHeader."No.";
                VendorBillLine."Line No." := NextLineNo;
                VendorBillLine."Vendor No." := "Vendor Ledger Entry"."Vendor No.";
                VendorBillLine."Vendor Bank Acc. No." := "Vendor Ledger Entry"."Recipient Bank Account";
                VendorBillLine."Document Type" := "Vendor Ledger Entry"."Document Type";
                VendorBillLine."Document No." := "Vendor Ledger Entry"."Document No.";
                VendorBillLine."Document Occurrence" := "Vendor Ledger Entry"."Document Occurrence";
                VendorBillLine."Document Date" := "Vendor Ledger Entry"."Document Date";
                VendorBillLine."External Document No." := "Vendor Ledger Entry"."External Document No.";
                VendorBillLine."Instalment Amount" := Abs("Vendor Ledger Entry".Amount);
                VendorBillLine."Remaining Amount" := Abs("Vendor Ledger Entry"."Remaining Amount");
                DimMgt.AddDimSource(DefaultDimSource, Database::Vendor, VendorBillLine."Vendor No.");
                VendorBillLine."Dimension Set ID" :=
                    DimMgt.GetRecDefaultDimID(
                        VendorBillLine, 0, DefaultDimSource, '', Dimension, Dimension, VendorBillLine."Dimension Set ID", DATABASE::Vendor);
                VendorBillLine."Gross Amount to Pay" := VendorBillLine."Remaining Amount";
                if VendorBillHeader."Posting Date" <= "Vendor Ledger Entry"."Pmt. Disc. Tolerance Date" then
                    VendorBillLine."Amount to Pay" :=
                      VendorBillLine."Remaining Amount" - Abs("Vendor Ledger Entry"."Remaining Pmt. Disc. Possible")
                else
                    VendorBillLine."Amount to Pay" := VendorBillLine."Remaining Amount";
                VendorBillLine."Due Date" := "Vendor Ledger Entry"."Due Date";
                VendorBillLine."Beneficiary Value Date" := VendorBillHeader."Beneficiary Value Date";
                VendorBillLine."Cumulative Transfers" := true;
                VendorBillLine."Vendor Entry No." := "Vendor Ledger Entry"."Entry No.";
                VendorBillLine."Reason Code" := VendorBillHeader."Reason Code";
                NextLineNo := NextLineNo + 10000;
                OnCreateLineOnBeforeVendorBillLineInsert(VendorBillLine, VendorBillHeader, "Vendor Ledger Entry");
                VendorBillLine.Insert(true);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLineOnBeforeVendorBillLineInsert(var VendorBillLine: Record "Vendor Bill Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

