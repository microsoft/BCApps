// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Warning dialog page for handling payment tolerance situations during payment application.
/// Provides user options for managing balance amounts when payments exceed or fall short of invoice amounts within tolerance limits.
/// </summary>
/// <remarks>
/// Interactive confirmation dialog presented when payment applications result in balance amounts within payment tolerance thresholds.
/// Offers options to post balance as payment tolerance or leave as remaining amount for future application.
/// Displays detailed calculation breakdown showing applied amounts, tolerance calculations, and resulting balances.
/// Integrates with payment tolerance management system for consistent handling across application scenarios.
/// </remarks>
page 591 "Payment Tolerance Warning"
{
    Caption = 'Payment Tolerance Warning';
    InstructionalText = 'An action is requested regarding the Payment Tolerance Warning.';
    PageType = ConfirmationDialog;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            field(Posting; Posting)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Regarding the Balance amount, do you want to:';
                OptionCaption = ',Post the Balance as Payment Tolerance?,Leave a Remaining Amount?';

                trigger OnValidate()
                begin
                    UpdateAmounts();
                end;
            }
            group(Details)
            {
                Caption = 'Details';
                group(Control1)
                {
                    InstructionalText = 'Posting this application will create an outstanding balance. You can close all entries by posting the balance as a payment tolerance amount.';
                    //The GridLayout property is only supported on controls of type Grid
                    //GridLayout = Rows;
                    ShowCaption = false;
                    Visible = Posting = Posting::"Payment Tolerance Accounts";
                }
                group(Control4)
                {
                    InstructionalText = 'Posting this application will be handled as a partial payment with a remaining balance. The document will not be closed.';
                    ShowCaption = false;
                    Visible = Posting = Posting::"Remaining Amount";
                }
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
                field(ApplyingAmount; ApplyingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = CurrencyCode;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount that the payment tolerance warning refers to.';
                }
                field(AppliedAmount; AppliedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = CurrencyCode;
                    Caption = 'Applied Amount';
                    Editable = false;
                    ToolTip = 'Specifies the applied amount that the payment tolerance warning refers to.';
                }
                field(BalanceAmount; BalanceAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = CurrencyCode;
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
        OnOpenPageOnBeforeUpdateAmounts(Posting);

        UpdateAmounts();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::No then
            NoOnPush();
        if CloseAction = ACTION::Yes then
            YesOnPush();
    end;

    var
        OriginalApplyingAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AppliedAmount: Decimal;
        BalanceAmount: Decimal;
        Posting: Option " ","Payment Tolerance Accounts","Remaining Amount";
        NewPostingAction: Integer;
        AccountName: Text;

    protected var
        CustVendNo: Code[20];
        PostingDate: Date;
        DocNo: Code[20];
        CurrencyCode: Code[10];

    /// <summary>
    /// Sets the display values for the payment tolerance warning dialog.
    /// </summary>
    /// <param name="ShowPostingDate">Posting date for the transaction</param>
    /// <param name="ShowCustVendNo">Customer or vendor number</param>
    /// <param name="ShowDocNo">Document number</param>
    /// <param name="ShowCurrencyCode">Currency code for amounts</param>
    /// <param name="ShowAmount">Original applying amount</param>
    /// <param name="ShowAppliedAmount">Original applied amount</param>
    /// <param name="ShowBalance">Balance amount requiring tolerance decision</param>
    procedure SetValues(ShowPostingDate: Date; ShowCustVendNo: Code[20]; ShowDocNo: Code[20]; ShowCurrencyCode: Code[10]; ShowAmount: Decimal; ShowAppliedAmount: Decimal; ShowBalance: Decimal)
    var
        BalAmount: Decimal;
    begin
        Clear(BalAmount);
        PostingDate := ShowPostingDate;
        CustVendNo := ShowCustVendNo;
        DocNo := ShowDocNo;
        CurrencyCode := ShowCurrencyCode;
        OriginalApplyingAmount := ShowAmount;
        OriginalAppliedAmount := ShowAppliedAmount;
        BalAmount := ShowBalance;
    end;

    /// <summary>
    /// Sets the account name displayed in the payment tolerance warning dialog.
    /// </summary>
    /// <param name="NewAccountName">Account name to display</param>
    procedure SetAccountName(NewAccountName: Text)
    begin
        AccountName := NewAccountName;
    end;

    /// <summary>
    /// Returns the user's posting action selection from the payment tolerance warning dialog.
    /// </summary>
    /// <param name="PostingAction">Selected posting action (1=Payment Tolerance, 2=Remaining Amount, 3=Cancel)</param>
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

    /// <summary>
    /// Initializes the posting action option value for the payment tolerance warning dialog.
    /// </summary>
    /// <param name="OptionValue">Initial posting action option value</param>
    procedure InitializeOption(OptionValue: Integer)
    begin
        NewPostingAction := OptionValue;
    end;

    local procedure UpdateAmounts()
    begin
        case Posting of
            Posting::"Payment Tolerance Accounts":
                begin
                    ApplyingAmount := OriginalApplyingAmount;
                    AppliedAmount := OriginalAppliedAmount;
                    BalanceAmount := 0;
                end;
            Posting::"Remaining Amount":
                begin
                    if Abs(OriginalApplyingAmount) < Abs(OriginalAppliedAmount) then begin
                        ApplyingAmount := OriginalApplyingAmount;
                        AppliedAmount := -OriginalApplyingAmount;
                    end else begin
                        ApplyingAmount := -OriginalAppliedAmount;
                        AppliedAmount := OriginalAppliedAmount;
                    end;
                    BalanceAmount := OriginalApplyingAmount + OriginalAppliedAmount;
                end;
        end;
    end;

    /// <summary>
    /// Integration event raised before updating amounts on page open for payment tolerance processing.
    /// </summary>
    /// <param name="Posting">Posting option value for tolerance handling</param>
    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeUpdateAmounts(var Posting: Option " ","Payment Tolerance Accounts","Remaining Amount")
    begin
    end;

}

