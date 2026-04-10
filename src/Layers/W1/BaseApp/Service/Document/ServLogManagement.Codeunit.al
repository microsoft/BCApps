// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;

codeunit 5906 ServLogManagement
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Order created';
        Text001: Label 'Status changed';
        Text002: Label 'Customer changed';
        Text003: Label 'Resource allocated';
        Text004: Label 'Allocation canceled';
        Text005: Label 'Shipment created';
        Text006: Label 'Loaner lent';
        Text007: Label 'Loaner received';
        Text008: Label 'Order invoiced';
        Text009: Label 'Order deleted';
        Text010: Label 'Contract no. changed';
        Text011: Label 'Quote accepted';
        Text012: Label 'Quote created';
        Text013: Label 'Repair status changed';
#pragma warning restore AA0074
        UnknownEventTxt: Label 'Unknown event';
#pragma warning disable AA0074
        Text015: Label 'Created';
        Text016: Label 'Automatically created';
        Text017: Label 'Added to contract';
        Text018: Label 'Removed from contract';
        Text019: Label 'Added to service order';
        Text020: Label 'Order status changed';
        Text021: Label 'Removed from service order';
        Text022: Label 'Service item component removed';
        Text023: Label 'Service item replaced';
        Text024: Label 'Ship-to address changed';
        Text025: Label 'Item no. changed';
        Text026: Label 'Serial no. changed';
        Text027: Label 'Added to service quote';
        Text028: Label 'Service item comp. replaced';
        Text029: Label 'Ship-to Code changed';
        Text030: Label 'Reallocation needed';
        Text031: Label 'Removed from service quote';
        Text032: Label 'No. changed';
        Text033: Label 'Response Date changed';
        Text034: Label 'Response Time changed';
        Text035: Label 'Invoice created';
        Text036: Label 'Credit memo created';
        Text037: Label 'Credit memo posted';
        Text038: Label 'Invoice posted';
        Text039: Label 'Invoice deleted';
        Text040: Label 'Credit memo deleted';
