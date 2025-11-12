// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;
using System.Utilities;

report 99001043 "Exchange Production BOM Item"
{
    ApplicationArea = Manufacturing;
    Caption = 'Exchange Production BOM Item';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPostDataItem()
            var
                ProdBOMHeader2: Record "Production BOM Header";
                FirstVersion: Boolean;
                ShouldInsertNewProductionBOMLine, ShouldModifyProductionBOMLine : Boolean;
            begin
                Window.Open(
                  Text004 +
                  Text005);

                Window.Update(1, FromProductionBOMLineType);
                Window.Update(2, FromProductionBOMNo);

                ProductionBOMLine.SetCurrentKey(Type, "No.");
                ProductionBOMLine.SetRange(Type, FromProductionBOMLineType);
                ProductionBOMLine.SetRange("No.", FromProductionBOMNo);

                if ProductionBOMLine.Find('+') then
                    repeat
                        FirstVersion := true;
                        ProductionBOMHeader.Get(ProductionBOMLine."Production BOM No.");
                        if ProductionBOMLine."Version Code" <> '' then begin
                            ProductionBOMVersion.Get(
                              ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code");
                            ProductionBOMHeader.Status := ProductionBOMVersion.Status;
                            ProdBOMHeader2 := ProductionBOMHeader;
                            ProdBOMHeader2."Unit of Measure Code" := ProductionBOMVersion."Unit of Measure Code";
                        end else begin
                            ProductionBOMVersion.SetRange("Production BOM No.");
                            ProductionBOMVersion."Version Code" := '';
                            ProdBOMHeader2 := ProductionBOMHeader;
                        end;

                        if IsActiveBOMVersion(ProductionBOMHeader, ProductionBOMLine) then begin
                            Window.Update(3, ProductionBOMLine."Production BOM No.");
                            if not CreateNewVersion then begin
                                if ProductionBOMLine."Version Code" <> '' then begin
                                    ProductionBOMVersion.Status := ProductionBOMVersion.Status::"Under Development";
                                    ProductionBOMVersion.Modify();
                                    ProductionBOMVersion.Mark(true);
                                end else begin
                                    ProductionBOMHeader.Status := ProductionBOMHeader.Status::"Under Development";
                                    ProductionBOMHeader.Modify();
                                    ProductionBOMHeader.Mark(true);
                                end;
                            end else
                                if ProductionBOMLine."Production BOM No." <> ProductionBOMLine2."Production BOM No." then begin
                                    ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMLine."Production BOM No.");

                                    if ProductionBOMVersion.Find('+') then
                                        ProductionBOMVersion."Version Code" := IncrementVersionNo(ProductionBOMVersion."Production BOM No.")
                                    else begin
                                        ProductionBOMVersion."Production BOM No." := ProductionBOMLine."Production BOM No.";
                                        ProductionBOMVersion."Version Code" := '1';
                                    end;
                                    ProductionBOMVersion.Description := ProdBOMHeader2.Description;
                                    ProductionBOMVersion.Validate("Starting Date", StartingDate);
                                    ProductionBOMVersion."Unit of Measure Code" := ProdBOMHeader2."Unit of Measure Code";
                                    ProductionBOMVersion."Last Date Modified" := Today;
                                    ProductionBOMVersion.Status := ProductionBOMVersion.Status::New;
                                    if ProdBOMHeader2."Version Nos." <> '' then begin
                                        ProductionBOMVersion."No. Series" := ProdBOMHeader2."Version Nos.";
                                        ProductionBOMVersion."Version Code" := '';
                                        ProductionBOMVersion.Insert(true);
                                    end else
                                        ProductionBOMVersion.Insert();

                                    OnAfterProdBOMVersionListInsert(ProductionBOMVersion, ProdBOMHeader2);

                                    ProductionBOMVersion.Mark(true);
                                    ProductionBOMLine3.Reset();
                                    ProductionBOMLine3.SetRange("Production BOM No.", ProductionBOMLine."Production BOM No.");
                                    ProductionBOMLine3.SetRange("Version Code", ProductionBOMLine."Version Code");
                                    if ProductionBOMLine3.Find('-') then
                                        repeat
                                            if (ProductionBOMLine.Type <> ProductionBOMLine3.Type) or
                                               (ProductionBOMLine."No." <> ProductionBOMLine3."No.")
                                            then begin
                                                ProductionBOMLine2 := ProductionBOMLine3;
                                                ProductionBOMLine2."Version Code" := ProductionBOMVersion."Version Code";
                                                ProductionBOMLine2.Insert();
                                            end;
                                        until ProductionBOMLine3.Next() = 0
                                    else
                                        FirstVersion := false;
                                end;

                            if (ToProductionBOMNo <> '') and FirstVersion then
                                if CreateNewVersion then begin
                                    ProductionBOMLine3.SetCurrentKey("Production BOM No.", "Version Code");
                                    ProductionBOMLine3.SetRange(Type, FromProductionBOMLineType);
                                    ProductionBOMLine3.SetRange("No.", FromProductionBOMNo);
                                    ProductionBOMLine3.SetRange("Production BOM No.", ProductionBOMLine."Production BOM No.");
                                    ProductionBOMLine3.SetRange("Version Code", ProductionBOMLine."Version Code");
                                    if ProductionBOMLine3.Find('-') then
                                        repeat
                                            ProductionBOMLine2 := ProductionBOMLine3;
                                            ProductionBOMLine2."Version Code" := ProductionBOMVersion."Version Code";
                                            ProductionBOMLine2.Validate(Type, ToProductionBOMLineType);
                                            ProductionBOMLine2.Validate("No.", ToProductionBOMNo);
                                            ProductionBOMLine2.Validate("Quantity per", ProductionBOMLine3."Quantity per" * QtyMultiply);
                                            if CopyRoutingLink then
                                                ProductionBOMLine2.Validate("Routing Link Code", ProductionBOMLine3."Routing Link Code");
                                            CopyPositionFields(ProductionBOMLine2, ProductionBOMLine3);
                                            ProductionBOMLine2."Ending Date" := 0D;

                                            ShouldInsertNewProductionBOMLine := true;
                                            OnBeforeInsertNewProdBOMLine(ProductionBOMLine2, ProductionBOMLine3, QtyMultiply, FirstVersion, ShouldInsertNewProductionBOMLine);
                                            if ShouldInsertNewProductionBOMLine then
                                                ProductionBOMLine2.Insert();
                                        until ProductionBOMLine3.Next() = 0;
                                end else begin
                                    ProductionBOMLine3.SetRange("Production BOM No.", ProductionBOMLine."Production BOM No.");
                                    ProductionBOMLine3.SetRange("Version Code", ProductionBOMVersion."Version Code");
                                    if not ProductionBOMLine3.Find('+') then
                                        Clear(ProductionBOMLine3);
                                    ProductionBOMLine3."Line No." := ProductionBOMLine3."Line No." + 10000;
                                    ProductionBOMLine2 := ProductionBOMLine;
                                    ProductionBOMLine2."Version Code" := ProductionBOMVersion."Version Code";
                                    ProductionBOMLine2.Validate(Type, ToProductionBOMLineType);
                                    ProductionBOMLine2.Validate("No.", ToProductionBOMNo);
                                    ProductionBOMLine2.Validate("Quantity per", ProductionBOMLine."Quantity per" * QtyMultiply);
                                    if CopyRoutingLink then
                                        ProductionBOMLine2.Validate("Routing Link Code", ProductionBOMLine."Routing Link Code");
                                    if not CreateNewVersion then
                                        ProductionBOMLine2."Starting Date" := StartingDate;
                                    ProductionBOMLine2."Ending Date" := 0D;
                                    if DeleteExcComp then begin
                                        ProductionBOMLine2."Line No." := ProductionBOMLine."Line No.";
                                        CopyPositionFields(ProductionBOMLine2, ProductionBOMLine);
                                        ProductionBOMLine.Delete(true);
                                    end else begin
                                        ProductionBOMLine2."Line No." := ProductionBOMLine3."Line No.";
                                        CopyPositionFields(ProductionBOMLine2, ProductionBOMLine3);
                                        ShouldModifyProductionBOMLine := true;
                                        OnIntegerOnPostDataItemOnBeforeModifyProductionBOMLine(ProductionBOMLine, ShouldModifyProductionBOMLine);
                                        if ShouldModifyProductionBOMLine then begin
                                            ProductionBOMLine."Ending Date" := StartingDate - 1;
                                            ProductionBOMLine.Modify();
                                        end;
                                    end;

                                    ShouldInsertNewProductionBOMLine := true;
                                    OnBeforeInsertNewProdBOMLine(ProductionBOMLine2, ProductionBOMLine, QtyMultiply, FirstVersion, ShouldInsertNewProductionBOMLine);
                                    if ShouldInsertNewProductionBOMLine then
                                        ProductionBOMLine2.Insert();
                                end;
                            if (ToProductionBOMNo = '') and FirstVersion then
                                if not CreateNewVersion then
                                    ProductionBOMLine.Delete(true);
                        end;
                    until ProductionBOMLine.Next(-1) = 0;
            end;
        }
        dataitem(RecertifyLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPreDataItem()
            begin
                OnRecertifyLoopOnBeforeOnPreDataItem(FromProductionBOMLineType, FromProductionBOMNo, ToProductionBOMLineType, ToProductionBOMNo, QtyMultiply, CreateNewVersion, StartingDate, Recertify, CopyRoutingLink, DeleteExcComp);
            end;

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                if Recertify then begin
                    ProductionBOMHeader.MarkedOnly(true);
                    IsHandled := false;
                    OnRecertifyLoopOnBeforeLoopProdBOMHeader(ProductionBOMHeader, IsHandled);
                    if not IsHandled then
                        if ProductionBOMHeader.Find('-') then
                            repeat
                                ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
                                ProductionBOMHeader.Modify();
                            until ProductionBOMHeader.Next() = 0;

                    ProductionBOMVersion.SetRange("Production BOM No.");
                    ProductionBOMVersion.MarkedOnly(true);
                    IsHandled := false;
                    OnRecertifyLoopOnBeforeLoopProdBOMVersionList(ProductionBOMVersion, IsHandled);
                    if not IsHandled then
                        if ProductionBOMVersion.Find('-') then
                            repeat
                                ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
                                ProductionBOMVersion.Modify();
                            until ProductionBOMVersion.Next() = 0;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Exchange)
                    {
                        Caption = 'Exchange';
                        field(ExchangeType; FromProductionBOMLineType)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Type';
                            ToolTip = 'Specifies what is to be exchanged here - Item or Production BOM.';

                            trigger OnValidate()
                            begin
                                FromProductionBOMNo := '';
                            end;
                        }
                        field(ExchangeNo; FromProductionBOMNo)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'No.';
                            ToolTip = 'Specifies the item number or the production BOM number that will be exchanged.';
                            ShowMandatory = true;

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                IsHandled: Boolean;
                            begin
                                case FromProductionBOMLineType of
                                    FromProductionBOMLineType::Item:
                                        if PAGE.RunModal(0, Item) = ACTION::LookupOK then begin
                                            Text := Item."No.";
                                            exit(true);
                                        end;
                                    FromProductionBOMLineType::"Production BOM":
                                        if PAGE.RunModal(0, ProductionBOMHeader) = ACTION::LookupOK then begin
                                            Text := ProductionBOMHeader."No.";
                                            exit(true);
                                        end;
                                    else
                                        OnLookupExchangeNo(FromProductionBOMLineType, Text, IsHandled);
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                if FromProductionBOMLineType = FromProductionBOMLineType::" " then
                                    Error(Text006);

                                case FromProductionBOMLineType of
                                    FromProductionBOMLineType::Item:
                                        Item.Get(FromProductionBOMNo);
                                    FromProductionBOMLineType::"Production BOM":
                                        ProductionBOMHeader.Get(FromProductionBOMNo);
                                end;
                            end;
                        }
                    }
                    group("With")
                    {
                        Caption = 'With';
                        field(WithType; ToProductionBOMLineType)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Type';
                            ToolTip = 'Specifies the replacement for the selected exchange type - either Item or Production BOM.';

                            trigger OnValidate()
                            begin
                                ToProductionBOMNo := '';
                            end;
                        }
                        field(WithNo; ToProductionBOMNo)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'No.';
                            ToolTip = 'Specifies the item or production BOM that should serve as a replacement. This field may be left blank if neither the item nor the production BOM is required anymore and should not be included in the new version or removed from the production BOM.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                case ToProductionBOMLineType of
                                    ToProductionBOMLineType::Item:
                                        if PAGE.RunModal(0, Item) = ACTION::LookupOK then begin
                                            Text := Item."No.";
                                            exit(true);
                                        end;
                                    ToProductionBOMLineType::"Production BOM":
                                        if PAGE.RunModal(0, ProductionBOMHeader) = ACTION::LookupOK then begin
                                            Text := ProductionBOMHeader."No.";
                                            exit(true);
                                        end;
                                end;
                                exit(false);
                            end;

                            trigger OnValidate()
                            begin
                                if ToProductionBOMLineType = ToProductionBOMLineType::" " then
                                    Error(Text006);

                                case ToProductionBOMLineType of
                                    ToProductionBOMLineType::Item:
                                        if ToProductionBOMNo <> '' then
                                            Item.Get(ToProductionBOMNo);
                                    ToProductionBOMLineType::"Production BOM":
                                        ProductionBOMHeader.Get(ToProductionBOMNo);
                                end;
                            end;
                        }
                    }
                    field("Create New Version"; CreateNewVersion)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Create New Version';
                        Editable = CreateNewVersionEditable;
                        ToolTip = 'Specifies whether the exchange should create a new version. If enabled, a new version will be created. If disabled, the current production BOM will be updated along with certified Production BOM versions. Note that Production BOM Versions with statuses other than Certified will be ignored.';

                        trigger OnValidate()
                        begin
                            CreateNewVersionOnAfterValidat();
                        end;
                    }
                    field(MultiplyQtyWith; QtyMultiply)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Multiply Qty. with';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the value of a quantity change here. If the quantity is to remain the same, enter 1 here. If you enter 2, the new quantities doubled in comparison with original quantity.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the effective date for these changes. For a new version of the production BOM, this date will be copied to the header. For lines added to the existing production BOM, the date will be specified in the lines.';
                    }
                    field(Recertify; Recertify)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Recertify';
                        ToolTip = 'Specifies whether the production BOM should be certified after the changes. Otherwise, after modification the production BOM or production BOM versions will remain in the Under Development status.';
                    }
                    field(CopyRoutingLink; CopyRoutingLink)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Copy Routing Link';
                        ToolTip = 'Specifies whether or not you want the routing link copied.';
                    }
                    field("Delete Exchanged Component"; DeleteExcComp)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Delete Exchanged Component';
                        Editable = DeleteExchangedComponentEditab;
                        ToolTip = 'Specifies whether the exchanged component should be deleted. This setting is applicable only if the Create New Version option is turned off and a replacement item or production BOM has been selected.';

                        trigger OnValidate()
                        begin
                            DeleteExcCompOnAfterValidate();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            DeleteExchangedComponentEditab := true;
            CreateNewVersionEditable := true;
            CreateNewVersion := true;
            QtyMultiply := 1;
            StartingDate := WorkDate();
            FromProductionBOMLineType := FromProductionBOMLineType::Item;
            ToProductionBOMLineType := ToProductionBOMLineType::Item;

            OnAfterOnInitReport(CreateNewVersion, StartingDate, DeleteExcComp);
        end;

        trigger OnOpenPage()
        begin
            CreateNewVersionEditable := not DeleteExcComp;
            DeleteExchangedComponentEditab := not CreateNewVersion;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Recertify := true;
        CopyRoutingLink := true;
    end;

    trigger OnPreReport()
    begin
        CheckParameters();
    end;

    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMLine2: Record "Production BOM Line";
        ProductionBOMLine3: Record "Production BOM Line";
        Window: Dialog;
        CreateNewVersionEditable: Boolean;
        DeleteExchangedComponentEditab: Boolean;
