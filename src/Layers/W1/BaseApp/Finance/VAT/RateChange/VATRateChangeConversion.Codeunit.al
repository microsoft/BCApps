// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;
using Microsoft.Warehouse.Request;
using System.Reflection;

codeunit 550 "VAT Rate Change Conversion"
{
    Permissions = TableData "VAT Rate Change Log Entry" = i;

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(IsHandled);
        if IsHandled then
            exit;

        if not VATRateChangeSetup.Get() then begin
            VATRateChangeSetup.Init();
            VATRateChangeSetup.Insert();
        end;

        Convert();
    end;

    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
        UOMMgt: Codeunit "Unit of Measure Management";
        ProgressWindow: Dialog;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text0001: Label 'Progressing Table #1#####################################  ';
        Text0002: Label 'Progressing Record #2############ of #3####################  ';
        Text0004: Label 'Order line %1 has a drop shipment purchasing code. Update the order manually.';
        Text0005: Label 'Order line %1 has a special order purchasing code. Update the order manually.';
#pragma warning restore AA0470
        Text0006: Label 'The order has a partially shipped line with link to a WHSE document. Update the order manually.';
        Text0007: Label 'There is nothing to convert. The outstanding quantity is zero.';
#pragma warning disable AA0470
        Text0008: Label 'There must be an entry in the %1 table for the combination of VAT business posting group %2 and VAT product posting group %3.';
        Text0009: Label 'Conversion cannot be performed before %1 is set to true.';
#pragma warning restore AA0470
        Text0011: Label 'Documents that have posted prepayment must be converted manually.';
#pragma warning disable AA0470
        Text0012: Label 'This line %1 has been split into two lines. The outstanding quantity will be on the new line.';
        Text0013: Label 'This line %1 has been added. It contains the outstanding quantity from line %2.';
        Text0014: Label 'The order line %1 of type %2 have been partial Shipped/Invoiced . Update the order manually.';
#pragma warning restore AA0470
        Text0015: Label 'A defined conversion does not exist. Define the conversion.';
        Text0016: Label 'Defined tables for conversion do not exist.';
#pragma warning disable AA0470
        Text0017: Label 'This line %1 will be split into two lines. The outstanding quantity will be on the new line.';
#pragma warning restore AA0470
        Text0018: Label 'This document is linked to an assembly order. You must convert the document manually.';
#pragma warning restore AA0074

    local procedure Convert()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        TempGenProductPostingGroup: Record "Gen. Product Posting Group" temporary;
    begin
        OnBeforeConvert(VATRateChangeSetup);

        VATRateChangeSetup.TestField("VAT Rate Change Tool Completed", false);
        if VATRateChangeConversion.IsEmpty() then
            Error(Text0015);
        if not AreTablesSelected() then
            Error(Text0016);
        TestVATPostingSetup();
        ProgressWindow.Open(Text0001 + Text0002);
        OnConvertOnBeforeStartConvert(VATRateChangeSetup);
        ProgressWindow.Update();
        UpdateTable(
          Database::"Gen. Product Posting Group",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Gen. Prod. Post. Groups"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Gen. Prod. Post. Groups"));
        TempGenProductPostingGroup.DeleteAll();
        if GenProductPostingGroup.Find('-') then
            repeat
                TempGenProductPostingGroup := GenProductPostingGroup;
                TempGenProductPostingGroup.Insert();
                GenProductPostingGroup."Auto Insert Default" := false;
                GenProductPostingGroup.Modify();
            until GenProductPostingGroup.Next() = 0;
        UpdateItem();
        UpdateResource();
        UpdateGLAccount();
        UpdatePurchase();
        UpdateSales();
        UpdateTables();

        OnBeforeFinishConvert(VATRateChangeSetup, ProgressWindow);

        GenProductPostingGroup.DeleteAll();
        if TempGenProductPostingGroup.Find('-') then
            repeat
                GenProductPostingGroup := TempGenProductPostingGroup;
                GenProductPostingGroup.Insert();
                TempGenProductPostingGroup.Delete();
            until TempGenProductPostingGroup.Next() = 0;

        ProgressWindow.Close();

        if VATRateChangeSetup."Perform Conversion" then begin
            VATRateChangeSetup."VAT Rate Change Tool Completed" := true;
            VATRateChangeSetup.Modify();
            VATRateChangeConversion.Reset();
            if VATRateChangeConversion.FindSet(true) then
                repeat
                    VATRateChangeConversion."Converted Date" := WorkDate();
                    VATRateChangeConversion.Modify();
                until VATRateChangeConversion.Next() = 0;
        end;

        OnAfterConvert(VATRateChangeSetup);
    end;

    local procedure UpdateTables()
    begin
        UpdateTable(
          Database::"Item Templ.",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Item Templates"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Item Templates"));
        UpdateTable(
          Database::"Item Charge",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Item Charges"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Item Charges"));
        UpdateTable(
          Database::"Gen. Journal Line",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Gen. Journal Lines"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Gen. Journal Lines"));
        UpdateTable(
          Database::"Gen. Jnl. Allocation",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Gen. Journal Allocation"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Gen. Journal Allocation"));
        UpdateTable(
          Database::"Standard General Journal Line",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Std. Gen. Jnl. Lines"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Std. Gen. Jnl. Lines"));
        UpdateTable(
          Database::"Res. Journal Line",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Res. Journal Lines"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Res. Journal Lines"));
        UpdateTable(
          Database::"Job Journal Line",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Job Journal Lines"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Job Journal Lines"));
        UpdateTable(
          Database::"Requisition Line",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Requisition Lines"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Requisition Lines"));
        UpdateTable(
          Database::"Standard Item Journal Line",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Std. Item Jnl. Lines"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Std. Item Jnl. Lines"));
        UpdateTable(
          Database::"Reminder Line",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Reminders"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Reminders"));
        UpdateTable(
          Database::"Finance Charge Memo Line",
          ConvertVATProdPostGrp(VATRateChangeSetup."Update Finance Charge Memos"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Finance Charge Memos"));

        OnAfterUpdateTables(VATRateChangeSetup);
    end;

    local procedure TestVATPostingSetup()
    var
        VATPostingSetupOld: Record "VAT Posting Setup";
        VATPostingSetupNew: Record "VAT Posting Setup";
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
    begin
        VATRateChangeConversion.SetRange(Type, VATRateChangeConversion.Type::"VAT Prod. Posting Group");
        if VATRateChangeConversion.FindSet() then
            repeat
                VATPostingSetupOld.SetRange("VAT Prod. Posting Group", VATRateChangeConversion."From Code");
                OnTestVATPostingSetupOnAfterVATPostingSetupOldSetFilters(VATPostingSetupOld, VATRateChangeSetup);
                if VATPostingSetupOld.FindSet() then
                    repeat
                        if not VATPostingSetupNew.Get(VATPostingSetupOld."VAT Bus. Posting Group", VATRateChangeConversion."To Code") then
                            Error(
                              Text0008,
                              VATPostingSetupNew.TableCaption(),
                              VATPostingSetupOld."VAT Bus. Posting Group",
                              VATRateChangeConversion."To Code");
                        if VATPostingSetupOld."VAT Identifier" <> '' then
                            VATPostingSetupNew.TestField("VAT Identifier")
                    until VATPostingSetupOld.Next() = 0;
            until VATRateChangeConversion.Next() = 0;
    end;

    local procedure UpdateItem()
    var
        Item: Record Item;
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        ProgressWindow.Update(1, Item.TableCaption());

        IsHandled := false;
        OnBeforeUpdateItem(Item, VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        if VATRateChangeSetup."Item Filter" = '' then
            UpdateTable(Database::Item, ConvertVATProdPostGrp(VATRateChangeSetup."Update Items"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Items"))
        else begin
            Item.SetFilter("No.", VATRateChangeSetup."Item Filter");
            if Item.Find('-') then
                repeat
                    RecRef.GetTable(Item);
                    UpdateRec(RecRef, ConvertVATProdPostGrp(VATRateChangeSetup."Update Items"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Items"));
                until Item.Next() = 0;
        end;
    end;

    local procedure UpdateGLAccount()
    var
        GLAccount: Record "G/L Account";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        ProgressWindow.Update(1, GLAccount.TableCaption());

        IsHandled := false;
        OnBeforeUpdateGLAccount(GLAccount, VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        if VATRateChangeSetup."Account Filter" = '' then
            UpdateTable(Database::"G/L Account", ConvertVATProdPostGrp(VATRateChangeSetup."Update G/L Accounts"), ConvertGenProdPostGrp(VATRateChangeSetup."Update G/L Accounts"))
        else begin
            GLAccount.SetFilter("No.", VATRateChangeSetup."Account Filter");
            if GLAccount.Find('-') then
                repeat
                    RecRef.GetTable(GLAccount);
                    UpdateRec(RecRef, ConvertVATProdPostGrp(VATRateChangeSetup."Update G/L Accounts"), ConvertGenProdPostGrp(VATRateChangeSetup."Update G/L Accounts"));
                until GLAccount.Next() = 0;
        end;
    end;

    local procedure UpdateResource()
    var
        Resource: Record Resource;
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateResource(Resource, VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        if VATRateChangeSetup."Resource Filter" = '' then
            UpdateTable(Database::Resource, ConvertVATProdPostGrp(VATRateChangeSetup."Update Resources"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Resources"))
        else begin
            Resource.SetFilter("No.", VATRateChangeSetup."Resource Filter");
            if Resource.Find('-') then
                repeat
                    RecRef.GetTable(Resource);
                    UpdateRec(RecRef, ConvertVATProdPostGrp(VATRateChangeSetup."Update Resources"), ConvertGenProdPostGrp(VATRateChangeSetup."Update Resources"));
                until Resource.Next() = 0;
        end;
    end;

    procedure ConvertVATProdPostGrp(UpdateOption: Option): Boolean
    var
        DummyVATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        if UpdateOption in [DummyVATRateChangeSetup."Update Items"::"VAT Prod. Posting Group",
                            DummyVATRateChangeSetup."Update Items"::Both]
        then
            exit(true);
        exit(false);
    end;

    procedure ConvertGenProdPostGrp(UpdateOption: Option): Boolean
    var
        DummyVATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        if UpdateOption in [DummyVATRateChangeSetup."Update Items"::"Gen. Prod. Posting Group",
                            DummyVATRateChangeSetup."Update Items"::Both]
        then
            exit(true);
        exit(false);
    end;

    procedure UpdateTable(TableID: Integer; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean)
    var
        RecRef: RecordRef;
        I: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTable(TableID, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup, IsHandled);
        if IsHandled then
            exit;

        if not ConvertVATProdPostingGroup and not ConvertGenProdPostingGroup then
            exit;
        RecRef.Open(TableID);
        ProgressWindow.Update(1, Format(RecRef.Caption));
        I := 0;
        ProgressWindow.Update(3, RecRef.Count);
        if RecRef.Find('-') then
            repeat
                I := I + 1;
                ProgressWindow.Update(2, I);
                UpdateRec(RecRef, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup);
            until RecRef.Next() = 0;
    end;

    procedure UpdateRec(var RecRef: RecordRef; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean)
    var
        "Field": Record "Field";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        FldRef: FieldRef;
        GenProdPostingGroupConverted: Boolean;
        VATProdPostingGroupConverted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRec(RecRef, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup, IsHandled);
        if IsHandled then
            exit;

        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        Field.SetRange(TableNo, RecRef.Number);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(RelationTableNo, Database::"Gen. Product Posting Group");
        Field.SetRange(Type, Field.Type::Code);
        if Field.Find('+') then
            repeat
                FldRef := RecRef.Field(Field."No.");
                GenProdPostingGroupConverted := false;
                if ConvertGenProdPostingGroup then
                    if VATRateChangeConversion.Get(VATRateChangeConversion.Type::"Gen. Prod. Posting Group", Format(FldRef.Value())) then begin
                        VATRateChangeLogEntry."Old Gen. Prod. Posting Group" := FldRef.Value();
                        IsHandled := false;
                        OnUpdateRecOnBeforeValidateGenProdPostingGroup(RecRef, FldRef, VATRateChangeConversion, IsHandled);
                        if not IsHandled then
                            FldRef.Validate(VATRateChangeConversion."To Code");
                        VATRateChangeLogEntry."New Gen. Prod. Posting Group" := FldRef.Value();
                        GenProdPostingGroupConverted := true;
                    end;
                if not GenProdPostingGroupConverted then begin
                    VATRateChangeLogEntry."Old Gen. Prod. Posting Group" := FldRef.Value();
                    VATRateChangeLogEntry."New Gen. Prod. Posting Group" := FldRef.Value();
                end;
            until Field.Next(-1) = 0;

        Field.SetRange(RelationTableNo, Database::"VAT Product Posting Group");
        if Field.Find('+') then
            repeat
                FldRef := RecRef.Field(Field."No.");
                VATProdPostingGroupConverted := false;
                if ConvertVATProdPostingGroup then
                    if VATRateChangeConversion.Get(VATRateChangeConversion.Type::"VAT Prod. Posting Group", Format(FldRef.Value())) then begin
                        VATRateChangeLogEntry."Old VAT Prod. Posting Group" := FldRef.Value();
                        FldRef.Validate(VATRateChangeConversion."To Code");
                        VATRateChangeLogEntry."New VAT Prod. Posting Group" := FldRef.Value();
                        VATProdPostingGroupConverted := true;
                    end;
                if not VATProdPostingGroupConverted then begin
                    VATRateChangeLogEntry."Old VAT Prod. Posting Group" := FldRef.Value();
                    VATRateChangeLogEntry."New VAT Prod. Posting Group" := FldRef.Value();
                end;
            until Field.Next(-1) = 0;

        VATRateChangeSetup.Get();
        if VATRateChangeSetup."Perform Conversion" then begin
            OnUpdateRecOnBeforeRecRefModify(RecRef, GenProdPostingGroupConverted, VATProdPostingGroupConverted);
            RecRef.Modify();
            OnUpdateRecOnAfterRecRefModify(RecRef, GenProdPostingGroupConverted, VATProdPostingGroupConverted);
            VATRateChangeLogEntry.Converted := true;
        end;
        if (VATRateChangeLogEntry."New Gen. Prod. Posting Group" <> VATRateChangeLogEntry."Old Gen. Prod. Posting Group") or
           (VATRateChangeLogEntry."New VAT Prod. Posting Group" <> VATRateChangeLogEntry."Old VAT Prod. Posting Group")
        then
            WriteLogEntry(VATRateChangeLogEntry);
    end;

    procedure WriteLogEntry(VATRateChangeLogEntry: Record "VAT Rate Change Log Entry")
    begin
        if VATRateChangeLogEntry.Converted then
            VATRateChangeLogEntry."Converted Date" := WorkDate()
        else
            if VATRateChangeLogEntry.Description = '' then
                VATRateChangeLogEntry.Description := StrSubstNo(Text0009, VATRateChangeSetup.FieldCaption("Perform Conversion"));
        VATRateChangeLogEntry.Insert();
    end;

    local procedure UpdateSales()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineOld: Record "Sales Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        SalesHeaderStatusChanged: Boolean;
        NewVATProdPotingGroup: Code[20];
        NewGenProdPostingGroup: Code[20];
        ConvertVATProdPostingGroup: Boolean;
        ConvertGenProdPostingGroup: Boolean;
        RoundingPrecision: Decimal;
        IsHandled: Boolean;
        IsModified: Boolean;
    begin
        ProgressWindow.Update(1, SalesHeader.TableCaption());
        ConvertVATProdPostingGroup := ConvertVATProdPostGrp(VATRateChangeSetup."Update Sales Documents");
        ConvertGenProdPostingGroup := ConvertGenProdPostGrp(VATRateChangeSetup."Update Sales Documents");
        if not ConvertVATProdPostingGroup and not ConvertGenProdPostingGroup then
            exit;

        IsHandled := false;
        OnBeforeUpdateSales(VATRateChangeSetup, IsHandled, SalesHeader);
        if IsHandled then
            exit;

        SalesHeader.SetFilter(
          "Document Type", '%1..%2|%3', SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Invoice,
          SalesHeader."Document Type"::"Blanket Order");
        OnUpdateSalesOnAfterSalesHeaderSetFilters(VATRateChangeSetup, SalesHeader);
        if SalesHeader.Find('-') then
            repeat
                SalesHeaderStatusChanged := false;
                if CanUpdateSales(SalesHeader, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup) then begin
                    if VATRateChangeSetup."Ignore Status on Sales Docs." then
                        if SalesHeader.Status <> SalesHeader.Status::Open then begin
                            SalesHeader2 := SalesHeader;
                            SalesHeader.Status := SalesHeader.Status::Open;
                            SalesHeader.Modify();
                            SalesHeaderStatusChanged := true;
                            OnUpdateSalesOnAfterOpenSalesHeader(SalesHeader);
                        end;
                    if SalesHeader.Status = SalesHeader.Status::Open then begin
                        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                        SalesLine.SetRange("Document No.", SalesHeader."No.");
                        OnUpdateSalesOnAfterSalesLineSetFilters(VATRateChangeSetup, SalesHeader, SalesLine);
                        if SalesLine.FindSet() then
                            repeat
                                if LineInScope(
                                     SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group", ConvertGenProdPostingGroup,
                                     ConvertVATProdPostingGroup)
                                then
                                    if (SalesLine."Shipment No." = '') and (SalesLine."Return Receipt No." = '') and
                                       IncludeSalesLine(SalesLine.Type, SalesLine."No.")
                                    then
                                        if DoUpdateSalesLine(SalesLine) then begin
                                            OnUpdateSalesOnBeforeChangeSalesLine(SalesLine);

                                            RecRef.GetTable(SalesLine);
                                            if SalesHeader."Prices Including VAT" then
                                                SalesLineOld := SalesLine;

                                            UpdateRec(
                                              RecRef, ConvertVATProdPostGrp(VATRateChangeSetup."Update Sales Documents"),
                                              ConvertGenProdPostGrp(VATRateChangeSetup."Update Sales Documents"));

                                            SalesLine.Find();
                                            IsModified := false;
                                            if SalesHeader."Prices Including VAT" and VATRateChangeSetup."Perform Conversion" and
                                               (SalesLine."VAT %" <> SalesLineOld."VAT %") and
                                               UpdateUnitPriceInclVAT(SalesLine.Type)
                                            then begin
                                                RoundingPrecision := GetRoundingPrecision(SalesHeader."Currency Code");
                                                SalesLine.Validate(
                                                  "Unit Price",
                                                  Round(
                                                    SalesLineOld."Unit Price" * (100 + SalesLine."VAT %") / (100 + SalesLineOld."VAT %"), RoundingPrecision));
                                                IsModified := true;
                                            end;
                                            if SalesLine."Prepayment %" <> 0 then begin
                                                SalesLine.UpdatePrepmtSetupFields();
                                                IsModified := true;
                                            end;
                                            OnUpdateSalesOnBeforeModifySalesLine(SalesLine, IsModified);
                                            if IsModified then
                                                SalesLine.Modify(true);
                                            OnUpdateSalesOnAfterModifySalesLine(SalesLine, IsModified, VATRateChangeSetup, SalesHeader, SalesLineOld);
                                        end else
                                            if VATRateChangeSetup."Perform Conversion" and (SalesLine."Outstanding Quantity" <> 0) then begin
                                                NewVATProdPotingGroup := SalesLine."VAT Prod. Posting Group";
                                                NewGenProdPostingGroup := SalesLine."Gen. Prod. Posting Group";
                                                if VATRateChangeConversion.Get(
                                                     VATRateChangeConversion.Type::"VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group")
                                                then
                                                    NewVATProdPotingGroup := VATRateChangeConversion."To Code";
                                                if VATRateChangeConversion.Get(
                                                     VATRateChangeConversion.Type::"Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group")
                                                then
                                                    NewGenProdPostingGroup := VATRateChangeConversion."To Code";
                                                AddNewSalesLine(SalesLine, NewVATProdPotingGroup, NewGenProdPostingGroup);
                                            end else begin
                                                RecRef.GetTable(SalesLine);
                                                InitVATRateChangeLogEntry(
                                                  VATRateChangeLogEntry, RecRef, SalesLine."Outstanding Quantity", SalesLine."Line No.");
                                                VATRateChangeLogEntry.UpdateGroups(
                                                  SalesLine."Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group",
                                                  SalesLine."VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
                                                WriteLogEntry(VATRateChangeLogEntry);
                                            end;
                            until SalesLine.Next() = 0;
                        OnUpdateSalesOnAfterUpdateSalesLines(VATRateChangeSetup, SalesHeader, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup);
                    end;
                    if SalesHeaderStatusChanged then begin
                        SalesHeader.Status := SalesHeader2.Status;
                        SalesHeader.Modify();
                        OnUpdateSalesOnAfterResetSalesHeaderStatus(SalesHeader);
                    end;
                end;
            until SalesHeader.Next() = 0;
    end;

    local procedure CanUpdateSales(SalesHeader: Record "Sales Header"; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean) Result: Boolean
    var
        SalesLine: Record "Sales Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        DescriptionTxt: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanUpdateSales(SalesHeader, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup, IsHandled, Result);
        if IsHandled then
            exit(Result);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        OnCanUpdateSalesOnAfterSalesLineSetFilters(SalesLine);
        if SalesLine.FindSet() then
            repeat
                DescriptionTxt := '';
                if LineInScope(SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group", ConvertGenProdPostingGroup, ConvertVATProdPostingGroup) then begin
                    if SalesLine."Drop Shipment" and (SalesLine."Purchase Order No." <> '') then
                        DescriptionTxt := StrSubstNo(Text0004, SalesLine."Line No.");
                    if SalesLine."Special Order" and (SalesLine."Special Order Purchase No." <> '') then
                        DescriptionTxt := StrSubstNo(Text0005, SalesLine."Line No.");
                    CheckSalesLinePartlyShipped(SalesLine, DescriptionTxt);
                    if (SalesLine."Outstanding Quantity" <> SalesLine.Quantity) and (SalesLine.Type = SalesLine.Type::"Charge (Item)") then
                        DescriptionTxt := StrSubstNo(Text0014, SalesLine."Line No.", SalesLine.Type::"Charge (Item)");
                    if SalesLine."Prepmt. Amount Inv. Incl. VAT" <> 0 then
                        DescriptionTxt := Text0011;
                    if SalesLine."Qty. to Assemble to Order" <> 0 then
                        DescriptionTxt := Text0018;
                    OnCanUpdateSalesOnAfterLoopIteration(DescriptionTxt, SalesLine);
                end;
            until (SalesLine.Next() = 0) or (DescriptionTxt <> '');
        if DescriptionTxt = '' then
            exit(true);

        RecRef.GetTable(SalesHeader);
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        VATRateChangeLogEntry.Description := DescriptionTxt;
        WriteLogEntry(VATRateChangeLogEntry);
    end;

    local procedure CheckSalesLinePartlyShipped(var SalesLine: Record "Sales Line"; var DescriptionTxt: Text[250])
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLinePartlyShipped(SalesLine, DescriptionTxt, IsHandled);
        if IsHandled then
            exit;

        if (SalesLine."Outstanding Quantity" <> SalesLine.Quantity) and
               WhseValidateSourceLine.WhseLinesExist(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, SalesLine.Quantity)
        then
            DescriptionTxt := Text0006;
    end;

    procedure AddNewSalesLine(SalesLine: Record "Sales Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        NewSalesLine: Record "Sales Line";
        OldSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        OldReservationEntry: Record "Reservation Entry";
        NewReservationEntry: Record "Reservation Entry";
        OldItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        NewItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewLineNo: Integer;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
        RoundingPrecision: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddNewSalesLine(SalesLine, VATProdPostingGroup, GenProdPostingGroup, IsHandled);
        if not IsHandled then begin
            if not GetNextSalesLineNo(SalesLine, NewLineNo) then
                exit;
            InitNewSalesLineFromSalesLine(NewSalesLine, SalesLine, NewLineNo);
            if (GenProdPostingGroup <> '') and ConvertGenProdPostGrp(VATRateChangeSetup."Update Sales Documents") then
                NewSalesLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            if (VATProdPostingGroup <> '') and ConvertVATProdPostGrp(VATRateChangeSetup."Update Sales Documents") then
                NewSalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            NewSalesLine.Validate(Quantity, SalesLine."Outstanding Quantity");
            NewSalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship");
            NewSalesLine.Validate("Return Qty. to Receive", SalesLine."Return Qty. to Receive");
            if Abs(SalesLine."Qty. to Invoice") > (Abs(SalesLine."Quantity Shipped") - Abs(SalesLine."Quantity Invoiced")) then
                NewSalesLine.Validate(
                  NewSalesLine."Qty. to Invoice", SalesLine."Qty. to Invoice" - (SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced"))
            else
                NewSalesLine.Validate("Qty. to Invoice", 0);
            SalesHeader.Get(NewSalesLine."Document Type", NewSalesLine."Document No.");
            RoundingPrecision := GetRoundingPrecision(SalesHeader."Currency Code");
            if SalesHeader."Prices Including VAT" then
                NewSalesLine.Validate("Unit Price", Round(SalesLine."Unit Price" * (100 + NewSalesLine."VAT %") / (100 + SalesLine."VAT %"), RoundingPrecision))
            else
                NewSalesLine.Validate("Unit Price", SalesLine."Unit Price");
            NewSalesLine.Validate("Line Discount %", SalesLine."Line Discount %");
            NewSalesLine.Insert();
            OnAddNewSalesLineOnAfterInsertNewLine(Salesline, NewSalesline);

            RecRef.GetTable(SalesLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.UpdateGroups(
              SalesLine."Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group",
              SalesLine."VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
            VATRateChangeLogEntry.Description := StrSubstNo(Text0012, Format(SalesLine."Line No."));
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);

            RecRef.GetTable(NewSalesLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.UpdateGroups(
              SalesLine."Gen. Prod. Posting Group", NewSalesLine."Gen. Prod. Posting Group",
              SalesLine."VAT Prod. Posting Group", NewSalesLine."VAT Prod. Posting Group");
            VATRateChangeLogEntry.Description := StrSubstNo(Text0013, Format(NewSalesLine."Line No."), Format(SalesLine."Line No."));
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);

            UpdateSalesBlanketOrder(NewSalesLine, SalesLine."Line No.");
            UpdateAttachedToLineNoSales(NewSalesLine, SalesLine."Line No.");

            OldReservationEntry.Reset();
            OldReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
            OldReservationEntry.SetRange("Source ID", SalesLine."Document No.");
            OldReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
            OldReservationEntry.SetRange("Source Type", Database::"Sales Line");
            OldReservationEntry.SetRange("Source Subtype", SalesLine."Document Type");
            if OldReservationEntry.FindSet() then
                repeat
                    NewReservationEntry := OldReservationEntry;
                    NewReservationEntry."Source Ref. No." := NewLineNo;
                    NewReservationEntry.Modify();
                until OldReservationEntry.Next() = 0;

            case SalesLine.Type of
                SalesLine.Type::Item:
                    begin
                        OldItemChargeAssignmentSales.Reset();
                        OldItemChargeAssignmentSales.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        OldItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", SalesLine."Document Type");
                        OldItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", SalesLine."Document No.");
                        OldItemChargeAssignmentSales.SetRange("Applies-to Doc. Line No.", SalesLine."Line No.");
                        if OldItemChargeAssignmentSales.Find('-') then
                            repeat
                                QtyRemainder := OldItemChargeAssignmentSales."Qty. to Assign";
                                AmountRemainder := OldItemChargeAssignmentSales."Amount to Assign";
                                NewItemChargeAssignmentSales := OldItemChargeAssignmentSales;
                                NewItemChargeAssignmentSales."Line No." := GetNextItemChrgAssSaleLineNo(OldItemChargeAssignmentSales);
                                NewItemChargeAssignmentSales."Applies-to Doc. Line No." := NewLineNo;
                                NewItemChargeAssignmentSales."Qty. to Assign" :=
                                  Round(QtyRemainder / SalesLine.Quantity * SalesLine."Outstanding Quantity", UOMMgt.QtyRndPrecision());
                                if SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced" = 0 then
                                    NewItemChargeAssignmentSales."Qty. to Assign" := QtyRemainder;
                                NewItemChargeAssignmentSales."Amount to Assign" :=
                                  Round(NewItemChargeAssignmentSales."Qty. to Assign" * NewItemChargeAssignmentSales."Unit Cost", RoundingPrecision);
                                NewItemChargeAssignmentSales.Insert();
                                QtyRemainder := QtyRemainder - NewItemChargeAssignmentSales."Qty. to Assign";
                                AmountRemainder := AmountRemainder - NewItemChargeAssignmentSales."Amount to Assign";
                                OldItemChargeAssignmentSales."Qty. to Assign" := QtyRemainder;
                                OldItemChargeAssignmentSales."Amount to Assign" := AmountRemainder;
                                OldItemChargeAssignmentSales.Modify();
                            until OldItemChargeAssignmentSales.Next() = 0;
                    end;
            end;

            OldSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
            OldSalesLine.Validate(Quantity, SalesLine."Quantity Shipped");

            OldSalesLine.Validate("Unit Price", SalesLine."Unit Price");
            OldSalesLine.Validate("Line Discount %", SalesLine."Line Discount %");
            OldSalesLine.Validate("Qty. to Ship", 0);
            OldSalesLine.Validate("Return Qty. to Receive", 0);
            if Abs(SalesLine."Qty. to Invoice") > (Abs(SalesLine."Quantity Shipped") - Abs(SalesLine."Quantity Invoiced")) then
                OldSalesLine.Validate("Qty. to Invoice", SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced")
            else
                OldSalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice");

            OnAddNewSalesLineOnBeforeOldSalesLineModify(OldSalesLine, NewSalesLine, VATProdPostingGroup, GenProdPostingGroup);
            OldSalesLine.Modify();
        end;

        OnAfterAddNewSalesLine(OldSalesLine, NewSalesLine);
    end;

    local procedure InitNewSalesLineFromSalesLine(var NewSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; NewLineNo: Integer)
    begin
        NewSalesLine.Init();
        NewSalesLine := SalesLine;
        NewSalesLine."Line No." := NewLineNo;
        NewSalesLine."Quantity Shipped" := 0;
        NewSalesLine."Qty. Shipped (Base)" := 0;
        NewSalesLine."Return Qty. Received" := 0;
        NewSalesLine."Return Qty. Received (Base)" := 0;
        NewSalesLine."Quantity Invoiced" := 0;
        NewSalesLine."Qty. Invoiced (Base)" := 0;
        NewSalesLine."Reserved Quantity" := 0;
        NewSalesLine."Reserved Qty. (Base)" := 0;
        NewSalesLine."Qty. to Ship" := 0;
        NewSalesLine."Qty. to Ship (Base)" := 0;
        NewSalesLine."Return Qty. to Receive" := 0;
        NewSalesLine."Return Qty. to Receive (Base)" := 0;
        NewSalesLine."Qty. to Invoice" := 0;
        NewSalesLine."Qty. to Invoice (Base)" := 0;
        NewSalesLine."Qty. Shipped Not Invoiced" := 0;
        NewSalesLine."Return Qty. Rcd. Not Invd." := 0;
        NewSalesLine."Shipped Not Invoiced" := 0;
        NewSalesLine."Return Rcd. Not Invd." := 0;
        NewSalesLine."Qty. Shipped Not Invd. (Base)" := 0;
        NewSalesLine."Ret. Qty. Rcd. Not Invd.(Base)" := 0;
        NewSalesLine."Shipped Not Invoiced (LCY)" := 0;
        NewSalesLine."Return Rcd. Not Invd. (LCY)" := 0;
        OnAfterInitNewSalesLineFromSalesLine(NewSalesLine, SalesLine);
    end;

    local procedure UpdateSalesBlanketOrder(SalesLine: Record "Sales Line"; OriginalLineNo: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        IsHandled: Boolean;
    begin
        if SalesLine."Document Type" = SalesLine."Document Type"::"Blanket Order" then begin
            SalesLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            SalesLine2.SetRange("Blanket Order No.", SalesLine."Document No.");
            SalesLine2.SetFilter("Blanket Order Line No.", '=%1', OriginalLineNo);
            SalesLine2.SetRange(Type, SalesLine.Type);
            SalesLine2.SetRange("No.", SalesLine."No.");
            SalesLine2.SetRange("Quantity Shipped", 0);
            Clear(SalesHeader);
            if SalesLine2.FindSet() then
                repeat
                    if (SalesHeader."Document Type" <> SalesLine2."Document Type") or
                       (SalesHeader."No." <> SalesLine2."Document No.")
                    then begin
                        SalesHeader.Get(SalesLine2."Document Type", SalesLine2."Document No.");
                        SalesLine3.Reset();
                        SalesLine3.SetRange("Document Type", SalesHeader."Document Type");
                        SalesLine3.SetRange("Document No.", SalesHeader."No.");
                        SalesLine3.SetRange("Blanket Order No.", SalesLine2."Blanket Order No.");
                        SalesLine3.SetRange("Blanket Order Line No.", SalesLine2."Blanket Order Line No.");
                        IsHandled := false;
                        OnUpdateSalesBlanketOrderOnBeforeChangeBlanketOrder(SalesLine3, IsHandled);
                        if not IsHandled then
                            if SalesLine3.FindLast() then begin
                                SalesLine3."Blanket Order Line No." := SalesLine."Line No.";
                                SalesLine3.Modify();
                            end;
                    end;
                until SalesLine2.Next() = 0;
        end;
    end;

    local procedure UpdateAttachedToLineNoSales(SalesLine: Record "Sales Line"; OriginalLineNo: Integer)
    var
        SalesLine2: Record "Sales Line";
    begin
        if SalesLine."Document Type" = SalesLine."Document Type"::"Blanket Order" then begin
            SalesLine2.SetRange("Document No.", SalesLine."Document No.");
            SalesLine2.SetRange(Type, SalesLine2.Type::" ");
            SalesLine2.SetRange("Attached to Line No.", OriginalLineNo);
            if not SalesLine2.IsEmpty() then
                SalesLine2.ModifyAll("Attached to Line No.", SalesLine."Line No.");
        end;
    end;

    local procedure UpdateAttachedToLineNoPurch(PurchLine: Record "Purchase Line"; OriginalLineNo: Integer)
    var
        PurchLine2: Record "Purchase Line";
    begin
        if PurchLine."Document Type" = PurchLine."Document Type"::"Blanket Order" then begin
            PurchLine2.SetRange("Document No.", PurchLine."Document No.");
            PurchLine2.SetRange(Type, PurchLine2.Type::" ");
            PurchLine2.SetRange("Attached to Line No.", OriginalLineNo);
            if not PurchLine2.IsEmpty() then
                PurchLine2.ModifyAll("Attached to Line No.", PurchLine."Line No.");
        end;
    end;

    procedure UpdatePurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineOld: Record "Purchase Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewVATProdPotingGroup: Code[20];
        NewGenProdPostingGroup: Code[20];
        StatusChanged: Boolean;
        ConvertVATProdPostingGroup: Boolean;
        ConvertGenProdPostingGroup: Boolean;
        RoundingPrecision: Decimal;
        IsHandled: Boolean;
        IsModified: Boolean;
        ShouldProcessLine: Boolean;
    begin
        ProgressWindow.Update(1, PurchaseHeader.TableCaption());

        ConvertVATProdPostingGroup := ConvertVATProdPostGrp(VATRateChangeSetup."Update Purchase Documents");
        ConvertGenProdPostingGroup := ConvertGenProdPostGrp(VATRateChangeSetup."Update Purchase Documents");
        if not ConvertVATProdPostingGroup and not ConvertGenProdPostingGroup then
            exit;

        IsHandled := false;
        OnBeforeUpdatePurchase(VATRateChangeSetup, IsHandled, PurchaseHeader);
        if IsHandled then
            exit;

        PurchaseHeader.SetFilter(
          "Document Type", '%1..%2|%3', PurchaseHeader."Document Type"::Quote, PurchaseHeader."Document Type"::Invoice,
          PurchaseHeader."Document Type"::"Blanket Order");
        OnUpdatePurchaseOnAfterPurchaseHeaderSetFilters(PurchaseHeader);
        if PurchaseHeader.Find('-') then
            repeat
                StatusChanged := false;
                if CanUpdatePurchase(PurchaseHeader, ConvertGenProdPostingGroup, ConvertVATProdPostingGroup) then begin
                    if VATRateChangeSetup."Ignore Status on Purch. Docs." then
                        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then begin
                            PurchaseHeader2 := PurchaseHeader;
                            PurchaseHeader.Status := PurchaseHeader.Status::Open;
                            PurchaseHeader.Modify();
                            StatusChanged := true;
                            OnUpdatePurchaseOnAfterOpenPurchaseHeader(PurchaseHeader);
                        end;
                    if PurchaseHeader.Status = PurchaseHeader.Status::Open then begin
                        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                        OnUpdatePurchaseOnAfterPurchaseLineSetFilters(PurchaseLine, PurchaseHeader);
                        if PurchaseLine.FindSet() then
                            repeat
                                ShouldProcessLine := LineInScope(PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group", ConvertGenProdPostingGroup, ConvertVATProdPostingGroup);
                                OnUpdatePurchaseOnAfterCalcShouldProcessLine(PurchaseLine, ShouldProcessLine);
                                if ShouldProcessLine then
                                    if (PurchaseLine."Receipt No." = '') and
                                       (PurchaseLine."Return Shipment No." = '') and IncludePurchLine(PurchaseLine.Type, PurchaseLine."No.")
                                    then
                                        if DoUpdatePurchaseLine(PurchaseLine) then begin
                                            OnUpdatePurchaseOnBeforeChangePurchaseLine(PurchaseLine);

                                            if PurchaseHeader."Prices Including VAT" then
                                                PurchaseLineOld := PurchaseLine;

                                            RecRef.GetTable(PurchaseLine);
                                            UpdateRec(
                                              RecRef, ConvertVATProdPostGrp(VATRateChangeSetup."Update Purchase Documents"),
                                              ConvertGenProdPostGrp(VATRateChangeSetup."Update Purchase Documents"));

                                            PurchaseLine.Find();
                                            IsModified := false;
                                            if PurchaseHeader."Prices Including VAT" and VATRateChangeSetup."Perform Conversion" and
                                               (PurchaseLine."VAT %" <> PurchaseLineOld."VAT %") and
                                               UpdateUnitPriceInclVAT(PurchaseLine.Type)
                                            then begin
                                                RecRef.SetTable(PurchaseLine);
                                                RoundingPrecision := GetRoundingPrecision(PurchaseHeader."Currency Code");
                                                PurchaseLine.Validate(
                                                  "Direct Unit Cost",
                                                  Round(
                                                    PurchaseLineOld."Direct Unit Cost" * (100 + PurchaseLine."VAT %") / (100 + PurchaseLineOld."VAT %"),
                                                    RoundingPrecision));
                                                IsModified := true;
                                            end;
                                            if PurchaseLine."Prepayment %" <> 0 then begin
                                                PurchaseLine.UpdatePrepmtSetupFields();
                                                IsModified := true;
                                            end;
                                            OnUpdatePurchaseOnBeforeModifyPurchaseLine(PurchaseLine, IsModified);
                                            if IsModified then begin
                                                PurchaseLine.Modify(true);
                                                OnUpdatePurchaseOnAfterPurchaseLineModify(VATRateChangeSetup, PurchaseHeader, PurchaseLine, PurchaseLineOld);
                                            end;
                                        end else
                                            if VATRateChangeSetup."Perform Conversion" and (PurchaseLine."Outstanding Quantity" <> 0) then begin
                                                NewVATProdPotingGroup := PurchaseLine."VAT Prod. Posting Group";
                                                NewGenProdPostingGroup := PurchaseLine."Gen. Prod. Posting Group";
                                                if ConvertVATProdPostingGroup then
                                                    if VATRateChangeConversion.Get(
                                                         VATRateChangeConversion.Type::"VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group")
                                                    then
                                                        NewVATProdPotingGroup := VATRateChangeConversion."To Code";
                                                if ConvertGenProdPostingGroup then
                                                    if VATRateChangeConversion.Get(
                                                         VATRateChangeConversion.Type::"Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group")
                                                    then
                                                        NewGenProdPostingGroup := VATRateChangeConversion."To Code";
                                                AddNewPurchaseLine(PurchaseLine, NewVATProdPotingGroup, NewGenProdPostingGroup);
                                            end else begin
                                                RecRef.GetTable(PurchaseLine);
                                                InitVATRateChangeLogEntry(
                                                  VATRateChangeLogEntry, RecRef, PurchaseLine."Outstanding Quantity", PurchaseLine."Line No.");
                                                VATRateChangeLogEntry.UpdateGroups(
                                                  PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group",
                                                  PurchaseLine."VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
                                                WriteLogEntry(VATRateChangeLogEntry);
                                            end;
                            until PurchaseLine.Next() = 0;

                        OnUpdatePurchaseOnAfterUpdatePurchaseLines(VATRateChangeSetup, PurchaseHeader, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup);
                    end;
                    if StatusChanged then begin
                        PurchaseHeader.Status := PurchaseHeader2.Status;
                        PurchaseHeader.Modify();
                        OnUpdatePurchaseOnAfterResetPurchaseHeaderStatus(PurchaseHeader);
                    end;
                end;
            until PurchaseHeader.Next() = 0;
    end;

    local procedure CanUpdatePurchase(PurchaseHeader: Record "Purchase Header"; ConvertGenProdPostingGroup: Boolean; ConvertVATProdPostingGroup: Boolean) Result: Boolean
    var
        PurchaseLine: Record "Purchase Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        DescriptionTxt: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanUpdatePurchase(PurchaseHeader, ConvertGenProdPostingGroup, ConvertVATProdPostingGroup, IsHandled, Result);
        if IsHandled then
            exit(Result);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        OnCanUpdatePurchaseOnAfterPurchaseLineSetFilters(PurchaseLine);
        if PurchaseLine.FindSet() then
            repeat
                DescriptionTxt := '';
                if LineInScope(PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group", ConvertGenProdPostingGroup, ConvertVATProdPostingGroup) then begin
                    if PurchaseLine."Drop Shipment" and (PurchaseLine."Sales Order No." <> '') then
                        DescriptionTxt := StrSubstNo(Text0004, PurchaseLine."Line No.");
                    if PurchaseLine."Special Order" and (PurchaseLine."Special Order Sales No." <> '') then
                        DescriptionTxt := StrSubstNo(Text0005, PurchaseLine."Line No.");
                    CheckPurchaseLinePartlyShipped(PurchaseLine, DescriptionTxt);
                    if (PurchaseLine."Outstanding Quantity" <> PurchaseLine.Quantity) and (PurchaseLine.Type = PurchaseLine.Type::"Charge (Item)") then
                        DescriptionTxt := StrSubstNo(Text0014, PurchaseLine."Line No.", PurchaseLine.Type::"Charge (Item)");
                    if PurchaseLine."Prepmt. Amount Inv. (LCY)" <> 0 then
                        DescriptionTxt := Text0011;
                end;
                OnCanUpdatePurchaseOnAfterLoopIteration(DescriptionTxt, PurchaseLine);
            until (PurchaseLine.Next() = 0) or (DescriptionTxt <> '');
        if DescriptionTxt = '' then
            exit(true);

        VATRateChangeLogEntry.Init();
        RecRef.GetTable(PurchaseHeader);
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        VATRateChangeLogEntry.Description := DescriptionTxt;
        WriteLogEntry(VATRateChangeLogEntry);
    end;

    local procedure CheckPurchaseLinePartlyShipped(var PurchaseLine: Record "Purchase Line"; var DescriptionTxt: Text[250])
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchaseLinePartlyShipped(PurchaseLine, DescriptionTxt, IsHandled);
        if IsHandled then
            exit;

        if (PurchaseLine."Outstanding Quantity" <> PurchaseLine.Quantity) and
               WhseValidateSourceLine.WhseLinesExist(
                 Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, PurchaseLine.Quantity)
        then
            DescriptionTxt := Text0006;
    end;

    local procedure AddNewPurchaseLine(PurchaseLine: Record "Purchase Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        NewPurchaseLine: Record "Purchase Line";
        OldPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        OldReservationEntry: Record "Reservation Entry";
        NewReservationEntry: Record "Reservation Entry";
        OldItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        NewItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewLineNo: Integer;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
        RoundingPrecision: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddNewPurchaseLine(PurchaseLine, VATProdPostingGroup, GenProdPostingGroup, IsHandled);
        if not IsHandled then begin
            if not GetNextPurchaseLineNo(PurchaseLine, NewLineNo) then
                exit;

            NewPurchaseLine.Init();
            NewPurchaseLine := PurchaseLine;
            NewPurchaseLine."Line No." := NewLineNo;
            NewPurchaseLine."Quantity Received" := 0;
            NewPurchaseLine."Qty. Received (Base)" := 0;
            NewPurchaseLine."Return Qty. Shipped" := 0;
            NewPurchaseLine."Return Qty. Shipped (Base)" := 0;
            NewPurchaseLine."Quantity Invoiced" := 0;
            NewPurchaseLine."Qty. Invoiced (Base)" := 0;
            NewPurchaseLine."Reserved Quantity" := 0;
            NewPurchaseLine."Reserved Qty. (Base)" := 0;
            NewPurchaseLine."Qty. Rcd. Not Invoiced" := 0;
            NewPurchaseLine."Qty. Rcd. Not Invoiced (Base)" := 0;
            NewPurchaseLine."Return Qty. Shipped Not Invd." := 0;
            NewPurchaseLine."Ret. Qty. Shpd Not Invd.(Base)" := 0;
            NewPurchaseLine."Qty. to Receive" := 0;
            NewPurchaseLine."Qty. to Receive (Base)" := 0;
            NewPurchaseLine."Return Qty. to Ship" := 0;
            NewPurchaseLine."Return Qty. to Ship (Base)" := 0;
            NewPurchaseLine."Qty. to Invoice" := 0;
            NewPurchaseLine."Qty. to Invoice (Base)" := 0;
            NewPurchaseLine."Amt. Rcd. Not Invoiced" := 0;
            NewPurchaseLine."Amt. Rcd. Not Invoiced (LCY)" := 0;
            NewPurchaseLine."Return Shpd. Not Invd." := 0;
            NewPurchaseLine."Return Shpd. Not Invd. (LCY)" := 0;
            OnAddNewPurchaseLineOnAfterNewPurchaseLineInit(OldPurchaseLine, NewPurchaseLine);

            if (GenProdPostingGroup <> '') and ConvertGenProdPostGrp(VATRateChangeSetup."Update Purchase Documents") then
                NewPurchaseLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            if (VATProdPostingGroup <> '') and ConvertVATProdPostGrp(VATRateChangeSetup."Update Purchase Documents") then
                NewPurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            NewPurchaseLine.Validate(Quantity, PurchaseLine."Outstanding Quantity");
            NewPurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Receive");
            NewPurchaseLine.Validate("Return Qty. to Ship", PurchaseLine."Return Qty. to Ship");
            if Abs(PurchaseLine."Qty. to Invoice") > (Abs(PurchaseLine."Quantity Received") - Abs(PurchaseLine."Quantity Invoiced")) then
                NewPurchaseLine.Validate(
                  NewPurchaseLine."Qty. to Invoice", PurchaseLine."Qty. to Invoice" - (PurchaseLine."Quantity Received" - PurchaseLine."Quantity Invoiced"))
            else
                NewPurchaseLine.Validate("Qty. to Invoice", 0);

            PurchaseHeader.Get(NewPurchaseLine."Document Type", NewPurchaseLine."Document No.");
            RoundingPrecision := GetRoundingPrecision(PurchaseHeader."Currency Code");

            if PurchaseHeader."Prices Including VAT" then
                NewPurchaseLine.Validate(
                  NewPurchaseLine."Direct Unit Cost",
                  Round(PurchaseLine."Direct Unit Cost" * (100 + NewPurchaseLine."VAT %") / (100 + PurchaseLine."VAT %"), RoundingPrecision))
            else
                NewPurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost");

            NewPurchaseLine.Validate("Line Discount %", PurchaseLine."Line Discount %");

            OnAddNewPurchaseLineOnBeforeInsertNewLine(PurchaseLine, NewPurchaseLine);
            NewPurchaseLine.Insert();
            OnAddNewPurchaseLineOnAfterInsertNewLine(PurchaseLine, NewPurchaseLine);

            RecRef.GetTable(PurchaseLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.Description := StrSubstNo(Text0012, Format(PurchaseLine."Line No."));
            VATRateChangeLogEntry.UpdateGroups(
              PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group",
              PurchaseLine."VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);

            RecRef.GetTable(NewPurchaseLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.UpdateGroups(
              PurchaseLine."Gen. Prod. Posting Group", NewPurchaseLine."Gen. Prod. Posting Group",
              PurchaseLine."VAT Prod. Posting Group", NewPurchaseLine."VAT Prod. Posting Group");
            VATRateChangeLogEntry.Description := StrSubstNo(Text0013, Format(NewPurchaseLine."Line No."), Format(PurchaseLine."Line No."));
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);

            UpdatePurchaseBlanketOrder(NewPurchaseLine, PurchaseLine."Line No.");
            UpdateAttachedToLineNoPurch(NewPurchaseLine, PurchaseLine."Line No.");

            OldReservationEntry.Reset();
            OldReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
            OldReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
            OldReservationEntry.SetRange("Source Ref. No.", PurchaseLine."Line No.");
            OldReservationEntry.SetRange("Source Type", Database::"Purchase Line");
            OldReservationEntry.SetRange("Source Subtype", PurchaseLine."Document Type");
            OldReservationEntry.SetFilter(
              "Reservation Status", '%1|%2',
              OldReservationEntry."Reservation Status"::Reservation,
              OldReservationEntry."Reservation Status"::Surplus);
            if OldReservationEntry.Find('-') then
                repeat
                    NewReservationEntry := OldReservationEntry;
                    NewReservationEntry."Source Ref. No." := NewLineNo;
                    NewReservationEntry.Modify();
                until OldReservationEntry.Next() = 0;

            case PurchaseLine.Type of
                PurchaseLine.Type::Item:
                    begin
                        OldItemChargeAssignmentPurch.Reset();
                        OldItemChargeAssignmentPurch.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        OldItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", PurchaseLine."Document Type");
                        OldItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", PurchaseLine."Document No.");
                        OldItemChargeAssignmentPurch.SetRange("Applies-to Doc. Line No.", PurchaseLine."Line No.");
                        if OldItemChargeAssignmentPurch.FindSet() then
                            repeat
                                QtyRemainder := OldItemChargeAssignmentPurch."Qty. to Assign";
                                AmountRemainder := OldItemChargeAssignmentPurch."Amount to Assign";
                                NewItemChargeAssignmentPurch := OldItemChargeAssignmentPurch;
                                NewItemChargeAssignmentPurch."Line No." := GetNextItemChrgAssPurchLineNo(OldItemChargeAssignmentPurch);
                                NewItemChargeAssignmentPurch."Applies-to Doc. Line No." := NewLineNo;
                                NewItemChargeAssignmentPurch."Qty. to Assign" :=
                                  Round(QtyRemainder / PurchaseLine.Quantity * PurchaseLine."Outstanding Quantity", UOMMgt.QtyRndPrecision());
                                if PurchaseLine."Quantity Received" - PurchaseLine."Quantity Invoiced" = 0 then
                                    NewItemChargeAssignmentPurch."Qty. to Assign" := QtyRemainder;
                                NewItemChargeAssignmentPurch."Amount to Assign" :=
                                  Round(NewItemChargeAssignmentPurch."Qty. to Assign" * NewItemChargeAssignmentPurch."Unit Cost", RoundingPrecision);
                                NewItemChargeAssignmentPurch.Insert();
                                QtyRemainder := QtyRemainder - NewItemChargeAssignmentPurch."Qty. to Assign";
                                AmountRemainder := AmountRemainder - NewItemChargeAssignmentPurch."Amount to Assign";
                                OldItemChargeAssignmentPurch."Qty. to Assign" := QtyRemainder;
                                OldItemChargeAssignmentPurch."Amount to Assign" := AmountRemainder;
                                OldItemChargeAssignmentPurch.Modify();
                            until OldItemChargeAssignmentPurch.Next() = 0;
                    end;
            end;

            OldPurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
            OldPurchaseLine.Validate("Qty. to Receive", 0);
            OldPurchaseLine.Validate(Quantity, PurchaseLine."Quantity Received");

            OldPurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost");

            OldPurchaseLine.Validate("Line Discount %", PurchaseLine."Line Discount %");
            OldPurchaseLine.Validate("Return Qty. to Ship", 0);
            if Abs(PurchaseLine."Qty. to Invoice") > (Abs(PurchaseLine."Quantity Received") - Abs(PurchaseLine."Quantity Invoiced")) then
                OldPurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Quantity Received" - PurchaseLine."Quantity Invoiced")
            else
                OldPurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice");

            OnAddNewPurchaseLineOnBeforeOldPurchaseLineModify(OldPurchaseLine, NewPurchaseLine, VATProdPostingGroup, GenProdPostingGroup);
            OldPurchaseLine.Modify();
        end;

        OnAfterAddNewPurchaseLine(OldPurchaseLine, NewPurchaseLine);
    end;

    procedure GetNextPurchaseLineNo(PurchaseLine: Record "Purchase Line"; var NextLineNo: Integer): Boolean
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        PurchaseLine2.Reset();
        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine2 := PurchaseLine;
        if PurchaseLine2.Find('>') then
            NextLineNo := PurchaseLine."Line No." + (PurchaseLine2."Line No." - PurchaseLine."Line No.") div 2;
        if (NextLineNo = PurchaseLine."Line No.") or (NextLineNo = 0) then begin
            PurchaseLine2.FindLast();
            NextLineNo := PurchaseLine2."Line No." + 10000;
        end;
        exit(NextLineNo <> PurchaseLine."Line No.");
    end;

    local procedure UpdatePurchaseBlanketOrder(PurchaseLine: Record "Purchase Line"; OriginalLineNo: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Blanket Order" then begin
            PurchaseLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            PurchaseLine2.SetRange("Blanket Order No.", PurchaseLine."Document No.");
            PurchaseLine2.SetFilter("Blanket Order Line No.", '=%1', OriginalLineNo);
            PurchaseLine2.SetRange(Type, PurchaseLine.Type);
            PurchaseLine2.SetRange("No.", PurchaseLine."No.");
            PurchaseLine2.SetRange("Quantity Received", 0);
            Clear(PurchaseHeader);
            if PurchaseLine2.Find('-') then
                repeat
                    if (PurchaseHeader."Document Type" <> PurchaseLine2."Document Type") or
                       (PurchaseHeader."No." <> PurchaseLine2."Document No.")
                    then begin
                        PurchaseHeader.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");
                        PurchaseLine3.Reset();
                        PurchaseLine3.SetRange("Document Type", PurchaseHeader."Document Type");
                        PurchaseLine3.SetRange("Document No.", PurchaseHeader."No.");
                        PurchaseLine3.SetRange("Blanket Order No.", PurchaseLine2."Blanket Order No.");
                        PurchaseLine3.SetRange("Blanket Order Line No.", PurchaseLine2."Blanket Order Line No.");
                        IsHandled := false;
                        OnUpdatePurchaseBlanketOrderOnBeforeChangeBlanketOrder(PurchaseLine, IsHandled);
                        if not IsHandled then
                            if PurchaseLine3.FindLast() then begin
                                PurchaseLine3."Blanket Order Line No." := PurchaseLine."Line No.";
                                PurchaseLine3.Modify();
                            end;
                    end;
                until PurchaseLine2.Next() = 0;
        end;
    end;

    procedure UpdateUnitPriceInclVAT(Type: Enum "Sales Line Type"): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        exit(
          ((VATRateChangeSetup."Update Unit Price For G/L Acc." and
            (Type = SalesLine.Type::"G/L Account")) or
           (VATRateChangeSetup."Upd. Unit Price For Item Chrg." and
            (Type = SalesLine.Type::"Charge (Item)")) or
           (VATRateChangeSetup."Upd. Unit Price For FA" and (Type = SalesLine.Type::"Fixed Asset"))));
    end;

    procedure LineInScope(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; ConvertGenProdPostingGroup: Boolean; ConvertVATProdPostingGroup: Boolean) Result: Boolean
    begin
        if ConvertGenProdPostingGroup then
            if VATRateChangeConversion.Get(VATRateChangeConversion.Type::"Gen. Prod. Posting Group", GenProdPostingGroup) then
                Result := true;
        if ConvertVATProdPostingGroup then
            if VATRateChangeConversion.Get(VATRateChangeConversion.Type::"VAT Prod. Posting Group", VATProdPostingGroup) then
                Result := true;
        OnAfterLineInScope(GenProdPostingGroup, VATProdPostingGroup, ConvertGenProdPostingGroup, ConvertVATProdPostingGroup, Result)
    end;

    procedure GetNextSalesLineNo(SalesLine: Record "Sales Line"; var NextLineNo: Integer): Boolean
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2.Reset();
        SalesLine2.SetRange("Document Type", SalesLine."Document Type");
        SalesLine2.SetRange("Document No.", SalesLine."Document No.");
        SalesLine2 := SalesLine;
        if SalesLine2.Find('>') then
            NextLineNo := SalesLine."Line No." + (SalesLine2."Line No." - SalesLine."Line No.") div 2;
        if (NextLineNo = SalesLine."Line No.") or (NextLineNo = 0) then begin
            SalesLine2.FindLast();
            NextLineNo := SalesLine2."Line No." + 10000;
        end;
        exit(NextLineNo <> SalesLine."Line No.");
    end;

    procedure GetRoundingPrecision(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);
        exit(Currency."Unit-Amount Rounding Precision");
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit "Serv. VAT Rate Change Conv."', '25.0')]
    procedure GetNextServiceLineNo(ServiceLine: Record Microsoft.Service.Document."Service Line"; var NextLineNo: Integer): Boolean
    var
        ServVATRateChangeConv: Codeunit "Serv. VAT Rate Change Conv.";
    begin
        exit(ServVATRateChangeConv.GetNextServiceLineNo(ServiceLine, NextLineNo));
    end;
#endif

    local procedure GetNextItemChrgAssSaleLineNo(ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"): Integer
    var
        ItemChargeAssignmentSales2: Record "Item Charge Assignment (Sales)";
        ExitValue: Integer;
    begin
        ExitValue := 10000;
        ItemChargeAssignmentSales2.Reset();
        ItemChargeAssignmentSales2.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        ItemChargeAssignmentSales2.SetRange("Document Type", ItemChargeAssignmentSales."Document Type");
        ItemChargeAssignmentSales2.SetRange("Document No.", ItemChargeAssignmentSales."Document No.");
        ItemChargeAssignmentSales2.SetRange("Document Line No.", ItemChargeAssignmentSales."Document Line No.");
        if ItemChargeAssignmentSales2.FindLast() then
            ExitValue := ItemChargeAssignmentSales2."Line No." + 10000;
        exit(ExitValue);
    end;

    local procedure GetNextItemChrgAssPurchLineNo(ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"): Integer
    var
        ItemChargeAssignmentPurch2: Record "Item Charge Assignment (Purch)";
        ExitValue: Integer;
    begin
        ExitValue := 10000;
        ItemChargeAssignmentPurch2.Reset();
        ItemChargeAssignmentPurch2.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        ItemChargeAssignmentPurch2.SetRange("Document Type", ItemChargeAssignmentPurch."Document Type");
        ItemChargeAssignmentPurch2.SetRange("Document No.", ItemChargeAssignmentPurch."Document No.");
        ItemChargeAssignmentPurch2.SetRange("Document Line No.", ItemChargeAssignmentPurch."Document Line No.");
        if ItemChargeAssignmentPurch2.FindLast() then
            ExitValue := ItemChargeAssignmentPurch2."Line No." + 10000;
        exit(ExitValue);
    end;

    local procedure AreTablesSelected() Result: Boolean
    begin
        if VATRateChangeSetup."Update Gen. Prod. Post. Groups" <> VATRateChangeSetup."Update Gen. Prod. Post. Groups"::No then
            exit(true);
        if VATRateChangeSetup."Update G/L Accounts" <> VATRateChangeSetup."Update G/L Accounts"::No then
            exit(true);
        if VATRateChangeSetup."Update Items" <> VATRateChangeSetup."Update Items"::No then
            exit(true);
        if VATRateChangeSetup."Update Item Templates" <> VATRateChangeSetup."Update Item Templates"::No then
            exit(true);
        if VATRateChangeSetup."Update Item Charges" <> VATRateChangeSetup."Update Item Charges"::No then
            exit(true);
        if VATRateChangeSetup."Update Resources" <> VATRateChangeSetup."Update Resources"::No then
            exit(true);
        if VATRateChangeSetup."Update Gen. Journal Lines" <> VATRateChangeSetup."Update Gen. Journal Lines"::No then
            exit(true);
        if VATRateChangeSetup."Update Gen. Journal Allocation" <> VATRateChangeSetup."Update Gen. Journal Allocation"::No then
            exit(true);
        if VATRateChangeSetup."Update Std. Gen. Jnl. Lines" <> VATRateChangeSetup."Update Std. Gen. Jnl. Lines"::No then
            exit(true);
        if VATRateChangeSetup."Update Res. Journal Lines" <> VATRateChangeSetup."Update Res. Journal Lines"::No then
            exit(true);
        if VATRateChangeSetup."Update Job Journal Lines" <> VATRateChangeSetup."Update Job Journal Lines"::No then
            exit(true);
        if VATRateChangeSetup."Update Requisition Lines" <> VATRateChangeSetup."Update Requisition Lines"::No then
            exit(true);
        if VATRateChangeSetup."Update Std. Item Jnl. Lines" <> VATRateChangeSetup."Update Std. Item Jnl. Lines"::No then
            exit(true);
        if VATRateChangeSetup."Update Sales Documents" <> VATRateChangeSetup."Update Sales Documents"::No then
            exit(true);
        if VATRateChangeSetup."Update Purchase Documents" <> VATRateChangeSetup."Update Purchase Documents"::No then
            exit(true);
        if VATRateChangeSetup."Update Reminders" <> VATRateChangeSetup."Update Reminders"::No then
            exit(true);
        if VATRateChangeSetup."Update Finance Charge Memos" <> VATRateChangeSetup."Update Finance Charge Memos"::No then
            exit(true);
        Result := false;

        OnAfterAreTablesSelected(VATRateChangeSetup, Result);
    end;

    procedure IncludeSalesLine(Type: Enum "Sales Line Type"; No: Code[20]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        case Type of
            "Sales Line Type"::"G/L Account":
                exit(IncludeGLAccount(No));
            "Sales Line Type"::Item:
                exit(IncludeItem(No));
            "Sales Line Type"::Resource:
                exit(IncludeRes(No));
            else begin
                IsHandled := false;
                OnIncludeSalesLineOnTypeElse(Type, Result, IsHandled);
                if IsHandled then
                    exit(Result);
            end;
        end;
        exit(true);
    end;

    procedure IncludePurchLine(Type: Enum "Purchase Line Type"; No: Code[20]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        case Type of
            "Purchase Line Type"::"G/L Account":
                exit(IncludeGLAccount(No));
            "Purchase Line Type"::Item:
                exit(IncludeItem(No));
            "Purchase Line Type"::Resource:
                exit(IncludeRes(No));
            else begin
                IsHandled := false;
                OnIncludePurchLineOnTypeElse(Type, Result, IsHandled);
                if IsHandled then
                    exit(Result);
            end;
        end;
        exit(true);
    end;

    local procedure IncludeGLAccount(No: Code[20]): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if VATRateChangeSetup."Account Filter" = '' then
            exit(true);
        GLAccount."No." := No;
        GLAccount.SetFilter("No.", VATRateChangeSetup."Account Filter");
        exit(GLAccount.Find());
    end;

    local procedure IncludeItem(No: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if VATRateChangeSetup."Item Filter" = '' then
            exit(true);
        Item."No." := No;
        Item.SetFilter("No.", VATRateChangeSetup."Item Filter");
        exit(Item.Find());
    end;

    local procedure IncludeRes(No: Code[20]): Boolean
    var
        Res: Record Resource;
    begin
        if VATRateChangeSetup."Resource Filter" = '' then
            exit(true);
        Res."No." := No;
        Res.SetFilter("No.", VATRateChangeSetup."Resource Filter");
        exit(Res.Find());
    end;

    procedure InitVATRateChangeLogEntry(var VATRateChangeLogEntry: Record "VAT Rate Change Log Entry"; RecRef: RecordRef; OutstandingQuantity: Decimal; LineNo: Integer)
    begin
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        if (OutstandingQuantity = 0) and VATRateChangeSetup."Perform Conversion" then
            VATRateChangeLogEntry.Description := Text0007
        else begin
            VATRateChangeLogEntry.Description :=
              StrSubstNo(Text0009, VATRateChangeSetup.FieldCaption("Perform Conversion"));
            if OutstandingQuantity <> 0 then
                VATRateChangeLogEntry.Description := StrSubstNo(Text0017, LineNo)
        end;
    end;

    local procedure DoUpdatePurchaseLine(var PurchaseLine: Record "Purchase Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDoUpdatePurchaseLine(PurchaseLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        exit(PurchaseLine.Quantity = PurchaseLine."Outstanding Quantity")
    end;

    local procedure DoUpdateSalesLine(var SalesLine: Record "Sales Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDoUpdateSalesLine(SalesLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        exit(SalesLine.Quantity = SalesLine."Outstanding Quantity")
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewPurchaseLineOnBeforeOldPurchaseLineModify(var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewSalesLineOnBeforeOldSalesLineModify(var OldSalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAddNewServiceLineOnBeforeOldServiceLineModify(var OldServiceLine: Record Microsoft.Service.Document."Service Line"; var NewServiceLine: Record Microsoft.Service.Document."Service Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        OnAddNewServiceLineOnBeforeOldServiceLineModify(OldServiceLine, NewServiceLine, VATProdPostingGroup, GenProdPostingGroup);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. VAT Rate Change Conv.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAddNewServiceLineOnBeforeOldServiceLineModify(var OldServiceLine: Record Microsoft.Service.Document."Service Line"; var NewServiceLine: Record Microsoft.Service.Document."Service Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewSalesLineFromSalesLine(var NewSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateTables(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterLineInScope(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; ConvertGenProdPostingGroup: Boolean; ConvertVATProdPostingGroup: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAreTablesSelected(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchaseLinePartlyShipped(var PurchaseLine: Record "Purchase Line"; var DescriptionTxt: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLinePartlyShipped(var SalesLine: Record "Sales Line"; var DescriptionTxt: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFinishConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var ProgressWindow: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGLAccount(var GLAccount: Record "G/L Account"; var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateItem(var Item: Record Item; var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateResource(var Resource: Record Resource; var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSales(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTable(TableID: Integer; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchase(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeUpdateServPriceAdjDetail(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
        OnBeforeUpdateServPriceAdjDetail(VATRateChangeSetup, IsHandled);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. VAT Rate Change Conv.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServPriceAdjDetail(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeUpdateService(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
        OnBeforeUpdateService(VATRateChangeSetup, IsHandled);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. VAT Rate Change Conv.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateService(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRec(var RecRef: RecordRef; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvertOnBeforeStartConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddNewSalesLine(var OldSalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddNewPurchaseLine(var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnAfterPurchaseHeaderSetFilters(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdatePurchaseOnAfterPurchaseLineSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRecOnBeforeRecRefModify(var RecRef: RecordRef; GenProdPostingGroupConverted: Boolean; VATProdPostingGroupConverted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRecOnAfterRecRefModify(var RecRef: RecordRef; GenProdPostingGroupConverted: Boolean; VATProdPostingGroupConverted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterSalesHeaderSetFilters(VATRateChangeSetup: Record "VAT Rate Change Setup"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterSalesLineSetFilters(VATRateChangeSetup: Record "VAT Rate Change Setup"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterModifySalesLine(var SalesLine: Record "Sales Line"; IsModified: Boolean; VATRateChangeSetup: Record "VAT Rate Change Setup"; SalesHeader: Record "Sales Header"; SalesLineOld: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateSalesOnAfterUpdateSalesLines(VATRateChangeSetup: Record "VAT Rate Change Setup"; var SalesHeader: Record "Sales Header"; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnAfterResetPurchaseHeaderStatus(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdatePurchaseOnAfterCalcShouldProcessLine(var PurchaseLine: Record "Purchase Line"; var ShouldProcessLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterResetSalesHeaderStatus(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnBeforeModifySalesLine(var SalesLine: Record "Sales Line"; var IsModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnBeforeModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; var IsModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewPurchaseLineOnAfterInsertNewLine(var PurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewPurchaseLineOnBeforeInsertNewLine(var PurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewSalesLineOnAfterInsertNewLine(var SalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnBeforeChangeSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnBeforeChangePurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseBlanketOrderOnBeforeChangeBlanketOrder(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesBlanketOrderOnBeforeChangeBlanketOrder(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnAfterOpenPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterOpenSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdatePurchaseOnAfterUpdatePurchaseLines(VATRateChangeSetup: Record "VAT Rate Change Setup"; var PurchaseHeader: Record "Purchase Header"; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestVATPostingSetupOnAfterVATPostingSetupOldSetFilters(var VATPostingSetupOld: Record "VAT Posting Setup"; VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateRecOnBeforeValidateGenProdPostingGroup(var RecRef: RecordRef; FldRef: FieldRef; VatRateChangeConversion: Record "VAT Rate Change Conversion"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewPurchaseLineOnAfterNewPurchaseLineInit(var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnAfterPurchaseLineModify(VATRateChangeSetup: Record "VAT Rate Change Setup"; PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchaseLineOld: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnIncludePurchLineOnTypeElse(Type: Enum "Purchase Line Type"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnIncludeSalesLineOnTypeElse(Type: Enum "Sales Line Type"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanUpdatePurchaseOnAfterLoopIteration(var DescriptionTxt: Text[250]; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanUpdatePurchaseOnAfterPurchaseLineSetFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanUpdateSalesOnAfterLoopIteration(var DescriptionTxt: Text[250]; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanUpdateSalesOnAfterSalesLineSetFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoUpdatePurchaseLine(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var CanUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoUpdateSalesLine(SalesLine: Record "Sales Line"; var IsHandled: Boolean; var CanUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanUpdateSales(SalesHeader: Record "Sales Header"; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean; var IsHandled: Boolean; var CanUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanUpdatePurchase(PurchaseHeader: Record "Purchase Header"; ConvertGenProdPostingGroup: Boolean; ConvertVATProdPostingGroup: Boolean; var IsHandled: Boolean; var CanUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddNewSalesLine(SalesLine: Record "Sales Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddNewPurchaseLine(PurchaseLine: Record "Purchase Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; var IsHandled: Boolean)
    begin
    end;
}
