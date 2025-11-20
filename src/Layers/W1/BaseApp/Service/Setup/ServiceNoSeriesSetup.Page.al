// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

page 1403 "Service No. Series Setup"
{
    Caption = 'Service No. Series Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Service Mgt. Setup";

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                InstructionalText = 'To fill the Document No. field automatically, you must set up a number series.';
                field("Service Quote Nos."; Rec."Service Quote Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to service quotes. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = QuoteNosVisible;
                }
                field("Service Order Nos."; Rec."Service Order Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to service orders. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = OrderNosVisible;
                }
                field("Service Invoice Nos."; Rec."Service Invoice Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to service invoices. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = InvoiceNosVisible;
                }
                field("Service Credit Memo Nos."; Rec."Service Credit Memo Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to service credit memos. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = CrMemoNosVisible;
                }
                field("Service Contract Nos."; Rec."Service Contract Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to service contracts. To see the number series that have been set up in the No. Series table, click the field.';
                    Visible = ContractNosVisible;
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
                Caption = 'Service Management Setup';
                Image = Setup;
                RunObject = Page "Service Mgt. Setup";
                ToolTip = 'Define your general policies for service documents processing. Set up your number series for different service documents.';
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
        OrderNosVisible: Boolean;
        InvoiceNosVisible: Boolean;
        CrMemoNosVisible: Boolean;
        ContractNosVisible: Boolean;

    procedure SetFieldsVisibility(DocType: Option Quote,"Order",Invoice,"Credit Memo",Contract)
    begin
        QuoteNosVisible := (DocType = DocType::Quote);
        OrderNosVisible := (DocType = DocType::Order);
        InvoiceNosVisible := (DocType = DocType::Invoice);
        CrMemoNosVisible := (DocType = DocType::"Credit Memo");
        ContractNosVisible := (DocType = DocType::Contract);
    end;
}