#pragma warning disable AA0074
        Text000: Label 'You must enter a Starting Date.';
        Text001: Label 'You must enter the Type to exchange.';
        Text002: Label 'You must enter the No. to exchange.';
#pragma warning restore AA0074
        ItemBOMExchangeErr: Label 'You cannot exchange %1 %2 with %3 %4.', Comment = '%1 and %3 are strings (''Item'' or ''Production BOM''), %2 and %4 are either an Item No. or a Production BOM Header No. (Code[20])';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Exchanging #1########## #2############\';
        Text005: Label 'Production BOM No.      #3############';
#pragma warning restore AA0470
        Text006: Label 'Type must be entered.';
#pragma warning restore AA0074

    protected var
        FromProductionBOMLineType: Enum "Production BOM Line Type";
        FromProductionBOMNo: Code[20];
        ToProductionBOMLineType: Enum "Production BOM Line Type";
        ToProductionBOMNo: Code[20];
        QtyMultiply: Decimal;
        CreateNewVersion: Boolean;
        DeleteExcComp: Boolean;
        StartingDate: Date;
        Recertify: Boolean;
        CopyRoutingLink: Boolean;

    local procedure CheckParameters()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckParameters(StartingDate, FromProductionBOMLineType, FromProductionBOMNo, ToProductionBOMLineType, ToProductionBOMNo, IsHandled);
        if IsHandled then
            exit;

        if StartingDate = 0D then
            Error(Text000);

        if FromProductionBOMLineType = FromProductionBOMLineType::" " then
            Error(Text001);

        if FromProductionBOMNo = '' then
            Error(Text002);

        if (FromProductionBOMLineType = ToProductionBOMLineType) and (FromProductionBOMNo = ToProductionBOMNo) then
            Error(ItemBOMExchangeErr, FromProductionBOMLineType, FromProductionBOMNo, ToProductionBOMLineType, ToProductionBOMNo);

        OnAfterCheckParameters(StartingDate, FromProductionBOMLineType, FromProductionBOMNo, ToProductionBOMLineType, ToProductionBOMNo);
    end;

    local procedure CreateNewVersionOnAfterValidat()
    begin
        CreateNewVersionEditable := not DeleteExcComp;
        DeleteExchangedComponentEditab := not CreateNewVersion;
    end;

    local procedure DeleteExcCompOnAfterValidate()
    begin
        CreateNewVersionEditable := not DeleteExcComp;
        DeleteExchangedComponentEditab := not CreateNewVersion;
    end;

    local procedure IsActiveBOMVersion(ProductionBOMHeaderToCheck: Record "Production BOM Header"; ProductionBOMLineToCheck: Record "Production BOM Line") Result: Boolean
    var
        VersionManagement: Codeunit VersionManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsActiveBOMVersion(ProductionBOMHeaderToCheck, ProductionBOMLineToCheck, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if ProductionBOMHeaderToCheck.Status = ProductionBOMHeaderToCheck.Status::Closed then
            exit(false);

        exit(ProductionBOMLineToCheck."Version Code" = VersionManagement.GetBOMVersion(ProductionBOMLineToCheck."Production BOM No.", StartingDate, true));
    end;

    local procedure IncrementVersionNo(ProductionBOMNo: Code[20]) Result: Code[20]
    var
        LastProductionBOMVersion: Record "Production BOM Version";
    begin
        LastProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        LastProductionBOMVersion.SetLoadFields("Version Code");
        if LastProductionBOMVersion.FindLast() then begin
            Result := IncStr(LastProductionBOMVersion."Version Code");
            LastProductionBOMVersion.SetRange("Version Code", Result);
            while not LastProductionBOMVersion.IsEmpty() do begin
                Result := IncStr(Result);
                if Result = '' then
                    exit(Result);
                LastProductionBOMVersion.SetRange("Version Code", Result);
            end;
        end;
    end;

    local procedure CopyPositionFields(var ProdBOMLineCopyTo: Record "Production BOM Line"; ProdBOMLineCopyFrom: Record "Production BOM Line")
    begin
        if (ProdBOMLineCopyTo.Type <> ProdBOMLineCopyTo.Type::Item) or (ProdBOMLineCopyFrom.Type <> ProdBOMLineCopyFrom.Type::Item) then
            exit;
        ProdBOMLineCopyTo.Validate(Position, ProdBOMLineCopyFrom.Position);
        ProdBOMLineCopyTo.Validate("Position 2", ProdBOMLineCopyFrom."Position 2");
        ProdBOMLineCopyTo.Validate("Position 3", ProdBOMLineCopyFrom."Position 3");

        OnAfterCopyPositionFields(ProdBOMLineCopyTo, ProdBOMLineCopyFrom);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPositionFields(var ProdBOMLineCopyTo: Record "Production BOM Line"; ProdBOMLineCopyFrom: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdBOMVersionListInsert(var ProductionBOMVersion: Record "Production BOM Version"; ProductionBOMHeader: Record "Production BOM Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewProdBOMLine(var ProductionBOMLine: Record "Production BOM Line"; var FromProductionBOMLine: Record "Production BOM Line"; QtyMultiply: Decimal; FirstVersion: Boolean; var ShouldInsertNewProductionBOMLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupExchangeNo(LineType: Enum "Production BOM Line Type"; LookupText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecertifyLoopOnBeforeOnPreDataItem(FromBOMType: Enum "Production BOM Line Type"; FromBOMNo: Code[20]; ToBOMType: Enum "Production BOM Line Type"; ToBOMNo: Code[20]; QtyMultiply: Decimal; CreateNewVersion: Boolean; StartingDate: Date; Recertify: Boolean; CopyRoutingLink: Boolean; DeleteExcComp: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckParameters(StartingDate: Date; FromBOMType: Enum "Production BOM Line Type"; FromBOMNo: Code[20]; ToBOMType: Enum "Production BOM Line Type"; ToBOMNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInitReport(var CreateNewVersion: Boolean; var StartingDate: Date; var DeleteExcComp: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecertifyLoopOnBeforeLoopProdBOMHeader(var ProductionBOMHeader: Record "Production BOM Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecertifyLoopOnBeforeLoopProdBOMVersionList(var ProductionBOMVersion: Record "Production BOM Version"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckParameters(var StartingDate: Date; var FromBOMType: Enum "Production BOM Line Type"; var FromBOMNo: Code[20]; var ToBOMType: Enum "Production BOM Line Type"; var ToBOMNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsActiveBOMVersion(ProductionBOMHeader: Record "Production BOM Header"; ProductionBOMLine: Record "Production BOM Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIntegerOnPostDataItemOnBeforeModifyProductionBOMLine(ProductionBOMLine: Record "Production BOM Line"; var ShouldModifyProductionBOMLine: Boolean)
    begin
    end;
}

