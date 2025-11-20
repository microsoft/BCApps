// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

using Microsoft.Service.Document;
using Microsoft.Service.Pricing;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

codeunit 6003 "Service Transfer Ext. Text"
{
    var
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        TempExtTextLine: Record "Extended Text Line" temporary;
        TransferExtendedText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
        LineSpacing: Integer;
        MakeUpdateRequired: Boolean;
        AutoText: Boolean;

        Text000: Label 'There is not enough space to insert extended text lines.';

    procedure ServCheckIfAnyExtText(var ServiceLine: Record "Service Line"; Unconditionally: Boolean) Result: Boolean
    var
        ServHeader: Record "Service Header";
        ExtTextHeader: Record "Extended Text Header";
        ServCost: Record "Service Cost";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServCheckIfAnyExtText(ServiceLine, Unconditionally, MakeUpdateRequired, AutoText, Result, IsHandled);
#if not CLEAN25
        TransferExtendedText.RunOnBeforeServCheckIfAnyExtText(ServiceLine, Unconditionally, MakeUpdateRequired, AutoText, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        MakeUpdateRequired := false;
        if TransferExtendedText.IsDeleteAttachedLines(ServiceLine."Line No.", ServiceLine."No.", ServiceLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteServiceLines(ServiceLine);

        AutoText := false;
        if Unconditionally then
            AutoText := true
        else
            case ServiceLine.Type of
                ServiceLine.Type::" ":
                    AutoText := true;
                ServiceLine.Type::Cost:
                    if ServCost.Get(ServiceLine."No.") then
                        if GLAcc.Get(ServCost."Account No.") then
                            AutoText := GLAcc."Automatic Ext. Texts";
                ServiceLine.Type::Item:
                    if Item.Get(ServiceLine."No.") then
                        AutoText := Item."Automatic Ext. Texts";
                ServiceLine.Type::Resource:
                    if Res.Get(ServiceLine."No.") then
                        AutoText := Res."Automatic Ext. Texts";
                ServiceLine.Type::"G/L Account":
                    if GLAcc.Get(ServiceLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
            end;

        OnServCheckIfAnyExtTextOnBeforeSetFilters(ServiceLine, AutoText, Unconditionally);
#if not CLEAN25
        TransferExtendedText.RunOnServCheckIfAnyExtTextOnBeforeSetFilters(ServiceLine, AutoText, Unconditionally);
#endif

        if AutoText then begin
            case ServiceLine.Type of
                ServiceLine.Type::" ":
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"Standard Text");
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Item:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Resource:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Resource);
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Cost:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
                        ServCost.Get(ServiceLine."No.");
                        ExtTextHeader.SetRange("No.", ServCost."Account No.");
                    end;
                ServiceLine.Type::"G/L Account":
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
            end;

            case ServiceLine."Document Type" of
                ServiceLine."Document Type"::Quote:
                    ExtTextHeader.SetRange("Service Quote", true);
                ServiceLine."Document Type"::Order:
                    ExtTextHeader.SetRange("Service Order", true);
                ServiceLine."Document Type"::Invoice:
                    ExtTextHeader.SetRange("Service Invoice", true);
                ServiceLine."Document Type"::"Credit Memo":
                    ExtTextHeader.SetRange("Service Credit Memo", true);
            end;
            ServHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
            OnServCheckIfAnyExtTextAutoText(ExtTextHeader, ServHeader, ServiceLine, Unconditionally, MakeUpdateRequired);
#if not CLEAN25
            TransferExtendedText.RunOnServCheckIfAnyExtTextAutoText(ExtTextHeader, ServHeader, ServiceLine, Unconditionally, MakeUpdateRequired);
#endif
            TransferExtendedText.SetMakeUpdateRequired(MakeUpdateRequired);
            exit(TransferExtendedText.ReadExtTextLines(ExtTextHeader, ServHeader."Order Date", ServHeader."Language Code"));
        end;
    end;

    local procedure DeleteServiceLines(var ServiceLine: Record "Service Line"): Boolean
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine2.SetRange("Attached to Line No.", ServiceLine."Line No.");
        OnDeleteServiceLinesOnAfterSetFilers(ServiceLine2, ServiceLine);
#if not CLEAN25
        TransferExtendedText.RunOnDeleteServiceLinesOnAfterSetFilers(ServiceLine2, ServiceLine);
#endif
        ServiceLine2 := ServiceLine;
        if ServiceLine2.Find('>') then begin
            repeat
                ServiceLine2.Delete();
            until ServiceLine2.Next() = 0;
            exit(true);
        end;
    end;

    procedure InsertServExtText(var ServiceLine: Record "Service Line")
    var
        ToServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServExtText(ServiceLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
#if not CLEAN25
        OnBeforeInsertServExtText(ServiceLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
#endif
        if IsHandled then
            exit;

        TransferExtendedText.GetTempExtTextLine(TempExtTextLine);

        ToServiceLine.Reset();
        ToServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ToServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ToServiceLine := ServiceLine;
        if ToServiceLine.Find('>') then begin
            LineSpacing :=
              (ToServiceLine."Line No." - ServiceLine."Line No.") div
              (1 + TempExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text000);
        end else
            LineSpacing := 10000;

        NextLineNo := ServiceLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToServiceLine.Init();
                ToServiceLine."Document Type" := ServiceLine."Document Type";
                ToServiceLine."Document No." := ServiceLine."Document No.";
                ToServiceLine."Service Item Line No." := ServiceLine."Service Item Line No.";
                ToServiceLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToServiceLine.Description := TempExtTextLine.Text;
                ToServiceLine."Attached to Line No." := ServiceLine."Line No.";
                ToServiceLine."Service Item No." := ServiceLine."Service Item No.";
                IsHandled := false;
                OnInsertServExtTextOnBeforeToServiceLineInsert(ServiceLine, ToServiceLine, TempExtTextLine, NextLineNo, LineSpacing, IsHandled);
                if not IsHandled then
                    ToServiceLine.Insert(true);
            until TempExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
    end;

    procedure MakeUpdate(): Boolean
    begin
        exit(MakeUpdateRequired);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServCheckIfAnyExtText(var ServiceLine: Record "Service Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean; var AutoText: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServCheckIfAnyExtTextOnBeforeSetFilters(var ServiceLine: Record "Service Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteServiceLinesOnAfterSetFilers(var ServiceLine2: Record "Service Line"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServExtText(var ServiceLine: Record "Service Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServExtTextOnBeforeToServiceLineInsert(var ServLine: Record "Service Line"; var ToServLine: Record "Service Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;
}
