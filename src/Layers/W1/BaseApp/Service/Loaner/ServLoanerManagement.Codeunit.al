// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Loaner;

using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Utilities;

codeunit 5901 ServLoanerManagement
{
    Permissions = TableData "Loaner Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The %1 field is empty.';
        Text001: Label 'You cannot receive loaner %1 because it has not been lent.';
        Text002: Label 'Loaner no. %1 has not been lent connection with %2 no. %3.';
        Text003: Label 'There is no %1 to receive.';
        Text004: Label 'There is no loaner to receive on the service shipment item line document no.=%1,line no.=%2.';
        Text005: Label 'Do you want to receive loaner %1?';
        Text006: Label 'There is no service shipment header within the filter.\Filters: order no.: %1\Do you want to receive the loaner anyway?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure LendLoaner(ServItemLine: Record "Service Item Line")
    var
        Loaner: Record Loaner;
        ServHeader: Record "Service Header";
        LoanerEntry: Record "Loaner Entry";
        ServLogMgt: Codeunit ServLogManagement;
    begin
        if ServItemLine."Loaner No." <> '' then begin
            Loaner.Get(ServItemLine."Loaner No.");
            Loaner.CalcFields(Lent);
            Loaner.TestField(Lent, false);
            Loaner.TestField(Blocked, false);

            LoanerEntry.LockTable();
            LoanerEntry.Init();
            LoanerEntry."Entry No." := LoanerEntry.GetNextEntryNo();
            LoanerEntry."Loaner No." := ServItemLine."Loaner No.";
            LoanerEntry."Document Type" := LoanerEntry.GetDocTypeFromServDocType(ServItemLine."Document Type");
            LoanerEntry."Document No." := ServItemLine."Document No.";
            LoanerEntry."Service Item Line No." := ServItemLine."Line No.";
            LoanerEntry."Service Item No." := ServItemLine."Service Item No.";
            LoanerEntry."Service Item Group Code" := ServItemLine."Service Item Group Code";
            if ServHeader.Get(ServItemLine."Document Type", ServItemLine."Document No.") then
                LoanerEntry."Customer No." := ServHeader."Customer No.";
            LoanerEntry."Date Lent" := WorkDate();
            LoanerEntry."Time Lent" := Time;
            LoanerEntry."Date Received" := 0D;
            LoanerEntry."Time Received" := 0T;
            LoanerEntry.Lent := true;
            OnLendLoanerOnBeforeInsertLoanerEntry(LoanerEntry, ServItemLine);
            LoanerEntry.Insert();
            Clear(ServLogMgt);
            ServLogMgt.LoanerLent(LoanerEntry);
        end else
            Error(Text000, ServItemLine.FieldCaption("Loaner No."));
    end;

    procedure ReceiveLoaner(var ServItemLine: Record "Service Item Line")
    var
        Loaner: Record Loaner;
        LoanerEntry: Record "Loaner Entry";
        ServLogMgt: Codeunit ServLogManagement;
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReceiveLoaner(ServItemLine, IsHandled);
        if not IsHandled then
            if ServItemLine."Loaner No." <> '' then begin
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text005, ServItemLine."Loaner No."), true) then
                    exit;
                LoanerEntry.Reset();
                LoanerEntry.SetCurrentKey("Document Type", "Document No.", "Loaner No.", Lent);
                LoanerEntry.SetRange("Document Type", LoanerEntry.GetDocTypeFromServDocType(ServItemLine."Document Type"));
                LoanerEntry.SetRange("Document No.", ServItemLine."Document No.");
                LoanerEntry.SetRange("Loaner No.", ServItemLine."Loaner No.");
                LoanerEntry.SetRange(Lent, true);
                if LoanerEntry.FindFirst() then begin
                    LoanerEntry."Date Received" := WorkDate();
                    LoanerEntry."Time Received" := Time;
                    LoanerEntry.Lent := false;
                    LoanerEntry.Modify();
                    ServItemLine."Loaner No." := '';
                    ServItemLine.Modify();
                    Clear(ServLogMgt);
                    ServLogMgt.LoanerReceived(LoanerEntry);
                    ClearLoanerField(ServItemLine."Document No.", ServItemLine."Line No.", LoanerEntry."Loaner No.");
                end else
                    Error(
                      Text002, ServItemLine."Loaner No.",
                      Format(ServItemLine."Document Type"), ServItemLine."Document No.");
            end else
                Error(Text003, Loaner.TableCaption());

        OnAfterReceiveLoaner(LoanerEntry, ServItemLine);
    end;

    procedure ReceiveLoanerShipment(ServShipmentItemLine: Record "Service Shipment Item Line")
    var
        LoanerEntry: Record "Loaner Entry";
        ServShptHeader: Record "Service Shipment Header";
        ServLogMgt: Codeunit ServLogManagement;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ServShipmentItemLine."Loaner No." = '' then
            Error(Text004, ServShipmentItemLine."No.", ServShipmentItemLine."Line No.");

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text005, ServShipmentItemLine."Loaner No."), true) then
            exit;
        ServShptHeader.Get(ServShipmentItemLine."No.");
        LoanerEntry.Reset();
        LoanerEntry.SetCurrentKey("Document Type", "Document No.", "Loaner No.", Lent);
        LoanerEntry.SetRange("Document Type", LoanerEntry."Document Type"::Order);
        LoanerEntry.SetRange("Document No.", ServShptHeader."Order No.");
        LoanerEntry.SetRange("Loaner No.", ServShipmentItemLine."Loaner No.");
        LoanerEntry.SetRange(Lent, true);
        if LoanerEntry.FindFirst() then begin
            LoanerEntry."Date Received" := WorkDate();
            LoanerEntry."Time Received" := Time;
            LoanerEntry.Lent := false;
            LoanerEntry.Modify();
            ServShipmentItemLine."Loaner No." := '';
            ServShipmentItemLine.Modify();
            Clear(ServLogMgt);
            ServLogMgt.LoanerReceived(LoanerEntry);
            ClearLoanerField(ServShptHeader."Order No.", ServShipmentItemLine."Line No.", LoanerEntry."Loaner No.");
        end else
            Error(
              Text002, ServShipmentItemLine."Loaner No.",
              ServShipmentItemLine.FieldCaption("No."), ServShipmentItemLine."No.");
    end;

    local procedure ClearLoanerField(OrderNo: Code[20]; LineNo: Integer; LoanerNo: Code[20])
    var
        ServShptHeader: Record "Service Shipment Header";
        ServShptItemLine: Record "Service Shipment Item Line";
        ServiceHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
    begin
        if ServItemLine.Get(ServiceHeader."Document Type"::Order, OrderNo, LineNo) then
            if ServItemLine."Loaner No." = LoanerNo then begin
                ServItemLine."Loaner No." := '';
                ServItemLine.Modify();
            end;

        ServShptHeader.Reset();
        ServShptHeader.SetCurrentKey("Order No.");
        ServShptHeader.SetRange("Order No.", OrderNo);
        if ServShptHeader.Find('-') then
            repeat
                ServShptItemLine.Reset();
                if ServShptItemLine.Get(ServShptHeader."No.", LineNo) then
                    if ServShptItemLine."Loaner No." = LoanerNo then begin
                        ServShptItemLine."Loaner No." := '';
                        ServShptItemLine.Modify();
                    end;
            until ServShptHeader.Next() = 0;
    end;

    procedure Receive(var Loaner: Record Loaner)
    var
        ServItemLine: Record "Service Item Line";
        LoanerEntry: Record "Loaner Entry";
        ServShptItemLine: Record "Service Shipment Item Line";
        ServShptHeader: Record "Service Shipment Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Loaner.Lent then begin
            Clear(LoanerEntry);
            LoanerEntry.SetCurrentKey("Document Type", "Document No.", "Loaner No.", Lent);
            LoanerEntry.SetRange("Document Type", Loaner."Document Type");
            LoanerEntry.SetRange("Document No.", Loaner."Document No.");
            LoanerEntry.SetRange("Loaner No.", Loaner."No.");
            LoanerEntry.SetRange(Lent, true);

            if LoanerEntry.FindFirst() then
                if ServItemLine.Get(LoanerEntry.GetServDocTypeFromDocType(), LoanerEntry."Document No.", LoanerEntry."Service Item Line No.") then
                    ReceiveLoaner(ServItemLine)
                else begin
                    ServShptHeader.Reset();
                    ServShptHeader.SetCurrentKey("Order No.");
                    ServShptHeader.SetRange("Order No.", LoanerEntry."Document No.");
                    if ServShptHeader.FindLast() then begin
                        ServShptItemLine.Get(ServShptHeader."No.", LoanerEntry."Service Item Line No.");
                        ReceiveLoanerShipment(ServShptItemLine);
                    end else
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text006, LoanerEntry."Document No."), true) then begin
                            // receive loaner anyway
                            LoanerEntry."Date Received" := WorkDate();
                            LoanerEntry."Time Received" := Time;
                            LoanerEntry.Lent := false;
                            LoanerEntry.Modify();
                        end;
                end;
        end else
            Error(Text001, Loaner."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReceiveLoaner(LoanerEntry: Record "Loaner Entry"; ServItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReceiveLoaner(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLendLoanerOnBeforeInsertLoanerEntry(var LoanerEntry: Record "Loaner Entry"; var ServiceItemLine: Record "Service Item Line")
    begin
    end;
}

