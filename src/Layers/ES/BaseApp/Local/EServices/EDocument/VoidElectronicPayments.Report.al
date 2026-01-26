// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;

report 10722 "Void Electronic Payments"
{
    Caption = 'Void Electronic Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.") where("Bank Payment Type" = const("Electronic Payment"), "Exported to Payment File" = const(true));

            trigger OnAfterGetRecord()
            var
                ElectPmtMgmt: Codeunit "Elect. Pmts Management";
            begin
                if not (("Account Type" = "Account Type"::Vendor) and ("Document Type" = "Document Type"::Payment) or
                        ("Account Type" = "Account Type"::Customer) and ("Document Type" = "Document Type"::Refund))
                then
                    CurrReport.Skip();

                if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                    if "Bal. Account No." <> BankAccount."No." then
                        Error(VoidElectronicPaymentErr, BankAccount.TableCaption());

                if FirstTime then begin
                    FileName := BankAccount."E-Pay Export File Path" + '\' + BankAccount."Last E-Pay Export File Name";
                    if Exists(FileName) then
                        Erase(FileName);
                    FirstTime := false;
                end;

                "Gen. Journal Line".TestField("Bank Payment Type", "Gen. Journal Line"."Bank Payment Type"::"Electronic Payment");
                "Gen. Journal Line".TestField("Exported to Payment File", true);
                "Gen. Journal Line".TestField("Document No.");
                if "Gen. Journal Line"."Bal. Account Type" = "Gen. Journal Line"."Bal. Account Type"::"Bank Account" then begin
                    "Gen. Journal Line".TestField("Bal. Account No.");
                    BankAccountNo := "Gen. Journal Line"."Bal. Account No.";
                end else
                    Error(Text1100002, "Gen. Journal Line".FieldCaption("Bal. Account Type"));
                ElectPmtMgmt.ProcessElectronicPayment("Gen. Journal Line"."Document No.", BankAccountNo);

                "Exported to Payment File" := false;
                "Export File Name" := '';
                "Document No." := '';

                Modify();
            end;

            trigger OnPreDataItem()
            begin
                if not FindFirst() then
                    Error(Text1100003);

                FirstTime := true;
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
                    field("BankAccount.""No."""; BankAccount."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the number of the bank account.';
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

    trigger OnPostReport()
    begin
        Message(Text1100004, FileName);
    end;

    trigger OnPreReport()
    begin
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Blocked, false);
        BankAccount.TestField("Currency Code", '');
        // local currency only
        if not Confirm(Text1100000, false, Text1100001, BankAccount.TableCaption(), BankAccount."No.") then
            CurrReport.Quit();
    end;

    var
        BankAccount: Record "Bank Account";
        FirstTime: Boolean;
        BankAccountNo: Code[20];
        Text1100000: Label 'Do you want to %1 all of the Electronic Payments written against %2 %3?';
        Text1100001: Label 'Void';
        FileName: Text[250];
        Text1100002: Label '%1 must refer to a Bank Account.';
        Text1100003: Label 'There is nothing to Void.';
        Text1100004: Label 'The exported Electronic Payment File %1 has been voided. To post the Payment Lines you must first export the Electronic Payment File again.';
        VoidElectronicPaymentErr: Label 'The exported  Electronic Payment can only be voided if you use the same %1 that was used for exporting the payment.';
}

