// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Vendor;

codeunit 330 ReqJnlManagement
{
    Permissions = TableData "Req. Wksh. Template" = rimd,
                  TableData "Requisition Wksh. Name" = rimd;

    trigger OnRun()
    begin
    end;

    var
        LastReqLine: Record "Requisition Line";
        OpenFromBatch: Boolean;

#pragma warning disable AA0074
        Text002: Label 'RECURRING';
        Text004: Label 'DEFAULT';
        Text005: Label 'Default Journal';
#pragma warning disable AA0470
        Text99000000: Label '%1 Worksheet';
#pragma warning restore AA0470
        Text99000001: Label 'Recurring Worksheet';
#pragma warning restore AA0074

    procedure WkshTemplateSelection(PageID: Integer; RecurringJnl: Boolean; TemplateType: Enum "Req. Worksheet Template Type"; var ReqLine: Record "Requisition Line"; var JnlSelected: Boolean)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        JnlSelected := true;

        ReqWkshTemplate.Reset();
        ReqWkshTemplate.SetRange("Page ID", PageID);
        ReqWkshTemplate.SetRange(Recurring, RecurringJnl);
        ReqWkshTemplate.SetRange(Type, TemplateType);
        OnWkshTemplateSelectionSetFilter(ReqWkshTemplate, TemplateType);

        case ReqWkshTemplate.Count() of
            0:
                begin
                    ReqWkshTemplate.Init();
                    ReqWkshTemplate.Recurring := RecurringJnl;
                    ReqWkshTemplate.Type := TemplateType;
                    if not RecurringJnl then begin
                        ReqWkshTemplate.Name := CopyStr(Format(TemplateType), 1, MaxStrLen(ReqWkshTemplate.Name));
                        ReqWkshTemplate.Description := StrSubstNo(Text99000000, Format(TemplateType));
                    end else begin
                        ReqWkshTemplate.Name := Text002;
                        ReqWkshTemplate.Description := Text99000001;
                    end;
                    ReqWkshTemplate.Validate("Page ID");
                    ReqWkshTemplate.Insert();
                    Commit();
                end;
            1:
                ReqWkshTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, ReqWkshTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            ReqLine.FilterGroup := 2;
            ReqLine.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
            ReqLine.FilterGroup := 0;
            if OpenFromBatch then begin
                ReqLine."Worksheet Template Name" := '';
                PAGE.Run(ReqWkshTemplate."Page ID", ReqLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var ReqWkshName: Record "Requisition Wksh. Name")
    var
        ReqLine: Record "Requisition Line";
        ReqWkshTmpl: Record "Req. Wksh. Template";
    begin
        OpenFromBatch := true;
        ReqWkshTmpl.Get(ReqWkshName."Worksheet Template Name");
        ReqWkshTmpl.TestField("Page ID");
        ReqWkshName.TestField(Name);

        ReqLine.FilterGroup := 2;
        ReqLine.SetRange("Worksheet Template Name", ReqWkshTmpl.Name);
        ReqLine.FilterGroup := 0;

        ReqLine."Worksheet Template Name" := '';
        ReqLine."Journal Batch Name" := ReqWkshName.Name;
        PAGE.Run(ReqWkshTmpl."Page ID", ReqLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    begin
        OnBeforeOpenJnl(CurrentJnlBatchName, ReqLine);

        CheckTemplateName(ReqLine.GetRangeMax("Worksheet Template Name"), CurrentJnlBatchName);
        ReqLine.FilterGroup := 2;
        ReqLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ReqLine.FilterGroup := 0;
    end;

    procedure OpenJnlBatch(var ReqWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqLine: Record "Requisition Line";
        JnlSelected: Boolean;
    begin
        if ReqWkshName.GetFilter("Worksheet Template Name") <> '' then
            exit;
        ReqWkshName.FilterGroup(2);
        if ReqWkshName.GetFilter("Worksheet Template Name") <> '' then begin
            ReqWkshName.FilterGroup(0);
            exit;
        end;
        ReqWkshName.FilterGroup(0);

        if not ReqWkshName.Find('-') then
            for ReqWkshTmpl.Type := ReqWkshTmpl.Type::"Req." to ReqWkshTmpl.Type::Planning do begin
                ReqWkshTmpl.SetRange(Type, ReqWkshTmpl.Type);
                if not ReqWkshTmpl.FindFirst() then
                    WkshTemplateSelection(0, false, ReqWkshTmpl.Type, ReqLine, JnlSelected);
                if ReqWkshTmpl.FindFirst() then
                    CheckTemplateName(ReqWkshTmpl.Name, ReqWkshName.Name);
                if ReqWkshTmpl.Type in [ReqWkshTmpl.Type::"Req."] then begin
                    ReqWkshTmpl.SetRange(Recurring, true);
                    if not ReqWkshTmpl.FindFirst() then
                        WkshTemplateSelection(0, true, ReqWkshTmpl.Type, ReqLine, JnlSelected);
                    if ReqWkshTmpl.FindFirst() then
                        CheckTemplateName(ReqWkshTmpl.Name, ReqWkshName.Name);
                    ReqWkshTmpl.SetRange(Recurring);
                end;
            end;

        ReqWkshName.Find('-');
        JnlSelected := true;
        ReqWkshName.CalcFields("Template Type", Recurring);
        ReqWkshTmpl.SetRange(Recurring, ReqWkshName.Recurring);
        if not ReqWkshName.Recurring then
            ReqWkshTmpl.SetRange(Type, ReqWkshName."Template Type");
        if ReqWkshName.GetFilter("Worksheet Template Name") <> '' then
            ReqWkshTmpl.SetRange(Name, ReqWkshName.GetFilter("Worksheet Template Name"));
        case ReqWkshTmpl.Count of
            1:
                ReqWkshTmpl.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, ReqWkshTmpl) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        ReqWkshName.FilterGroup(0);
        ReqWkshName.SetRange("Worksheet Template Name", ReqWkshTmpl.Name);
        ReqWkshName.FilterGroup(2);
    end;

    local procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshName.SetRange("Worksheet Template Name", CurrentJnlTemplateName);
        if not ReqWkshName.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not ReqWkshName.FindFirst() then begin
                ReqWkshName.Init();
                ReqWkshName."Worksheet Template Name" := CurrentJnlTemplateName;
                ReqWkshName.Name := Text004;
                ReqWkshName.Description := Text005;
                ReqWkshName.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := ReqWkshName.Name
        end;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshName.Get(ReqLine.GetRangeMax("Worksheet Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    begin
        ReqLine.FilterGroup := 2;
        ReqLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ReqLine.FilterGroup := 0;
        if ReqLine.Find('-') then;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        Commit();
        ReqWkshName."Worksheet Template Name" := ReqLine.GetRangeMax("Worksheet Template Name");
        ReqWkshName.Name := ReqLine.GetRangeMax("Journal Batch Name");
        ReqWkshName.FilterGroup(2);
        ReqWkshName.SetRange("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        ReqWkshName.FilterGroup(0);
        OnBeforeLookupName(ReqWkshName);
        if PAGE.RunModal(0, ReqWkshName) = ACTION::LookupOK then begin
            CurrentJnlBatchName := ReqWkshName.Name;
            SetName(CurrentJnlBatchName, ReqLine);
        end;
    end;

    procedure GetDescriptionAndRcptName(var ReqLine: Record "Requisition Line"; var Description: Text[100]; var BuyFromVendorName: Text[100])
    var
        Vend: Record Vendor;
        GLAcc: Record "G/L Account";
    begin
        if ReqLine."No." = '' then
            Description := ''
        else
            if (ReqLine.Type <> LastReqLine.Type) or
               (ReqLine."No." <> LastReqLine."No.")
            then
                case ReqLine.Type of
                    ReqLine.Type::"G/L Account":
                        if GLAcc.Get(ReqLine."No.") then
                            Description := GLAcc.Name
                        else
                            Description := '';
                end;

        OnGetDescriptionAndRcptNameOnAfterSetDescription(ReqLine, LastReqLine, Description);

        if ReqLine."Vendor No." = '' then
            BuyFromVendorName := ''
        else
            if ReqLine."Vendor No." <> LastReqLine."Vendor No." then
                if Vend.Get(ReqLine."Vendor No.") then
                    BuyFromVendorName := Vend.Name
                else
                    BuyFromVendorName := '';

        LastReqLine := ReqLine;
        OnAfterGetDescriptionAndRcptName(ReqLine, Description, BuyFromVendorName, LastReqLine);
    end;

    procedure SetUpNewLine(var ReqLine: Record "Requisition Line"; LastReqLine: Record "Requisition Line")
    begin
        ReqLine.Type := LastReqLine.Type;
        ReqLine."Recurring Method" := LastReqLine."Recurring Method";
        ReqLine."Order Date" := LastReqLine."Order Date";

        OnAfterSetUpNewLine(ReqLine, LastReqLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDescriptionAndRcptName(var ReqLine: Record "Requisition Line"; var Description: Text[100]; var BuyFromVendorName: Text[100]; var LastReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ReqLine: Record "Requisition Line"; var LastReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupName(var ReqWkshName: Record "Requisition Wksh. Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWkshTemplateSelectionSetFilter(var ReqWkshTemplate: Record "Req. Wksh. Template"; var Type: Enum "Req. Worksheet Template Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDescriptionAndRcptNameOnAfterSetDescription(var RequisitionLine: Record "Requisition Line"; LastRequisitionLine: Record "Requisition Line"; var Description: Text[100])
    begin
    end;
}

