// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Bank.Reports;
using Microsoft.Purchases.Setup;
using System.Telemetry;

page 32000006 "Bank Payments to send"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Payments to send';
    DelayedInsert = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "Ref. Payment - Exported";
    SourceTableView = sorting("Payment Date", "Vendor No.", "Entry No.")
                      where(Transferred = const(false),
                            "Applied Payments" = const(false));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a vendor number for the reference payment.';
                }
                field(Description2; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the reference payment.';
                }
                field("Payment Account"; Rec."Payment Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment account for the reference payment.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value to filter by entry number.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of the purchase invoice.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment will be debited from the bank account.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document type.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the reference payment.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a currency code for the reference payment.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payable amount.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, in local currency, for the reference payment.';
                }
                field("Vendor Account"; Rec."Vendor Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a vendor account for the reference payment.';
                }
                field("SEPA Payment"; Rec."SEPA Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if Single Euro Payment Area (SEPA) payments are displayed for the reference payment.';
                }
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a message type.';
                }
                field("Invoice Message"; Rec."Invoice Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an invoice message for the reference payment.';
                }
                field("Foreign Payment"; Rec."Foreign Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the reference payment is a foreign payment.';
                }
                field("Foreign Payment Method"; Rec."Foreign Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the foreign payment method for the reference payment.';
                }
                field("Foreign Banks Service Fee"; Rec."Foreign Banks Service Fee")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payment method code for the foreign bank service fee.';
                }
            }
            group(Control24)
            {
                ShowCaption = false;
                field("Summa (PVA)"; TotalAmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1090005; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("Document No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Payments")
            {
                Caption = '&Payments';
                action("&Suggest Vendor Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Vendor Payments';
                    Ellipsis = true;
                    Image = SuggestVendorPayments;
                    ToolTip = 'Process open vendor ledger entries on posting invoices, finance charge memos, credit memos, and payments to create payment suggestions as lines in a payment journal. Entries that are marked as On Hold are not included. You can include payments with discounts. You can also use the combine foreign payments feature to post transactions as a bundle.';

                    trigger OnAction()
                    begin
                        CreateRefPmtSuggestion.RunModal();
                        Clear(CreateRefPmtSuggestion);
                    end;
                }
                action("Combine &Domestic Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Combine &Domestic Payments';
                    Image = GeneralPostingSetup;
                    ToolTip = 'Combine all domestic payments into one recipient from one day for the same bank account.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        RefPmtMgt.CombineVendPmt(PaymentType::Domestic);
                    end;
                }
                action("Combine &Foreign Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Combine &Foreign Payments';
                    Image = GeneralPostingSetup;
                    ToolTip = 'Combine all domestic payments into one recipient from one day for the same bank account.';

                    trigger OnAction()
                    begin
                        if Confirm(Text002) then
                            RefPmtMgt.CombineVendPmt(PaymentType::Foreign);
                    end;
                }
                action("&Combine SEPA Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Combine SEPA Payments';
                    Image = GeneralPostingSetup;
                    ToolTip = 'Combine all SEPA payments into one recipient from one day for the same bank account.';

                    trigger OnAction()
                    begin
                        if Confirm(Text003) then
                            RefPmtMgt.CombineVendPmt(PaymentType::SEPA);
                    end;
                }
                action("&Print Payment Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Print Payment Report';
                    Image = PrintForm;
                    RunObject = Report Payment;
                    ToolTip = 'View outbound payments after a payment has been selected. The report itemizes outbound payments by settlement account and is sorted by the payment date.';
                }
            }
            group("&Transfer files")
            {
                Caption = '&Transfer files';
                action("Domestic payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Domestic payments';
                    Image = TransmitElectronicDoc;
                    ToolTip = 'Create a payment file for domestic payments.';

                    trigger OnAction()
                    begin
                        FeatureTelemetry.LogUptake('1000HN6', FIBankTok, Enum::"Feature Uptake Status"::"Used");
                        if Confirm(Text001) then
                            CreateLMPFile.Run();
                        Clear(CreateLMPFile);
                        FeatureTelemetry.LogUsage('1000HN7', FIBankTok, 'FI Electronic Banking Domestic Payments Created');
                    end;
                }
                action("Foreign payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Foreign payments';
                    Image = TransmitElectronicDoc;
                    ToolTip = 'Create a payment file for foreign payments.';

                    trigger OnAction()
                    begin
                        FeatureTelemetry.LogUptake('1000HN8', FIBankTok, Enum::"Feature Uptake Status"::"Used");
                        if Confirm(Text001) then
                            CreateLUMFile.Run();
                        Clear(CreateLUMFile);
                        FeatureTelemetry.LogUsage('1000HN9', FIBankTok, 'FI Electronic Banking Foreign Payments Created');
                    end;
                }
                action("SEPA Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SEPA Payments';
                    Image = TransmitElectronicDoc;
                    ToolTip = 'Create a payment file for SEPA payments.';

                    trigger OnAction()
                    var
                    begin
                        FeatureTelemetry.LogUptake('1000HO0', FIBankTok, Enum::"Feature Uptake Status"::"Used");
                        Rec.ExportToFile();
                        FeatureTelemetry.LogUsage('1000HO1', FIBankTok, 'FI Electronic Banking SEPA Payments Created');
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Suggest Vendor Payments_Promoted"; "&Suggest Vendor Payments")
                {
                }
                actionref("Combine &Foreign Payments_Promoted"; "Combine &Foreign Payments")
                {
                }
                actionref("&Combine SEPA Payments_Promoted"; "&Combine SEPA Payments")
                {
                }
                actionref("&Print Payment Report_Promoted"; "&Print Payment Report")
                {
                }
                actionref("Domestic payments_Promoted"; "Domestic payments")
                {
                }
                actionref("Foreign payments_Promoted"; "Foreign payments")
                {
                }
                actionref("SEPA Payments_Promoted"; "SEPA Payments")
                {
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        UpdateBalance();
        if Rec."Affiliated to Line" <> 0 then begin
            PurchRefLines.Reset();
            PurchRefLines.SetRange("Affiliated to Line", Rec."Affiliated to Line");
            PurchRefLines.DeleteAll();
        end;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdateBalance();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PurchRefLines.Reset();
        if PurchRefLines.FindLast() then
            Rec."No." := PurchRefLines."No." + 1
        else
            Rec."No." := 0;
        UpdateBalance();
    end;

    trigger OnOpenPage()
    begin
        UpdateBalance();
        PurchSetup.Get();
        PurchSetup.TestField("Bank Batch Nos.");
    end;

    var
        PurchRefLines: Record "Ref. Payment - Exported";
        PurchSetup: Record "Purchases & Payables Setup";
        CreateLMPFile: Report "Export Ref. Payment -  LMP";
        CreateLUMFile: Report "Export Ref. Payment -  LUM";
        RefPmtMgt: Codeunit "Ref. Payment Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CreateRefPmtSuggestion: Report "Suggest Bank Payments";
        TotalAmountLCY: Decimal;
        Text001: Label 'Do you want to create the payment file?';
        Text002: Label 'Do you want to combine foreign payments?';
        Text003: Label 'Do you want to combine SEPA payments?';
        FIBankTok: Label 'FI Electronic Banking', Locked = true;
        PaymentType: Option Domestic,Foreign,SEPA;

    local procedure UpdateBalance()
    begin
        PurchRefLines.Reset();
        PurchRefLines.SetCurrentKey(Transferred);
        PurchRefLines.SetRange(Transferred, false);
        PurchRefLines.SetRange("Applied Payments", false);
        PurchRefLines.CalcSums("Amount (LCY)");
        TotalAmountLCY := PurchRefLines."Amount (LCY)";
    end;
}

