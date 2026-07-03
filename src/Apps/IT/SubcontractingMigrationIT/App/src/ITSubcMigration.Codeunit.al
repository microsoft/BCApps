#if not CLEAN29
namespace Microsoft.Manufacturing.Subcontracting.Migration;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 149951 "IT Subc. Migration"
{
    Access = Internal;

    ObsoleteState = Pending;
    ObsoleteReason = 'The legacy subcontracting feature is being deprecated.';
    ObsoleteTag = '29.0';

    internal procedure RunMigration()
    begin
        MigrateVendors();
        MigrateSubcontractorPrices();
        MigratePurchaseHeaders();
        MigratePurchaseLines();
        MigrateTransferLines();
        MigrateTransferHeaders();
        MigrateProdOrderComponents();
        MigrateProdOrderRoutingLines();
        MigrateRoutingLines();
    end;

    internal procedure StartDisableLegacySubcontracting(ShowDialog: Boolean)
#if not CLEAN29
    var
#pragma warning disable AL0432
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN29
        LegacySubcFeatureHandler.CheckCanDisableLegacySubcontracting();
#endif
        UIAllowed := ShowDialog and GuiAllowed();
        if UIAllowed then begin
            ConfirmDisableLegacySubcontracting();
            MigrationProgressDialog.Open(MigrationProgressLbl);
        end;

        LockTables();
        Clear(PreMigrationCounts);
        RunMigration();

        if UIAllowed then
            StartProgressPhase(VerifyingPhaseLbl, VerifyingProgressEntityLbl, 1);

        VerifyMigration();

        if UIAllowed then
            UpdateProgressPhase();

        if UIAllowed then begin
            StartProgressPhase(FinalizingPhaseLbl, FinalizingProgressEntityLbl, 1);
            UpdateProgressPhase();
        end;

        if UIAllowed then
            MigrationProgressDialog.Close();
    end;

