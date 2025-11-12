// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 599 "Payment Disc Tolerance Warning"
{
    Caption = 'Payment Discount Tolerance Warning';
    InstructionalText = 'An action is requested regarding the Payment Discount Tolerance Warning.';
    PageType = ConfirmationDialog;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            field(Posting; Posting)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'To handle the late payment discount, do you want to:';
                OptionCaption = ',Post as Payment Discount Tolerance?,Do Not Accept the Late Payment Discount?';
            }
            group(Details)
            {
                Caption = 'Details';
                InstructionalText = 'You can accept a late payment discount on the following document.';
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the document to be paid.';
                }
                field(CustVendNo; CustVendNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the record that the payment tolerance warning refers to.';
                }
                field(AccountName; AccountName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the customer or vendor.';
                }
                field(DocNo; DocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the document that the payment is for.';
                }
                field(CurrencyCode; CurrencyCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount that the payment tolerance warning refers to.';
                }
                field(AppliedAmount; AppliedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied Amount';
                    Editable = false;
                    ToolTip = 'Specifies the applied amount that the payment tolerance warning refers to.';
                }
                field(BalanceAmount; BalanceAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Editable = false;
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Posting := Posting::"Remaining Amount";

        if BalanceAmount = 0 then
            BalanceAmount := Amount + AppliedAmount;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::No then
            NoOnPush();
        if CloseAction = ACTION::Yes then
            YesOnPush();
    end;

    var
        Amount: Decimal;
        AppliedAmount: Decimal;
        BalanceAmount: Decimal;
        Posting: Option " ","Payment Tolerance Accounts","Remaining Amount";
        NewPostingAction: Integer;
        AccountName: Text;

    protected var
        PostingDate: Date;
        CustVendNo: Code[20];
        DocNo: Code[20];
        CurrencyCode: Code[10];

    procedure SetValues(ShowPostingDate: Date; ShowCustVendNo: Code[20]; ShowDocNo: Code[20]; ShowCurrencyCode: Code[10]; ShowAmount: Decimal; ShowAppliedAmount: Decimal; ShowBalance: Decimal)
    begin
        PostingDate := ShowPostingDate;
        CustVendNo := ShowCustVendNo;
        DocNo := ShowDocNo;
        CurrencyCode := ShowCurrencyCode;
        Amount := ShowAmount;
        AppliedAmount := ShowAppliedAmount;
        BalanceAmount := ShowBalance;
    end;

    procedure SetAccountName(NewAccountName: Text)
    begin
        AccountName := NewAccountName;
    end;

    procedure GetValues(var PostingAction: Integer)
    begin
        PostingAction := NewPostingAction
    end;

    local procedure YesOnPush()
    begin
        if Posting = Posting::"Payment Tolerance Accounts" then
            NewPostingAction := 1
        else
            if Posting = Posting::"Remaining Amount" then
                NewPostingAction := 2;
    end;

    local procedure NoOnPush()
    begin
        NewPostingAction := 3;
    end;

    procedure InitializeNewPostingAction(OptionValue: Integer)
    begin
        NewPostingAction := OptionValue;
    end;
}

