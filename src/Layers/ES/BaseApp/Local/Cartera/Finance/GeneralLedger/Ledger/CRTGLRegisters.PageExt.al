// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.ReceivablesPayables;

pageextension 7000010 "CRT G/L Registers" extends "G/L Registers"
{
    actions
    {
        addlast("&Register")
        {
            separator(Action1100006)
            {
            }
            action("&Cartera Docs")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Cartera Docs';
                Image = "Order";
                ToolTip = 'View bills and invoices for customers and vendors. Bills are used by customers to pay invoices. They are sent to customers, who pay them under particular conditions on a specified date. Typically, the total amount of an invoice is divided into parts as bills are generated.';

                trigger OnAction()
                begin
                    GLRegDocs.Docs(Rec);
                end;
            }
            action("&Posted Cartera  Docs.")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Posted Cartera  Docs.';
                Image = PostedOrder;
                ToolTip = 'View posted bills and invoices for customers and vendors. Bills are used by customers to pay invoices. They are sent to customers, who pay them under particular conditions on a specified date. Typically, the total amount of an invoice is divided into parts as bills are generated.';

                trigger OnAction()
                begin
                    GLRegDocs.DocsinPostedBGPO(Rec);
                end;
            }
            action("Cl&osed Cartera Docs.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cl&osed Cartera Docs.';
                Image = Invoice;
                ToolTip = 'View completed bills and invoices for customers and vendors. Bills are used by customers to pay invoices. They are sent to customers, who pay them under particular conditions on a specified date. Typically, the total amount of an invoice is divided into parts as bills are generated.';

                trigger OnAction()
                begin
                    GLRegDocs.ClosedDocs(Rec);
                end;
            }
        }
    }

    var
        GLRegDocs: Codeunit "G/L Reg.-Docs.";
}
