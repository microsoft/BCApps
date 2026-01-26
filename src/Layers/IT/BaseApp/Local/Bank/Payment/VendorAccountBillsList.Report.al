// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 12116 "Vendor Account Bills List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/VendorAccountBillsList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Account Bill List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(EndingDate; Format(EndingDate))
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__Purchaser_Code_; "Purchaser Code")
            {
            }
            column(Vendor_Address; Address)
            {
            }
            column(Vendor_City; City)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor__Payment_Terms_Code_; "Payment Terms Code")
            {
            }
            column(EndingDate_Control1130007; EndingDate)
            {
            }
            column(OnlyOpened; OnlyOpened)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor_Account_Bill_List___Date_Caption; Vendor_Account_Bill_List___Date_CaptionLbl)
            {
            }
            column(Vendor__Purchaser_Code_Caption; FieldCaption("Purchaser Code"))
            {
            }
            column(Vendor__Payment_Terms_Code_Caption; FieldCaption("Payment Terms Code"))
            {
            }
            column(BalanceNoteLbl; BalanceNoteLbl)
            {
            }
            dataitem(VendLedgEntry1; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting(Open, "Due Date") order(ascending);
                column(VendLedgEntry1__On_Hold_; "On Hold")
                {
                }
                column(VendLedgEntry1__Payment_Method_; "Payment Method Code")
                {
                }
                column(VendorBillAmnt; VendorBillAmnt)
                {
                }
                column(RemainingAmountLCY; RemainingAmountLCY)
                {
                }
                column(VendLedgEntry1__Amount__LCY__; "Amount (LCY)")
                {
                }
                column(VendLedgEntry1__Due_Date_; Format("Due Date"))
                {
                }
                column(VendLedgEntry1_Description; Description)
                {
                }
                column(VendLedgEntry1__Document_Date_; Format("Document Date"))
                {
                }
                column(VendLedgEntry1__Document_Occurrence_; "Document Occurrence")
                {
                }
                column(VendLedgEntry1__Document_No__; "Document No.")
                {
                }
                column(VendLedgEntry1__External_Document_No__; "External Document No.")
                {
                }
                column(VendLedgEntry1__Document_Type_; "Document Type")
                {
                }
                column(VendLedgEntry1__Posting_Date_; Format("Posting Date"))
                {
                }
                column(VendorLedgerEmtryTypeINT; VendorLedgerEmtryTypeINT)
                {
                }
                column(VendLedgEntry1__Posting_Date__Control1130014; Format("Posting Date"))
                {
                }
                column(RemainingAmountLCY_Control1130015; RemainingAmountLCY)
                {
                }
                column(VendLedgEntry1__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                {
                }
                column(VendLedgEntry1__Amount__LCY___Control1130017; "Amount (LCY)")
                {
                }
                column(VendLedgEntry1__Due_Date__Control1130018; Format("Due Date"))
                {
                }
                column(VendLedgEntry1_Description_Control1130019; Description)
                {
                }
                column(VendLedgEntry1__Document_Date__Control1130020; Format("Document Date"))
                {
                }
                column(VendLedgEntry1__Document_Occurrence__Control1130021; "Document Occurrence")
                {
                }
                column(VendLedgEntry1__Document_No___Control1130022; "Document No.")
                {
                }
                column(VendLedgEntry1__External_Document_No___Control1130023; "External Document No.")
                {
                }
                column(VendLedgEntry1__Document_Type__Control1130024; "Document Type")
                {
                }
                column(VendLedgEntry1_DocumentType; Format("Document Type", 0, 2))
                {
                }
                column(TotalVendorBillAmnt; TotalVendorBillAmnt)
                {
                }
                column(BalanceDue; BalanceDue)
                {
                }
                column(TotalForVendor; TotalForVendor)
                {
                }
                column(TotalVendLedgrEntries_; TotalVendLedgrEntries)
                {
                }
                column(TotalDtldVendLedgrEntries_; TotalDtldVendLedgrEntries)
                {
                }
                column(VendLedgEntry1_Entry_No_; "Entry No.")
                {
                }
                column(VendLedgEntry1_Vendor_No_; "Vendor No.")
                {
                }
                column(VendLedgEntry1__Due_Date_Caption; VendLedgEntry1__Due_Date_CaptionLbl)
                {
                }
                column(VendLedgEntry1__Amount__LCY___Control1130017Caption; VendLedgEntry1__Amount__LCY___Control1130017CaptionLbl)
                {
                }
                column(RemainingAmountLCYCaption; RemainingAmountLCYCaptionLbl)
                {
                }
                column(VendorBillAmntCaption; VendorBillAmntCaptionLbl)
                {
                }
                column(VendLedgEntry1__Payment_Method_Caption; FieldCaption("Payment Method Code"))
                {
                }
                column(VendLedgEntry1__Amount__LCY__Caption; VendLedgEntry1__Amount__LCY__CaptionLbl)
                {
                }
                column(VendLedgEntry1__On_Hold_Caption; FieldCaption("On Hold"))
                {
                }
                column(VendLedgEntry1_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(VendLedgEntry1__Document_Date_Caption; VendLedgEntry1__Document_Date_CaptionLbl)
                {
                }
                column(VendLedgEntry1__Document_Occurrence_Caption; FieldCaption("Document Occurrence"))
                {
                }
                column(VendLedgEntry1__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(VendLedgEntry1__External_Document_No__Caption; FieldCaption("External Document No."))
                {
                }
                column(VendLedgEntry1__Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(VendLedgEntry1__Posting_Date_Caption; VendLedgEntry1__Posting_Date_CaptionLbl)
                {
                }
                column(Vendor_BalanceCaption; Vendor_BalanceCaptionLbl)
                {
                }
                dataitem(VendLedgEntry2; "Vendor Ledger Entry")
                {
                    DataItemLink = "Applies-to Doc. No." = field("Document No.");
                    column(ClosedByAmountLCY; ClosedByAmountLCY)
                    {
                    }
                    column(VendLedgEntry2__Amount__LCY__; "Amount (LCY)")
                    {
                    }
                    column(VendLedgEntry2__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(VendLedgEntry2_Description; Description)
                    {
                    }
                    column(VendLedgEntry2__Document_Date_; Format("Document Date"))
                    {
                    }
                    column(VendLedgEntry2__Document_Occurrence_; "Document Occurrence")
                    {
                    }
                    column(VendLedgEntry2__Document_No__; "Document No.")
                    {
                    }
                    column(VendLedgEntry2__External_Document_No__; "External Document No.")
                    {
                    }
                    column(VendLedgEntry2__Document_Type_; "Document Type")
                    {
                    }
                    column(VendLedgEntry2__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(TotalClosedByAmntLCY; TotalClosedByAmntLCY)
                    {
                    }
                    column(VendLedgEntry2_Entry_No_; "Entry No.")
                    {
                    }
                    column(VendLedgEntry2_Applies_to_Doc__No_; "Applies-to Doc. No.")
                    {
                    }
                    column(BalanceCaption; BalanceCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Open = false then
                            CurrReport.Skip();
                        ClosedByAmountLCY := "Closed by Amount (LCY)";
                        TotalForVendor += "Closed by Amount (LCY)";
                        TotalClosedByAmntLCY += "Amount (LCY)";
                        TotalVendLedgrEntries := TotalVendLedgrEntries + "Amount (LCY)";
                    end;

                    trigger OnPreDataItem()
                    begin
                        VendLedgEntry1.CopyFilter("Posting Date", "Posting Date");
                    end;
                }
                dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor No." = field("Vendor No.");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = const(Application));
                    column(ClosedByAmountLCY_Control1130070; ClosedByAmountLCY)
                    {
                    }
                    column(Detailed_Vendor_Ledg__Entry__Document_No__; VendLedgEntry3."Document No.")
                    {
                    }
                    column(Detailed_Vendor_Ledg__Entry__Document_Type_; VendLedgEntry3."Document Type")
                    {
                    }
                    column(Detailed_Vendor_Ledg__Entry__Posting_Date_; Format(VendLedgEntry3."Posting Date"))
                    {
                    }
                    column(VendLedgEntry3__Document_Occurrence_; VendLedgEntry3."Document Occurrence")
                    {
                    }
                    column(VendLedgEntry3__Document_Date_; Format(VendLedgEntry3."Document Date"))
                    {
                    }
                    column(VendLedgEntry3__External_Document_No__; VendLedgEntry3."Document No.")
                    {
                    }
                    column(VendLedgEntry3_Description; VendLedgEntry3.Description)
                    {
                    }
                    column(VendLedgEntry3__Due_Date_; Format(VendLedgEntry3."Due Date"))
                    {
                    }
                    column(VendLedgEntry3__Original_Amt___LCY__; VendLedgEntry3."Original Amt. (LCY)")
                    {
                    }
                    column(Detailed_Vendor_Ledg__Entry__Unapplied_by_Entry_No__; "Unapplied by Entry No.")
                    {
                    }
                    column(TotalClosedByAmntLCY_Control1130080; TotalClosedByAmntLCY)
                    {
                    }
                    column(Detailed_Vendor_Ledg__Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Detailed_Vendor_Ledg__Entry_Vendor_Ledger_Entry_No_; "Vendor Ledger Entry No.")
                    {
                    }
                    column(BalanceCaption_Control1130079; BalanceCaption_Control1130079Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        DetailedVendorLedgEntryApplication: Record "Detailed Vendor Ledg. Entry";
                        AmountLCY: Decimal;
                    begin
                        if not TempDetailedVendorLedgEntryApplied.Get("Entry No.") then
                            CurrReport.Skip();

                        VendLedgEntry3.Get("Vendor Ledger Entry No.");
                        VendLedgEntry3.CalcFields("Original Amt. (LCY)");

                        AmountLCY := -"Amount (LCY)";

                        if VendLedgEntry1."Document Type" = VendLedgEntry1."Document Type"::Invoice then begin
                            DetailedVendorLedgEntryApplication.SetRange(Unapplied, false);
                            DetailedVendorLedgEntryApplication.SetRange("Entry Type", "Entry Type"::Application);
                            DetailedVendorLedgEntryApplication.SetRange("Document Type", TempDetailedVendorLedgEntryApplied."Document Type");
                            DetailedVendorLedgEntryApplication.SetRange("Applied Vend. Ledger Entry No.", VendLedgEntry3."Entry No.");
                            DetailedVendorLedgEntryApplication.SetRange("Vendor Ledger Entry No.", VendLedgEntry1."Entry No.");
                            if DetailedVendorLedgEntryApplication.FindFirst() then
                                AmountLCY := DetailedVendorLedgEntryApplication."Amount (LCY)"
                            else begin
                                DetailedVendorLedgEntryApplication.SetRange("Document Type", "Document Type"::Invoice);
                                DetailedVendorLedgEntryApplication.SetRange("Applied Vend. Ledger Entry No.", VendLedgEntry1."Entry No.");
                                DetailedVendorLedgEntryApplication.SetRange("Vendor Ledger Entry No.", VendLedgEntry3."Entry No.");
                                if DetailedVendorLedgEntryApplication.FindFirst() then
                                    AmountLCY := -DetailedVendorLedgEntryApplication."Amount (LCY)";
                            end;
                        end;

                        if Abs(AmountLCY) < Abs(VendLedgEntry1."Amount (LCY)") then
                            ClosedByAmountLCY := AmountLCY
                        else
                            ClosedByAmountLCY := -VendLedgEntry1."Amount (LCY)";

                        TotalForVendor += ClosedByAmountLCY;
                        TotalClosedByAmntLCY += ClosedByAmountLCY;
                        TotalDtldVendLedgrEntries += ClosedByAmountLCY;
                    end;

                    trigger OnPreDataItem()
                    begin
                        FindAppliedDetailedVendorLedgerEntry(VendLedgEntry1."Entry No.");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    RemainingAmountLCY := 0;
                    VendorBillAmnt := 0;


                    TotalForVendor := TotalForVendor + "Amount (LCY)";
                    TotalVendLedgrEntries := TotalVendLedgrEntries + "Amount (LCY)";
                    if "Vendor Bill No." <> '' then begin
                        VendorBillLine.Reset();
                        VendorBillLine.SetRange("Vendor Entry No.", "Entry No.");
                        if VendorBillLine.FindFirst() then
                            VendorBillAmnt := VendorBillLine."Amount to Pay";
                    end;

                    TotalClosedByAmntLCY := "Amount (LCY)";

                    if "Due Date" <= EndingDate then begin
                        RemainingAmountLCY := "Remaining Amt. (LCY)";
                        BalanceDue := BalanceDue + RemainingAmountLCY;
                    end;

                    TotalVendorBillAmnt := TotalVendorBillAmnt + VendorBillAmnt;
                    VendorLedgerEmtryTypeINT := "Document Type".AsInteger()
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", 0D, EndingDate);
                    SetRange("Date Filter", 0D, EndingDate);

                    SetAutoCalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                    if OnlyOpened then
                        SetFilter("Remaining Amt. (LCY)", '<>0');

                    TotalForVendor := 0;
                    BalanceDue := 0;
                    TotalVendorBillAmnt := 0;
                    TotalVendLedgrEntries := 0;
                    TotalDtldVendLedgrEntries := 0;

                    SetFilter("Document Type", '<>%1&<>%2&<>%3',
                                            "Document Type"::" ",
                                            "Document Type"::Payment,
                                            "Document Type"::"Credit Memo");

                end;
            }
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
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date.';
                    }
                    field(OnlyOpenedEntries; OnlyOpened)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Opened Entries';
                        ToolTip = 'Specifies if you want to see only opened entries.';
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

    trigger OnPreReport()
    begin
        if EndingDate = 0D then
            Error(EmptyEndingDateErr);
    end;

    var
        EmptyEndingDateErr: Label 'Specify the Ending Date.';
        VendorBillLine: Record "Vendor Bill Line";
        VendLedgEntry3: Record "Vendor Ledger Entry";
        TempDetailedVendorLedgEntryApplied: Record "Detailed Vendor Ledg. Entry" temporary;
        EndingDate: Date;
        RemainingAmountLCY: Decimal;
        ClosedByAmountLCY: Decimal;
        TotalClosedByAmntLCY: Decimal;
        TotalForVendor: Decimal;
        BalanceDue: Decimal;
        VendorBillAmnt: Decimal;
        TotalVendorBillAmnt: Decimal;
        VendorLedgerEmtryTypeINT: Integer;
        TotalVendLedgrEntries: Decimal;
        TotalDtldVendLedgrEntries: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page No.';
        Vendor_Account_Bill_List___Date_CaptionLbl: Label 'Vendor Account Bill List - Date:';
        VendLedgEntry1__Due_Date_CaptionLbl: Label 'Due Date';
        VendLedgEntry1__Amount__LCY___Control1130017CaptionLbl: Label 'Entry Amount (LCY)';
        RemainingAmountLCYCaptionLbl: Label 'Due Amount (LCY)';
        VendorBillAmntCaptionLbl: Label 'Vendor Bill Amount';
        VendLedgEntry1__Amount__LCY__CaptionLbl: Label 'Applied Amount (LCY)';
        VendLedgEntry1__Document_Date_CaptionLbl: Label 'Document Date';
        VendLedgEntry1__Posting_Date_CaptionLbl: Label 'PostingDate';
        Vendor_BalanceCaptionLbl: Label 'Total';
        BalanceCaptionLbl: Label 'Balance';
        BalanceCaption_Control1130079Lbl: Label 'Balance';
        BalanceNoteLbl: Label 'Note: The report shows the vendor''s invoiced bills and the resulting balance for each. Because stand-alone payments and opening balances are not included, the report does not reflect the vendor''s total balance.';

    protected var
        OnlyOpened: Boolean;

    local procedure FindAppliedDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntryApplied: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntryApplied: Record "Vendor Ledger Entry";
    begin
        TempDetailedVendorLedgEntryApplied.Reset();
        TempDetailedVendorLedgEntryApplied.DeleteAll();

        DetailedVendorLedgEntry.SetFilter("Posting Date", '<=%1', EndingDate);
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntryNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange(Unapplied, false);

        DetailedVendorLedgEntryApplied.SetRange(
          "Entry Type", DetailedVendorLedgEntryApplied."Entry Type"::Application);

        if DetailedVendorLedgEntry.FindSet() then
            repeat
                if (DetailedVendorLedgEntry."Transaction No." <> 0) or (DetailedVendorLedgEntry."Application No." <> 0) then begin
                    DetailedVendorLedgEntryApplied.SetRange(
                      "Applied Vend. Ledger Entry No.", DetailedVendorLedgEntry."Applied Vend. Ledger Entry No.");
                    DetailedVendorLedgEntryApplied.SetFilter(
                      "Vendor Ledger Entry No.", '<>%1', VendorLedgerEntryNo);
                    DetailedVendorLedgEntryApplied.SetRange(
                      "Vendor No.", DetailedVendorLedgEntry."Vendor No.");
                    DetailedVendorLedgEntryApplied.SetRange(
                      "Application No.", DetailedVendorLedgEntry."Application No.");
                    DetailedVendorLedgEntryApplied.SetRange(
                      "Transaction No.", DetailedVendorLedgEntry."Transaction No.");
                    if DetailedVendorLedgEntryApplied.FindSet() then
                        repeat
                            VendorLedgerEntryApplied.Get(DetailedVendorLedgEntryApplied."Vendor Ledger Entry No.");
                            if IsPaymentDocumentType(VendorLedgerEntryApplied) then begin
                                TempDetailedVendorLedgEntryApplied := DetailedVendorLedgEntryApplied;
                                if TempDetailedVendorLedgEntryApplied.Insert() then;
                            end;
                        until DetailedVendorLedgEntryApplied.Next() = 0;
                end;
            until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure IsPaymentDocumentType(VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        exit(
              VendorLedgerEntry."Document Type" in [VendorLedgerEntry."Document Type"::" ", VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::"Credit Memo"]);
    end;
}

