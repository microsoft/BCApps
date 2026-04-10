// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;

/// <summary>
/// Displays a confirmation dialog when customer credit limits or overdue balances are exceeded.
/// </summary>
page 343 "Check Credit Limit"
{
    Caption = 'Check Credit Limit';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    InstructionalText = 'An action is requested regarding the Credit Limit check.';
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            label(Control2)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(StrSubstNo(Text000, Heading));
                MultiLine = true;
                ShowCaption = false;
            }
            field(HideMessage; HideMessage)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Do not show this message again.';
                ToolTip = 'Specifies to no longer show this message when working with this document while the customer is over credit limit';
                Visible = HideMessageVisible;
            }
            part(CreditLimitDetails; "Credit Limit Details")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Customer")
            {
                Caption = '&Customer';
                Image = Customer;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View details for the selected record.';
                }
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Customer Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistics for credit limit entries.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcCreditLimitLCY();
        CalcOverdueBalanceLCY();

        SetParametersOnDetails();
    end;

    trigger OnOpenPage()
    begin
        Rec.Copy(Cust2);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 Do you still want to record the amount?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        CurrExchRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Cust2: Record Customer;
        SalesSetup: Record "Sales & Receivables Setup";
        CustNo: Code[20];
        Heading: Text[250];
        SecondHeading: Text[250];
        NotificationId: Guid;
        DeltaAmount: Decimal;
        NewOrderAmountLCY: Decimal;
        OldOrderAmountLCY: Decimal;
        OrderAmountThisOrderLCY: Decimal;
        OrderAmountTotalLCY: Decimal;
        CustCreditAmountLCY: Decimal;
        ShippedRetRcdNotIndLCY: Decimal;
        OutstandingRetOrdersLCY: Decimal;
        RcdNotInvdRetOrdersLCY: Decimal;
        HideMessage: Boolean;
        HideMessageVisible: Boolean;
        ExtensionAmountsDic: Dictionary of [Guid, Decimal];

    /// <summary>
    /// Checks if a credit limit warning should be shown for a general journal line.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to check.</param>
    /// <returns>True if a warning should be shown, otherwise false.</returns>
    [Scope('OnPrem')]
    procedure GenJnlLineShowWarning(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        OnBeforeGenJnlLineShowWarning(GenJnlLine, IsHandled, Result, Rec);
        if IsHandled then
            exit(Result);

        SalesSetup.Get();
        if SalesSetup."Credit Warnings" =
           SalesSetup."Credit Warnings"::"No Warning"
        then
            exit(false);
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then
            exit(ShowWarning(GenJnlLine."Account No.", GenJnlLine."Amount (LCY)", 0, true));
        exit(ShowWarning(GenJnlLine."Bal. Account No.", -GenJnlLine.Amount, 0, true));
    end;

    /// <summary>
    /// Checks if a credit limit warning should be shown for a general journal line and returns the notification cause.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to check.</param>
    /// <param name="NotificationContextGuidOut">Returns the GUID identifying the notification cause.</param>
    /// <returns>True if a warning should be shown, otherwise false.</returns>
    [Scope('OnPrem')]
    procedure GenJnlLineShowWarningAndGetCause(GenJnlLine: Record "Gen. Journal Line"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := GenJnlLineShowWarning(GenJnlLine);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;

    /// <summary>
    /// Checks if a credit limit warning should be shown for a sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <returns>True if a warning should be shown, otherwise false.</returns>
    procedure SalesHeaderShowWarning(SalesHeader: Record "Sales Header") Result: Boolean
    var
        OldSalesHeader: Record "Sales Header";
        AssignDeltaAmount: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesHeaderShowWarning(SalesHeader, Result, IsHandled, Rec, DeltaAmount);
        if IsHandled then
            exit(Result);

        // Used when additional lines are inserted
        SalesSetup.Get();
        if SalesSetup."Credit Warnings" =
           SalesSetup."Credit Warnings"::"No Warning"
        then
            exit(false);
        CalcSalesHeaderNewOrderAmountLCY(SalesHeader);

        if not (SalesHeader."Document Type" in
                [SalesHeader."Document Type"::Quote,
                 SalesHeader."Document Type"::Order,
                 SalesHeader."Document Type"::"Return Order"])
        then
            NewOrderAmountLCY := NewOrderAmountLCY + SalesLineAmount(SalesHeader."Document Type", SalesHeader."No.");
        OnSalesHeaderShowWarningOnAfterAssingNewOrderAmountLCY(SalesHeader, NewOrderAmountLCY);

        OldSalesHeader := SalesHeader;
        if OldSalesHeader.Find() then
            // If "Bill-To Customer" is the same and Sales Header exists then do not consider amount in credit limit calculation since it's already included in "Outstanding Amount"
            // If "Bill-To Customer" was changed the consider amount in credit limit calculation since changes was not yet commited and not included in "Outstanding Amount"
            AssignDeltaAmount := OldSalesHeader."Bill-to Customer No." <> SalesHeader."Bill-to Customer No."
        else
            // If Sales Header is not inserted yet then consider the amount in credit limit calculation
            AssignDeltaAmount := true;
        if AssignDeltaAmount then
            DeltaAmount := NewOrderAmountLCY;
        exit(ShowWarning(SalesHeader."Bill-to Customer No.", NewOrderAmountLCY, 0, true));
    end;

    local procedure CalcSalesHeaderNewOrderAmountLCY(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcSalesHeaderNewOrderAmountLCY(Rec, SalesHeader, NewOrderAmountLCY, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Currency Code" = '' then
            NewOrderAmountLCY := SalesHeader."Amount Including VAT"
        else
            NewOrderAmountLCY :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  WorkDate(), SalesHeader."Currency Code",
                  SalesHeader."Amount Including VAT", SalesHeader."Currency Factor"));
    end;

    /// <summary>
    /// Checks if a credit limit warning should be shown for a sales header and returns the notification cause.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <param name="NotificationContextGuidOut">Returns the GUID identifying the notification cause.</param>
    /// <returns>True if a warning should be shown, otherwise false.</returns>
    procedure SalesHeaderShowWarningAndGetCause(SalesHeader: Record "Sales Header"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := SalesHeaderShowWarning(SalesHeader);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;

    /// <summary>
    /// Checks if a credit limit warning should be shown for a sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <returns>True if a warning should be shown, otherwise false.</returns>
    procedure SalesLineShowWarning(SalesLine: Record "Sales Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineShowWarning(SalesLine, Result, IsHandled, Rec, DeltaAmount);
        if IsHandled then
            exit(Result);

        SalesSetup.Get();
        if SalesSetup."Credit Warnings" =
           SalesSetup."Credit Warnings"::"No Warning"
        then
            exit(false);
        if (SalesHeader."Document Type" <> SalesLine."Document Type") or
           (SalesHeader."No." <> SalesLine."Document No.")
        then
            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CalcSalesLineOrderAmountsLCY(SalesLine);

        DeltaAmount := NewOrderAmountLCY - OldOrderAmountLCY;
        NewOrderAmountLCY :=
          DeltaAmount + SalesLineAmount(SalesLine."Document Type", SalesLine."Document No.");

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
            DeltaAmount := NewOrderAmountLCY;

        exit(ShowWarning(SalesHeader."Bill-to Customer No.", NewOrderAmountLCY, OldOrderAmountLCY, false))
    end;

    local procedure CalcSalesLineOrderAmountsLCY(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcSalesLineOrderAmountsLCY(Rec, SalesLine, NewOrderAmountLCY, OldOrderAmountLCY, IsHandled);
        if IsHandled then
            exit;

        NewOrderAmountLCY := SalesLine."Outstanding Amount (LCY)" + SalesLine."Shipped Not Invoiced (LCY)";

        if SalesLine.Find() then
            OldOrderAmountLCY := SalesLine."Outstanding Amount (LCY)" + SalesLine."Shipped Not Invoiced (LCY)"
        else
            OldOrderAmountLCY := 0;
    end;

    /// <summary>
    /// Checks if a credit limit warning should be shown for a sales line and returns the notification cause.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <param name="NotificationContextGuidOut">Returns the GUID identifying the notification cause.</param>
    /// <returns>True if a warning should be shown, otherwise false.</returns>
    [Scope('OnPrem')]
    procedure SalesLineShowWarningAndGetCause(SalesLine: Record "Sales Line"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := SalesLineShowWarning(SalesLine);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;







    local procedure SalesLineAmount(DocType: Enum "Sales Document Type"; DocNo: Code[20]) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineAmount(Rec, DocType, DocNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.CalcSums("Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)");
        exit(SalesLine."Outstanding Amount (LCY)" + SalesLine."Shipped Not Invoiced (LCY)");
    end;

    /// <summary>
    /// Evaluates credit limit and overdue balance and determines if a warning should be displayed.
    /// </summary>
    /// <param name="NewCustNo">The customer number to check.</param>
    /// <param name="NewOrderAmountLCY2">The new order amount in local currency.</param>
    /// <param name="OldOrderAmountLCY2">The old order amount in local currency.</param>
    /// <param name="CheckOverDueBalance">Indicates whether to also check the overdue balance.</param>
    /// <returns>True if a warning should be shown, otherwise false.</returns>
    procedure ShowWarning(NewCustNo: Code[20]; NewOrderAmountLCY2: Decimal; OldOrderAmountLCY2: Decimal; CheckOverDueBalance: Boolean) Result: Boolean
    var
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
        ExitValue: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowWarning(
            Rec, NewOrderAmountLCY, OldOrderAmountLCY, OrderAmountTotalLCY, ShippedRetRcdNotIndLCY, CustCreditAmountLCY, DeltaAmount,
            CheckOverDueBalance, Heading, Result, IsHandled, NotificationId, NewCustNo, NewOrderAmountLCY2, OldOrderAmountLCY2, OrderAmountThisOrderLCY);
        if IsHandled then
            exit(Result);

        if NewCustNo = '' then
            exit;
        CustNo := NewCustNo;
        NewOrderAmountLCY := NewOrderAmountLCY2;
        OldOrderAmountLCY := OldOrderAmountLCY2;
        Rec.Get(CustNo);
        Rec.SetRange("No.", Rec."No.");
        Cust2.Copy(Rec);

        SalesSetup.Get();
        if (SalesSetup."Credit Warnings" in
            [SalesSetup."Credit Warnings"::"Both Warnings",
             SalesSetup."Credit Warnings"::"Credit Limit"]) and
           CustCheckCrLimit.IsCreditLimitNotificationEnabled(Rec)
        then begin
            CalcCreditLimitLCY();
            if (CustCreditAmountLCY > Rec."Credit Limit (LCY)") and (Rec."Credit Limit (LCY)" <> 0) then
                ExitValue := 1;
            OnShowWarningOnAfterCalcCreditLimitLCYExitValue(Rec, CustCreditAmountLCY, ExitValue);
        end;
        if CheckOverDueBalance and
           (SalesSetup."Credit Warnings" in
            [SalesSetup."Credit Warnings"::"Both Warnings",
             SalesSetup."Credit Warnings"::"Overdue Balance"]) and
           CustCheckCrLimit.IsOverdueBalanceNotificationEnabled(Rec)
        then begin
            CalcOverdueBalanceLCY();
            if Rec."Balance Due (LCY)" > 0 then
                ExitValue := ExitValue + 2;
            OnShowWarningOnAfterCalcDueBalanceExitValue(Rec, ExitValue);
        end;

        IsHandled := false;
        OnShowWarningOnBeforeExitValue(Rec, ExitValue, Result, IsHandled, Heading, SecondHeading, NotificationId);
        if IsHandled then
            exit(Result);

        if ExitValue > 0 then begin
            case ExitValue of
                1:
                    begin
                        Heading := CopyStr(CustCheckCrLimit.GetCreditLimitNotificationMsg(), 1, 250);
                        NotificationId := CustCheckCrLimit.GetCreditLimitNotificationId();
                    end;
                2:
                    begin
                        Heading := CopyStr(CustCheckCrLimit.GetOverdueBalanceNotificationMsg(), 1, 250);
                        NotificationId := CustCheckCrLimit.GetOverdueBalanceNotificationId();
                    end;
                3:
                    begin
                        Heading := CopyStr(CustCheckCrLimit.GetCreditLimitNotificationMsg(), 1, 250);
                        SecondHeading := CopyStr(CustCheckCrLimit.GetOverdueBalanceNotificationMsg(), 1, 250);
                        NotificationId := CustCheckCrLimit.GetBothNotificationsId();
                    end;
            end;
            exit(true);
        end;
    end;

    local procedure CalcCreditLimitLCY()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCreditLimitLCY(
            Cust2, OutstandingRetOrdersLCY, RcdNotInvdRetOrdersLCY, NewOrderAmountLCY, OrderAmountTotalLCY, OrderAmountThisOrderLCY,
            ShippedRetRcdNotIndLCY, CustCreditAmountLCY, CustNo, ExtensionAmountsDic, IsHandled, DeltaAmount, Rec);
        if not IsHandled then begin
            if Rec.GetFilter("Date Filter") = '' then
                Rec.SetFilter("Date Filter", '..%1', WorkDate());
            Rec.CalcFields("Balance (LCY)", "Shipped Not Invoiced (LCY)");
            CalcReturnAmounts(OutstandingRetOrdersLCY, RcdNotInvdRetOrdersLCY);

            OrderAmountTotalLCY := CalcTotalOutstandingAmt() - OutstandingRetOrdersLCY + DeltaAmount;
            ShippedRetRcdNotIndLCY := Rec."Shipped Not Invoiced (LCY)" - RcdNotInvdRetOrdersLCY;
            if Rec."No." = CustNo then
                OrderAmountThisOrderLCY := NewOrderAmountLCY
            else
                OrderAmountThisOrderLCY := 0;

            CustCreditAmountLCY :=
              Rec."Balance (LCY)" + Rec."Shipped Not Invoiced (LCY)" - RcdNotInvdRetOrdersLCY +
              OrderAmountTotalLCY - Rec.GetInvoicedPrepmtAmountLCY();
            OnCalcCreditLimitLCYOnAfterCalcAmounts(Rec, ShippedRetRcdNotIndLCY, CustCreditAmountLCY);
        end;

        OnAfterCalcCreditLimitLCYProcedure(Rec, CustCreditAmountLCY, ExtensionAmountsDic);
    end;

    local procedure CalcOverdueBalanceLCY()
    begin
        if Rec.GetFilter("Date Filter") = '' then
            Rec.SetFilter("Date Filter", '..%1', WorkDate());
        OnCalcOverdueBalanceLCYAfterSetFilter(Rec);
        Rec.CalcFields("Balance Due (LCY)");
        OnAfterCalcOverdueBalanceLCY(Rec);
    end;

    local procedure CalcReturnAmounts(var OutstandingRetOrdersLCY2: Decimal; var RcdNotInvdRetOrdersLCY2: Decimal)
    begin
        SalesLine.Reset();
        SalesLine.SetCurrentKey("Document Type", "Bill-to Customer No.", "Currency Code");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Bill-to Customer No.", Rec."No.");
        SalesLine.CalcSums("Outstanding Amount (LCY)", "Return Rcd. Not Invd. (LCY)");
        OutstandingRetOrdersLCY2 := SalesLine."Outstanding Amount (LCY)";
        RcdNotInvdRetOrdersLCY2 := SalesLine."Return Rcd. Not Invd. (LCY)";
    end;

    local procedure CalcTotalOutstandingAmt() Result: Decimal
    var
        SalesLine: Record "Sales Line";
        SalesOutstandingAmountFromShipment: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTotalOutstandingAmt(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        Rec.CalcFields("Outstanding Invoices (LCY)", "Outstanding Orders (LCY)");
        SalesOutstandingAmountFromShipment := SalesLine.OutstandingInvoiceAmountFromShipment(Rec."No.");

        Result := Rec."Outstanding Orders (LCY)" + Rec."Outstanding Invoices (LCY)" - SalesOutstandingAmountFromShipment;

        OnAfterCalcTotalOutstandingAmt(Rec, Result);
    end;

    /// <summary>
    /// Sets the visibility of the hide message checkbox.
    /// </summary>
    /// <param name="HideMsgVisible">True to show the hide message checkbox, otherwise false.</param>
    procedure SetHideMessageVisible(HideMsgVisible: Boolean)
    begin
        HideMessageVisible := HideMsgVisible;
    end;

    /// <summary>
    /// Sets the hide message state for the credit limit dialog.
    /// </summary>
    /// <param name="HideMsg">True to hide future messages, otherwise false.</param>
    procedure SetHideMessage(HideMsg: Boolean)
    begin
        HideMessage := HideMsg;
    end;

    /// <summary>
    /// Gets whether the user has opted to hide the credit limit message.
    /// </summary>
    /// <returns>True if the user chose to hide the message, otherwise false.</returns>
    procedure GetHideMessage(): Boolean
    begin
        exit(HideMessage);
    end;

    /// <summary>
    /// Gets the primary heading text for the credit limit notification.
    /// </summary>
    /// <returns>The heading text for the notification.</returns>
    procedure GetHeading(): Text[250]
    begin
        exit(Heading);
    end;

    /// <summary>
    /// Gets the secondary heading text for the overdue balance notification.
    /// </summary>
    /// <returns>The secondary heading text for the notification.</returns>
    procedure GetSecondHeading(): Text[250]
    begin
        exit(SecondHeading);
    end;

    /// <summary>
    /// Gets the notification identifier for the current credit limit or overdue balance warning.
    /// </summary>
    /// <returns>The GUID identifier for the notification.</returns>
    procedure GetNotificationId(): Guid
    begin
        exit(NotificationId);
    end;

    /// <summary>
    /// Populates the credit limit notification with data from the current customer record.
    /// </summary>
    /// <param name="CreditLimitNotification">The notification object to populate with data.</param>
    procedure PopulateDataOnNotification(CreditLimitNotification: Notification)
    begin
        CurrPage.CreditLimitDetails.PAGE.SetCustomerNumber(Rec."No.");
        SetParametersOnDetails();
        CurrPage.CreditLimitDetails.PAGE.PopulateDataOnNotification(CreditLimitNotification);
    end;

    local procedure SetParametersOnDetails()
    begin
        CurrPage.CreditLimitDetails.PAGE.SetOrderAmountTotalLCY(OrderAmountTotalLCY);
        CurrPage.CreditLimitDetails.PAGE.SetShippedRetRcdNotIndLCY(ShippedRetRcdNotIndLCY);
        CurrPage.CreditLimitDetails.PAGE.SetOrderAmountThisOrderLCY(OrderAmountThisOrderLCY);
        CurrPage.CreditLimitDetails.PAGE.SetCustCreditAmountLCY(CustCreditAmountLCY);
        CurrPage.CreditLimitDetails.Page.SetExtensionAmounts(ExtensionAmountsDic);
    end;

    /// <summary>
    /// Raised before calculating the total outstanding amount for the customer.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation.</param>
    /// <param name="Result">Set to the result to override the calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTotalOutstandingAmt(var Customer: Record Customer; var IsHandled: Boolean; var Result: Decimal)
    begin
    end;

    /// <summary>
    /// Raised before calculating the credit limit amounts in local currency.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="OutstandingRetOrdersLCY">The outstanding return orders amount in local currency.</param>
    /// <param name="RcdNotInvdRetOrdersLCY">The received not invoiced return orders amount in local currency.</param>
    /// <param name="NewOrderAmountLCY">The new order amount in local currency.</param>
    /// <param name="OrderAmountTotalLCY">The total order amount in local currency.</param>
    /// <param name="OrderAmountThisOrderLCY">The amount for this order in local currency.</param>
    /// <param name="ShippedRetRcdNotIndLCY">The shipped/returned received not invoiced amount in local currency.</param>
    /// <param name="CustCreditAmountLCY">The customer credit amount in local currency.</param>
    /// <param name="CustNo">The customer number.</param>
    /// <param name="ExtensionAmountsDic">Dictionary of extension amounts by GUID.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation.</param>
    /// <param name="DeltaAmount">The delta amount for the calculation.</param>
    /// <param name="CustomerRec">The customer record reference.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcCreditLimitLCY(var Customer: Record Customer; var OutstandingRetOrdersLCY: Decimal; var RcdNotInvdRetOrdersLCY: Decimal; var NewOrderAmountLCY: Decimal; var OrderAmountTotalLCY: Decimal; var OrderAmountThisOrderLCY: Decimal; var ShippedRetRcdNotIndLCY: Decimal; var CustCreditAmountLCY: Decimal; var CustNo: Code[20]; var ExtensionAmountsDic: Dictionary of [Guid, Decimal]; var IsHandled: Boolean; DeltaAmount: Decimal; var CustomerRec: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised before calculating the new order amount in local currency for a sales header.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="SalesHeader">The sales header to calculate the amount for.</param>
    /// <param name="NewOrderAmountLCY">The new order amount in local currency to override.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesHeaderNewOrderAmountLCY(var Customer: Record Customer; SalesHeader: Record "Sales Header"; var NewOrderAmountLCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before calculating the order amounts in local currency for a sales line.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="SalesLine">The sales line to calculate the amounts for.</param>
    /// <param name="NewOrderAmountLCY">The new order amount in local currency to override.</param>
    /// <param name="OldOrderAmountLCY">The old order amount in local currency to override.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesLineOrderAmountsLCY(var Customer: Record Customer; SalesLine: Record "Sales Line"; var NewOrderAmountLCY: Decimal; var OldOrderAmountLCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before showing the credit limit warning for a general journal line.
    /// </summary>
    /// <param name="GenJournalLine">The general journal line to check.</param>
    /// <param name="IsHandled">Set to true to skip the default warning logic.</param>
    /// <param name="Result">Set to the result to override the warning.</param>
    /// <param name="Customer">The customer record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineShowWarning(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var Result: Boolean; var Customer: Record Customer);
    begin
    end;

    /// <summary>
    /// Raised before showing the credit limit warning for a sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <param name="Result">Set to the result to override the warning.</param>
    /// <param name="IsHandled">Set to true to skip the default warning logic.</param>
    /// <param name="Customer">The customer record.</param>
    /// <param name="DeltaAmount">The delta amount for the calculation.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeSalesHeaderShowWarning(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean; var Customer: Record Customer; var DeltaAmount: Decimal);
    begin
    end;

    /// <summary>
    /// Raised before showing the credit limit warning for a sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <param name="Result">Set to the result to override the warning.</param>
    /// <param name="IsHandled">Set to true to skip the default warning logic.</param>
    /// <param name="Customer">The customer record.</param>
    /// <param name="DeltaAmount">The delta amount for the calculation.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeSalesLineShowWarning(var SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean; var Customer: Record Customer; var DeltaAmount: Decimal);
    begin
    end;

    /// <summary>
    /// Raised before calculating the sales line amount.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="DocType">The document type.</param>
    /// <param name="DocNo">The document number.</param>
    /// <param name="Result">Set to the result to override the calculation.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineAmount(var Customer: Record Customer; DocType: Enum "Sales Document Type"; DocNo: Code[20]; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;




    /// <summary>
    /// Raised before showing the credit limit warning dialog.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="NewOrderAmountLCY">The new order amount in local currency.</param>
    /// <param name="OldOrderAmountLCY">The old order amount in local currency.</param>
    /// <param name="OrderAmountTotalLCY">The total order amount in local currency.</param>
    /// <param name="ShippedRetRcdNotIndLCY">The shipped/returned received not invoiced amount in local currency.</param>
    /// <param name="CustCreditAmountLCY">The customer credit amount in local currency.</param>
    /// <param name="DeltaAmount">The delta amount for the calculation.</param>
    /// <param name="CheckOverDueBalance">Indicates whether to check overdue balance.</param>
    /// <param name="Heading">The heading text for the warning.</param>
    /// <param name="Result">Set to the result to override the warning.</param>
    /// <param name="IsHandled">Set to true to skip the default warning logic.</param>
    /// <param name="NotificationId">The notification identifier.</param>
    /// <param name="NewCustNo">The customer number.</param>
    /// <param name="NewOrderAmountLCY2">The new order amount in local currency (alternative).</param>
    /// <param name="OldOrderAmountLCY2">The old order amount in local currency (alternative).</param>
    /// <param name="OrderAmountThisOrderLCY">The amount for this order in local currency.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowWarning(var Customer: Record Customer; var NewOrderAmountLCY: Decimal; OldOrderAmountLCY: Decimal; OrderAmountTotalLCY: Decimal; ShippedRetRcdNotIndLCY: Decimal; CustCreditAmountLCY: Decimal; DeltaAmount: Decimal; CheckOverDueBalance: Boolean; var Heading: Text[250]; var Result: Boolean; var IsHandled: Boolean; var NotificationId: Guid; var NewCustNo: Code[20]; NewOrderAmountLCY2: Decimal; OldOrderAmountLCY2: Decimal; OrderAmountThisOrderLCY: Decimal);
    begin
    end;

    /// <summary>
    /// Raised after setting the date filter when calculating the overdue balance.
    /// </summary>
    /// <param name="Customer">The customer record with the date filter applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcOverdueBalanceLCYAfterSetFilter(var Customer: Record Customer);
    begin
    end;

    /// <summary>
    /// Raised after calculating the credit limit and determining the exit value.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="CustCreditAmountLCY">The customer credit amount in local currency.</param>
    /// <param name="ExitValue">The exit value indicating the warning type.</param>
    [IntegrationEvent(false, false)]
    local procedure OnShowWarningOnAfterCalcCreditLimitLCYExitValue(var Customer: Record Customer; var CustCreditAmountLCY: Decimal; var ExitValue: Integer)
    begin
    end;

    /// <summary>
    /// Raised after calculating the due balance and determining the exit value.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="ExitValue">The exit value indicating the warning type.</param>
    [IntegrationEvent(true, false)]
    local procedure OnShowWarningOnAfterCalcDueBalanceExitValue(var Customer: Record Customer; var ExitValue: Integer)
    begin
    end;

    /// <summary>
    /// Raised before returning the exit value from ShowWarning.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="ExitValue">The calculated exit value.</param>
    /// <param name="Result">Set to the result to override the return value.</param>
    /// <param name="IsHandled">Set to true to skip the default return logic.</param>
    /// <param name="Heading">The heading text to modify.</param>
    /// <param name="SecondHeading">The secondary heading text to modify.</param>
    /// <param name="NotificationID">The notification identifier to modify.</param>
    [IntegrationEvent(true, false)]
    local procedure OnShowWarningOnBeforeExitValue(var Customer: Record Customer; ExitValue: Integer; var Result: Boolean; var IsHandled: Boolean; var Heading: Text[250]; var SecondHeading: Text[250]; var NotificationID: Guid)
    begin
    end;

    /// <summary>
    /// Raised after calculating the overdue balance in local currency.
    /// </summary>
    /// <param name="Customer">The customer record with calculated overdue balance.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcOverdueBalanceLCY(var Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised after calculating the total outstanding amount.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="Result">The calculated result that can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcTotalOutstandingAmt(var Customer: Record Customer; var Result: Decimal)
    begin
    end;

    /// <summary>
    /// Raised after the credit limit calculation procedure completes.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="CustCreditAmountLCY">The calculated customer credit amount in local currency.</param>
    /// <param name="ExtensionAmountsDic">Dictionary for extension amounts by GUID.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcCreditLimitLCYProcedure(var Customer: Record Customer; var CustCreditAmountLCY: Decimal; var ExtensionAmountsDic: Dictionary of [Guid, Decimal])
    begin
    end;

    /// <summary>
    /// Raised after assigning the new order amount for a sales header warning.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="NewOrderAmountLCY">The new order amount that can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderShowWarningOnAfterAssingNewOrderAmountLCY(var SalesHeader: Record "Sales Header"; var NewOrderAmountLCY: Decimal);
    begin
    end;

    /// <summary>
    /// Raised after calculating amounts during credit limit calculation.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="ShippedRetRcdNotIndLCY">The shipped/returned received not invoiced amount.</param>
    /// <param name="CustCreditAmountLCY">The customer credit amount in local currency.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcCreditLimitLCYOnAfterCalcAmounts(var Customer: Record Customer; var ShippedRetRcdNotIndLCY: Decimal; var CustCreditAmountLCY: Decimal)
    begin
    end;
}
