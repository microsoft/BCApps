// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

report 12117 "Customer Bills List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/CustomerBillsList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Bill List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(EndingDate; Format(EndingDate))
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer_Address; Address)
            {
            }
            column(Customer_City; City)
            {
            }
            column(Customer__Payment_Terms_Code_; "Payment Terms Code")
            {
            }
            column(Customer__Payment_Method_Code_; "Payment Method Code")
            {
            }
            column(Customer__Salesperson_Code_; "Salesperson Code")
            {
            }
            column(ExposureDate; Format(ExposureDate))
            {
            }
            column(EndingDate_Control1130005; EndingDate)
            {
            }
            column(OnlyOpened; OnlyOpened)
            {
            }
            column(Page_No_Caption; Page_No_CaptionLbl)
            {
            }
            column(Customer_Bill_List___Date_Caption; Customer_Bill_List___Date_CaptionLbl)
            {
            }
            column(Customer__Payment_Terms_Code_Caption; FieldCaption("Payment Terms Code"))
            {
            }
            column(Customer__Payment_Method_Code_Caption; FieldCaption("Payment Method Code"))
            {
            }
            column(Customer__Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
            {
            }
            column(ExposureDateCaption; ExposureDateCaptionLbl)
            {
            }
            column(BalanceNoteLbl; BalanceNoteLbl)
            {
            }
            dataitem(CustLedgEntry1; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No.");
                DataItemTableView = sorting(Open, "Due Date") order(ascending);
                column(CustLedgEntry1__Due_Date_; Format("Due Date"))
                {
                }
                column(CustLedgEntry1__Payment_Method_; "Payment Method Code")
                {
                }
                column(ExposureAmount; ExposureAmount)
                {
                }
                column(RemainingAmountLCY; RemainingAmountLCY)
                {
                }
                column(CustLedgEntry1__Amount__LCY__; "Amount (LCY)")
                {
                }
                column(CustLedgEntry1_Description; Description)
                {
                }
                column(CustLedgEntry1__Document_Date_; Format("Document Date"))
                {
                }
                column(CustLedgEntry1__Document_Occurrence_; "Document Occurrence")
                {
                }
                column(CustLedgEntry1__Document_No__; "Document No.")
                {
                }
                column(CustLedgEntry1__Document_Type_; "Document Type")
                {
                }
                column(CustLedgEntry1__Posting_Date_; Format("Posting Date"))
                {
                }
                column(RemainingAmountLCY_Control1130034; RemainingAmountLCY)
                {
                }
                column(CustLedgEntry1__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                {
                }
                column(CustLedgEntry1__Amount__LCY___Control1130036; "Amount (LCY)")
                {
                }
                column(CustLedgEntry1__Due_Date__Control1130037; Format("Due Date"))
                {
                }
                column(CustLedgEntry1_Description_Control1130038; Description)
                {
                }
                column(CustLedgEntry1__Document_Date__Control1130039; Format("Document Date"))
                {
                }
                column(CustLedgEntry1__Document_Occurrence__Control1130040; "Document Occurrence")
                {
                }
                column(CustLedgEntry1__Document_No___Control1130041; "Document No.")
                {
                }
                column(CustLedgEntry1__Document_Type__Control1130042; "Document Type")
                {
                }
                column(CustLedgEntry1__Posting_Date__Control1130043; Format("Posting Date"))
                {
                }
                column(CustLedgEntry1_CustLedgEntry1__Bank_Receipt_; "Bank Receipt")
                {
                }
                column(CustLedgEntry1_DocumentType; Format("Document Type", 0, 2))
                {
                }
                column(TotalForCustomer; TotalForCustomer)
                {
                }
                column(BalanceDue; BalanceDue)
                {
                }
                column(TotExpAmntForCust; TotExpAmntForCust)
                {
                }
                column(TotalCustLedgrEntries_; TotalCustLedgrEntries)
                {
                }
                column(TotalDtldCustLedgrEntries_; TotalDtldCustLedgrEntries)
                {
                }
                column(CustLedgEntry1_Entry_No_; "Entry No.")
                {
                }
                column(CustLedgEntry1_Customer_No_; "Customer No.")
                {
                }
                column(CustLedgEntry1__Due_Date_Caption; CustLedgEntry1__Due_Date_CaptionLbl)
                {
                }
                column(CustLedgEntry1__Amount__LCY___Control1130036Caption; CustLedgEntry1__Amount__LCY___Control1130036CaptionLbl)
                {
                }
                column(RemainingAmountLCYCaption; RemainingAmountLCYCaptionLbl)
                {
                }
                column(ExposureAmountCaption; ExposureAmountCaptionLbl)
                {
                }
                column(CustLedgEntry1__Payment_Method_Caption; FieldCaption("Payment Method Code"))
                {
                }
                column(CustLedgEntry1__Amount__LCY__Caption; CustLedgEntry1__Amount__LCY__CaptionLbl)
                {
                }
                column(CustLedgEntry1_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(CustLedgEntry1__Document_Date_Caption; CustLedgEntry1__Document_Date_CaptionLbl)
                {
                }
                column(CustLedgEntry1__Document_Occurrence_Caption; FieldCaption("Document Occurrence"))
                {
                }
                column(CustLedgEntry1__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(CustLedgEntry1__Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(CustLedgEntry1__Posting_Date_Caption; CustLedgEntry1__Posting_Date_CaptionLbl)
                {
                }
                column(Customer_BalanceCaption; Customer_BalanceCaptionLbl)
                {
                }
                dataitem(CustLedgEntry2; "Cust. Ledger Entry")
                {
                    DataItemLink = "Document No. to Close" = field("Document No.");
                    column(CustLedgEntry2__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(CustLedgEntry2__Document_Type_; "Document Type")
                    {
                    }
                    column(CustLedgEntry2__Document_No__; "Document No.")
                    {
                    }
                    column(CustLedgEntry2__Document_Occurrence_; "Document Occurrence")
                    {
                    }
                    column(CustLedgEntry2__Document_Date_; Format("Document Date"))
                    {
                    }
                    column(CustLedgEntry2_Description; Description)
                    {
                    }
                    column(CustLedgEntry2__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(CustLedgEntry2__Amount__LCY__; "Amount (LCY)")
                    {
                    }
                    column(ClosedByAmountLCY; ClosedByAmountLCY)
                    {
                    }
                    column(TotalClosedByAmntLCY; TotalClosedByAmntLCY)
                    {
                    }
                    column(CustLedgEntry2_Entry_No_; "Entry No.")
                    {
                    }
                    column(CustLedgEntry2_Applies_to_Doc__No_; "Applies-to Doc. No.")
                    {
                    }
                    column(CustLedgEntry2_Document_No__to_Close; "Document No. to Close")
                    {
                    }
                    column(BalanceCaption; BalanceCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if OnlyOpened then
                            CurrReport.Skip();

                        ClosedByAmountLCY := "Amount (LCY)";
                        TotalForCustomer += "Amount (LCY)";
                        TotalClosedByAmntLCY += "Amount (LCY)";
                        TotalCustLedgrEntries += "Amount (LCY)";
                    end;

                    trigger OnPreDataItem()
                    begin
                        CustLedgEntry1.CopyFilter("Posting Date", "Posting Date");
                        SetRange("Document Occurrence to Close", CustLedgEntry1."Document Occurrence");
                    end;
                }
                dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Customer No." = field("Customer No.");
                    DataItemTableView = sorting("Cust. Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = const(Application), "Unapplied by Entry No." = const(0), "Bank Receipt" = filter(<> true), "Bank Receipt Issued" = filter(<> true));
                    column(ClosedByAmountLCY_Control1130120; ClosedByAmountLCY)
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry__Document_No__; CustLedgEntry3."Document No.")
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry__Document_Type_; CustLedgEntry3."Document Type")
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry__Posting_Date_; Format(CustLedgEntry3."Posting Date"))
                    {
                    }
                    column(CustLedgEntry3__Document_Occurrence_; CustLedgEntry3."Document Occurrence")
                    {
                    }
                    column(CustLedgEntry3__Document_Date_; Format(CustLedgEntry3."Document Date"))
                    {
                    }
                    column(CustLedgEntry3_Description; CustLedgEntry3.Description)
                    {
                    }
                    column(CustLedgEntry3__Due_Date_; Format(CustLedgEntry3."Due Date"))
                    {
                    }
                    column(CustLedgEntry3__Original_Amt___LCY__; CustLedgEntry3."Original Amt. (LCY)")
                    {
                    }
                    column(Document_Type_____Document_Type___Dishonored; CustLedgEntry3."Document Type" = "Document Type"::Dishonored)
                    {
                    }
                    column(TotalClosedByAmntLCY_Control1130122; TotalClosedByAmntLCY)
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry_Cust__Ledger_Entry_No_; "Cust. Ledger Entry No.")
                    {
                    }
                    column(BalanceCaption_Control1130121; BalanceCaption_Control1130121Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        DetailedCustLedgEntryApplied: Record "Detailed Cust. Ledg. Entry";
                        AmountLCY: Decimal;
                    begin
                        if not TempDetailedCustLedgEntry.Get("Entry No.") then
                            CurrReport.Skip();

                        CustLedgEntry3.Get("Cust. Ledger Entry No.");
                        CustLedgEntry3.CalcFields("Original Amt. (LCY)");

                        AmountLCY := -"Amount (LCY)";

                        if CustLedgEntry1."Document Type" = CustLedgEntry1."Document Type"::Invoice then begin
                            DetailedCustLedgEntryApplied.SetRange(Unapplied, false);
                            DetailedCustLedgEntryApplied.SetRange("Entry Type", "Entry Type"::Application);
                            DetailedCustLedgEntryApplied.SetRange("Document Type", TempDetailedCustLedgEntry."Document Type");
                            DetailedCustLedgEntryApplied.SetRange("Applied Cust. Ledger Entry No.", CustLedgEntry3."Entry No.");
                            DetailedCustLedgEntryApplied.SetRange("Cust. Ledger Entry No.", CustLedgEntry1."Entry No.");
                            if DetailedCustLedgEntryApplied.FindFirst() then
                                AmountLCY := DetailedCustLedgEntryApplied."Amount (LCY)"
                            else begin
                                DetailedCustLedgEntryApplied.SetRange("Document Type", "Document Type"::Invoice);
                                DetailedCustLedgEntryApplied.SetRange("Applied Cust. Ledger Entry No.", CustLedgEntry1."Entry No.");
                                DetailedCustLedgEntryApplied.SetRange("Cust. Ledger Entry No.", CustLedgEntry3."Entry No.");
                                if DetailedCustLedgEntryApplied.FindFirst() then
                                    AmountLCY := -DetailedCustLedgEntryApplied."Amount (LCY)";
                            end;
                        end;

                        if Abs(AmountLCY) < Abs(CustLedgEntry1."Amount (LCY)") then
                            ClosedByAmountLCY := AmountLCY
                        else
                            ClosedByAmountLCY := -CustLedgEntry1."Amount (LCY)";

                        TotalForCustomer += ClosedByAmountLCY;
                        TotalClosedByAmntLCY += ClosedByAmountLCY;
                        TotalDtldCustLedgrEntries += ClosedByAmountLCY;
                    end;

                    trigger OnPreDataItem()
                    begin
                        FindAppliedDetailedCustomerLedgerEntry(CustLedgEntry1."Entry No.");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    RemainingAmountLCY := 0;
                    ExposureAmount := 0;

                    if "Bank Receipt Issued" and
                        ("Due Date" > ExposureDate)
                    then
                        ExposureAmount := "Remaining Amt. (LCY)";

                    if not "Bank Receipt Issued" and
                        ("Due Date" <= EndingDate)
                    then
                        RemainingAmountLCY := "Remaining Amt. (LCY)";

                    TotalForCustomer := TotalForCustomer + "Amount (LCY)";
                    TotalCustLedgrEntries := TotalCustLedgrEntries + "Amount (LCY)";
                    TotExpAmntForCust := TotExpAmntForCust + ExposureAmount;
                    BalanceDue := BalanceDue + RemainingAmountLCY;

                    TotalClosedByAmntLCY := "Amount (LCY)";
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", 0D, EndingDate);
                    SetRange("Date Filter", 0D, EndingDate);

                    TotalForCustomer := 0;
                    TotExpAmntForCust := 0;
                    BalanceDue := 0;
                    TotalCustLedgrEntries := 0;
                    TotalDtldCustLedgrEntries := 0;
                    SetAutoCalcFields("Amount (LCY)", "Remaining Amt. (LCY)");

                    if OnlyOpened then
                        SetFilter("Remaining Amt. (LCY)", '<>0');

                    SetFilter("Document Type", '<>%1&<>%2&<>%3&<>%4',
                                            "Document Type"::" ",
                                            "Document Type"::Payment,
                                            "Document Type"::Dishonored,
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
                    field("Ending Date"; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date.';
                    }
                    field("Only Opened Entries"; OnlyOpened)
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
    var
        RiskPeriod: DateFormula;
    begin
        if EndingDate = 0D then
            Error(EmptyEndingDateErr);
        SalesSetup.Get();
        SalesSetup.TestField("Bank Receipts Risk Period");
        Evaluate(RiskPeriod, '-' + Format(SalesSetup."Bank Receipts Risk Period"));
        ExposureDate := CalcDate(RiskPeriod, EndingDate);
    end;

    var
        EmptyEndingDateErr: Label 'Specify the Ending Date.';
        SalesSetup: Record "Sales & Receivables Setup";
        CustLedgEntry3: Record "Cust. Ledger Entry";
        TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        EndingDate: Date;
        ExposureDate: Date;
        OnlyOpened: Boolean;
        ExposureAmount: Decimal;
        RemainingAmountLCY: Decimal;
        ClosedByAmountLCY: Decimal;
        TotalClosedByAmntLCY: Decimal;
        TotalForCustomer: Decimal;
        TotExpAmntForCust: Decimal;
        BalanceDue: Decimal;
        TotalCustLedgrEntries: Decimal;
        TotalDtldCustLedgrEntries: Decimal;
        Page_No_CaptionLbl: Label 'Page No.';
        Customer_Bill_List___Date_CaptionLbl: Label 'Customer Bill List - Date:';
        ExposureDateCaptionLbl: Label 'Exposure Date';
        CustLedgEntry1__Due_Date_CaptionLbl: Label 'Due Date';
        CustLedgEntry1__Amount__LCY___Control1130036CaptionLbl: Label 'Entry Amount (LCY)';
        RemainingAmountLCYCaptionLbl: Label 'Amount Due (LCY)';
        ExposureAmountCaptionLbl: Label 'Exposure Amount';
        CustLedgEntry1__Amount__LCY__CaptionLbl: Label 'Applied Amount (LCY)';
        CustLedgEntry1__Document_Date_CaptionLbl: Label 'Document Date';
        CustLedgEntry1__Posting_Date_CaptionLbl: Label 'Posting Date';
        Customer_BalanceCaptionLbl: Label 'Total';
        BalanceCaptionLbl: Label 'Balance';
        BalanceCaption_Control1130121Lbl: Label 'Balance';
        BalanceNoteLbl: Label 'Note: The report shows the customer''s invoiced bills and the resulting balance for each. Because stand-alone payments and opening balances are not included, the report does not reflect the customer''s total balance.';

    local procedure FindAppliedDetailedCustomerLedgerEntry(CustomerLedgerEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntryApplied: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
    begin
        TempDetailedCustLedgEntry.Reset();
        TempDetailedCustLedgEntry.DeleteAll();

        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustomerLedgerEntryNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange(Unapplied, false);

        DetailedCustLedgEntryApplied.SetRange(
          "Entry Type", DetailedCustLedgEntryApplied."Entry Type"::Application);

        if DetailedCustLedgEntry.FindSet() then
            repeat
                if (DetailedCustLedgEntry."Transaction No." <> 0) or (DetailedCustLedgEntry."Application No." <> 0) then begin
                    DetailedCustLedgEntryApplied.SetRange(
                      "Applied Cust. Ledger Entry No.", DetailedCustLedgEntry."Applied Cust. Ledger Entry No.");
                    DetailedCustLedgEntryApplied.SetFilter(
                      "Cust. Ledger Entry No.", '<>%1', CustomerLedgerEntryNo);
                    DetailedCustLedgEntryApplied.SetRange(
                      "Customer No.", DetailedCustLedgEntry."Customer No.");
                    DetailedCustLedgEntryApplied.SetRange(
                      "Application No.", DetailedCustLedgEntry."Application No.");
                    DetailedCustLedgEntryApplied.SetRange(
                      "Transaction No.", DetailedCustLedgEntry."Transaction No.");
                    if DetailedCustLedgEntryApplied.FindSet() then
                        repeat
                            CustLedgerEntryApplied.Get(DetailedCustLedgEntryApplied."Cust. Ledger Entry No.");
                            if IsPaymentDocumentType(CustLedgerEntryApplied) then begin
                                TempDetailedCustLedgEntry := DetailedCustLedgEntryApplied;
                                if TempDetailedCustLedgEntry.Insert() then;
                            end;
                        until DetailedCustLedgEntryApplied.Next() = 0;
                end;
            until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure IsPaymentDocumentType(CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        exit(
              CustLedgerEntry."Document Type" in [CustLedgerEntry."Document Type"::" ",
                                  CustLedgerEntry."Document Type"::Payment,
                                  CustLedgerEntry."Document Type"::Dishonored,
                                  CustLedgerEntry."Document Type"::"Credit Memo"]);
    end;
}

