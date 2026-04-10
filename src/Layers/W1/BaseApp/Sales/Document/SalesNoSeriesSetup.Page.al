// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

page 1401 "Sales No. Series Setup"
{
    Caption = 'Sales No. Series Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Sales & Receivables Setup";

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                InstructionalText = 'To fill the Document No. field automatically, you must set up a number series.';
                field("Quote Nos."; Rec."Quote Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales quotes. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = QuoteNosVisible;
                }
                field("Blanket Order Nos."; Rec."Blanket Order Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to blanket sales orders. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = BlanketOrderNosVisible;
                }
                field("Order Nos."; Rec."Order Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales orders. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = OrderNosVisible;
                }
                field("Return Order Nos."; Rec."Return Order Nos.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number series that is used to assign numbers to new sales return orders.';
                    Visible = ReturnOrderNosVisible;
                }
                field("Invoice Nos."; Rec."Invoice Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales invoices. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = InvoiceNosVisible;
                }
                field("Credit Memo Nos."; Rec."Credit Memo Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales credit memos. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = CrMemoNosVisible;
                }
                field("Reminder Nos."; Rec."Reminder Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to reminders. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = ReminderNosVisible;
                }
                field("Fin. Chrg. Memo Nos."; Rec."Fin. Chrg. Memo Nos.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to finance charge memos. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = FinChMemoNosVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales & Receivables Setup';
                Image = Setup;
                RunObject = Page "Sales & Receivables Setup";
                ToolTip = 'Define your general policies for sales invoicing and returns, such as when to show credit and stockout warnings and how to post sales discounts. Set up your number series for creating customers and different sales documents.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Setup_Promoted; Setup)
                {
                }
            }
        }
    }

    var
        QuoteNosVisible: Boolean;
        BlanketOrderNosVisible: Boolean;
        OrderNosVisible: Boolean;
        ReturnOrderNosVisible: Boolean;
        InvoiceNosVisible: Boolean;
        CrMemoNosVisible: Boolean;
        ReminderNosVisible: Boolean;
        FinChMemoNosVisible: Boolean;

    procedure SetFieldsVisibility(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo)
    begin
        QuoteNosVisible := (DocType = DocType::Quote);
        BlanketOrderNosVisible := (DocType = DocType::"Blanket Order");
        OrderNosVisible := (DocType = DocType::Order);
        ReturnOrderNosVisible := (DocType = DocType::"Return Order");
        InvoiceNosVisible := (DocType = DocType::Invoice);
        CrMemoNosVisible := (DocType = DocType::"Credit Memo");
        ReminderNosVisible := (DocType = DocType::Reminder);
        FinChMemoNosVisible := (DocType = DocType::FinChMemo);
    end;
}

