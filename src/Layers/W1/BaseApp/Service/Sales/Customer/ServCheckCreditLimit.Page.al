// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Document;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;

page 6489 "Serv. Check Credit Limit"
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
        CurrExchRate: Record "Currency Exchange Rate";
        SalesSetup: Record "Sales & Receivables Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Cust2: Record Customer;
#if not CLEAN25
        CheckCreditLimit: Page "Check Credit Limit";
#endif
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

        Text000: Label '%1 Do you still want to record the amount?';

    procedure ServiceHeaderShowWarning(ServHeader: Record "Service Header") Result: Boolean
    var
        ServSetup: Record "Service Mgt. Setup";
        OldServHeader: Record "Service Header";
        AssignDeltaAmount: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderShowWarning(ServHeader, Result, IsHandled, Rec, DeltaAmount);
#if not CLEAN25
        CheckCreditLimit.RunOnBeforeServiceHeaderShowWarning(ServHeader, Result, IsHandled, Rec, DeltaAmount);
#endif
        if IsHandled then
            exit;

        ServSetup.Get();
        SalesSetup.Get();
        if SalesSetup."Credit Warnings" =
           SalesSetup."Credit Warnings"::"No Warning"
        then
            exit(false);

        NewOrderAmountLCY := 0;
        ServiceLine.Reset();
        ServiceLine.SetRange("Document Type", ServHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                if ServHeader."Currency Code" = '' then
                    NewOrderAmountLCY := NewOrderAmountLCY + ServiceLine."Amount Including VAT"
                else
                    NewOrderAmountLCY := NewOrderAmountLCY +
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          WorkDate(), ServHeader."Currency Code",
                          ServiceLine."Amount Including VAT", ServHeader."Currency Factor"));
            until ServiceLine.Next() = 0;

        if ServHeader."Document Type" <> ServHeader."Document Type"::Order then
            NewOrderAmountLCY := NewOrderAmountLCY + ServLineAmount(ServHeader."Document Type", ServHeader."No.", ServiceLine);
        OldServHeader := ServHeader;
        if OldServHeader.Find() then
            AssignDeltaAmount := OldServHeader."Bill-to Customer No." <> ServHeader."Bill-to Customer No."
        else
            AssignDeltaAmount := true;
        if AssignDeltaAmount then
            DeltaAmount := NewOrderAmountLCY;
        exit(ShowWarning(ServHeader."Bill-to Customer No.", NewOrderAmountLCY, 0, true));
    end;

    procedure ServiceHeaderShowWarningAndGetCause(ServHeader: Record "Service Header"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := ServiceHeaderShowWarning(ServHeader);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;

    procedure ServiceLineShowWarning(ServLine: Record "Service Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceLineShowWarning(ServLine, Result, IsHandled, Rec, DeltaAmount);
#if not CLEAN25
        CheckCreditLimit.RunOnBeforeServiceLineShowWarning(ServLine, Result, IsHandled, Rec, DeltaAmount);
#endif
        if IsHandled then
            exit(Result);

        SalesSetup.Get();
        if SalesSetup."Credit Warnings" =
           SalesSetup."Credit Warnings"::"No Warning"
        then
            exit(false);
        if (ServiceHeader."Document Type" <> ServLine."Document Type") or
           (ServiceHeader."No." <> ServLine."Document No.")
        then
            ServiceHeader.Get(ServLine."Document Type", ServLine."Document No.");
        NewOrderAmountLCY := ServLine."Outstanding Amount (LCY)" + ServLine."Shipped Not Invoiced (LCY)";

        if ServLine.Find() then
            OldOrderAmountLCY := ServLine."Outstanding Amount (LCY)" + ServLine."Shipped Not Invoiced (LCY)"
        else
            OldOrderAmountLCY := 0;

        DeltaAmount := NewOrderAmountLCY - OldOrderAmountLCY;
        NewOrderAmountLCY :=
          DeltaAmount + ServLineAmount(ServLine."Document Type", ServLine."Document No.", ServLine);

        exit(ShowWarning(ServiceHeader."Bill-to Customer No.", NewOrderAmountLCY, OldOrderAmountLCY, false))
    end;

    procedure ServiceLineShowWarningAndGetCause(ServLine: Record "Service Line"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := ServiceLineShowWarning(ServLine);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;

    procedure ServiceContractHeaderShowWarning(ServiceContractHeader: Record "Service Contract Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceContractHeaderShowWarning(ServiceContractHeader, Rec, Result, IsHandled);
#if not CLEAN25
        CheckCreditLimit.RunOnBeforeServiceContractHeaderShowWarning(ServiceContractHeader, Rec, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        SalesSetup.Get();
        if SalesSetup."Credit Warnings" =
           SalesSetup."Credit Warnings"::"No Warning"
        then
            exit(false);
        exit(ShowWarning(ServiceContractHeader."Bill-to Customer No.", 0, 0, true));
    end;

    [Scope('OnPrem')]
    procedure ServiceContractHeaderShowWarningAndGetCause(ServiceContractHeader: Record "Service Contract Header"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := ServiceContractHeaderShowWarning(ServiceContractHeader);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;

    local procedure ServLineAmount(DocType: Enum "Service Document Type"; DocNo: Code[20]; var ServLine2: Record "Service Line"): Decimal
    begin
        ServLine2.Reset();
        ServLine2.SetRange("Document Type", DocType);
        ServLine2.SetRange("Document No.", DocNo);
        ServLine2.CalcSums("Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)");
        exit(ServLine2."Outstanding Amount (LCY)" + ServLine2."Shipped Not Invoiced (LCY)");
    end;

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
            ShippedRetRcdNotIndLCY, CustCreditAmountLCY, CustNo, ExtensionAmountsDic, IsHandled, DeltaAmount);
        if not IsHandled then begin
            if Rec.GetFilter("Date Filter") = '' then
                Rec.SetFilter("Date Filter", '..%1', WorkDate());
            Rec.CalcFields("Balance (LCY)", "Shipped Not Invoiced (LCY)", "Serv Shipped Not Invoiced(LCY)");
            CalcReturnAmounts(OutstandingRetOrdersLCY, RcdNotInvdRetOrdersLCY);

            OrderAmountTotalLCY := CalcTotalOutstandingAmt() - OutstandingRetOrdersLCY + DeltaAmount;
            ShippedRetRcdNotIndLCY := Rec."Shipped Not Invoiced (LCY)" + Rec."Serv Shipped Not Invoiced(LCY)" - RcdNotInvdRetOrdersLCY;
            if Rec."No." = CustNo then
                OrderAmountThisOrderLCY := NewOrderAmountLCY
            else
                OrderAmountThisOrderLCY := 0;

            CustCreditAmountLCY :=
              Rec."Balance (LCY)" + Rec."Shipped Not Invoiced (LCY)" + Rec."Serv Shipped Not Invoiced(LCY)" - RcdNotInvdRetOrdersLCY +
              OrderAmountTotalLCY - Rec.GetInvoicedPrepmtAmountLCY();
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
    var
        SalesLine: Record "Sales Line";
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
        ServOutstandingAmountFromShipment: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTotalOutstandingAmt(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        Rec.CalcFields(
          "Outstanding Invoices (LCY)", "Outstanding Orders (LCY)", "Outstanding Serv.Invoices(LCY)", "Outstanding Serv. Orders (LCY)");
        SalesOutstandingAmountFromShipment := SalesLine.OutstandingInvoiceAmountFromShipment(Rec."No.");
        ServOutstandingAmountFromShipment := ServiceLine.OutstandingInvoiceAmountFromShipment(Rec."No.");

        exit(
          Rec."Outstanding Orders (LCY)" + Rec."Outstanding Invoices (LCY)" + Rec."Outstanding Serv. Orders (LCY)" +
          Rec."Outstanding Serv.Invoices(LCY)" - SalesOutstandingAmountFromShipment - ServOutstandingAmountFromShipment);
    end;

    procedure SetHideMessageVisible(HideMsgVisible: Boolean)
    begin
        HideMessageVisible := HideMsgVisible;
    end;

    procedure SetHideMessage(HideMsg: Boolean)
    begin
        HideMessage := HideMsg;
    end;

    procedure GetHideMessage(): Boolean
    begin
        exit(HideMessage);
    end;

    procedure GetHeading(): Text[250]
    begin
        exit(Heading);
    end;

    procedure GetSecondHeading(): Text[250]
    begin
        exit(SecondHeading);
    end;

    procedure GetNotificationId(): Guid
    begin
        exit(NotificationId);
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTotalOutstandingAmt(var Customer: Record Customer; var IsHandled: Boolean; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcCreditLimitLCY(var Customer: Record Customer; var OutstandingRetOrdersLCY: Decimal; var RcdNotInvdRetOrdersLCY: Decimal; var NewOrderAmountLCY: Decimal; var OrderAmountTotalLCY: Decimal; var OrderAmountThisOrderLCY: Decimal; var ShippedRetRcdNotIndLCY: Decimal; var CustCreditAmountLCY: Decimal; var CustNo: Code[20]; var ExtensionAmountsDic: Dictionary of [Guid, Decimal]; var IsHandled: Boolean; DeltaAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineShowWarning(var ServLine: Record "Service Line"; var Result: Boolean; var IsHandled: Boolean; var Customer: Record Customer; var DeltaAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderShowWarning(var ServiceHeader: Record "Service Header"; var Result: Boolean; var IsHandled: Boolean; var Customer: Record Customer; var DeltaAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceContractHeaderShowWarning(ServiceContractHeader: Record "Service Contract Header"; var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowWarning(var Customer: Record Customer; var NewOrderAmountLCY: Decimal; OldOrderAmountLCY: Decimal; OrderAmountTotalLCY: Decimal; ShippedRetRcdNotIndLCY: Decimal; CustCreditAmountLCY: Decimal; DeltaAmount: Decimal; CheckOverDueBalance: Boolean; var Heading: Text[250]; var Result: Boolean; var IsHandled: Boolean; var NotificationId: Guid; var NewCustNo: Code[20]; NewOrderAmountLCY2: Decimal; OldOrderAmountLCY2: Decimal; OrderAmountThisOrderLCY: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcOverdueBalanceLCYAfterSetFilter(var Customer: Record Customer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowWarningOnAfterCalcCreditLimitLCYExitValue(var Customer: Record Customer; var CustCreditAmountLCY: Decimal; var ExitValue: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnShowWarningOnAfterCalcDueBalanceExitValue(var Customer: Record Customer; var ExitValue: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnShowWarningOnBeforeExitValue(var Customer: Record Customer; ExitValue: Integer; var Result: Boolean; var IsHandled: Boolean; var Heading: Text[250]; var SecondHeading: Text[250]; var NotificationID: Guid)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcOverdueBalanceLCY(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcCreditLimitLCYProcedure(var Customer: Record Customer; var CustCreditAmountLCY: Decimal; var ExtensionAmountsDic: Dictionary of [Guid, Decimal])
    begin
    end;
}

