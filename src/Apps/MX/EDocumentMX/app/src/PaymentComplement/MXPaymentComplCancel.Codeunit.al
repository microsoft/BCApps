// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 3374 "MX Payment Compl. Cancel"
{
    Permissions = tabledata "MX Payment Complement" = rm;

    procedure RunCancelAction(var Complement: Record "MX Payment Complement")
    begin
        case StrMenu(CancelOptionsTxt, 1) of
            1:
                CancelRequest(Complement, false);
            2:
                GetCancellationResponse(Complement);
            3:
                MarkAsCanceled(Complement);
            4:
                ResetCancellationRequest(Complement);
        end;
    end;

    procedure CancelRequest(var Complement: Record "MX Payment Complement"; SkipConfirmation: Boolean)
    var
        CFDICancellationMX: Codeunit "CFDI Cancellation MX";
        InterfacturaProcessing: Codeunit "Interfactura Processing";
        TempBlob: Codeunit "Temp Blob";
        CancelReasonDlg: Page "MX CFDI Cancel Reason Dlg";
        ResponseText: Text;
        UUID: Text[50];
        StampedDateTimeTxt: Text[50];
    begin
        if not (Complement."Cancellation Status" in [Complement."Cancellation Status"::" ", Complement."Cancellation Status"::"Cancel Error"]) then
            Error(InvalidStatusForCancelErr, Complement."Cancellation Status");
        if not InterfacturaProcessing.TryGetStampDataFromResponse(GetPACResponse(Complement), UUID, StampedDateTimeTxt) then
            Error(NotStampedErr);
        if Complement."Stamped UUID" = '' then
            Complement."Stamped UUID" := UUID;
        if not SkipConfirmation then
            if not Confirm(CancelQst, false) then
                exit;

        CancelReasonDlg.SetPaymentComplement(Complement."Entry No.");
        if CancelReasonDlg.RunModal() <> Action::OK then
            exit;
        Complement."Cancellation Reason Code" := CancelReasonDlg.GetReasonCode();
        Complement."Substitution UUID" := CancelReasonDlg.GetSubstitutionUUID();

        if InterfacturaProcessing.CancelsOnTimeExpiration(Complement."Stamped At") then begin
            SetCanceled(Complement, false);
            Message(CanceledMsg);
            exit;
        end;

        CFDICancellationMX.CreateCancellationXML(
            CopyStr(Format(CurrentDateTime(), 0, 9), 1, 50), StampedDateTimeTxt, UUID,
            Complement."Cancellation Reason Code", Complement."Substitution UUID", TempBlob);
        SendToPAC(Complement, GetText(TempBlob), false, ResponseText);
    end;

    procedure GetCancellationResponse(var Complement: Record "MX Payment Complement")
    var
        CFDICancellationMX: Codeunit "CFDI Cancellation MX";
        TempBlob: Codeunit "Temp Blob";
        ResponseText: Text;
    begin
        Complement.TestField("CFDI Cancellation ID");
        if not (Complement."Cancellation Status" in [Complement."Cancellation Status"::"Cancel In Progress", Complement."Cancellation Status"::"Cancel Error"]) then
            Error(InvalidStatusForResponseErr, Complement."Cancellation Status");

        CFDICancellationMX.CreateCancelStatusRequestXML(Complement."CFDI Cancellation ID", TempBlob);
        SendToPAC(Complement, GetText(TempBlob), true, ResponseText);
    end;

    procedure MarkAsCanceled(var Complement: Record "MX Payment Complement")
    begin
        // Legacy parity: only a cancellation that was already requested can be closed manually
        if not (Complement."Cancellation Status" in [Complement."Cancellation Status"::"Cancel In Progress", Complement."Cancellation Status"::"Cancel Error"]) then
            Error(InvalidStatusForMarkErr);
        if not Confirm(MarkAsCanceledQst, false) then
            exit;

        SetCanceled(Complement, true);
    end;

    local procedure SetCanceled(var Complement: Record "MX Payment Complement"; MarkedAsCanceled: Boolean)
    begin
        Complement."Cancellation Status" := Complement."Cancellation Status"::Canceled;
        Complement."Marked as Canceled" := MarkedAsCanceled;
        Complement."Date/Time Canceled" := CopyStr(Format(CurrentDateTime(), 0, 9), 1, MaxStrLen(Complement."Date/Time Canceled"));
        Complement."Cancellation Error" := '';
        Complement.Modify();
    end;

    procedure ResetCancellationRequest(var Complement: Record "MX Payment Complement")
    begin
        if Complement."Cancellation Status" <> Complement."Cancellation Status"::"Cancel In Progress" then
            Error(InvalidStatusForResetErr);
        if not Confirm(ResetCancellationRequestQst, false) then
            exit;

        Complement."Cancellation Status" := Complement."Cancellation Status"::"Cancel Error";
        Complement."Date/Time Canceled" := '';
        Complement.Modify();
    end;

    procedure ApplyCancellationResponse(var Complement: Record "MX Payment Complement"; ResponseText: Text)
    var
        CFDICancellationMX: Codeunit "CFDI Cancellation MX";
        StatusToken: Text;
        ResultText: Text;
        DateTimeCanceledTxt: Text;
        CancellationId: Text;
        ResponseOutStream: OutStream;
    begin
        Clear(Complement."Cancellation Response XML");
        Complement."Cancellation Response XML".CreateOutStream(ResponseOutStream, TextEncoding::UTF8);
        ResponseOutStream.WriteText(ResponseText);

        CFDICancellationMX.ParseCancellationResponse(ResponseText, StatusToken, ResultText, DateTimeCanceledTxt, CancellationId);
        case LowerCase(StatusToken) of
            'enproceso', 'en proceso':
                Complement."Cancellation Status" := Complement."Cancellation Status"::"Cancel In Progress";
            'cancelado':
                Complement."Cancellation Status" := Complement."Cancellation Status"::Canceled;
            else
                Complement."Cancellation Status" := Complement."Cancellation Status"::"Cancel Error";
        end;
        if CancellationId <> '' then
            Complement."CFDI Cancellation ID" := CopyStr(CancellationId, 1, MaxStrLen(Complement."CFDI Cancellation ID"));
        Complement."Date/Time Canceled" := CopyStr(DateTimeCanceledTxt, 1, MaxStrLen(Complement."Date/Time Canceled"));
        Complement."Cancellation Error" := '';
        if Complement."Cancellation Status" = Complement."Cancellation Status"::"Cancel Error" then
            Complement."Cancellation Error" := CopyStr(ResultText, 1, MaxStrLen(Complement."Cancellation Error"));
        Complement.Modify();
    end;

    local procedure SendToPAC(var Complement: Record "MX Payment Complement"; RequestText: Text; IsStatusRequest: Boolean; var ResponseText: Text)
    var
        InterfacturaProcessing: Codeunit "Interfactura Processing";
        ErrorText: Text;
    begin
        if RequestText = '' then
            Error(MissingCancelRequestErr);
        Complement.Modify();
        if not InterfacturaProcessing.InvokeCancellationRequest(RequestText, IsStatusRequest, ResponseText, ErrorText) then
            Error(ErrorText);

        Complement.Get(Complement."Entry No.");
        ApplyCancellationResponse(Complement, ResponseText);
        case Complement."Cancellation Status" of
            Complement."Cancellation Status"::Canceled:
                Message(CanceledMsg);
            Complement."Cancellation Status"::"Cancel In Progress":
                Message(CancelInProgressMsg);
            Complement."Cancellation Status"::"Cancel Error":
                Message(CancelErrorMsg, Complement."Cancellation Error");
        end;
    end;

    local procedure GetPACResponse(var Complement: Record "MX Payment Complement") ResponseText: Text
    var
        ResponseInStream: InStream;
        Line: Text;
    begin
        Complement.CalcFields("PAC Response XML");
        if not Complement."PAC Response XML".HasValue() then
            exit('');
        Complement."PAC Response XML".CreateInStream(ResponseInStream, TextEncoding::UTF8);
        while not ResponseInStream.EOS do begin
            ResponseInStream.ReadText(Line);
            ResponseText += Line;
        end;
    end;

    local procedure GetText(var TempBlob: Codeunit "Temp Blob") Result: Text
    var
        InStream: InStream;
        Line: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        while not InStream.EOS do begin
            InStream.ReadText(Line);
            Result += Line;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnAfterUnApplyCustomer', '', false, false)]
    local procedure OnAfterUnApplyCustomer(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        Payment: Record "Cust. Ledger Entry";
        Complement: Record "MX Payment Complement";
    begin
        if not GuiAllowed() then
            exit;
        if not DtldCustLedgEntry.Find() then
            exit;
        if not DtldCustLedgEntry.Unapplied then
            exit;
        if not FindPayment(DtldCustLedgEntry, Payment) then
            exit;

        Complement.SetRange("Payment Entry No.", Payment."Entry No.");
        Complement.SetFilter("Stamped UUID", '<>%1', '');
        Complement.SetFilter("Cancellation Status", '%1|%2', Complement."Cancellation Status"::" ", Complement."Cancellation Status"::"Cancel Error");
        if not Complement.FindLast() then
            exit;

        Payment.CalcFields(Amount, "Remaining Amount");
        if Payment."Remaining Amount" <> Payment.Amount then begin
            Message(PartialUnapplyMsg, Complement."Stamped UUID");
            exit;
        end;

        if Confirm(CancelAfterUnapplyQst, true, Complement."Stamped UUID") then
            CancelRequest(Complement, true);
    end;

    local procedure FindPayment(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var Payment: Record "Cust. Ledger Entry"): Boolean
    begin
        if Payment.Get(DtldCustLedgEntry."Cust. Ledger Entry No.") then
            if Payment."Document Type" = Payment."Document Type"::Payment then
                exit(true);
        if Payment.Get(DtldCustLedgEntry."Applied Cust. Ledger Entry No.") then
            if Payment."Document Type" = Payment."Document Type"::Payment then
                exit(true);
        exit(false);
    end;

    var
        CancelOptionsTxt: Label 'Cancel Request,Get Response,Mark as Canceled,Reset Cancellation Request';
        NotStampedErr: Label 'The payment complement has not been stamped, so there is nothing to cancel.';
        InvalidStatusForMarkErr: Label 'Only a payment complement with a cancellation in progress or a cancellation error can be marked as canceled.';
        CancelQst: Label 'Do you want to cancel the payment complement?';
        InvalidStatusForCancelErr: Label 'The payment complement cannot be canceled because its cancellation status is %1.', Comment = '%1 = cancellation status';
        InvalidStatusForResponseErr: Label 'There is no cancellation in progress for this payment complement. The cancellation status is %1.', Comment = '%1 = cancellation status';
        InvalidStatusForResetErr: Label 'Only a cancellation in progress can be reset.';
        MissingCancelRequestErr: Label 'The cancellation request could not be created.';
        MarkAsCanceledQst: Label 'This will mark the payment complement as canceled in Business Central without contacting the PAC. Only use this if you have confirmed the complement is already canceled in SAT. Do you want to continue?';
        ResetCancellationRequestQst: Label 'Do you want to reset the cancellation request to the error status?';
        CanceledMsg: Label 'The payment complement was canceled.';
        CancelInProgressMsg: Label 'The cancellation request was accepted and is in progress. Use Get Response to check its status later.';
        CancelErrorMsg: Label 'The cancellation was rejected: %1', Comment = '%1 = error returned by the PAC';
        CancelAfterUnapplyQst: Label 'The payment has a stamped payment complement (UUID %1). Do you want to cancel it in SAT now?', Comment = '%1 = UUID of the payment complement';
        PartialUnapplyMsg: Label 'The payment is still applied to other invoices, so its payment complement (UUID %1) must be substituted rather than only canceled. You can cancel it from the Messages part of the invoice e-document.', Comment = '%1 = UUID of the payment complement';
}