#pragma warning restore AA0074
        BlockedChangedLbl: Label 'Blocked changed';

    procedure ServOrderEventDescription(EventNo: Integer): Text[50]
    var
        Description: Text[50];
        Handled: Boolean;
    begin
        case EventNo of
            1:
                exit(Text000);
            2:
                exit(Text001);
            3:
                exit(Text002);
            4:
                exit(Text003);
            5:
                exit(Text004);
            6:
                exit(Text005);
            7:
                exit(Text006);
            8:
                exit(Text007);
            9:
                exit(Text008);
            10:
                exit(Text009);
            11:
                exit(Text010);
            12:
                exit(Text011);
            13:
                exit(Text012);
            14:
                exit(Text013);
            15:
                exit(Text029);
            16:
                exit(Text037);
            17:
                exit(Text030);
            18:
                exit(Text033);
            19:
                exit(Text034);
            20:
                exit(Text035);
            21:
                exit(Text036);
            22:
                exit(Text038);
            23:
                exit(Text039);
            24:
                exit(Text040);
            else begin
                OnServOrderEventDescription(EventNo, Description, Handled);
                if Handled then
                    exit(Description);
                exit(UnknownEventTxt);
            end;
        end;
    end;

    procedure ServItemEventDescription(EventNo: Integer): Text[50]
    var
        Description: Text[50];
        Handled: Boolean;
    begin
        OnBeforeServItemEventDescription(EventNo);

        case EventNo of
            1:
                exit(Text015);
            2:
                exit(Text016);
            3:
                exit(Text017);
            4:
                exit(Text018);
            5:
                exit(Text019);
            6:
                exit(Text020);
            7:
                exit(Text021);
            8:
                exit(Text001);
            9:
                exit(Text022);
            10:
                exit(Text023);
            11:
                exit(Text002);
            12:
                exit(Text024);
            13:
                exit(Text025);
            14:
                exit(Text026);
            15:
                exit(Text027);
            16:
                exit(Text028);
            17:
                exit(Text031);
            18:
                exit(Text032);
            19:
                exit(BlockedChangedLbl);
            else begin
                OnServItemEventDescription(EventNo, Description, Handled);
                if Handled then
                    exit(Description);
                exit(UnknownEventTxt);
            end;
        end;
    end;

    procedure ServItemCreated(ServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItem."No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog."Event No." := 1;
        ServItemLog.Insert(true);
    end;

    procedure ServItemAutoCreated(ServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItem."No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog.After := ServItem."Description 2";
        ServItemLog."Event No." := 2;
        ServItemLog.Insert(true);
    end;

    procedure ServItemAddToContract(ServContrLine: Record "Service Contract Line")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServContrLine."Service Item No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServContrLine."Service Item No.";
        ServItemLog."Event No." := 3;
        ServItemLog."Document Type" := ServItemLog."Document Type"::Contract;
        ServItemLog."Document No." := ServContrLine."Contract No.";
        OnServItemAddToContractOnBeforeServItemLogInsert(ServItemLog, ServContrLine);
        ServItemLog.Insert(true);
    end;

    procedure ServItemRemovedFromContract(ServContrLine: Record "Service Contract Line")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServContrLine."Service Item No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServContrLine."Service Item No.";
        ServItemLog."Event No." := 4;
        ServItemLog."Document Type" := ServItemLog."Document Type"::Contract;
        ServItemLog."Document No." := ServContrLine."Contract No.";
        OnServItemRemovedFromContractOnBeforeServItemLogInsert(ServItemLog, ServContrLine);
        ServItemLog.Insert(true);
    end;

    procedure ServItemToServOrder(ServItemLine: Record "Service Item Line")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItemLine."Service Item No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItemLine."Service Item No.";
        if ServItemLine."Document Type" = ServItemLine."Document Type"::Order then
            ServItemLog."Event No." := 5
        else
            ServItemLog."Event No." := 15;
        ServItemLog."Document Type" := ServItemLine."Document Type".AsInteger() + 1;
        ServItemLog."Document No." := ServItemLine."Document No.";
        OnServItemToServOrderOnBeforeServItemLogInsert(ServItemLog, ServItemLine);
        ServItemLog.Insert(true);
    end;

    procedure ServItemOffServOrder(ServItemLine: Record "Service Item Line")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItemLine."Service Item No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItemLine."Service Item No.";
        if ServItemLine."Document Type" = ServItemLine."Document Type"::Order then
            ServItemLog."Event No." := 7
        else
            ServItemLog."Event No." := 17;
        ServItemLog."Document Type" := ServItemLine."Document Type".AsInteger() + 1;
        ServItemLog."Document No." := ServItemLine."Document No.";
        OnServItemOffServOrderOnBeforeServItemLogInsert(ServItemLog, ServItemLine);
        ServItemLog.Insert(true);
    end;

    procedure ServItemComponentAdded(Component: Record "Service Item Component")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if Component."Parent Service Item No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := Component."Parent Service Item No.";
        ServItemLog.After := Format(Component.Type) + ' ' + Component."No.";
        ServItemLog."Event No." := 16;
        ServItemLog."Document Type" := ServItemLog."Document Type"::Order;
        ServItemLog."Document No." := Component."Service Order No.";
        ServItemLog.Insert(true);
    end;

    procedure ServItemComponentRemoved(Component: Record "Service Item Component")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if Component."Parent Service Item No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := Component."Parent Service Item No.";
        ServItemLog.Before := Format(Component.Type) + ' ' + Component."No.";
        ServItemLog."Event No." := 9;
        ServItemLog."Document Type" := ServItemLog."Document Type"::Order;
        ServItemLog."Document No." := Component."Service Order No.";
        ServItemLog.Insert(true);
    end;

    procedure ServItemCustChange(ServItem: Record "Service Item"; OldServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItem."No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog."Event No." := 11;
        ServItemLog.Before := OldServItem."Customer No.";
        ServItemLog.After := ServItem."Customer No.";
        ServItemLog.Insert(true);
    end;

    procedure ServItemShipToCodeChange(ServItem: Record "Service Item"; OldServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog."Event No." := 12;
        ServItemLog.Before := OldServItem."Ship-to Code";
        ServItemLog.After := ServItem."Ship-to Code";
        ServItemLog.Insert(true);
    end;

    procedure ServItemStatusChange(ServItem: Record "Service Item"; OldServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItem."No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog."Event No." := 8;
        ServItemLog.Before := Format(OldServItem.Status);
        ServItemLog.After := Format(ServItem.Status);
        ServItemLog.Insert(true);
    end;

    procedure ServItemSerialNoChange(ServItem: Record "Service Item"; OldServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItem."No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog."Event No." := 14;
        ServItemLog.After := ServItem."Serial No.";
        ServItemLog.Before := OldServItem."Serial No.";
        ServItemLog.Insert(true);
    end;

    procedure ServItemNoChange(ServItem: Record "Service Item"; OldServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if (ServItem."No." = '') or (OldServItem."No." = '') then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := OldServItem."No.";
        ServItemLog."Event No." := 18;
        ServItemLog.After := ServItem."No.";
        ServItemLog.Before := OldServItem."No.";
        ServItemLog.Insert(true);
    end;

    procedure ServItemItemNoChange(ServItem: Record "Service Item"; OldServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if (ServItem."Item No." = '') and (OldServItem."Item No." = '') then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog."Event No." := 13;
        ServItemLog.After := ServItem."Item No.";
        ServItemLog.Before := OldServItem."Item No.";
        ServItemLog.Insert(true);
    end;

    procedure ServItemReplaced(ServItem: Record "Service Item"; NewServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItem."No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog."Event No." := 10;
        ServItemLog.After := NewServItem."No.";
        ServItemLog.Insert(true);
    end;

    procedure ServItemBlockedChange(ServItem: Record "Service Item"; OldServItem: Record "Service Item")
    var
        ServItemLog: Record "Service Item Log";
    begin
        if ServItem."No." = '' then
            exit;

        ServItemLog.Init();
        ServItemLog."Service Item No." := ServItem."No.";
        ServItemLog."Event No." := 19;
        ServItemLog.Before := Format(OldServItem.Blocked);
        ServItemLog.After := Format(ServItem.Blocked);
        ServItemLog.Insert(true);
    end;

    procedure ServItemDeleted(ServItemNo: Code[20])
    var
        ServItemLog: Record "Service Item Log";
    begin
        ServItemLog.SetRange("Service Item No.", ServItemNo);
        ServItemLog.DeleteAll();
    end;

    procedure ServHeaderStatusChange(ServHeader: Record "Service Header"; OldServHeader: Record "Service Header")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServHeader."No." = '') or (OldServHeader."No." = '') then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServHeader."Document Type";
        ServOrderLog."Document No." := ServHeader."No.";
        ServOrderLog."Event No." := 2;
        ServOrderLog.After := Format(ServHeader.Status);
        ServOrderLog.Before := Format(OldServHeader.Status);
        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderCustomerChange(ServHeader: Record "Service Header"; OldServHeader: Record "Service Header")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServHeader."No." = '') or (OldServHeader."Customer No." = '') or
           (ServHeader."Customer No." = OldServHeader."Customer No.")
        then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServHeader."Document Type";
        ServOrderLog."Document No." := ServHeader."No.";
        ServOrderLog."Event No." := 3;
        ServOrderLog.After := ServHeader."Customer No.";
        ServOrderLog.Before := OldServHeader."Customer No.";
        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderShiptoChange(ServHeader: Record "Service Header"; OldServHeader: Record "Service Header")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServHeader."No." = '') or (OldServHeader."Customer No." = '') or
           (ServHeader."Ship-to Code" = OldServHeader."Ship-to Code")
        then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServHeader."Document Type";
        ServOrderLog."Document No." := ServHeader."No.";
        ServOrderLog."Event No." := 15;
        ServOrderLog.After := ServHeader."Ship-to Code";
        ServOrderLog.Before := OldServHeader."Ship-to Code";
        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderAllocation(ResourceNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20]; ServItemLineNo: Integer)
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (DocumentNo = '') or (ResourceNo = '') then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := "Service Log Document Type".FromInteger(DocumentType);
        ServOrderLog."Document No." := DocumentNo;
        ServOrderLog."Service Item Line No." := ServItemLineNo;
        ServOrderLog."Event No." := 4;
        ServOrderLog.After := ResourceNo;
        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderCancelAllocation(ResourceNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20]; ServItemLineNo: Integer)
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (DocumentNo = '') or (ResourceNo = '') then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := "Service Log Document Type".FromInteger(DocumentType);
        ServOrderLog."Document No." := DocumentNo;
        ServOrderLog."Service Item Line No." := ServItemLineNo;
        ServOrderLog."Event No." := 5;
        ServOrderLog.After := ResourceNo;
        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderReallocationNeeded(ResourceNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20]; ServItemLineNo: Integer)
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (DocumentNo = '') or (ResourceNo = '') then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := "Service Log Document Type".FromInteger(DocumentType);
        ServOrderLog."Document No." := DocumentNo;
        ServOrderLog."Service Item Line No." := ServItemLineNo;
        ServOrderLog."Event No." := 17;
        ServOrderLog.After := ResourceNo;
        ServOrderLog.Before := ResourceNo;
        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderCreate(ServHeader: Record "Service Header")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if ServHeader."No." = '' then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServHeader."Document Type";
        ServOrderLog."Document No." := ServHeader."No.";
        case ServOrderLog."Document Type" of
            ServOrderLog."Document Type"::Quote:
                ServOrderLog."Event No." := 13;
            ServOrderLog."Document Type"::Invoice:
                ServOrderLog."Event No." := 20;
            ServOrderLog."Document Type"::"Credit Memo":
                ServOrderLog."Event No." := 21;
            else begin
                ServOrderLog."Event No." := 1;
                OnServHeaderCreateOnCaseElse(ServOrderLog, ServHeader);
            end;
        end;
        ServOrderLog.Insert(true);
    end;

    procedure ServOrderShipmentPost(ServOrderNo: Code[20]; ShptNo: Code[20])
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServOrderNo = '') or (ShptNo = '') then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServOrderLog."Document Type"::Shipment;
        ServOrderLog."Document No." := ShptNo;
        ServOrderLog.Before := ServOrderNo;
        ServOrderLog."Event No." := 6;
        ServOrderLog.Insert(true);
    end;

    procedure ServOrderInvoicePost(ServOrderNo: Code[20]; InvoiceNo: Code[20])
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServOrderNo = '') or (InvoiceNo = '') then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServOrderLog."Document Type"::"Posted Invoice";
        ServOrderLog."Document No." := InvoiceNo;
        ServOrderLog.Before := ServOrderNo;
        ServOrderLog."Event No." := 9;
        ServOrderLog.Insert(true);
    end;

    procedure ServInvoicePost(ServOrderNo: Code[20]; InvoiceNo: Code[20])
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServOrderNo = '') or (InvoiceNo = '') then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServOrderLog."Document Type"::"Posted Invoice";
        ServOrderLog."Document No." := InvoiceNo;
        ServOrderLog.Before := ServOrderNo;
        ServOrderLog."Event No." := 22;
        ServOrderLog.Insert(true);
    end;

    procedure ServCrMemoPost(ServOrderNo: Code[20]; CrMemoNo: Code[20])
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServOrderNo = '') or (CrMemoNo = '') then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServOrderLog."Document Type"::"Posted Credit Memo";
        ServOrderLog."Document No." := CrMemoNo;
        ServOrderLog."Event No." := 16;
        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderManualDelete(ServHeader: Record "Service Header")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if ServHeader."No." = '' then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServHeader."Document Type";
        ServOrderLog."Document No." := ServHeader."No.";
        case ServOrderLog."Document Type" of
            ServOrderLog."Document Type"::Invoice:
                ServOrderLog."Event No." := 23;
            ServOrderLog."Document Type"::"Credit Memo":
                ServOrderLog."Event No." := 24;
            else
                ServOrderLog."Event No." := 10
        end;
        ServOrderLog.After := '';

        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderContractNoChanged(ServHeader: Record "Service Header"; OldServHeader: Record "Service Header")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServHeader."No." = '') or (ServHeader."Contract No." = OldServHeader."Contract No.") then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServHeader."Document Type";
        ServOrderLog."Document No." := ServHeader."No.";
        ServOrderLog.After := ServHeader."Contract No.";
        ServOrderLog.Before := OldServHeader."Contract No.";
        ServOrderLog."Event No." := 11;
        ServOrderLog.Insert(true);
    end;

    procedure ServOrderQuoteChanged(ServHeader: Record "Service Header"; OldServHeader: Record "Service Header")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if ServHeader."No." = '' then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := OldServHeader."Document Type";
        ServOrderLog."Document No." := OldServHeader."No.";
        ServOrderLog.After :=
          CopyStr(
            Format(ServHeader."Document Type") + ' ' + ServHeader."No.",
            1, MaxStrLen(ServOrderLog.After));
        ServOrderLog.Before :=
          CopyStr(
            Format(OldServHeader."Document Type") + ' ' + OldServHeader."No.",
            1, MaxStrLen(ServOrderLog.Before));
        ServOrderLog."Event No." := 12;
        ServOrderLog.Insert(true);
    end;

    procedure ServHeaderRepairStatusChange(ServItemLine: Record "Service Item Line"; OldServItemLine: Record "Service Item Line")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServItemLine."Document No." = '') or (ServItemLine."Line No." = 0) then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServItemLine."Document Type";
        ServOrderLog."Document No." := ServItemLine."Document No.";
        ServOrderLog."Service Item Line No." := ServItemLine."Line No.";
        ServOrderLog.After := ServItemLine."Repair Status Code";
        ServOrderLog.Before := OldServItemLine."Repair Status Code";
        ServOrderLog."Event No." := 14;
        ServOrderLog.Insert(true);
    end;

    procedure LoanerLent(LoanerEntry: Record "Loaner Entry")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if LoanerEntry."Loaner No." = '' then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := LoanerEntry.GetServDocTypeFromDocType();
        ServOrderLog."Document No." := LoanerEntry."Document No.";
        ServOrderLog."Event No." := 7;
        ServOrderLog.After := LoanerEntry."Loaner No.";
        ServOrderLog.Insert(true);
    end;

    procedure LoanerReceived(LoanerEntry: Record "Loaner Entry")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if LoanerEntry."Loaner No." = '' then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := LoanerEntry.GetServDocTypeFromDocType();
        ServOrderLog."Document No." := LoanerEntry."Document No.";
        ServOrderLog."Event No." := 8;
        ServOrderLog.After := LoanerEntry."Loaner No.";
        ServOrderLog.Insert(true);
    end;

    procedure ServItemLineResponseDateChange(var ServItemLine: Record "Service Item Line"; var OldServItemLine: Record "Service Item Line")
    var
        ServiceDocumentLog: Record "Service Document Log";
    begin
        if (ServItemLine."Document No." = '') or (ServItemLine."Line No." = 0) then
            exit;

        ServiceDocumentLog.Init();
        ServiceDocumentLog."Document Type" := ServItemLine."Document Type";
        ServiceDocumentLog."Document No." := ServItemLine."Document No.";
        ServiceDocumentLog."Service Item Line No." := ServItemLine."Line No.";
        ServiceDocumentLog.After := Format(ServItemLine."Response Date");
        ServiceDocumentLog.Before := Format(OldServItemLine."Response Date");
        ServiceDocumentLog."Event No." := 18;
        ServiceDocumentLog.Insert(true);
    end;

    procedure ServItemLineResponseTimeChange(var ServItemLine: Record "Service Item Line"; var OldServItemLine: Record "Service Item Line")
    var
        ServOrderLog: Record "Service Document Log";
    begin
        if (ServItemLine."Document No." = '') or (ServItemLine."Line No." = 0) then
            exit;

        ServOrderLog.Init();
        ServOrderLog."Document Type" := ServItemLine."Document Type";
        ServOrderLog."Document No." := ServItemLine."Document No.";
        ServOrderLog."Service Item Line No." := ServItemLine."Line No.";
        ServOrderLog.After := Format(ServItemLine."Response Time");
        ServOrderLog.Before := Format(OldServItemLine."Response Time");
        ServOrderLog."Event No." := 19;
        ServOrderLog.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServItemEventDescription(var EventNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServItemEventDescription(EventNo: Integer; var Description: Text[50]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServHeaderCreateOnCaseElse(var ServOrderLog: Record "Service Document Log"; ServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServOrderEventDescription(EventNo: Integer; var Description: Text[50]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServItemAddToContractOnBeforeServItemLogInsert(var ServiceItemLog: Record "Service Item Log"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServItemRemovedFromContractOnBeforeServItemLogInsert(var ServiceItemLog: Record "Service Item Log"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServItemToServOrderOnBeforeServItemLogInsert(var ServiceItemLog: Record "Service Item Log"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServItemOffServOrderOnBeforeServItemLogInsert(var ServiceItemLog: Record "Service Item Log"; ServiceItemLine: Record "Service Item Line")
    begin
    end;
}