    internal procedure MigrateTransferLines()
    var
        TransferLine: Record "Transfer Line";
        DoModify: Boolean;
        TotalRecords: Integer;
    begin
        SetTransferLineMigrationFilters(TransferLine);
        TotalRecords := TransferLine.Count();
        PreMigrationCounts.Set(TransferLineProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(TransferLinesPhaseLbl, TransferLineProgressEntityLbl, TotalRecords);

        if not TransferLine.FindSet() then
            exit;

        repeat
            DoModify := false;

            if TransferLine."Subc. Purch. Order No." <> TransferLine."Subcontr. Purch. Order No." then begin
                TransferLine."Subc. Purch. Order No." := TransferLine."Subcontr. Purch. Order No.";
                DoModify := true;
            end;

            if TransferLine."Subc. Purch. Order Line No." <> TransferLine."Subcontr. Purch. Order Line" then begin
                TransferLine."Subc. Purch. Order Line No." := TransferLine."Subcontr. Purch. Order Line";
                DoModify := true;
            end;

            if TransferLine."Subc. Prod. Order No." <> TransferLine."Prod. Order No." then begin
                TransferLine."Subc. Prod. Order No." := TransferLine."Prod. Order No.";
                DoModify := true;
            end;

            if TransferLine."Subc. Prod. Order Line No." <> TransferLine."Prod. Order Line No." then begin
                TransferLine."Subc. Prod. Order Line No." := TransferLine."Prod. Order Line No.";
                DoModify := true;
            end;

            if TransferLine."Subc. Prod. Ord. Comp Line No." <> TransferLine."Prod. Order Comp. Line No." then begin
                TransferLine."Subc. Prod. Ord. Comp Line No." := TransferLine."Prod. Order Comp. Line No.";
                DoModify := true;
            end;

            if TransferLine."Subc. Routing No." <> TransferLine."Routing No." then begin
                TransferLine."Subc. Routing No." := TransferLine."Routing No.";
                DoModify := true;
            end;

            if TransferLine."Subc. Routing Reference No." <> TransferLine."Routing Reference No." then begin
                TransferLine."Subc. Routing Reference No." := TransferLine."Routing Reference No.";
                DoModify := true;
            end;

            if TransferLine."Subc. Work Center No." <> TransferLine."Work Center No." then begin
                TransferLine."Subc. Work Center No." := TransferLine."Work Center No.";
                DoModify := true;
            end;

            if TransferLine."Subc. Operation No." <> TransferLine."Operation No." then begin
                TransferLine."Subc. Operation No." := TransferLine."Operation No.";
                DoModify := true;
            end;

            if DoModify then
                TransferLine.Modify();

            if UIAllowed then
                UpdateProgressPhase();
        until TransferLine.Next() = 0;
    end;

    internal procedure MigratePurchaseLines()
    var
        PurchaseLine: Record "Purchase Line";
        SubcPurchaseLineType: Enum "Subc. Purchase Line Type";
        DoModify: Boolean;
        TotalRecords: Integer;
    begin
        SetPurchaseLineMigrationFilters(PurchaseLine);
        TotalRecords := PurchaseLine.Count();
        PreMigrationCounts.Set(PurchaseLineProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(PurchaseLinesPhaseLbl, PurchaseLineProgressEntityLbl, TotalRecords);
        if not PurchaseLine.FindSet() then
            exit;

        repeat
            DoModify := false;
            SubcPurchaseLineType := GetSubcPurchaseLineType(PurchaseLine);
            if PurchaseLine."Subc. Purchase Line Type" <> SubcPurchaseLineType then begin
                PurchaseLine."Subc. Purchase Line Type" := SubcPurchaseLineType;
                DoModify := true;
            end;
            if DoModify then
                PurchaseLine.Modify();

            if UIAllowed then
                UpdateProgressPhase();
        until PurchaseLine.Next() = 0;
    end;

    internal procedure MigrateTransferHeaders()
    var
        TransferHeader: Record "Transfer Header";
        NewSourceType: Enum "Transfer Source Type";
        DocsWithSubcLines: Dictionary of [Code[20], Boolean];
        DoModify: Boolean;
        TotalRecords: Integer;
    begin
        BuildSubcTransferLineDocLookup(DocsWithSubcLines);

        TotalRecords := TransferHeader.Count();
        PreMigrationCounts.Set(TransferHeaderProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(TransferHeadersPhaseLbl, TransferHeaderProgressEntityLbl, TotalRecords);
        if not TransferHeader.FindSet() then
            exit;

        repeat
            DoModify := false;

            if TransferHeader."Subc. Return Order" <> TransferHeader."Return Order" then begin
                TransferHeader."Subc. Return Order" := TransferHeader."Return Order";
                DoModify := true;
            end;

            if DocsWithSubcLines.ContainsKey(TransferHeader."No.") then
                NewSourceType := NewSourceType::Subcontracting
            else
                NewSourceType := NewSourceType::Empty;

            if TransferHeader."Subc. Source Type" <> NewSourceType then begin
                TransferHeader."Subc. Source Type" := NewSourceType;
                DoModify := true;
            end;

            if DoModify then
                TransferHeader.Modify();

            if UIAllowed then
                UpdateProgressPhase();
        until TransferHeader.Next() = 0;
    end;

    local procedure BuildSubcTransferLineDocLookup(var DocsWithSubcLines: Dictionary of [Code[20], Boolean])
    var
        TransferLine: Record "Transfer Line";
    begin
        SetSubcTransferLineLookupFilters(TransferLine);
        TransferLine.SetLoadFields("Document No.");
        if not TransferLine.FindSet() then
            exit;

        repeat
            if not DocsWithSubcLines.ContainsKey(TransferLine."Document No.") then
                DocsWithSubcLines.Add(TransferLine."Document No.", true);
        until TransferLine.Next() = 0;
    end;

    internal procedure MigrateProdOrderComponents()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        DoModify: Boolean;
        TotalRecords: Integer;
    begin
        SetProdOrderComponentMigrationFilters(ProdOrderComponent);
        TotalRecords := ProdOrderComponent.Count();
        PreMigrationCounts.Set(ProdOrderComponentProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(ProdOrderComponentsPhaseLbl, ProdOrderComponentProgressEntityLbl, TotalRecords);
        if not ProdOrderComponent.FindSet() then
            exit;

        repeat
            DoModify := false;
#pragma warning disable AL0432
            if ProdOrderComponent."Subc. Original Location Code" <> ProdOrderComponent."Original Location" then begin
                ProdOrderComponent."Subc. Original Location Code" := ProdOrderComponent."Original Location";
#pragma warning restore AL0432
                DoModify := true;
            end;
            if DoModify then
                ProdOrderComponent.Modify();

            if UIAllowed then
                UpdateProgressPhase();
        until ProdOrderComponent.Next() = 0;
    end;

    internal procedure MigrateProdOrderRoutingLines()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        DoModify: Boolean;
        TotalRecords: Integer;
    begin
        SetProdOrderRoutingLineMigrationFilters(ProdOrderRoutingLine);
        TotalRecords := ProdOrderRoutingLine.Count();
        PreMigrationCounts.Set(ProdOrderRoutingLineProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(ProdOrderRoutingLinesPhaseLbl, ProdOrderRoutingLineProgressEntityLbl, TotalRecords);
        if not ProdOrderRoutingLine.FindSet() then
            exit;

        repeat
            DoModify := false;
#pragma warning disable AL0432
            if ProdOrderRoutingLine."Transfer WIP Item" <> ProdOrderRoutingLine."WIP Item" then begin
                ProdOrderRoutingLine."Transfer WIP Item" := ProdOrderRoutingLine."WIP Item";
#pragma warning restore AL0432
                DoModify := true;
            end;
            if DoModify then
                ProdOrderRoutingLine.Modify();

            if UIAllowed then
                UpdateProgressPhase();
        until ProdOrderRoutingLine.Next() = 0;
    end;

    internal procedure MigrateRoutingLines()
    var
        RoutingLine: Record "Routing Line";
        DoModify: Boolean;
        TotalRecords: Integer;
    begin
        SetRoutingLineMigrationFilters(RoutingLine);
        TotalRecords := RoutingLine.Count();
        PreMigrationCounts.Set(RoutingLineProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(RoutingLinesPhaseLbl, RoutingLineProgressEntityLbl, TotalRecords);
        if not RoutingLine.FindSet() then
            exit;

        repeat
            DoModify := false;
#pragma warning disable AL0432
            if RoutingLine."Transfer WIP Item" <> RoutingLine."WIP Item" then begin
                RoutingLine."Transfer WIP Item" := RoutingLine."WIP Item";
#pragma warning restore AL0432
                DoModify := true;
            end;
            if DoModify then
                RoutingLine.Modify();

            if UIAllowed then
                UpdateProgressPhase();
        until RoutingLine.Next() = 0;
    end;

    internal procedure MigrateVendors()
    var
        Vendor: Record Vendor;
        DoModify: Boolean;
        TotalRecords: Integer;
    begin
        SetVendorMigrationFilters(Vendor);
        TotalRecords := Vendor.Count();
        PreMigrationCounts.Set(VendorProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(VendorsPhaseLbl, VendorProgressEntityLbl, TotalRecords);
        if not Vendor.FindSet() then
            exit;

        repeat
            DoModify := false;
            if Vendor."Subc. Location Code" <> Vendor."Subcontracting Location Code" then begin
                Vendor."Subc. Location Code" := Vendor."Subcontracting Location Code";
                DoModify := true;
            end;
            if DoModify then
                Vendor.Modify();

            if UIAllowed then
                UpdateProgressPhase();
        until Vendor.Next() = 0;
    end;

    internal procedure MigratePurchaseHeaders()
    var
        PurchaseHeader: Record "Purchase Header";
        DoModify: Boolean;
        TotalRecords: Integer;
    begin
        SetPurchaseHeaderMigrationFilters(PurchaseHeader);
        TotalRecords := PurchaseHeader.Count();
        PreMigrationCounts.Set(PurchaseHeaderProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(PurchaseHeadersPhaseLbl, PurchaseHeaderProgressEntityLbl, TotalRecords);
        if not PurchaseHeader.FindSet() then
            exit;

        repeat
            DoModify := false;
            if PurchaseHeader."Subc. Location Code" <> PurchaseHeader."Subcontracting Location Code" then begin
                PurchaseHeader."Subc. Location Code" := PurchaseHeader."Subcontracting Location Code";
                DoModify := true;
            end;
            if DoModify then
                PurchaseHeader.Modify();

            if UIAllowed then
                UpdateProgressPhase();
        until PurchaseHeader.Next() = 0;
    end;

    internal procedure MigrateSubcontractorPrices()
    var
#pragma warning disable AL0432
        LegacySubcontractorPrice: Record "Subcontractor Prices";
#pragma warning restore AL0432
        SubcontractorPrice: Record "Subcontractor Price";
        SubcontractorPriceExists: Boolean;
        TotalRecords: Integer;
    begin
        TotalRecords := LegacySubcontractorPrice.Count();
        PreMigrationCounts.Set(SubcontractorPriceProgressEntityLbl, TotalRecords);
        if UIAllowed then
            StartProgressPhase(SubcontractorPricesPhaseLbl, SubcontractorPriceProgressEntityLbl, TotalRecords);
        if not LegacySubcontractorPrice.FindSet() then
            exit;

        repeat
            SubcontractorPriceExists := SubcontractorPrice.Get(
                LegacySubcontractorPrice."Vendor No.",
                LegacySubcontractorPrice."Item No.",
                LegacySubcontractorPrice."Work Center No.",
                LegacySubcontractorPrice."Variant Code",
                LegacySubcontractorPrice."Standard Task Code",
                LegacySubcontractorPrice."Start Date",
                LegacySubcontractorPrice."Unit of Measure Code",
                LegacySubcontractorPrice."Minimum Quantity",
                LegacySubcontractorPrice."Currency Code");

            if not SubcontractorPriceExists then
                SubcontractorPrice.Init();
            SubcontractorPrice."Vendor No." := LegacySubcontractorPrice."Vendor No.";
            SubcontractorPrice."Item No." := LegacySubcontractorPrice."Item No.";
            SubcontractorPrice."Work Center No." := LegacySubcontractorPrice."Work Center No.";
            SubcontractorPrice."Variant Code" := LegacySubcontractorPrice."Variant Code";
            SubcontractorPrice."Standard Task Code" := LegacySubcontractorPrice."Standard Task Code";
            SubcontractorPrice."Starting Date" := LegacySubcontractorPrice."Start Date";
            SubcontractorPrice."Unit of Measure Code" := LegacySubcontractorPrice."Unit of Measure Code";
            SubcontractorPrice."Minimum Quantity" := LegacySubcontractorPrice."Minimum Quantity";
            SubcontractorPrice."Currency Code" := LegacySubcontractorPrice."Currency Code";
            SubcontractorPrice."Ending Date" := LegacySubcontractorPrice."End Date";
            SubcontractorPrice."Direct Unit Cost" := LegacySubcontractorPrice."Direct Unit Cost";
            SubcontractorPrice."Minimum Amount" := LegacySubcontractorPrice."Minimum Amount";
            if SubcontractorPriceExists then
                SubcontractorPrice.Modify()
            else
                SubcontractorPrice.Insert();

            if UIAllowed then
                UpdateProgressPhase();
        until LegacySubcontractorPrice.Next() = 0;
    end;

    internal procedure ConfirmDisableLegacySubcontracting()
    begin
        if not Confirm(DisableLegacySubcontractingQst, false) then
            Error(CanceledByUserErr);
    end;

    local procedure LockTables()
    var
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingLine: Record "Routing Line";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
#pragma warning disable AL0432
        LegacySubcontractorPrice: Record "Subcontractor Prices";
#pragma warning restore AL0432
        SubcontractorPrice: Record "Subcontractor Price";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        TransferLine.LockTable();
        PurchaseLine.LockTable();
        TransferHeader.LockTable();
        ProdOrderComponent.LockTable();
        ProdOrderRoutingLine.LockTable();
        RoutingLine.LockTable();
        Vendor.LockTable();
        PurchaseHeader.LockTable();
        LegacySubcontractorPrice.LockTable();
        SubcontractorPrice.LockTable();
        ManufacturingSetup.LockTable();
    end;

    local procedure GetSubcPurchaseLineType(PurchaseLine: Record "Purchase Line"): Enum "Subc. Purchase Line Type"
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcPurchaseLineType: Enum "Subc. Purchase Line Type";
    begin
        if not ProdOrderRoutingLine.Get(
                "Production Order Status"::Released,
                PurchaseLine."Prod. Order No.",
                PurchaseLine."Routing Reference No.",
                PurchaseLine."Routing No.",
                PurchaseLine."Operation No.") then
            exit(SubcPurchaseLineType::None);

        if ProdOrderRoutingLine."Next Operation No." = '' then
            exit(SubcPurchaseLineType::LastOperation);

        exit(SubcPurchaseLineType::NotLastOperation);
    end;

    local procedure StartProgressPhase(CurrentPhase: Text; ProgressEntity: Text; TotalPhaseRecords: Integer)
    begin
        if not UIAllowed then
            exit;
        CurrentProgressEntity := ProgressEntity;
        TotalProgressRecords := TotalPhaseRecords;
        ProcessedProgressRecords := 0;
        MigrationProgressDialog.Update(1, CurrentPhase);
        MigrationProgressDialog.Update(
            2,
            StrSubstNo(
                PhaseProgressLbl,
                CurrentProgressEntity,
                ProcessedProgressRecords,
                TotalProgressRecords,
                GetPhaseProgressPercent(ProcessedProgressRecords, TotalProgressRecords),
                PercentageTok));
    end;

    local procedure UpdateProgressPhase()
    begin
        if not UIAllowed then
            exit;
        ProcessedProgressRecords += 1;
        MigrationProgressDialog.Update(
            2,
            StrSubstNo(
                PhaseProgressLbl,
                CurrentProgressEntity,
                ProcessedProgressRecords,
                TotalProgressRecords,
                GetPhaseProgressPercent(ProcessedProgressRecords, TotalProgressRecords),
                PercentageTok));
    end;

    local procedure GetPhaseProgressPercent(ProcessedRecords: Integer; TotalRecords: Integer): Integer
    begin
        if TotalRecords = 0 then
            exit(100);
        exit(Round(ProcessedRecords / TotalRecords * 100, 1));
    end;

    local procedure SetTransferLineMigrationFilters(var TransferLine: Record "Transfer Line")
    begin
        TransferLine.SetRange("WIP Item", false);
        TransferLine.SetFilter("Subcontr. Purch. Order No.", '<>%1', '');
    end;

    local procedure SetPurchaseLineMigrationFilters(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
#pragma warning disable AL0432
        PurchaseLine.SetRange("WIP Item", false);
#pragma warning restore AL0432
        PurchaseLine.SetFilter("Prod. Order No.", '<>%1', '');
        PurchaseLine.SetFilter("Operation No.", '<>%1', '');
    end;

    local procedure SetSubcTransferLineLookupFilters(var TransferLine: Record "Transfer Line")
    begin
        TransferLine.SetFilter("Subc. Purch. Order No.", '<>%1', '');
    end;

    local procedure SetProdOrderComponentMigrationFilters(var ProdOrderComponent: Record "Prod. Order Component")
    begin
#pragma warning disable AL0432
        ProdOrderComponent.SetFilter("Original Location", '<>%1', '');
#pragma warning restore AL0432
    end;

    local procedure SetProdOrderRoutingLineMigrationFilters(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
#pragma warning disable AL0432
        ProdOrderRoutingLine.SetRange("WIP Item", true);
#pragma warning restore AL0432
    end;

    local procedure SetRoutingLineMigrationFilters(var RoutingLine: Record "Routing Line")
    begin
#pragma warning disable AL0432
        RoutingLine.SetRange("WIP Item", true);
#pragma warning restore AL0432
    end;

    local procedure SetVendorMigrationFilters(var Vendor: Record Vendor)
    begin
        Vendor.SetFilter("Subcontracting Location Code", '<>%1', '');
    end;

    local procedure SetPurchaseHeaderMigrationFilters(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetFilter("Subcontracting Location Code", '<>%1', '');
    end;

    local procedure VerifyMigration()
    var
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingLine: Record "Routing Line";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
#pragma warning disable AL0432
        LegacySubcontractorPrice: Record "Subcontractor Prices";
#pragma warning restore AL0432
    begin
        SetVendorMigrationFilters(Vendor);
        VerifyEntityCount(VendorProgressEntityLbl, Vendor.Count());

        VerifyEntityCount(SubcontractorPriceProgressEntityLbl, LegacySubcontractorPrice.Count());

        SetPurchaseHeaderMigrationFilters(PurchaseHeader);
        VerifyEntityCount(PurchaseHeaderProgressEntityLbl, PurchaseHeader.Count());

        SetPurchaseLineMigrationFilters(PurchaseLine);
        VerifyEntityCount(PurchaseLineProgressEntityLbl, PurchaseLine.Count());

        SetTransferLineMigrationFilters(TransferLine);
        VerifyEntityCount(TransferLineProgressEntityLbl, TransferLine.Count());

        VerifyEntityCount(TransferHeaderProgressEntityLbl, TransferHeader.Count());

        SetProdOrderComponentMigrationFilters(ProdOrderComponent);
        VerifyEntityCount(ProdOrderComponentProgressEntityLbl, ProdOrderComponent.Count());

        SetProdOrderRoutingLineMigrationFilters(ProdOrderRoutingLine);
        VerifyEntityCount(ProdOrderRoutingLineProgressEntityLbl, ProdOrderRoutingLine.Count());

        SetRoutingLineMigrationFilters(RoutingLine);
        VerifyEntityCount(RoutingLineProgressEntityLbl, RoutingLine.Count());
    end;

    local procedure VerifyEntityCount(EntityKey: Text; PostMigrationCount: Integer)
    var
        PreCount: Integer;
    begin
        if not PreMigrationCounts.Get(EntityKey, PreCount) then
            exit;
        if PreCount <> PostMigrationCount then
            Error(MigrationVerificationFailedErr, EntityKey, PreCount, PostMigrationCount);
    end;

    var
        MigrationProgressDialog: Dialog;
        PreMigrationCounts: Dictionary of [Text, Integer];
        UIAllowed: Boolean;
        CurrentProgressEntity: Text;
        TotalProgressRecords: Integer;
        ProcessedProgressRecords: Integer;
        CanceledByUserErr: Label 'Canceled by user.';
        DisableLegacySubcontractingQst: Label 'This migrates legacy IT subcontracting data to the new subcontracting app. Legacy subcontracting will be disabled and cannot be activated again.\\Related records will be locked during the migration process to ensure data consistency. No other processes can modify these records until the migration completes.\\Do you want to continue?';
        MigrationProgressLbl: Label 'Migrating IT subcontracting data...\\#1##################################################\\#2##################################################', Comment = '#1 = current migration phase, #2 = current record progress';
        PhaseProgressLbl: Label '%1 %2 of %3 (%4%5)', Comment = '%1 = record caption, %2 = processed record count, %3 = total record count, %4 = percentage complete, %5 = percentage symbol';
        PercentageTok: Label '%', Locked = true;
        TransferLinesPhaseLbl: Label 'Migrating transfer lines...';
        TransferLineProgressEntityLbl: Label 'Transfer line';
        PurchaseLinesPhaseLbl: Label 'Migrating purchase lines...';
        PurchaseLineProgressEntityLbl: Label 'Purchase line';
        TransferHeadersPhaseLbl: Label 'Migrating transfer headers...';
        TransferHeaderProgressEntityLbl: Label 'Transfer header';
        ProdOrderComponentsPhaseLbl: Label 'Migrating production order components...';
        ProdOrderComponentProgressEntityLbl: Label 'Production order component';
        ProdOrderRoutingLinesPhaseLbl: Label 'Migrating production order routing lines...';
        ProdOrderRoutingLineProgressEntityLbl: Label 'Production order routing line';
        RoutingLinesPhaseLbl: Label 'Migrating routing lines...';
        RoutingLineProgressEntityLbl: Label 'Routing line';
        VendorsPhaseLbl: Label 'Migrating vendors...';
        VendorProgressEntityLbl: Label 'Vendor';
        PurchaseHeadersPhaseLbl: Label 'Migrating purchase headers...';
        PurchaseHeaderProgressEntityLbl: Label 'Purchase header';
        SubcontractorPricesPhaseLbl: Label 'Migrating subcontractor prices...';
        SubcontractorPriceProgressEntityLbl: Label 'Subcontractor price';
        FinalizingPhaseLbl: Label 'Disabling legacy subcontracting...';
        FinalizingProgressEntityLbl: Label 'Final step';
        VerifyingPhaseLbl: Label 'Verifying migration...';
        VerifyingProgressEntityLbl: Label 'Verification step';
        MigrationVerificationFailedErr: Label 'Migration verification failed for %1: expected %2 record(s) but found %3 after migration.', Comment = '%1 = entity name, %2 = pre-migration count, %3 = post-migration count';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Legacy Subc. Feature Handler", 'OnMigrationSubcontractingData', '', false, false)]
    local procedure MigrateSubconOnMigrationSubcontractingData()
    begin
        StartDisableLegacySubcontracting(true);
    end;
}
#endif
