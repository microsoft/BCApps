// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.Deferral;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Utilities;

codeunit 5063 ArchiveManagement
{
    Permissions = tableData "Purch. Comment Line" = r,
                  tableData "Purchase Header Archive" = ri,
                  tableData "Purchase Line Archive" = ri,
                  tableData "Purch. Comment Line Archive" = ri,
                  tabledata "Sales Comment Line" = r,
                  tabledata "Sales Header Archive" = ri,
                  tabledata "Sales Line Archive" = ri,
                  tabledata "Sales Comment Line Archive" = ri;

    trigger OnRun()
    begin
    end;

    var
        DeferralUtilities: Codeunit "Deferral Utilities";
        RecordLinkManagement: Codeunit "Record Link Management";
        ReleaseSalesDoc: Codeunit "Release Sales Document";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Document %1 has been archived.';
        Text002: Label 'Do you want to Restore %1 %2 Version %3?';
        Text003: Label '%1 %2 has been restored.';
        Text004: Label 'Document restored from Version %1.';
        Text005: Label '%1 %2 has been partly posted.\Restore not possible.';
        Text006: Label 'Entries exist for on or more of the following:\  - %1\  - %2\  - %3.\Restoration of document will delete these entries.\Continue with restore?';
        Text007: Label 'Archive %1 no.: %2?';
#pragma warning restore AA0470
        Text008: Label 'Item Tracking Line';
#pragma warning disable AA0470
        Text009: Label 'Unposted %1 %2 does not exist anymore.\It is not possible to restore the %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AutoArchiveSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoArchiveSalesDocument(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesReceivablesSetup.Get();

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                case SalesReceivablesSetup."Archive Quotes" of
                    SalesReceivablesSetup."Archive Quotes"::Always:
                        ArchSalesDocumentNoConfirm(SalesHeader);
                    SalesReceivablesSetup."Archive Quotes"::Question:
                        ArchiveSalesDocument(SalesHeader);
                end;
            SalesHeader."Document Type"::Order:
                if SalesReceivablesSetup."Archive Orders" then begin
                    PrepareDeferralsForSalesOrder(SalesHeader);
                    ArchSalesDocumentNoConfirm(SalesHeader);
                end;
            SalesHeader."Document Type"::"Blanket Order":
                if SalesReceivablesSetup."Archive Blanket Orders" then
                    ArchSalesDocumentNoConfirm(SalesHeader);
            SalesHeader."Document Type"::"Return Order":
                if SalesReceivablesSetup."Archive Return Orders" then
                    ArchSalesDocumentNoConfirm(SalesHeader);
        end;

        OnAfterAutoArchiveSalesDocument(SalesHeader);
    end;

    procedure AutoArchivePurchDocument(var PurchaseHeader: Record "Purchase Header")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoArchivePurchDocument(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        PurchasesPayablesSetup.Get();

        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Quote:
                case PurchasesPayablesSetup."Archive Quotes" of
                    PurchasesPayablesSetup."Archive Quotes"::Always:
                        ArchPurchDocumentNoConfirm(PurchaseHeader);
                    PurchasesPayablesSetup."Archive Quotes"::Question:
                        ArchivePurchDocument(PurchaseHeader);
                end;
            PurchaseHeader."Document Type"::Order:
                if PurchasesPayablesSetup."Archive Orders" then begin
                    PrepareDeferralsPurchaseOrder(PurchaseHeader);
                    ArchPurchDocumentNoConfirm(PurchaseHeader);
                end;
            PurchaseHeader."Document Type"::"Blanket Order":
                if PurchasesPayablesSetup."Archive Blanket Orders" then
                    ArchPurchDocumentNoConfirm(PurchaseHeader);
            PurchaseHeader."Document Type"::"Return Order":
                if PurchasesPayablesSetup."Archive Return Orders" then
                    ArchPurchDocumentNoConfirm(PurchaseHeader);
        end;

        OnAfterAutoArchivePurchDocument(PurchaseHeader);
    end;

    procedure ArchiveSalesDocument(var SalesHeader: Record "Sales Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveSalesDocument(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text007, SalesHeader."Document Type", SalesHeader."No."), true)
        then begin
            StoreSalesDocument(SalesHeader, false);
            Message(Text001, SalesHeader."No.");
        end;
    end;

    procedure ArchivePurchDocument(var PurchHeader: Record "Purchase Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchivePurchDocument(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text007, PurchHeader."Document Type", PurchHeader."No."), true)
        then begin
            StorePurchDocument(PurchHeader, false);
            Message(Text001, PurchHeader."No.");
        end;
    end;

    procedure StoreSalesDocument(var SalesHeader: Record "Sales Header"; InteractionExist: Boolean)
    var
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStoreSalesDocument(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesHeaderArchive.Init();
        SalesHeader.CalcFields("Work Description");
        SalesHeaderArchive.TransferFields(SalesHeader);
        SalesHeaderArchive."Archived By" := CopyStr(UserId(), 1, MaxStrLen(SalesHeaderArchive."Archived By"));
        SalesHeaderArchive."Date Archived" := Today();
        SalesHeaderArchive."Time Archived" := Time();
        SalesHeaderArchive."Version No." :=
            GetNextVersionNo(
                DATABASE::"Sales Header", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", SalesHeader."Doc. No. Occurrence");
        SalesHeaderArchive."Interaction Exist" := InteractionExist;
        RecordLinkManagement.CopyLinks(SalesHeader, SalesHeaderArchive);
        OnBeforeSalesHeaderArchiveInsert(SalesHeaderArchive, SalesHeader);
        SalesHeaderArchive.Insert();
        OnAfterSalesHeaderArchiveInsert(SalesHeaderArchive, SalesHeader);

        StoreSalesDocumentComments(
            SalesHeader."Document Type".AsInteger(), SalesHeader."No.", SalesHeader."Doc. No. Occurrence", SalesHeaderArchive."Version No.");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                SalesLineArchive.Init();
                SalesLineArchive.TransferFields(SalesLine);
                SalesLineArchive."Doc. No. Occurrence" := SalesHeader."Doc. No. Occurrence";
                SalesLineArchive."Version No." := SalesHeaderArchive."Version No.";
                RecordLinkManagement.CopyLinks(SalesLine, SalesLineArchive);
                OnBeforeSalesLineArchiveInsert(SalesLineArchive, SalesLine);
                SalesLineArchive.Insert();
                if SalesLine."Deferral Code" <> '' then
                    StoreDeferrals(
                        Enum::"Deferral Document Type"::Sales.AsInteger(), SalesLine."Document Type".AsInteger(),
                        SalesLine."Document No.", SalesLine."Line No.", SalesHeader."Doc. No. Occurrence", SalesHeaderArchive."Version No.");

                OnAfterStoreSalesLineArchive(SalesHeader, SalesLine, SalesHeaderArchive, SalesLineArchive);
            until SalesLine.Next() = 0;

        OnAfterStoreSalesDocument(SalesHeader, SalesHeaderArchive);
    end;

    procedure StorePurchDocument(var PurchHeader: Record "Purchase Header"; InteractionExist: Boolean)
    var
        PurchLine: Record "Purchase Line";
        PurchHeaderArchive: Record "Purchase Header Archive";
        PurchLineArchive: Record "Purchase Line Archive";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStorePurchDocument(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchHeaderArchive.Init();
        PurchHeaderArchive.TransferFields(PurchHeader);
        PurchHeaderArchive."Archived By" := CopyStr(UserId(), 1, MaxStrLen(PurchHeaderArchive."Archived By"));
        PurchHeaderArchive."Date Archived" := Today();
        PurchHeaderArchive."Time Archived" := Time();
        PurchHeaderArchive."Version No." :=
            GetNextVersionNo(
                DATABASE::"Purchase Header", PurchHeader."Document Type".AsInteger(), PurchHeader."No.", PurchHeader."Doc. No. Occurrence");
        PurchHeaderArchive."Interaction Exist" := InteractionExist;
        RecordLinkManagement.CopyLinks(PurchHeader, PurchHeaderArchive);
        OnBeforePurchHeaderArchiveInsert(PurchHeaderArchive, PurchHeader);
        PurchHeaderArchive.Insert();
        OnAfterPurchHeaderArchiveInsert(PurchHeaderArchive, PurchHeader);

        StorePurchDocumentComments(
            PurchHeader."Document Type".AsInteger(), PurchHeader."No.", PurchHeader."Doc. No. Occurrence", PurchHeaderArchive."Version No.");

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindSet() then
            repeat
                PurchLineArchive.Init();
                PurchLineArchive.TransferFields(PurchLine);
                PurchLineArchive."Doc. No. Occurrence" := PurchHeader."Doc. No. Occurrence";
                PurchLineArchive."Version No." := PurchHeaderArchive."Version No.";
                RecordLinkManagement.CopyLinks(PurchLine, PurchLineArchive);
                OnBeforePurchLineArchiveInsert(PurchLineArchive, PurchLine);
                PurchLineArchive.Insert();
                if PurchLine."Deferral Code" <> '' then
                    StoreDeferrals(
                        Enum::"Deferral Document Type"::Purchase.AsInteger(), PurchLine."Document Type".AsInteger(),
                        PurchLine."Document No.", PurchLine."Line No.", PurchHeader."Doc. No. Occurrence", PurchHeaderArchive."Version No.");

                OnAfterStorePurchLineArchive(PurchHeader, PurchLine, PurchHeaderArchive, PurchLineArchive);
            until PurchLine.Next() = 0;

        OnAfterStorePurchDocument(PurchHeader, PurchHeaderArchive);
    end;

    procedure RestoreSalesDocument(var SalesHeaderArchive: Record "Sales Header Archive")
    var
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        ReservEntry: Record "Reservation Entry";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmRequired: Boolean;
        RestoreDocument: Boolean;
        OldOpportunityNo: Code[20];
        IsHandled: Boolean;
        DoCheck, SkipDeletingLinks : Boolean;
    begin
        OnBeforeRestoreSalesDocument(SalesHeaderArchive, IsHandled);
        if IsHandled then
            exit;

        if not SalesHeader.Get(SalesHeaderArchive."Document Type", SalesHeaderArchive."No.") then
            Error(Text009, SalesHeaderArchive."Document Type", SalesHeaderArchive."No.");

        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        DoCheck := true;
        OnBeforeCheckIfDocumentIsPartiallyPosted(SalesHeaderArchive, DoCheck);

        if (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) and DoCheck then begin
            SalesShptHeader.Reset();
            SalesShptHeader.SetCurrentKey("Order No.");
            SalesShptHeader.SetRange("Order No.", SalesHeader."No.");
            if not SalesShptHeader.IsEmpty() then
                Error(Text005, SalesHeader."Document Type", SalesHeader."No.");
            SalesInvHeader.Reset();
            SalesInvHeader.SetCurrentKey("Order No.");
            SalesInvHeader.SetRange("Order No.", SalesHeader."No.");
            if not SalesInvHeader.IsEmpty() then
                Error(Text005, SalesHeader."Document Type", SalesHeader."No.");
        end;

        ConfirmRequired := false;
        ReservEntry.Reset();
        ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        ReservEntry.SetRange("Source ID", SalesHeader."No.");
        ReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservEntry.SetRange("Source Subtype", SalesHeader."Document Type");
        if ReservEntry.FindFirst() then
            ConfirmRequired := true;

        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", SalesHeader."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesHeader."No.");
        if ItemChargeAssgntSales.FindFirst() then
            ConfirmRequired := true;

        RestoreDocument := false;
        if ConfirmRequired then begin
            if ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text006, ReservEntry.TableCaption(), ItemChargeAssgntSales.TableCaption(), Text008), true)
            then
                RestoreDocument := true;
        end else
            if ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text002, SalesHeaderArchive."Document Type",
                   SalesHeaderArchive."No.", SalesHeaderArchive."Version No."), true)
            then
                RestoreDocument := true;
        if RestoreDocument then begin
            SalesHeader.TestField("Doc. No. Occurrence", SalesHeaderArchive."Doc. No. Occurrence");
            SalesHeaderArchive.CalcFields("Work Description");
            if SalesHeader."Opportunity No." <> '' then begin
                OldOpportunityNo := SalesHeader."Opportunity No.";
                SalesHeader."Opportunity No." := '';
            end;
            SkipDeletingLinks := false;
            OnRestoreDocumentOnBeforeDeleteSalesHeader(SalesHeader, SkipDeletingLinks);
            if not SkipDeletingLinks then
                SalesHeader.DeleteLinks();
            SalesHeader.Delete(true);
            OnRestoreDocumentOnAfterDeleteSalesHeader(SalesHeader);

            SalesHeader.Init();
            SalesHeader.SetHideValidationDialog(true);
            SalesHeader."Document Type" := SalesHeaderArchive."Document Type";
            SalesHeader."No." := SalesHeaderArchive."No.";
            OnBeforeSalesHeaderInsert(SalesHeader, SalesHeaderArchive);
            SalesHeader.Insert(true);
            OnRestoreSalesDocumentOnAfterSalesHeaderInsert(SalesHeader, SalesHeaderArchive);
            SalesHeader.TransferFields(SalesHeaderArchive);
            SalesHeader.Status := SalesHeader.Status::Open;
            OnRestoreSalesDocumentOnBeforeSalesHeaderValidateFields(SalesHeader, SalesHeaderArchive);
            if SalesHeaderArchive."Sell-to Contact No." <> '' then
                SalesHeader.Validate("Sell-to Contact No.", SalesHeaderArchive."Sell-to Contact No.")
            else
                SalesHeader.Validate("Sell-to Customer No.", SalesHeaderArchive."Sell-to Customer No.");
            if SalesHeaderArchive."Bill-to Contact No." <> '' then
                SalesHeader.Validate("Bill-to Contact No.", SalesHeaderArchive."Bill-to Contact No.")
            else
                SalesHeader.Validate("Bill-to Customer No.", SalesHeaderArchive."Bill-to Customer No.");
            SalesHeader.Validate("Salesperson Code", SalesHeaderArchive."Salesperson Code");
            SalesHeader.Validate("Payment Terms Code", SalesHeaderArchive."Payment Terms Code");
            SalesHeader.Validate("Payment Discount %", SalesHeaderArchive."Payment Discount %");
            SalesHeader."Shortcut Dimension 1 Code" := SalesHeaderArchive."Shortcut Dimension 1 Code";
            SalesHeader."Shortcut Dimension 2 Code" := SalesHeaderArchive."Shortcut Dimension 2 Code";
            SalesHeader."Dimension Set ID" := SalesHeaderArchive."Dimension Set ID";
            RecordLinkManagement.CopyLinks(SalesHeaderArchive, SalesHeader);
            SalesHeader.LinkSalesDocWithOpportunity(OldOpportunityNo);
            OnAfterTransferFromArchToSalesHeader(SalesHeader, SalesHeaderArchive);
            SalesHeader.Modify(true);
            RestoreSalesLines(SalesHeaderArchive, SalesHeader);
            SalesHeader.Status := SalesHeader.Status::Released;
            ReleaseSalesDoc.Reopen(SalesHeader);
            OnAfterRestoreSalesDocument(SalesHeader, SalesHeaderArchive);

            Message(Text003, SalesHeader."Document Type", SalesHeader."No.");
        end;
    end;

    local procedure RestoreSalesLines(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesLineArchive: Record "Sales Line Archive";
        ShouldValidateQuantity: Boolean;
    begin
        RestoreSalesLineComments(SalesHeaderArchive, SalesHeader);

        SalesLineArchive.SetRange("Document Type", SalesHeaderArchive."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesHeaderArchive."No.");
        SalesLineArchive.SetRange("Doc. No. Occurrence", SalesHeaderArchive."Doc. No. Occurrence");
        SalesLineArchive.SetRange("Version No.", SalesHeaderArchive."Version No.");
        OnRestoreSalesLinesOnAfterSalesLineArchiveSetFilters(SalesLineArchive, SalesHeaderArchive, SalesHeader);
        if SalesLineArchive.FindSet() then
            repeat
                SalesLine.Init();
                SalesLine.TransferFields(SalesLineArchive);
                OnRestoreSalesLinesOnBeforeSalesLineInsert(SalesLine, SalesLineArchive);
                SalesLine.Insert(true);
                OnRestoreSalesLinesOnAfterSalesLineInsert(SalesLine, SalesLineArchive);
                if SalesLine.Type <> SalesLine.Type::" " then begin
                    SalesLine.Validate("No.");
                    if SalesLineArchive."Variant Code" <> '' then
                        SalesLine.Validate("Variant Code", SalesLineArchive."Variant Code");
                    if SalesLineArchive."Unit of Measure Code" <> '' then
                        SalesLine.Validate("Unit of Measure Code", SalesLineArchive."Unit of Measure Code");
                    SalesLine.Validate("Location Code", SalesLineArchive."Location Code");
                    ShouldValidateQuantity := SalesLine.Quantity <> 0;
                    OnRestoreSalesLinesOnAfterCalcShouldValidateQuantity(SalesLine, SalesLineArchive, ShouldValidateQuantity);
                    if ShouldValidateQuantity then
                        SalesLine.Validate(Quantity, SalesLineArchive.Quantity);
                    OnRestoreSalesLinesOnAfterValidateQuantity(SalesLine, SalesLineArchive);
                    SalesLine.Validate("Unit Price", SalesLineArchive."Unit Price");
                    SalesLine.Validate("Unit Cost (LCY)", SalesLineArchive."Unit Cost (LCY)");
                    SalesLine.Validate("Line Discount %", SalesLineArchive."Line Discount %");
                    if SalesLineArchive."Inv. Discount Amount" <> 0 then
                        SalesLine.Validate("Inv. Discount Amount", SalesLineArchive."Inv. Discount Amount");
                    if SalesLine.Amount <> SalesLineArchive.Amount then
                        SalesLine.Validate(Amount, SalesLineArchive.Amount);
                    SalesLine.Validate(Description, SalesLineArchive.Description);
                end;
                SalesLine."Shortcut Dimension 1 Code" := SalesLineArchive."Shortcut Dimension 1 Code";
                SalesLine."Shortcut Dimension 2 Code" := SalesLineArchive."Shortcut Dimension 2 Code";
                SalesLine."Dimension Set ID" := SalesLineArchive."Dimension Set ID";
                SalesLine."Deferral Code" := SalesLineArchive."Deferral Code";
                RestoreDeferrals(
                    Enum::"Deferral Document Type"::Sales.AsInteger(),
                    SalesLineArchive."Document Type".AsInteger(), SalesLineArchive."Document No.", SalesLineArchive."Line No.",
                    SalesHeaderArchive."Doc. No. Occurrence", SalesHeaderArchive."Version No.");
                RecordLinkManagement.CopyLinks(SalesLineArchive, SalesLine);
                OnAfterTransferFromArchToSalesLine(SalesLine, SalesLineArchive);
                SalesLine.Modify(true);
                OnAfterRestoreSalesLine(SalesHeader, SalesLine, SalesHeaderArchive, SalesLineArchive);
            until SalesLineArchive.Next() = 0;

        OnAfterRestoreSalesLines(SalesHeader, SalesLine, SalesHeaderArchive, SalesLineArchive);
    end;

    procedure GetNextOccurrenceNo(TableId: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]) OccurenceNo: Integer
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchHeaderArchive: Record "Purchase Header Archive";
    begin
        case TableId of
            DATABASE::"Sales Header":
                begin
                    SalesHeaderArchive.LockTable();
                    SalesHeaderArchive.SetRange("Document Type", DocType);
                    SalesHeaderArchive.SetRange("No.", DocNo);
                    if SalesHeaderArchive.FindLast() then
                        exit(SalesHeaderArchive."Doc. No. Occurrence" + 1);

                    exit(1);
                end;
            DATABASE::"Purchase Header":
                begin
                    PurchHeaderArchive.LockTable();
                    PurchHeaderArchive.SetRange("Document Type", DocType);
                    PurchHeaderArchive.SetRange("No.", DocNo);
                    if PurchHeaderArchive.FindLast() then
                        exit(PurchHeaderArchive."Doc. No. Occurrence" + 1);

                    exit(1);
                end;
            else begin
                OnGetNextOccurrenceNo(TableId, DocType, DocNo, OccurenceNo);
                exit(OccurenceNo)
            end;
        end;
    end;

    procedure GetNextVersionNo(TableId: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]; DocNoOccurrence: Integer) VersionNo: Integer
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchHeaderArchive: Record "Purchase Header Archive";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNextVersionNo(TableId, DocType, DocNo, DocNoOccurrence, VersionNo, IsHandled);
        if IsHandled then
            exit(VersionNo);

        case TableId of
            DATABASE::"Sales Header":
                begin
                    SalesHeaderArchive.LockTable();
                    SalesHeaderArchive.SetRange("Document Type", DocType);
                    SalesHeaderArchive.SetRange("No.", DocNo);
                    SalesHeaderArchive.SetRange("Doc. No. Occurrence", DocNoOccurrence);
                    if SalesHeaderArchive.FindLast() then
                        exit(SalesHeaderArchive."Version No." + 1);

                    exit(1);
                end;
            DATABASE::"Purchase Header":
                begin
                    PurchHeaderArchive.LockTable();
                    PurchHeaderArchive.SetRange("Document Type", DocType);
                    PurchHeaderArchive.SetRange("No.", DocNo);
                    PurchHeaderArchive.SetRange("Doc. No. Occurrence", DocNoOccurrence);
                    if PurchHeaderArchive.FindLast() then
                        exit(PurchHeaderArchive."Version No." + 1);

                    exit(1);
                end;
            else begin
                OnGetNextVersionNo(TableId, DocType, DocNo, DocNoOccurrence, VersionNo);
                exit(VersionNo)
            end;
        end;
    end;

    procedure SalesDocArchiveGranule(): Boolean
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        if not ((SalesSetup."Archive Quotes" in [SalesSetup."Archive Quotes"::Question, SalesSetup."Archive Quotes"::Always]) or SalesSetup."Archive Orders") then
            exit(false);
        exit(SalesHeaderArchive.WritePermission);
    end;

    procedure PurchaseDocArchiveGranule(): Boolean
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchaseSetup: Record "Purchases & Payables Setup";
    begin
        PurchaseSetup.Get();
        if not ((PurchaseSetup."Archive Quotes" in [PurchaseSetup."Archive Quotes"::Question, PurchaseSetup."Archive Quotes"::Always]) or PurchaseSetup."Archive Orders") then
            exit(false);
        exit(PurchaseHeaderArchive.WritePermission);
    end;

    local procedure StoreSalesDocumentComments(DocType: Option; DocNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesCommentLineArch: Record "Sales Comment Line Archive";
    begin
        SalesCommentLine.SetRange("Document Type", DocType);
        SalesCommentLine.SetRange("No.", DocNo);
        if SalesCommentLine.FindSet() then
            repeat
                SalesCommentLineArch.Init();
                SalesCommentLineArch.TransferFields(SalesCommentLine);
                SalesCommentLineArch."Doc. No. Occurrence" := DocNoOccurrence;
                SalesCommentLineArch."Version No." := VersionNo;
                OnStoreSalesDocumentCommentsOnBeforeSalesCommentLineArchInsert(SalesCommentLineArch, SalesCommentLine);
                SalesCommentLineArch.Insert();
            until SalesCommentLine.Next() = 0;
    end;

    procedure StorePurchDocumentComments(DocType: Option; DocNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer)
    var
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCommentLineArch: Record "Purch. Comment Line Archive";
    begin
        PurchCommentLine.SetRange("Document Type", DocType);
        PurchCommentLine.SetRange("No.", DocNo);
        if PurchCommentLine.FindSet() then
            repeat
                PurchCommentLineArch.Init();
                PurchCommentLineArch.TransferFields(PurchCommentLine);
                PurchCommentLineArch."Doc. No. Occurrence" := DocNoOccurrence;
                PurchCommentLineArch."Version No." := VersionNo;
                OnStorePurchDocumentCommentsOnBeforePurchCommentLineArchInsert(PurchCommentLineArch, PurchCommentLine);
                PurchCommentLineArch.Insert();
            until PurchCommentLine.Next() = 0;
    end;

    procedure ArchSalesDocumentNoConfirm(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchSalesDocumentNoConfirm(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        StoreSalesDocument(SalesHeader, false);
    end;

    procedure ArchPurchDocumentNoConfirm(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchPurchDocumentNoConfirm(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        StorePurchDocument(PurchHeader, false);
    end;

    local procedure StoreDeferrals(DeferralDocType: Integer; DocType: Integer; DocNo: Code[20]; LineNo: Integer; DocNoOccurrence: Integer; VersionNo: Integer)
    var
        DeferralHeaderArchive: Record "Deferral Header Archive";
        DeferralLineArchive: Record "Deferral Line Archive";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        if DeferralHeader.Get(DeferralDocType, '', '', DocType, DocNo, LineNo) then begin
            DeferralHeaderArchive.Init();
            DeferralHeaderArchive.TransferFields(DeferralHeader);
            DeferralHeaderArchive."Doc. No. Occurrence" := DocNoOccurrence;
            DeferralHeaderArchive."Version No." := VersionNo;
            DeferralHeaderArchive.Insert();

            DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
            DeferralLine.SetRange("Gen. Jnl. Template Name", '');
            DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
            DeferralLine.SetRange("Document Type", DocType);
            DeferralLine.SetRange("Document No.", DocNo);
            DeferralLine.SetRange("Line No.", LineNo);
            if DeferralLine.FindSet() then
                repeat
                    DeferralLineArchive.Init();
                    DeferralLineArchive.TransferFields(DeferralLine);
                    DeferralLineArchive."Doc. No. Occurrence" := DocNoOccurrence;
                    DeferralLineArchive."Version No." := VersionNo;
                    DeferralLineArchive.Insert();
                until DeferralLine.Next() = 0;
        end;
    end;

    local procedure RestoreDeferrals(DeferralDocType: Integer; DocType: Integer; DocNo: Code[20]; LineNo: Integer; DocNoOccurrence: Integer; VersionNo: Integer)
    var
        DeferralHeaderArchive: Record "Deferral Header Archive";
        DeferralLineArchive: Record "Deferral Line Archive";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        if DeferralHeaderArchive.Get(DeferralDocType, DocType, DocNo, DocNoOccurrence, VersionNo, LineNo) then begin
            OnRestoreDeferralsOnAfterGetDeferralHeaderArchive(DeferralHeaderArchive, DeferralHeader);
            // Updates the header if is exists already and removes all the lines
            DeferralUtilities.SetDeferralRecords(DeferralHeader,
              DeferralDocType, '', '',
              DocType, DocNo, LineNo,
              DeferralHeaderArchive."Calc. Method",
              DeferralHeaderArchive."No. of Periods",
              DeferralHeaderArchive."Amount to Defer",
              DeferralHeaderArchive."Start Date",
              DeferralHeaderArchive."Deferral Code",
              DeferralHeaderArchive."Schedule Description",
              DeferralHeaderArchive."Initial Amount to Defer",
              true,
              DeferralHeaderArchive."Currency Code");

            // Add lines as exist in the archives
            DeferralLineArchive.SetRange("Deferral Doc. Type", DeferralDocType);
            DeferralLineArchive.SetRange("Document Type", DocType);
            DeferralLineArchive.SetRange("Document No.", DocNo);
            DeferralLineArchive.SetRange("Doc. No. Occurrence", DocNoOccurrence);
            DeferralLineArchive.SetRange("Version No.", VersionNo);
            DeferralLineArchive.SetRange("Line No.", LineNo);
            if DeferralLineArchive.FindSet() then
                repeat
                    DeferralLine.Init();
                    DeferralLine.TransferFields(DeferralLineArchive);
                    DeferralLine.Insert();
                until DeferralLineArchive.Next() = 0;
        end else
            // Removes any lines that may have been defaulted
            DeferralUtilities.RemoveOrSetDeferralSchedule('', DeferralDocType, '', '', DocType, DocNo, LineNo, 0, 0D, '', '', true);
    end;

    local procedure RestoreSalesLineComments(SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    var
        SalesCommentLineArchive: Record "Sales Comment Line Archive";
        SalesCommentLine: Record "Sales Comment Line";
        NextLine: Integer;
    begin
        SalesCommentLineArchive.SetRange("Document Type", SalesHeaderArchive."Document Type");
        SalesCommentLineArchive.SetRange("No.", SalesHeaderArchive."No.");
        SalesCommentLineArchive.SetRange("Doc. No. Occurrence", SalesHeaderArchive."Doc. No. Occurrence");
        SalesCommentLineArchive.SetRange("Version No.", SalesHeaderArchive."Version No.");
        if SalesCommentLineArchive.FindSet() then
            repeat
                SalesCommentLine.Init();
                SalesCommentLine.TransferFields(SalesCommentLineArchive);
                SalesCommentLine.Insert();
            until SalesCommentLineArchive.Next() = 0;

        SalesCommentLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        SalesCommentLine.SetRange("Document Line No.", 0);
        if SalesCommentLine.FindLast() then
            NextLine := SalesCommentLine."Line No.";
        NextLine += 10000;
        SalesCommentLine.Init();
        SalesCommentLine."Document Type" := SalesHeader."Document Type";
        SalesCommentLine."No." := SalesHeader."No.";
        SalesCommentLine."Document Line No." := 0;
        SalesCommentLine."Line No." := NextLine;
        SalesCommentLine.Date := WorkDate();
        SalesCommentLine.Comment := StrSubstNo(Text004, Format(SalesHeaderArchive."Version No."));
        OnRestoreSalesLineCommentsOnBeforeInsertSalesCommentLine(SalesCommentLine);
        SalesCommentLine.Insert();
    end;

    procedure RoundSalesDeferralsForArchive(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        DeferralHeader: Record "Deferral Header";
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
    begin
        SalesLine.SetFilter("Deferral Code", '<>%1', '');
        if SalesLine.FindSet() then
            repeat
                if DeferralHeader.Get(Enum::"Deferral Document Type"::Sales, '', '',
                     SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
                then
                    DeferralUtilities.RoundDeferralAmount(
                      DeferralHeader, SalesHeader."Currency Code",
                      SalesHeader."Currency Factor", SalesHeader."Posting Date",
                      AmtToDeferACY, AmtToDefer);

            until SalesLine.Next() = 0;
    end;

    procedure RoundPurchaseDeferralsForArchive(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        DeferralHeader: Record "Deferral Header";
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
    begin
        PurchaseLine.SetFilter("Deferral Code", '<>%1', '');
        if PurchaseLine.FindSet() then
            repeat
                if DeferralHeader.Get(Enum::"Deferral Document Type"::Purchase, '', '',
                     PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.")
                then
                    DeferralUtilities.RoundDeferralAmount(
                      DeferralHeader, PurchaseHeader."Currency Code",
                      PurchaseHeader."Currency Factor", PurchaseHeader."Posting Date",
                      AmtToDeferACY, AmtToDefer);
            until PurchaseLine.Next() = 0;
    end;

    local procedure PrepareDeferralsForSalesOrder(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetFilter("Qty. Invoiced (Base)", '<>%1', 0);
            if SalesLine.IsEmpty() then
                exit;
            RoundSalesDeferralsForArchive(SalesHeader, SalesLine);
        end;
    end;

    local procedure PrepareDeferralsPurchaseOrder(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then begin
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            PurchaseLine.SetFilter("Qty. Invoiced (Base)", '<>%1', 0);
            if PurchaseLine.IsEmpty() then
                exit;
            RoundPurchaseDeferralsForArchive(PurchaseHeader, PurchaseLine);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoArchivePurchDocument(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoArchiveSalesDocument(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStoreSalesDocument(var SalesHeader: Record "Sales Header"; var SalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStoreSalesLineArchive(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesHeaderArchive: Record "Sales Header Archive"; var SalesLineArchive: Record "Sales Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStorePurchDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeaderArchive: Record "Purchase Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStorePurchLineArchive(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var PurchHeaderArchive: Record "Purchase Header Archive"; var PurchLineArchive: Record "Purchase Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreSalesDocument(var SalesHeader: Record "Sales Header"; var SalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesHeaderArchive: Record "Sales Header Archive"; var SalesLineArchive: Record "Sales Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreSalesLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesHeaderArchive: Record "Sales Header Archive"; var SalesLineArchive: Record "Sales Line Archive")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesHeaderArchiveInsert(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchHeaderArchiveInsert(var PurchaseHeaderArchive: Record "Purchase Header Archive"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromArchToSalesHeader(var SalesHeader: Record "Sales Header"; var SalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromArchToSalesLine(var SalesLine: Record "Sales Line"; var SalesLineArchive: Record "Sales Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoArchiveSalesDocument(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoArchivePurchDocument(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchivePurchDocument(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; SalesHeaderArchive: Record "Sales Header Archive");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRestoreSalesDocument(var SalesHeaderArchive: Record "Sales Header Archive"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfDocumentIsPartiallyPosted(var SalesHeaderArchive: Record "Sales Header Archive"; var DoCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextVersionNo(TableId: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]; DocNoOccurrence: Integer; var VersionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderArchiveInsert(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineArchiveInsert(var SalesLineArchive: Record "Sales Line Archive"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderArchiveInsert(var PurchaseHeaderArchive: Record "Purchase Header Archive"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineArchiveInsert(var PurchaseLineArchive: Record "Purchase Line Archive"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStoreSalesDocument(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNextOccurrenceNo(TableId: Integer; DocType: Option; DocNo: Code[20]; var OccurenceNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNextVersionNo(TableId: Integer; DocType: Option; DocNo: Code[20]; DocNoOccurrence: Integer; var VersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreDocumentOnAfterDeleteSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreDocumentOnBeforeDeleteSalesHeader(var SalesHeader: Record "Sales Header"; var SkipDeletingLinks: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesLinesOnAfterCalcShouldValidateQuantity(var SalesLine: Record "Sales Line"; var SalesLineArchive: Record "Sales Line Archive"; var ShouldValidateQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesDocumentOnAfterSalesHeaderInsert(var SalesHeader: Record "Sales Header"; var SalesHeaderArchive: Record "Sales Header Archive");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesLinesOnAfterSalesLineInsert(var SalesLine: Record "Sales Line"; var SalesLineArchive: Record "Sales Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesLinesOnAfterSalesLineArchiveSetFilters(var SalesLineArchive: Record "Sales Line Archive"; var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesLinesOnBeforeSalesLineInsert(var SalesLine: Record "Sales Line"; var SalesLineArchive: Record "Sales Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesLinesOnAfterValidateQuantity(var SalesLine: Record "Sales Line"; var SalesLineArchive: Record "Sales Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStorePurchDocumentCommentsOnBeforePurchCommentLineArchInsert(var PurchCommentLineArchive: Record "Purch. Comment Line Archive"; PurchCommentLine: Record "Purch. Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStoreSalesDocumentCommentsOnBeforeSalesCommentLineArchInsert(var SalesCommentLineArchive: Record "Sales Comment Line Archive"; SalesCommentLine: Record "Sales Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStorePurchDocument(var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveSalesDocument(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreDeferralsOnAfterGetDeferralHeaderArchive(DeferralHeaderArchive: Record "Deferral Header Archive"; var DeferralHeader: Record "Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchPurchDocumentNoConfirm(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchSalesDocumentNoConfirm(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesLineCommentsOnBeforeInsertSalesCommentLine(var SalesCommentLine: Record "Sales Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesDocumentOnBeforeSalesHeaderValidateFields(var SalesHeader: Record "Sales Header"; SalesHeaderArchive: Record "Sales Header Archive");
    begin
    end;
}
