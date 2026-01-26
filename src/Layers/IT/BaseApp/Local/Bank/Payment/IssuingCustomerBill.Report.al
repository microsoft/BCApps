// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Receivables;

report 12180 "Issuing Customer Bill"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Issue Bank Receipts';
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd;
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = order(ascending);
            RequestFilterFields = "Customer No.", "Due Date";

            trigger OnAfterGetRecord()
            var
                NoSeries: Codeunit "No. Series";
            begin
                Window.Update(1, "Customer No.");
                Window.Update(2, "Document No.");
                CalcFields("Remaining Amount", "Remaining Amt. (LCY)");

                BankReceiptToIssue := BankReceiptToIssue + 1;

                GenJnlLine.Init();
                GenJnlLine.Validate("Posting Date", PostingDate);
                GenJnlLine."Document Date" := DocumentDate;
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;

                GetBillCode("Payment Method Code");

                BillCode.TestField("Temporary Bill No.");

                GenJnlLine."Document No." := NoSeries.GetNextNo(BillCode."Temporary Bill No.", GenJnlLine."Posting Date");

                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
                GenJnlLine.Validate("Account No.", "Customer No.");

                if BillCode."Bills for Coll. Temp. Acc. No." = '' then
                    Error(Text1130015,
                      BillCode.FieldCaption("Bills for Coll. Temp. Acc. No."),
                      BillCode.Code,
                      BillCode.TableCaption());

                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                GenJnlLine.Validate("Bal. Account No.", BillCode."Bills for Coll. Temp. Acc. No.");
                GenJnlLine.Description := PostingDescription;
                GenJnlLine."Source Code" := BillCode."Bill Source Code";
                GenJnlLine."Reason Code" := BillCode."Reason Code Cust. Bill";
                Window.Update(3, GenJnlLine."Document No.");
                GenJnlLine."External Document No." := "External Document No.";
                GenJnlLine.Validate("Currency Code", "Currency Code");
                GenJnlLine.Validate(Amount, -1 * "Remaining Amount");
                GenJnlLine."Amount (LCY)" := -1 * "Remaining Amt. (LCY)";
                GenJnlLine."Document Type to Close" := "Document Type";
                GenJnlLine."Document No. to Close" := "Document No.";
                GenJnlLine."Document Occurrence to Close" := "Document Occurrence";
                GenJnlLine."Allow Application" := true;
                GenJnlLine."Bank Receipt" := true;
                GenJnlLine."Allow Issue" := "Allow Issue";
                GenJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := "Dimension Set ID";
                GenJnlLine."Due Date" := "Due Date";
                GenJnlLine."Payment Method Code" := "Payment Method Code";

                GenJnlLine."Salespers./Purch. Code" := "Salesperson Code";
                "Bank Receipt Issued" := true;
                "Bank Receipt Temp. No." := GenJnlLine."Document No.";
                Modify();

                DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", "Entry No.");
                DetailedCustLedgEntry.FindFirst();
                DetailedCustLedgEntry."Bank Receipt Issued" := true;
                DetailedCustLedgEntry.Modify();

                GenJnlPostLine.SetCheckDim(CheckDim);
                if not CheckDim then
                    GenJnlPostLine.RunWithCheck(GenJnlLine)
                else
                    GenJnlPostLine.RunWithoutCheck(GenJnlLine);
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text001);

                SetCurrentKey(Open, "Document Type", "Allow Issue", "Bank Receipt Issued", "Currency Code");
                SetRange(Open, true);
                SetRange("Document Type", "Document Type"::Invoice);
                SetRange("Allow Issue", true);
                SetRange("Bank Receipt Issued", false);
                SetRange("Currency Code", '');
                SetCurrentKey("Entry No.");
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
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date.';
                    }
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the posting description.';
                    }
                    field(DoNotCheckDimensions; CheckDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Do Not Check Dimensions';
                        ToolTip = 'Specifies if you do not want to check the dimensions.';
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

    trigger OnInitReport()
    begin
        PostingDate := WorkDate();
        DocumentDate := WorkDate();
    end;

    trigger OnPostReport()
    begin
        if BankReceiptToIssue <> 0 then begin
            if not DisableMessage then
                Message(Text1130016,
                  BankReceiptToIssue)
        end else
            Error(Text1130017);
    end;

    trigger OnPreReport()
    begin
        if DocumentDate > PostingDate then
            Error(Text1130004);

        if PostingDescription = '' then
            Error(Text1130005);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        PaymentMethod: Record "Payment Method";
        BillCode: Record Bill;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        PostingDate: Date;
        DocumentDate: Date;
        PostingDescription: Text[30];
        Text1130004: Label 'Document Date must be greater than Posting Date.';
        Text1130005: Label 'Please specify Posting Description.';
        BankReceiptToIssue: Integer;
        Text1130011: Label '%1 %2 does not exist in %3 table.';
        Text1130012: Label '%1 is not specified for %2 %3.';
        Text1130015: Label 'Please specify %1 for %2 in table %3.';
        Text1130016: Label '%1 customer bills have been issued.';
        Text1130017: Label 'There are no customer bills to issue.';
        CheckDim: Boolean;
        DisableMessage: Boolean;
        Text001: Label 'Issuing Customer Bill...\\Customer No.       #1##################\Document No.       #2##################\Temporary Bill No. #3##################';

    [Scope('OnPrem')]
    procedure GetBillCode(PaymentMethodCode: Code[20])
    begin
        if not PaymentMethod.Get(PaymentMethodCode) then
            Error(Text1130011,
              PaymentMethod.FieldCaption(Code),
              PaymentMethod.Code,
              PaymentMethod.TableCaption());

        if not BillCode.Get(PaymentMethod."Bill Code") then
            Error(Text1130012,
              PaymentMethod.FieldCaption("Bill Code"),
              PaymentMethod.TableCaption(),
              PaymentMethod.Code);
    end;

    [Scope('OnPrem')]
    procedure SetPostingDescription(PostingDescr: Text[30])
    begin
        PostingDescription := PostingDescr;
    end;

    [Scope('OnPrem')]
    procedure SetMessageDisabled(DisableMsg: Boolean)
    begin
        DisableMessage := DisableMsg;
    end;
}

