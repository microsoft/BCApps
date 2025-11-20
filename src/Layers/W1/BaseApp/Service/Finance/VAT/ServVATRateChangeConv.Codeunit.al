// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using Microsoft.Service.Pricing;
using Microsoft.Service.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.Item;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 6471 "Serv. VAT Rate Change Conv."
{
    var
        VATRateChangeConversionMgt: Codeunit "VAT Rate Change Conversion";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text0009: Label 'Conversion cannot be performed before %1 is set to true.';
        Text0010: Label 'The line has been shipped.';
        Text0012: Label 'This line %1 has been split into two lines. The outstanding quantity will be on the new line.';
        Text0013: Label 'This line %1 has been added. It contains the outstanding quantity from line %2.';
#pragma warning restore AA0074
#pragma warning restore AA0470

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VAT Rate Change Conversion", 'OnBeforeFinishConvert', '', false, false)]
    local procedure OnBeforeFinishConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var ProgressWindow: Dialog; var sender: Codeunit "VAT Rate Change Conversion")
    begin
        VATRateChangeConversionMgt := sender;
        UpdateServPriceAdjDetail(VATRateChangeSetup);
        UpdateService(VATRateChangeSetup, ProgressWindow);
    end;

    local procedure UpdateServPriceAdjDetail(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    var
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
        ServPriceAdjustmentDetailNew: Record "Serv. Price Adjustment Detail";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateServPriceAdjDetail(VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        if VATRateChangeSetup."Update Serv. Price Adj. Detail" <>
           VATRateChangeSetup."Update Serv. Price Adj. Detail"::"Gen. Prod. Posting Group"
        then
            exit;
        VATRateChangeConversion.SetRange(Type, VATRateChangeConversion.Type::"Gen. Prod. Posting Group");
        if VATRateChangeConversion.FindSet() then
            repeat
                ServPriceAdjustmentDetail.SetRange("Gen. Prod. Posting Group", VATRateChangeConversion."From Code");
                if ServPriceAdjustmentDetail.FindSet() then
                    repeat
                        VATRateChangeLogEntry.Init();
                        RecRef.GetTable(ServPriceAdjustmentDetailNew);
                        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
                        VATRateChangeLogEntry."Table ID" := Database::"Serv. Price Adjustment Detail";
                        VATRateChangeLogEntry."Old Gen. Prod. Posting Group" := ServPriceAdjustmentDetail."Gen. Prod. Posting Group";
                        VATRateChangeLogEntry."New Gen. Prod. Posting Group" := VATRateChangeConversion."To Code";
                        ServPriceAdjustmentDetailNew := ServPriceAdjustmentDetail;
                        if VATRateChangeSetup."Perform Conversion" then begin
                            ServPriceAdjustmentDetailNew.Rename(
                              ServPriceAdjustmentDetail."Serv. Price Adjmt. Gr. Code", ServPriceAdjustmentDetail.Type, ServPriceAdjustmentDetail."No.", ServPriceAdjustmentDetail."Work Type", VATRateChangeConversion."To Code");
                            VATRateChangeLogEntry.Converted := true
                        end else
                            VATRateChangeLogEntry.Description := StrSubstNo(Text0009, VATRateChangeSetup.FieldCaption("Perform Conversion"));
                        VATRateChangeConversionMgt.WriteLogEntry(VATRateChangeLogEntry);
                    until ServPriceAdjustmentDetail.Next() = 0;
            until VATRateChangeConversion.Next() = 0;
    end;

    local procedure CanUpdateService(ServiceLine: Record "Service Line"): Boolean
    var
        ServiceHeader: Record "Service Header";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        DescriptionTxt: Text[250];
    begin
        DescriptionTxt := '';
        if ServiceLine."Shipment No." <> '' then
            DescriptionTxt := Text0010;
        if DescriptionTxt = '' then
            exit(true);

        VATRateChangeLogEntry.Init();
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        RecRef.GetTable(ServiceHeader);
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        VATRateChangeLogEntry.Description := DescriptionTxt;
        VATRateChangeConversionMgt.WriteLogEntry(VATRateChangeLogEntry);
    end;

    local procedure UpdateService(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var ProgressWindow: Dialog)
    var
        ServiceHeader: Record "Service Header";
        ServiceHeader2: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineOld: Record "Service Line";
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewVATProdPotingGroup: Code[20];
        NewGenProdPostingGroup: Code[20];
        ConvertVATProdPostingGroup: Boolean;
        ConvertGenProdPostingGroup: Boolean;
        ServiceHeaderStatusChanged: Boolean;
        RoundingPrecision: Decimal;
        LastDocNo: Code[20];
        IsHandled: Boolean;
    begin
        ProgressWindow.Update(1, ServiceLine.TableCaption());
        ConvertVATProdPostingGroup := VATRateChangeConversionMgt.ConvertVATProdPostGrp(VATRateChangeSetup."Update Service Docs.");
        ConvertGenProdPostingGroup := VATRateChangeConversionMgt.ConvertGenProdPostGrp(VATRateChangeSetup."Update Service Docs.");
        if not ConvertVATProdPostingGroup and not ConvertGenProdPostingGroup then
            exit;

        IsHandled := false;
        OnBeforeUpdateService(VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        ServiceLine.SetFilter("Document Type", '%1|%2|%3', ServiceLine."Document Type"::Quote, ServiceLine."Document Type"::Order, ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Shipment No.", '');
        LastDocNo := '';
        if ServiceLine.Find('-') then
            repeat
                if VATRateChangeConversionMgt.LineInScope(ServiceLine."Gen. Prod. Posting Group", ServiceLine."VAT Prod. Posting Group", ConvertGenProdPostingGroup, ConvertVATProdPostingGroup) then
                    if CanUpdateService(ServiceLine) and IncludeServiceLine(VATRateChangeSetup, ServiceLine.Type, ServiceLine."No.") then begin
                        if LastDocNo <> ServiceLine."Document No." then begin
                            ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
                            LastDocNo := ServiceHeader."No.";
                        end;

                        if VATRateChangeSetup."Ignore Status on Service Docs." then
                            if ServiceHeader."Release Status" <> ServiceHeader."Release Status"::Open then begin
                                ServiceHeader2 := ServiceHeader;
                                ServiceHeader."Release Status" := ServiceHeader."Release Status"::Open;
                                ServiceHeader.Modify();
                                ServiceHeaderStatusChanged := true;
                            end;

                        if ServiceLine.Quantity = ServiceLine."Outstanding Quantity" then begin
                            if ServiceHeader."Prices Including VAT" then
                                ServiceLineOld := ServiceLine;

                            RecRef.GetTable(ServiceLine);
                            VATRateChangeConversionMgt.UpdateRec(
                              RecRef, VATRateChangeConversionMgt.ConvertVATProdPostGrp(VATRateChangeSetup."Update Service Docs."),
                              VATRateChangeConversionMgt.ConvertGenProdPostGrp(VATRateChangeSetup."Update Service Docs."));

                            ServiceLine.Find();
                            if ServiceHeader."Prices Including VAT" and VATRateChangeSetup."Perform Conversion" and
                               (ServiceLine."VAT %" <> ServiceLineOld."VAT %") and
                               VATRateChangeSetup."Update Unit Price For G/L Acc." and
                               (ServiceLine.Type = ServiceLine.Type::"G/L Account")
                            then begin
                                RecRef.SetTable(ServiceLine);
                                RoundingPrecision := VATRateChangeConversionMgt.GetRoundingPrecision(ServiceHeader."Currency Code");
                                ServiceLine.Validate(ServiceLine."Unit Price", Round(ServiceLine."Unit Price" * (100 + ServiceLine."VAT %") / (100 + ServiceLineOld."VAT %"), RoundingPrecision));
                                ServiceLine.Modify(true);
                            end;
                        end else
                            if VATRateChangeSetup."Perform Conversion" and (ServiceLine."Outstanding Quantity" <> 0) then begin
                                NewVATProdPotingGroup := ServiceLine."VAT Prod. Posting Group";
                                NewGenProdPostingGroup := ServiceLine."Gen. Prod. Posting Group";
                                if ConvertVATProdPostingGroup then
                                    if VATRateChangeConversion.Get(
                                         VATRateChangeConversion.Type::"VAT Prod. Posting Group", ServiceLine."VAT Prod. Posting Group")
                                    then
                                        NewVATProdPotingGroup := VATRateChangeConversion."To Code";
                                if ConvertGenProdPostingGroup then
                                    if VATRateChangeConversion.Get(
                                         VATRateChangeConversion.Type::"Gen. Prod. Posting Group", ServiceLine."Gen. Prod. Posting Group")
                                    then
                                        NewGenProdPostingGroup := VATRateChangeConversion."To Code";
                                AddNewServiceLine(VATRateChangeSetup, ServiceLine, NewVATProdPotingGroup, NewGenProdPostingGroup);
                            end else begin
                                RecRef.GetTable(ServiceLine);
                                VATRateChangeConversionMgt.InitVATRateChangeLogEntry(VATRateChangeLogEntry, RecRef, ServiceLine."Outstanding Quantity", ServiceLine."Line No.");
                                VATRateChangeLogEntry.UpdateGroups(
                                  ServiceLine."Gen. Prod. Posting Group", ServiceLine."Gen. Prod. Posting Group", ServiceLine."VAT Prod. Posting Group", ServiceLine."VAT Prod. Posting Group");
                                VATRateChangeConversionMgt.WriteLogEntry(VATRateChangeLogEntry);
                            end;

                        if ServiceHeaderStatusChanged then begin
                            ServiceHeader."Release Status" := ServiceHeader2."Release Status";
                            ServiceHeader.Modify();
                            ServiceHeaderStatusChanged := false;
                        end;
                    end;
            until ServiceLine.Next() = 0;
    end;

    local procedure AddNewServiceLine(VATRateChangeSetup: Record "VAT Rate Change Setup"; ServiceLine: Record "Service Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        NewServiceLine: Record "Service Line";
        OldServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        OldReservationEntry: Record "Reservation Entry";
        NewReservationEntry: Record "Reservation Entry";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewLineNo: Integer;
        RoundingPrecision: Decimal;
    begin
        if not GetNextServiceLineNo(ServiceLine, NewLineNo) then
            exit;

        NewServiceLine.Init();
        NewServiceLine := ServiceLine;
        NewServiceLine."Line No." := NewLineNo;
        NewServiceLine."Qty. to Invoice" := 0;
        NewServiceLine."Qty. to Ship" := 0;
        NewServiceLine."Qty. Shipped Not Invoiced" := 0;
        NewServiceLine."Quantity Shipped" := 0;
        NewServiceLine."Quantity Invoiced" := 0;
        NewServiceLine."Qty. to Invoice (Base)" := 0;
        NewServiceLine."Qty. to Ship (Base)" := 0;
        NewServiceLine."Qty. Shipped Not Invd. (Base)" := 0;
        NewServiceLine."Qty. Shipped (Base)" := 0;
        NewServiceLine."Qty. Invoiced (Base)" := 0;
        NewServiceLine."Qty. to Consume" := 0;
        NewServiceLine."Quantity Consumed" := 0;
        NewServiceLine."Qty. to Consume (Base)" := 0;
        NewServiceLine."Qty. Consumed (Base)" := 0;
        if (GenProdPostingGroup <> '') and VATRateChangeConversionMgt.ConvertGenProdPostGrp(VATRateChangeSetup."Update Service Docs.") then
            NewServiceLine.Validate(NewServiceLine."Gen. Prod. Posting Group", GenProdPostingGroup);
        if (VATProdPostingGroup <> '') and VATRateChangeConversionMgt.ConvertVATProdPostGrp(VATRateChangeSetup."Update Service Docs.") then
            NewServiceLine.Validate(NewServiceLine."VAT Prod. Posting Group", VATProdPostingGroup);

        NewServiceLine.Validate(NewServiceLine.Quantity, ServiceLine."Outstanding Quantity");
        NewServiceLine.Validate(NewServiceLine."Qty. to Ship", ServiceLine."Qty. to Ship");
        NewServiceLine.Validate(NewServiceLine."Qty. to Consume", ServiceLine."Qty. to Consume");
        if Abs(ServiceLine."Qty. to Invoice") >
           (Abs(ServiceLine."Quantity Shipped") - Abs(ServiceLine."Quantity Invoiced"))
        then
            NewServiceLine.Validate(
              NewServiceLine."Qty. to Invoice",
              ServiceLine."Qty. to Invoice" - (ServiceLine."Quantity Shipped" - ServiceLine."Quantity Invoiced"))
        else
            NewServiceLine.Validate(NewServiceLine."Qty. to Invoice", 0);
        ServiceHeader.Get(NewServiceLine."Document Type", NewServiceLine."Document No.");
        RoundingPrecision := VATRateChangeConversionMgt.GetRoundingPrecision(ServiceHeader."Currency Code");
        if ServiceHeader."Prices Including VAT" then
            NewServiceLine.Validate(NewServiceLine."Unit Price", Round(ServiceLine."Unit Price" * (100 + NewServiceLine."VAT %") / (100 + ServiceLine."VAT %"), RoundingPrecision))
        else
            NewServiceLine.Validate(NewServiceLine."Unit Price", ServiceLine."Unit Price");
        NewServiceLine.Validate(NewServiceLine."Line Discount %", ServiceLine."Line Discount %");
        NewServiceLine.Insert();
        RecRef.GetTable(ServiceLine);
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        VATRateChangeLogEntry.Description := StrSubstNo(Text0012, Format(ServiceLine."Line No."));
        VATRateChangeLogEntry.UpdateGroups(
          ServiceLine."Gen. Prod. Posting Group", ServiceLine."Gen. Prod. Posting Group",
          ServiceLine."VAT Prod. Posting Group", ServiceLine."VAT Prod. Posting Group");
        VATRateChangeLogEntry.Converted := true;
        VATRateChangeConversionMgt.WriteLogEntry(VATRateChangeLogEntry);

        RecRef.GetTable(NewServiceLine);
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        VATRateChangeLogEntry.UpdateGroups(
          ServiceLine."Gen. Prod. Posting Group", NewServiceLine."Gen. Prod. Posting Group",
          ServiceLine."VAT Prod. Posting Group", NewServiceLine."VAT Prod. Posting Group");
        VATRateChangeLogEntry.Description := StrSubstNo(Text0013, Format(NewServiceLine."Line No."), Format(ServiceLine."Line No."));
        VATRateChangeLogEntry.Converted := true;
        VATRateChangeConversionMgt.WriteLogEntry(VATRateChangeLogEntry);

        ServiceLine.CalcFields("Reserved Quantity");
        if ServiceLine."Reserved Quantity" <> 0 then begin
            OldReservationEntry.Reset();
            OldReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
            OldReservationEntry.SetRange("Source ID", ServiceLine."Document No.");
            OldReservationEntry.SetRange("Source Ref. No.", ServiceLine."Line No.");
            OldReservationEntry.SetRange("Source Type", Database::"Service Line");
            OldReservationEntry.SetRange("Source Subtype", ServiceLine."Document Type");
            OldReservationEntry.SetRange("Reservation Status", OldReservationEntry."Reservation Status"::Reservation);
            if OldReservationEntry.FindSet() then
                repeat
                    NewReservationEntry := OldReservationEntry;
                    NewReservationEntry."Source Ref. No." := NewLineNo;
                    NewReservationEntry.Modify();
                until OldReservationEntry.Next() = 0;
        end;

        OldReservationEntry.Reset();
        OldReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        OldReservationEntry.SetRange("Source ID", ServiceLine."Document No.");
        OldReservationEntry.SetRange("Source Ref. No.", ServiceLine."Line No.");
        OldReservationEntry.SetRange("Source Type", Database::"Service Line");
        OldReservationEntry.SetRange("Source Subtype", ServiceLine."Document Type");
        OldReservationEntry.SetRange("Reservation Status", OldReservationEntry."Reservation Status"::Surplus);
        if OldReservationEntry.Find('-') then
            repeat
                NewReservationEntry := OldReservationEntry;
                NewReservationEntry."Source Ref. No." := NewLineNo;
                NewReservationEntry.Modify();
            until OldReservationEntry.Next() = 0;

        OldServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        OldServiceLine.Validate(Quantity, ServiceLine."Quantity Shipped");
        OldServiceLine.Validate("Unit Price", ServiceLine."Unit Price");
        OldServiceLine.Validate("Line Discount %", ServiceLine."Line Discount %");
        OldServiceLine.Validate("Qty. to Ship", 0);
        OldServiceLine.Validate("Qty. to Consume", 0);
        if Abs(OldServiceLine."Qty. to Invoice") >
           (Abs(OldServiceLine."Quantity Shipped") - Abs(OldServiceLine."Quantity Consumed") - Abs(ServiceLine."Quantity Invoiced"))
        then
            OldServiceLine.Validate(
              "Qty. to Invoice", OldServiceLine."Qty. to Invoice" - ServiceLine."Quantity Shipped" - OldServiceLine."Quantity Consumed")
        else
            OldServiceLine.Validate("Qty. to Invoice", OldServiceLine."Qty. to Invoice");

        OnAddNewServiceLineOnBeforeOldServiceLineModify(OldServiceLine, NewServiceLine, VATProdPostingGroup, GenProdPostingGroup);
#if not CLEAN25
        VATRateChangeConversionMgt.RunOnAddNewServiceLineOnBeforeOldServiceLineModify(OldServiceLine, NewServiceLine, VATProdPostingGroup, GenProdPostingGroup);
#endif
        OldServiceLine.Modify();
    end;

    procedure GetNextServiceLineNo(ServiceLine: Record "Service Line"; var NextLineNo: Integer): Boolean
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2.Reset();
        ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine2 := ServiceLine;
        if ServiceLine2.Find('>') then
            NextLineNo := ServiceLine."Line No." + (ServiceLine2."Line No." - ServiceLine."Line No.") div 2;
        if (NextLineNo = ServiceLine."Line No.") or (NextLineNo = 0) then begin
            ServiceLine2.FindLast();
            NextLineNo := ServiceLine2."Line No." + 10000;
        end;
        exit(NextLineNo <> ServiceLine."Line No.");
    end;

    local procedure IncludeServiceLine(var VATRateChangeSetup: Record "VAT Rate Change Setup"; Type: Enum "Service Line Type"; No: Code[20]): Boolean
    begin
        case Type of
            Type::"G/L Account":
                exit(IncludeGLAccount(VATRateChangeSetup, No));
            Type::Item:
                exit(IncludeItem(VATRateChangeSetup, No));
            Type::Resource:
                exit(IncludeRes(VATRateChangeSetup, No));
        end;
        exit(true);
    end;

    local procedure IncludeGLAccount(var VATRateChangeSetup: Record "VAT Rate Change Setup"; No: Code[20]): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if VATRateChangeSetup."Account Filter" = '' then
            exit(true);
        GLAccount."No." := No;
        GLAccount.SetFilter("No.", VATRateChangeSetup."Account Filter");
        exit(not GLAccount.IsEmpty());
    end;

    local procedure IncludeItem(var VATRateChangeSetup: Record "VAT Rate Change Setup"; No: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if VATRateChangeSetup."Item Filter" = '' then
            exit(true);
        Item."No." := No;
        Item.SetFilter("No.", VATRateChangeSetup."Item Filter");
        exit(not Item.IsEmpty());
    end;

    local procedure IncludeRes(var VATRateChangeSetup: Record "VAT Rate Change Setup"; No: Code[20]): Boolean
    var
        Res: Record Resource;
    begin
        if VATRateChangeSetup."Resource Filter" = '' then
            exit(true);
        Res."No." := No;
        Res.SetFilter("No.", VATRateChangeSetup."Resource Filter");
        exit(not Res.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewServiceLineOnBeforeOldServiceLineModify(var OldServiceLine: Record Microsoft.Service.Document."Service Line"; var NewServiceLine: Record Microsoft.Service.Document."Service Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServPriceAdjDetail(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateService(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    // Page "VAT Rate Change Log Entries"

    [EventSubscriber(ObjectType::Page, Page::"VAT Rate Change Log Entries", 'OnAfterShow', '', false, false)]
    local procedure OnAfterShow(VATRateChangeLogEntry: Record "VAT Rate Change Log Entry"; var IsHandled: Boolean; RecRef: RecordRef)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PageManagement: Codeunit "Page Management";
    begin
        if VATRateChangeLogEntry."Table ID" = Database::"Service Line" then begin
            RecRef.SetTable(ServiceLine);
            ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
            PageManagement.PageRunModal(ServiceHeader);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VAT Rate Change Conversion", 'OnAfterAreTablesSelected', '', false, false)]
    local procedure OnAfterAreTablesSelected(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var Result: Boolean)
    begin
        if (VATRateChangeSetup."Update Service Docs." <> VATRateChangeSetup."Update Service Docs."::No) or
           (VATRateChangeSetup."Update Serv. Price Adj. Detail" <> VATRateChangeSetup."Update Serv. Price Adj. Detail"::No)
        then
            Result := true;
    end;
}
