// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.ReceivablesPayables;

report 7000061 "Void PO - Export"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Void PO - Export';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Payment Order"; "Payment Order")
        {
            DataItemTableView = sorting("No.") where("Elect. Pmts Exported" = const(true));
            dataitem("Cartera Doc."; "Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                DataItemTableView = sorting(Type, "Bill Gr./Pmt. Order No.", "Category Code", "Currency Code", Accepted, "Due Date");

                trigger OnAfterGetRecord()
                var
                    ElectPmtMgmt: Codeunit "Elect. Pmts Management";
                begin
                    TestField("Elect. Pmts Exported", true);
                    TestField("Document No.");
                    ElectPmtMgmt.ProcessElectronicPayment("Document No.", "Payment Order"."Bank Account No.");

                    "Elect. Pmts Exported" := false;
                    "Export File Name" := '';
                    Modify();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if FirstTime then begin
                    BankAccount.Get("Bank Account No.");
                    "Cartera Doc.".SetRange(Type, "Cartera Doc.".Type::Payable);
                    "Cartera Doc.".SetRange("Bill Gr./Pmt. Order No.", "No.");
                    if "Cartera Doc.".FindFirst() then
                        FileName := "Cartera Doc."."Export File Name";
                    if Exists(FileName) then
                        Erase(FileName);
                    FirstTime := false;
                end;
                TestField("Bank Account No.");

                "Elect. Pmts Exported" := false;
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("No.", "No.");

                if not FindFirst() then
                    Error(Text1100002);

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
                    field(PaymentOrderNo; "Payment Order"."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Order No.';
                        TableRelation = "Payment Order";
                        ToolTip = 'Specifies the number of the payment order.';
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
        Message(Text1100001, FileName);
    end;

    trigger OnPreReport()
    begin
        "Payment Order".Get("Payment Order"."No.");
        BankAccount.Get("Payment Order"."Bank Account No.");
        BankAccount.TestField("Currency Code", '');
        if not Confirm(Text1100000, false, "Payment Order"."No.", BankAccount.TableCaption(), BankAccount."No.") then
            CurrReport.Quit();
    end;

    var
        BankAccount: Record "Bank Account";
        FirstTime: Boolean;
        FileName: Text[250];
        Text1100000: Label 'Are you SURE you want to Void all of the Cartera Electronic Payments in Order %1 written against %2 %3?';
        Text1100001: Label 'The exported Electronic Payment File %1 has been voided. To post the Payment Order you must first export the Electronic Payment File again.';
        Text1100002: Label 'There is nothing to Void.';
}
