// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.Comment;
using Microsoft.Assembly.History;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using System.Utilities;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Job;

table 904 "Assemble-to-Order Link"
{
    Caption = 'Assemble-to-Order Link';
    DataClassification = CustomerContent;
    Permissions = TableData "Assembly Header" = rimd,
                  TableData "Assemble-to-Order Link" = rimd;

    fields
    {
#pragma warning disable AS0004 // required fix
        field(1; "Assembly Document Type"; Enum "Assembly Document Type")
        {
            Caption = 'Assembly Document Type';
        }
#pragma warning restore AS0004
        field(2; "Assembly Document No."; Code[20])
        {
            Caption = 'Assembly Document No.';
            TableRelation = "Assembly Header" where("Document Type" = field("Assembly Document Type"),
                                                     "No." = field("Assembly Document No."));
            ValidateTableRelation = false;
        }
        field(11; Type; Enum "Assemble-to-Order Link Type")
        {
            Caption = 'Type';
        }
        field(12; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(13; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if (Type = const(Sale)) "Sales Line"."Document No." where("Document Type" = field("Document Type"),
                                                                                     "Document No." = field("Document No."),
                                                                                     "Line No." = field("Document Line No."))
            else
            if (Type = const(Job)) "Job Planning Line"."Document No." where("Job No." = field("Job No."),
                                                                                     "Job Task No." = field("Job Task No."),
                                                                                     "Line No." = field("Document Line No."));
        }
        field(14; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(20; "Assembled Quantity"; Decimal)
        {
            Caption = 'Assembled Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(40; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(41; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
    }

    keys
    {
        key(Key1; "Assembly Document Type", "Assembly Document No.")
        {
            Clustered = true;
        }
        key(Key2; Type, "Document Type", "Document No.", "Document Line No.")
        {
        }
        key(Key3; Type, "Job No.", "Job Task No.", "Document Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        AsmHeader: Record "Assembly Header";
        UOMMgt: Codeunit "Unit of Measure Management";
        HideConfirm: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Synchronizing...\  from: %1 with %2\  to: %3 with %4.', Comment = '%1 = Table caption of SalesLine or WhseShptLine or InvtPickLine, %2 = Key text of SalesLine or WhseShptLine or InvtPickLine, %3 = Table caption of Assembly header, %4 = Key text of assembly header';
        Text001: Label 'Do you want to roll up the price from the assembly components?';
        Text002: Label 'Do you want to roll up the cost from the assembly components?';
#pragma warning disable AA0470
        Text003: Label 'The item tracking defined on Assembly Header with Document Type %1, No. %2 exceeds %3 on Sales Line with Document Type %4, Document No. %5, Line No. %6.\\ You must adjust the existing item tracking before you can reenter the new quantity.', Comment = '%1 = Document Type, %2 = No.';
        Text004: Label '%1 cannot be lower than %2 or higher than %3.\These limits may be defined by constraints calculated from the %4 field on the related %5. Refer to the field help for more information.';
        Text005: Label 'One or more %1 lines exist for the %2.';
        Text006: Label 'The status of the linked assembly order will be changed to %1. Do you want to continue?';
        Text007: Label 'A %1 exists for the %2. \\If you want to record and post a different %3, then you must do this in the %4 field on the related %1.';
#pragma warning restore AA0470
        Text008: Label '%1 %2', Comment = 'Key Value, say: %1=Line No. %2=10000';
#pragma warning restore AA0074
        ItemTrackingQtyDiffErr: Label 'The item tracking defined on Assembly Header with Document Type %1, No. %2 exceeds %3 on Project Planning Line with Job No. %4, Job Task No. %5, Line No. %6.\\ You must adjust the existing item tracking before you can reenter the new quantity.', Comment = '%1 = Document Type, %2 = No., %3 = Qty. to Assemble (Base), %4 = Job No., %5 = Job Task No., %6 = Line No.';
        CreateAsmForJobErr: Label 'It is not possible to create an assembly order for a job task that is completed.';
        AssebmlyOrderExistsForJobErr: Label 'One or more assembly orders exists for the project %1.\\You must delete the assembly order before you can change the job status.', Comment = '%1 = Job No.';

    procedure UpdateAsmFromSalesLine(var NewSalesLine: Record "Sales Line")
    begin
        UpdateAsm(NewSalesLine, AsmExistsForSalesLine(NewSalesLine));
    end;

    procedure UpdateAsmFromSalesLineATOExist(var NewSalesLine: Record "Sales Line")
    begin
        UpdateAsm(NewSalesLine, true);
    end;

    local procedure UpdateAsm(var NewSalesLine: Record "Sales Line"; AsmExists: Boolean)
    var
        SalesLine2: Record "Sales Line";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        IsHandled: Boolean;
        ShouldDeleteAsm: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAsm(NewSalesLine, AsmExists, IsHandled);
        if not IsHandled then begin
            if AsmExists then begin
                if not NewSalesLine.IsAsmToOrderAllowed() then begin
                    DeleteAsmFromSalesLine(NewSalesLine);
                    exit;
                end;
                ShouldDeleteAsm := NewSalesLine."Qty. to Assemble to Order" = 0;
                OnUpdateAsmOnAfterCalcShouldDeleteAsm(NewSalesLine, ShouldDeleteAsm);
                if ShouldDeleteAsm then begin
                    DeleteAsmFromSalesLine(NewSalesLine);
                    if "Assembly Document Type" = "Assembly Document Type"::Order then begin
                        InvtAdjmtEntryOrder.SetLoadFields("Order Type", "Order No.");
                        InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Assembly);
                        InvtAdjmtEntryOrder.SetRange("Order No.", "Assembly Document No.");
                        if not InvtAdjmtEntryOrder.IsEmpty() then begin
                            PostedATOLink.SetRange("Assembly Order No.", "Assembly Document No.");
                            if PostedATOLink.IsEmpty() then
                                Insert();
                        end;
                    end;
                    exit;
                end;
                if not GetAsmHeader() then begin
                    Delete();
                    InsertAsmHeader(AsmHeader, "Assembly Document Type", "Assembly Document No.");
                end else begin
                    if not NeedsSynchronization(NewSalesLine) then
                        exit;
                    OnUpdateAsmOnBeforeAsmReOpenIfReleased(Rec, AsmHeader);
                    AsmReopenIfReleased();
                    Delete();
                end;
            end else begin
                if NewSalesLine."Qty. to Assemble to Order" = 0 then
                    exit;
                if not SalesLine2.Get(NewSalesLine."Document Type", NewSalesLine."Document No.", NewSalesLine."Line No.") then
                    exit;

                InsertAsmHeader(AsmHeader, NewSalesLine."Document Type", '');

                "Assembly Document Type" := AsmHeader."Document Type";
                "Assembly Document No." := AsmHeader."No.";
                Type := Type::Sale;
                "Document Type" := NewSalesLine."Document Type";
                "Document No." := NewSalesLine."Document No.";
                "Document Line No." := NewSalesLine."Line No.";
            end;

            OnUpdateAsmOnBeforeSynchronizeAsmFromSalesLine(Rec, AsmHeader, NewSalesLine);
            SynchronizeAsmFromSalesLine(NewSalesLine);

            Insert();
            AsmHeader."Shortcut Dimension 1 Code" := NewSalesLine."Shortcut Dimension 1 Code";
            AsmHeader."Shortcut Dimension 2 Code" := NewSalesLine."Shortcut Dimension 2 Code";
            AsmHeader.Modify(true);
        end;
        OnAfterUpdateAsm(AsmHeader, Rec, NewSalesLine, AsmExists);
    end;

    procedure UpdateAsmFromJobPlanningLine(var NewJobPlanningLine: Record "Job Planning Line")
    begin
        UpdateAsmFromJobPlanningLine(NewJobPlanningLine, AsmExistsForJobPlanningLine(NewJobPlanningLine));
    end;

    local procedure UpdateAsmFromJobPlanningLine(var NewJobPlanningLine: Record "Job Planning Line"; AsmExists: Boolean)
    var
        Job: Record Job;
    begin
        if AsmExists then begin
            if not NewJobPlanningLine.IsAsmToOrderAllowed() then begin
                DeleteAsmFromJobPlanningLine(NewJobPlanningLine);
                exit;
            end;
            if NewJobPlanningLine."Qty. to Assemble" = 0 then begin
                DeleteAsmFromJobPlanningLine(NewJobPlanningLine);
                NewJobPlanningLine."Assemble to Order" := false;
                InsertAssembeToOrderLinkIfInvtAdjmtEntryOrderExist();
                exit;
            end;
            if not DeleteAssembleToOrderLink(NewJobPlanningLine) then
                exit;
        end else begin
            if JobPlanningLineIsNotCorrect(NewJobPlanningLine) then
                exit;

            if not NewJobPlanningLine.IsAsmToOrderAllowed() then begin
                NewJobPlanningLine."Qty. to Assemble" := 0;
                NewJobPlanningLine."Qty. to Assemble (Base)" := 0;
                exit;
            end;

            Job.Get(NewJobPlanningLine."Job No.");
            CheckJobStatus(Job);
            AssignAssembleToOrderData(NewJobPlanningLine, Job);
            NewJobPlanningLine."Assemble to Order" := true;
        end;
        SynchronizeAsmFromJobPlanningLine(NewJobPlanningLine, "Document Type" = "Document Type"::Order);
        Insert();
        AssignGlobalDimensionsFromJobTask(NewJobPlanningLine);
    end;

    procedure UpdateAsmDimFromSalesLine(SalesLine: Record "Sales Line")
    begin
        UpdateAsmDimFromSalesLine(SalesLine, false);
    end;

    procedure UpdateAsmDimFromSalesLine(SalesLine: Record "Sales Line"; HideValidationDialog: Boolean)
    var
        Window: Dialog;
    begin
        if AsmExistsForSalesLine(SalesLine) then
            if GetAsmHeader() then begin
                AsmHeader.SetHideValidationDialog(HideValidationDialog);
                Window.Open(GetWindowOpenTextSale(SalesLine));
                if ChangeDim(SalesLine."Dimension Set ID") then begin
                    AsmHeader."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
                    AsmHeader."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
                    AsmHeader.Modify(true);
                end;
                Window.Close();
            end;
    end;

    procedure UpdateQtyToAsmFromSalesLine(SalesLine: Record "Sales Line")
    var
        Window: Dialog;
        ShowWindow: Boolean;
    begin
        if AsmExistsForSalesLine(SalesLine) then
            if GetAsmHeader() then begin
                ShowWindow := GuiAllowed();
                OnUpdateQtyToAsmFromSalesLineOnBeforeUpdateQtyToAsm(SalesLine, ShowWindow);
                if ShowWindow then
                    Window.Open(GetWindowOpenTextSale(SalesLine));
                UpdateQtyToAsm(MaxQtyToAsm(SalesLine, AsmHeader));
                if ShowWindow then
                    Window.Close();
            end;
    end;

    procedure UpdateQtyToAsmFromWhseShptLine(WhseShptLine: Record "Warehouse Shipment Line")
    var
        Window: Dialog;
        IsHandled: Boolean;
        ShowWindow: Boolean;
    begin
        IsHandled := false;
        ShowWindow := GuiAllowed();
        OnBeforeUpdateQtyToAsmFromWhseShptLine(WhseShptLine, IsHandled, ShowWindow);
        if IsHandled then
            exit;

        if AsmExistsForWhseShptLine(WhseShptLine) then
            if GetAsmHeader() then begin
                if ShowWindow then
                    Window.Open(GetWindowOpenTextWhseShpt(WhseShptLine));
                UpdateQtyToAsm(WhseShptLine."Qty. to Ship");
                if ShowWindow then
                    Window.Close();
            end;
    end;

    procedure UpdateQtyToAsmFromInvtPickLine(InvtPickWhseActivityLine: Record "Warehouse Activity Line")
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        Window: Dialog;
        TotalQtyToAsm: Decimal;
    begin
        WhseActivityLine.SetRange("Activity Type", InvtPickWhseActivityLine."Activity Type");
        WhseActivityLine.SetRange("Source Type", InvtPickWhseActivityLine."Source Type");
        WhseActivityLine.SetRange("Source Subtype", InvtPickWhseActivityLine."Source Subtype");
        WhseActivityLine.SetRange("Source No.", InvtPickWhseActivityLine."Source No.");
        WhseActivityLine.SetRange("Source Line No.", InvtPickWhseActivityLine."Source Line No.");
        WhseActivityLine.SetRange("Assemble to Order", true);
        if WhseActivityLine.FindSet() then
            repeat
                TotalQtyToAsm += WhseActivityLine."Qty. to Handle";
            until WhseActivityLine.Next() = 0;
        if AsmExistsForInvtPickLine(InvtPickWhseActivityLine) then
            if GetAsmHeader() then begin
                Window.Open(GetWindowOpenTextInvtPick(InvtPickWhseActivityLine));
                UpdateQtyToAsm(TotalQtyToAsm);
                Window.Close();
            end;
    end;

    local procedure UpdateQtyToAsm(NewQtyToAsm: Decimal)
    begin
        Delete();
        if ChangeQtyToAsm(NewQtyToAsm) then
            AsmHeader.Modify(true);
        Insert();
    end;

    procedure UpdateAsmBinCodeFromSalesLine(SalesLine: Record "Sales Line")
    var
        Window: Dialog;
    begin
        if AsmExistsForSalesLine(SalesLine) then
            if GetAsmHeader() then begin
                Window.Open(GetWindowOpenTextSale(SalesLine));
                UpdateAsmBinCode(SalesLine."Bin Code");
                Window.Close();
            end;
    end;

    procedure UpdateAsmBinCodeFromWhseShptLine(WhseShptLine: Record "Warehouse Shipment Line")
    var
        Window: Dialog;
    begin
        if AsmExistsForWhseShptLine(WhseShptLine) then
            if GetAsmHeader() then begin
                Window.Open(GetWindowOpenTextWhseShpt(WhseShptLine));
                UpdateAsmBinCode(WhseShptLine."Bin Code");
                Window.Close();
            end;
    end;

    procedure UpdateAsmBinCodeFromInvtPickLine(InvtPickWhseActivityLine: Record "Warehouse Activity Line")
    var
        Window: Dialog;
    begin
        if AsmExistsForInvtPickLine(InvtPickWhseActivityLine) then
            if GetAsmHeader() then begin
                Window.Open(GetWindowOpenTextInvtPick(InvtPickWhseActivityLine));
                UpdateAsmBinCode(InvtPickWhseActivityLine."Bin Code");
                Window.Close();
            end;
    end;


    internal procedure UpdateAsmBinCodeFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    var
        Window: Dialog;
    begin
        if AsmExistsForJobPlanningLine(JobPlanningLine) then
            if GetAsmHeader() and GuiAllowed() then begin
                Window.Open(GetWindowOpenTextJob(JobPlanningLine));
                UpdateAsmBinCode(JobPlanningLine."Bin Code");
                Window.Close();
            end;
    end;

    local procedure UpdateAsmBinCode(NewBinCode: Code[20])
    begin
        AsmHeader.SuspendStatusCheck(true);
        if ChangeBinCode(NewBinCode) then
            AsmHeader.Modify(true);
        AsmHeader.SuspendStatusCheck(false);
    end;

    procedure DeleteAsmFromSalesLine(SalesLine: Record "Sales Line")
    begin
        if AsmExistsForSalesLine(SalesLine) then begin
            Delete();
            if "Document Type" = "Document Type"::Order then
                UnreserveAsm();

            if GetAsmHeader() then begin
                AsmHeader.Delete(true);
                AsmHeader.Init();
            end;
        end;
    end;

    procedure DeleteAsmFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        if AsmExistsForJobPlanningLine(JobPlanningLine) then begin
            Delete();
            if "Document Type" = "Document Type"::Order then
                UnreserveAsm();

            if GetAsmHeader() then begin
                AsmHeader.Delete(true);
                AsmHeader.Init();
            end;
        end;
    end;

    procedure InsertAsmHeader(var AsmHeader: Record "Assembly Header"; NewDocType: Enum "Assembly Document Type"; NewDocNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertAsmHeader(AsmHeader, NewDocType.AsInteger(), NewDocNo, IsHandled);
        if IsHandled then
            exit;

        AsmHeader.Init();
        AsmHeader.Validate("Document Type", NewDocType);
        AsmHeader."No." := NewDocNo;
        OnBeforeAsmHeaderInsert(AsmHeader);
        AsmHeader.Insert(true);
    end;

    local procedure SynchronizeAsmFromSalesLine(var NewSalesLine: Record "Sales Line")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SalesHeader: Record "Sales Header";
        Window: Dialog;
        QtyTracked: Decimal;
        QtyTrackedBase: Decimal;
        ShowWindow: Boolean;
    begin
        GetAsmHeader();
        ShowWindow := GuiAllowed();
        OnSynchronizeAsmFromSalesLineOnAfterGetAsmHeader(NewSalesLine, AsmHeader, ShowWindow);

        if ShowWindow then
            Window.Open(GetWindowOpenTextSale(NewSalesLine));

        CaptureItemTracking(TempTrackingSpecification, QtyTracked, QtyTrackedBase);

        if NewSalesLine."Qty. to Asm. to Order (Base)" < QtyTrackedBase then
            Error(Text003,
              AsmHeader."Document Type",
              AsmHeader."No.",
              NewSalesLine.FieldCaption("Qty. to Assemble to Order"),
              NewSalesLine."Document Type",
              NewSalesLine."Document No.",
              NewSalesLine."Line No.");

        UnreserveAsm();

        SalesHeader.Get(NewSalesLine."Document Type", NewSalesLine."Document No.");
        AsmHeader.SetWarningsOff();
        ChangeItem(NewSalesLine."No.");
        ChangeLocation(NewSalesLine."Location Code");
        ChangeVariant(NewSalesLine."Variant Code");
        ChangeBinCode(NewSalesLine."Bin Code");
        ChangeUOM(NewSalesLine."Unit of Measure Code");
        ChangeDate(NewSalesLine."Shipment Date");
        ChangePostingDate(SalesHeader."Posting Date");
        ChangeDim(NewSalesLine."Dimension Set ID");
        ChangePlanningFlexibility();
        OnSynchronizeAsmFromSalesLineOnBeforeChangeQty(AsmHeader, NewSalesLine);
        ChangeQty(NewSalesLine."Qty. to Assemble to Order");
        if NewSalesLine."Document Type" <> NewSalesLine."Document Type"::Quote then
            ChangeQtyToAsm(MaxQtyToAsm(NewSalesLine, AsmHeader));

        OnBeforeAsmHeaderModify(AsmHeader, NewSalesLine);
        AsmHeader.Modify(true);

        ReserveAsmToSale(NewSalesLine,
          AsmHeader."Remaining Quantity" - QtyTracked,
          AsmHeader."Remaining Quantity (Base)" - QtyTrackedBase);
        RestoreItemTracking(TempTrackingSpecification, NewSalesLine);

        NewSalesLine.CheckAsmToOrder(AsmHeader);
        if ShowWindow then
            Window.Close();

        AsmHeader.SetWarningsOn();
        AsmHeader.ShowDueDateBeforeWorkDateMsg();
    end;

    local procedure SynchronizeAsmFromJobPlanningLine(var NewJobPlanningLine: Record "Job Planning Line"; ReserveLine: Boolean)
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        Window: Dialog;
        QtyTracked: Decimal;
        QtyTrackedBase: Decimal;
    begin
        GetAsmHeader();

        Window.Open(GetWindowOpenTextJob(NewJobPlanningLine));

        CaptureItemTracking(TempTrackingSpecification, QtyTracked, QtyTrackedBase);

        if NewJobPlanningLine."Qty. to Assemble (Base)" < QtyTrackedBase then
            Error(ItemTrackingQtyDiffErr,
              AsmHeader."Document Type",
              AsmHeader."No.",
              NewJobPlanningLine.FieldCaption("Qty. to Assemble"),
              NewJobPlanningLine."Job No.",
              NewJobPlanningLine."Job Task No.",
              NewJobPlanningLine."Line No.");

        UnreserveAsm();
        ChangeAsmHeaderFromJobPLanningLine(NewJobPlanningLine);

        if ReserveLine then
            ReserveAsmToJob(NewJobPlanningLine,
              AsmHeader."Remaining Quantity" - QtyTracked,
              AsmHeader."Remaining Quantity (Base)" - QtyTrackedBase);
        RestoreItemTracking(TempTrackingSpecification, NewJobPlanningLine);

        NewJobPlanningLine.CheckAsmToOrder(AsmHeader);
        Window.Close();

        AsmHeader.SetWarningsOn();
        AsmHeader.ShowDueDateBeforeWorkDateMsg();
    end;

    local procedure ChangeAsmHeaderFromJobPLanningLine(var NewJobPlanningLine: Record "Job Planning Line")
    begin
        AsmHeader.SetWarningsOff();
        ChangeItem(NewJobPlanningLine."No.");
        ChangeLocation(NewJobPlanningLine."Location Code");
        ChangeVariant(NewJobPlanningLine."Variant Code");
        ChangeBinCode(NewJobPlanningLine."Bin Code");
        ChangeUOM(NewJobPlanningLine."Unit of Measure Code");
        ChangePostingDate(NewJobPlanningLine."Planning Date");
        ChangePlanningFlexibility();
        ChangeQty(NewJobPlanningLine."Qty. to Assemble");
        AsmHeader.Modify(true);
    end;

    procedure MakeAsmOrderLinkedToSalesOrderLine(FromSalesLine: Record "Sales Line"; ToSalesOrderLine: Record "Sales Line")
    var
        ToAsmOrderHeader: Record "Assembly Header";
    begin
        if AsmExistsForSalesLine(FromSalesLine) then begin
            ToSalesOrderLine.TestField(Type, ToSalesOrderLine.Type::Item);
            ToSalesOrderLine.TestField("No.", FromSalesLine."No.");

            if GetAsmHeader() then begin
                ToAsmOrderHeader.Init();
                CopyAsmToNewAsmOrder(AsmHeader, ToAsmOrderHeader, true);

                Init();
                "Assembly Document Type" := ToAsmOrderHeader."Document Type";
                "Assembly Document No." := ToAsmOrderHeader."No.";
                Type := Type::Sale;
                "Document Type" := ToSalesOrderLine."Document Type";
                "Document No." := ToSalesOrderLine."Document No.";
                "Document Line No." := ToSalesOrderLine."Line No.";

                SynchronizeAsmFromSalesLine(ToSalesOrderLine);
                RecalcAutoReserve(ToAsmOrderHeader);
                Insert();
            end;
            OnMakeAsmOrderLinkedToSalesOrderLineOnBeforeCheckDocumentType(Rec, ToAsmOrderHeader, AsmHeader, ToSalesOrderLine, FromSalesLine);
            if FromSalesLine."Document Type" = FromSalesLine."Document Type"::Quote then
                DeleteAsmFromSalesLine(FromSalesLine);
        end;
    end;

    procedure CheckIfAssembleToOrderLinkExist(Job: Record Job)
    begin
        if Job.Status in [Job.Status::Completed, Job.Status::Open] then
            exit;
        SetRange(Type, Type::Job);
        SetRange("Job No.", Job."No.");
        SetRange("Document Type", "Document Type"::Order);
        if not IsEmpty() then
            Error(AssebmlyOrderExistsForJobErr, Job."No.");
    end;

    procedure MakeAsmOrderLinkedToJobPlanningOrderLine(var JobPlanningLine: Record "Job Planning Line")
    var
        ToAsmOrderHeader: Record "Assembly Header";
    begin
        if not JobPlanningLine."Assemble to Order" then
            exit;

        if JobPlanningLine.Status = JobPlanningLine.Status::Order then
            exit;

        if JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::Billable then
            exit;

        if not AsmExistsForJobPlanningLine(JobPlanningLine) then
            exit;

        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        if GetAsmHeader() then begin
            ToAsmOrderHeader.Init();
            CopyAsmToNewAsmOrder(AsmHeader, ToAsmOrderHeader, true);

            Init();
            "Assembly Document Type" := ToAsmOrderHeader."Document Type";
            "Assembly Document No." := ToAsmOrderHeader."No.";
            Type := Type::Job;
            "Document No." := JobPlanningLine."Document No.";
            "Document Type" := "Document Type"::Order;
            "Document Line No." := JobPlanningLine."Line No.";
            "Job No." := JobPlanningLine."Job No.";
            "Job Task No." := JobPlanningLine."Job Task No.";

            SynchronizeAsmFromJobPlanningLine(JobPlanningLine, true);
            RecalcAutoReserve(ToAsmOrderHeader);
            Insert();
        end;
        if JobPlanningLine.Status <> JobPlanningLine.Status::Order then
            DeleteAsmFromJobPlanningLine(JobPlanningLine);
    end;

    local procedure NeedsSynchronization(SalesLine: Record "Sales Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNeedsSynchronization(AsmHeader, SalesLine, Result, IsHandled);
        if IsHandled then
            exit(Result);
        GetAsmHeader();
        AsmHeader.CalcFields("Reserved Qty. (Base)");
        exit(
          (SalesLine."No." <> AsmHeader."Item No.") or
          (SalesLine."Location Code" <> AsmHeader."Location Code") or
          (SalesLine."Shipment Date" <> AsmHeader."Due Date") or
          (SalesLine."Variant Code" <> AsmHeader."Variant Code") or
          (SalesLine."Bin Code" <> AsmHeader."Bin Code") or
          (SalesLine."Dimension Set ID" <> AsmHeader."Dimension Set ID") or
          (SalesLine."Qty. to Asm. to Order (Base)" <> AsmHeader."Quantity (Base)") or
          (SalesLine."Unit of Measure Code" <> AsmHeader."Unit of Measure Code") or
          (AsmHeader."Planning Flexibility" <> AsmHeader."Planning Flexibility"::None) or
          ((SalesLine."Document Type" = SalesLine."Document Type"::Order) and
           (AsmHeader."Remaining Quantity (Base)" <> AsmHeader."Reserved Qty. (Base)")));
    end;

    local procedure NeedsSynchronization(JobPlanningLine: Record "Job Planning Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNeedsSynchronizationForProjectPlanningLine(AsmHeader, JobPlanningLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetAsmHeader();
        AsmHeader.CalcFields("Reserved Qty. (Base)");
        exit(
          (JobPlanningLine."No." <> AsmHeader."Item No.") or
          (JobPlanningLine."Location Code" <> AsmHeader."Location Code") or
          (JobPlanningLine."Variant Code" <> AsmHeader."Variant Code") or
          (JobPlanningLine."Bin Code" <> AsmHeader."Bin Code") or
          (JobPlanningLine."Qty. to Assemble (Base)" <> AsmHeader."Quantity (Base)") or
          (JobPlanningLine."Unit of Measure Code" <> AsmHeader."Unit of Measure Code") or
          (AsmHeader."Planning Flexibility" <> AsmHeader."Planning Flexibility"::None) or
          (AsmHeader."Remaining Quantity (Base)" <> AsmHeader."Reserved Qty. (Base)"));
    end;

    local procedure ChangeItem(NewItemNo: Code[20])
    begin
        if AsmHeader."Item No." = NewItemNo then
            exit;

        AsmHeader.Validate("Item No.", NewItemNo);
    end;

    local procedure ChangeQty(NewQty: Decimal)
    begin
        if AsmHeader.Quantity = NewQty then
            exit;

        AsmHeader.Validate(Quantity, NewQty);
    end;

    local procedure ChangeQtyToAsm(NewQtyToAsm: Decimal): Boolean
    begin
        if AsmHeader."Quantity to Assemble" = NewQtyToAsm then
            exit(false);

        AsmHeader.Validate("Quantity to Assemble", NewQtyToAsm);
        exit(true)
    end;

    local procedure ChangeLocation(NewLocation: Code[10])
    begin
        if AsmHeader."Location Code" = NewLocation then
            exit;

        AsmHeader.Validate("Location Code", NewLocation);
    end;

    local procedure ChangeVariant(NewVariant: Code[10])
    begin
        if AsmHeader."Variant Code" = NewVariant then
            exit;

        AsmHeader.Validate("Variant Code", NewVariant);
    end;

    local procedure ChangeUOM(NewUOMCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeUOM(AsmHeader, NewUOMCode, IsHandled);
        if IsHandled then
            exit;

        if AsmHeader."Unit of Measure Code" = NewUOMCode then
            exit;

        AsmHeader.Validate("Unit of Measure Code", NewUOMCode);
    end;

    local procedure ChangeDate(NewDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeDate(AsmHeader, NewDate, IsHandled);
        if IsHandled then
            exit;

        if AsmHeader."Due Date" = NewDate then
            exit;

        AsmHeader.Validate("Due Date", NewDate);
    end;

    local procedure ChangePostingDate(NewDate: Date)
    begin
        if AsmHeader."Posting Date" = NewDate then
            exit;

        AsmHeader.Validate("Posting Date", NewDate);
    end;

    local procedure ChangeDim(NewDimSetID: Integer): Boolean
    begin
        if AsmHeader."Dimension Set ID" = NewDimSetID then
            exit(false);

        AsmHeader.Validate("Dimension Set ID", NewDimSetID);
        exit(true)
    end;

    local procedure ChangeBinCode(NewBinCode: Code[20]): Boolean
    begin
        if AsmHeader."Bin Code" = NewBinCode then
            exit(false);

        AsmHeader.ValidateBinCode(NewBinCode);
        exit(true);
    end;

    local procedure ChangePlanningFlexibility()
    begin
        if AsmHeader."Planning Flexibility" = AsmHeader."Planning Flexibility"::None then
            exit;

        AsmHeader.Validate("Planning Flexibility", AsmHeader."Planning Flexibility"::None);
    end;

    procedure ReserveAsmToSale(var SalesLine: Record "Sales Line"; QtyToReserve: Decimal; QtyToReserveBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        AsmHeaderReserve: Codeunit "Assembly Header-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReserveAsmToSale(SalesLine, QtyToReserve, QtyToReserveBase, IsHandled, Rec);
        if IsHandled then
            exit;

        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit;

        if Type = Type::Sale then begin
            GetAsmHeader();

            AsmHeaderReserve.SetBinding(ReservEntry.Binding::"Order-to-Order");
            AsmHeaderReserve.SetDisallowCancellation(true);
            TrackingSpecification.InitTrackingSpecification(
                DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", '', 0, SalesLine."Line No.",
                AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader."Qty. per Unit of Measure");
            AsmHeaderReserve.CreateReservationSetFrom(TrackingSpecification);
            AsmHeaderReserve.CreateReservation(AsmHeader, AsmHeader.Description, AsmHeader."Due Date", QtyToReserve, QtyToReserveBase);

            if SalesLine.Reserve = SalesLine.Reserve::Never then
                SalesLine.Reserve := SalesLine.Reserve::Optional;

            OnAfterReserveAsmToSale(Rec, AsmHeader, SalesLine, TrackingSpecification, QtyToReserve, QtyToReserveBase);
        end;
    end;

    procedure ReserveAsmToJob(var JobPlanningLine: Record "Job Planning Line"; QtyToReserve: Decimal; QtyToReserveBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        AsmHeaderReserve: Codeunit "Assembly Header-Reserve";
    begin
        if Type <> Type::Job then
            exit;

        GetAsmHeader();
        AsmHeaderReserve.SetBinding(ReservEntry.Binding::"Order-to-Order");
        AsmHeaderReserve.SetDisallowCancellation(true);
        TrackingSpecification.InitTrackingSpecification(
            Database::"Job Planning Line", 2, JobPlanningLine."Job No.", '', 0, JobPlanningLine."Job Contract Entry No.",
            AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader."Qty. per Unit of Measure");
        AsmHeaderReserve.CreateReservationSetFrom(TrackingSpecification);
        AsmHeaderReserve.CreateReservation(AsmHeader, AsmHeader.Description, AsmHeader."Due Date", QtyToReserve, QtyToReserveBase);

        if JobPlanningLine.Reserve = JobPlanningLine.Reserve::Never then
            JobPlanningLine.Reserve := JobPlanningLine.Reserve::Optional;
    end;

    local procedure UnreserveAsm()
    var
        ReservEntry: Record "Reservation Entry";
        AsmHeaderReserve: Codeunit "Assembly Header-Reserve";
    begin
        GetAsmHeader();

        AsmHeader.SetReservationFilters(ReservEntry);
        AsmHeaderReserve.DeleteLine(AsmHeader);
    end;

    local procedure CaptureItemTracking(var TrackingSpecification: Record "Tracking Specification"; var QtyTracked: Decimal; var QtyTrackedBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        Item: Record Item;
    begin
        GetAsmHeader();

        TrackingSpecification.Reset();
        TrackingSpecification.DeleteAll();

        AsmHeader.SetReservationFilters(ReservEntry);
        if ReservEntry.Find('-') then begin
            Item.Get(AsmHeader."Item No.");
            repeat
                if ReservEntry.TrackingExists() then begin
                    TrackingSpecification.TransferFields(ReservEntry);
                    TrackingSpecification.Insert();

                    QtyTracked += ReservEntry.Quantity;
                    QtyTrackedBase += ReservEntry."Quantity (Base)";

                    RemoveTrackingFromReservation(ReservEntry, Item."Item Tracking Code");
                end;
            until ReservEntry.Next() = 0;
        end;
    end;

    local procedure RemoveTrackingFromReservation(ReservEntry: Record "Reservation Entry"; ItemTrackingCode: Code[10])
    var
        ItemTrackingCodeRec: Record "Item Tracking Code";
        TrackingSpecification: Record "Tracking Specification";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        QtyToAdd: Decimal;
    begin
        OnBeforeRemoveTrackingFromReservation(ReservEntry, ItemTrackingCode);

        ReservEntry.SetPointerFilter();
        ReservEntry.SetTrackingFilterFromReservEntry(ReservEntry);
        TrackingSpecification.TransferFields(ReservEntry);
        TrackingSpecification.SetTrackingBlank();
        OnRemoveTrackingFromReservationOnAfterSetTracking(TrackingSpecification);

        ItemTrackingCodeRec.Get(ItemTrackingCode);
        ReservEngineMgt.AddItemTrackingToTempRecSet(
            ReservEntry, TrackingSpecification, TrackingSpecification."Quantity (Base)",
            QtyToAdd, ItemTrackingCodeRec);

        OnAfterRemoveTrackingFromReservation(ReservEntry, TrackingSpecification, ItemTrackingCodeRec);
    end;

    local procedure RestoreItemTracking(var TrackingSpecification: Record "Tracking Specification"; SalesLine: Record "Sales Line")
    var
        ReservEntry: Record "Reservation Entry";
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        GetAsmHeader();

        if TrackingSpecification.Find('-') then
            repeat
                OnRestoreItemTrackingOnBeforeTrackingSpecificationLoop(TrackingSpecification);
                CreateReservEntry.SetDates(TrackingSpecification."Warranty Date", TrackingSpecification."Expiration Date");
                CreateReservEntry.SetApplyFromEntryNo(TrackingSpecification."Appl.-from Item Entry");
                CreateReservEntry.SetDisallowCancellation(true);
                CreateReservEntry.SetBinding(ReservEntry.Binding::"Order-to-Order");
                CreateReservEntry.SetQtyToHandleAndInvoice(
                  TrackingSpecification."Qty. to Handle (Base)", TrackingSpecification."Qty. to Invoice (Base)");

                ReservEntry.CopyTrackingFromSpec(TrackingSpecification);
                CreateReservEntry.CreateReservEntryFor(
                  DATABASE::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."No.", '', 0, 0,
                  AsmHeader."Qty. per Unit of Measure", 0, TrackingSpecification."Quantity (Base)", ReservEntry);

                SalesLineReserve.InitFromSalesLine(FromTrackingSpecification, SalesLine);
                FromTrackingSpecification."Qty. per Unit of Measure" := AsmHeader."Qty. per Unit of Measure";
                FromTrackingSpecification.CopyTrackingFromTrackingSpec(TrackingSpecification);
                CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);

                OnRestoreItemTrackingOnAfterCreateReservEntryFrom(TrackingSpecification);

                CreateReservEntry.CreateEntry(
                    AsmHeader."Item No.", AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader.Description,
                    AsmHeader."Due Date", AsmHeader."Due Date", 0, "Reservation Status"::Reservation);
            until TrackingSpecification.Next() = 0;
        TrackingSpecification.DeleteAll();
    end;

    local procedure RestoreItemTracking(var TrackingSpecification: Record "Tracking Specification"; JobPlanningLine: Record "Job Planning Line")
    var
        ReservEntry: Record "Reservation Entry";
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
    begin
        if not TrackingSpecification.Find('-') then
            exit;

        GetAsmHeader();
        repeat
            CreateReservEntry.SetDates(TrackingSpecification."Warranty Date", TrackingSpecification."Expiration Date");
            CreateReservEntry.SetApplyFromEntryNo(TrackingSpecification."Appl.-from Item Entry");
            CreateReservEntry.SetDisallowCancellation(true);
            CreateReservEntry.SetBinding(ReservEntry.Binding::"Order-to-Order");
            CreateReservEntry.SetQtyToHandleAndInvoice(
              TrackingSpecification."Qty. to Handle (Base)", TrackingSpecification."Qty. to Invoice (Base)");

            ReservEntry.CopyTrackingFromSpec(TrackingSpecification);
            CreateReservEntry.CreateReservEntryFor(
              DATABASE::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."No.", '', 0, 0,
              AsmHeader."Qty. per Unit of Measure", 0, TrackingSpecification."Quantity (Base)", ReservEntry);

            JobPlanningLineReserve.InitFromJobPlanningLine(FromTrackingSpecification, JobPlanningLine);
            FromTrackingSpecification."Qty. per Unit of Measure" := AsmHeader."Qty. per Unit of Measure";
            FromTrackingSpecification.CopyTrackingFromTrackingSpec(TrackingSpecification);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
            CreateReservEntry.CreateEntry(
                AsmHeader."Item No.", AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader.Description,
                AsmHeader."Due Date", AsmHeader."Due Date", 0, "Reservation Status"::Reservation);
        until TrackingSpecification.Next() = 0;
        TrackingSpecification.DeleteAll();
    end;

    local procedure CopyAsmToNewAsmOrder(FromAsmHeader: Record "Assembly Header"; var ToAsmOrderHeader: Record "Assembly Header"; CopyComments: Boolean)
    var
        FromAsmLine: Record "Assembly Line";
        ToAsmOrderLine: Record "Assembly Line";
        FromAsmCommentLine: Record "Assembly Comment Line";
        ToAsmCommentLine: Record "Assembly Comment Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        ToAsmOrderHeader := FromAsmHeader;
        ToAsmOrderHeader."Document Type" := ToAsmOrderHeader."Document Type"::Order;
        ToAsmOrderHeader."No." := '';
        ToAsmOrderHeader.Status := ToAsmOrderHeader.Status::Open;
        ToAsmOrderHeader."Assembled Quantity" := 0;
        ToAsmOrderHeader."Assembled Quantity (Base)" := 0;
        ToAsmOrderHeader.Validate(Quantity, FromAsmHeader."Quantity to Assemble");
        ToAsmOrderHeader.Insert(true);
        RecordLinkManagement.CopyLinks(FromAsmHeader, ToAsmOrderHeader);

        FromAsmLine.SetRange("Document Type", FromAsmHeader."Document Type");
        FromAsmLine.SetRange("Document No.", FromAsmHeader."No.");
        if FromAsmLine.Find('-') then
            repeat
                ToAsmOrderLine := FromAsmLine;
                ToAsmOrderLine."Document Type" := ToAsmOrderLine."Document Type"::Order;
                ToAsmOrderLine."Document No." := ToAsmOrderHeader."No.";
                ToAsmOrderLine."Consumed Quantity" := 0;
                ToAsmOrderLine."Consumed Quantity (Base)" := 0;
                ToAsmOrderLine.Validate(Quantity, FromAsmLine."Quantity to Consume");
                ToAsmOrderLine.Insert(true);
                OnCopyAsmToNewAsmOrderOnToAsmOrderLineInsert(FromAsmLine, ToAsmOrderLine);
                AssemblyLineReserve.TransferAsmLineToAsmLine(FromAsmLine, ToAsmOrderLine, ToAsmOrderLine."Quantity (Base)");
                AssemblyLineReserve.SetDeleteItemTracking(true);
                AssemblyLineReserve.DeleteLine(FromAsmLine);
            until FromAsmLine.Next() = 0;

        if CopyComments then begin
            FromAsmCommentLine.SetRange("Document Type", FromAsmHeader."Document Type");
            FromAsmCommentLine.SetRange("Document No.", FromAsmHeader."No.");
            if FromAsmCommentLine.Find('-') then
                repeat
                    ToAsmCommentLine := FromAsmCommentLine;
                    ToAsmCommentLine."Document Type" := ToAsmCommentLine."Document Type"::"Assembly Order";
                    ToAsmCommentLine."Document No." := ToAsmOrderHeader."No.";
                    ToAsmCommentLine.Insert(true);
                until FromAsmCommentLine.Next() = 0;
        end;
    end;

    procedure RollUpPrice(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        AssemblyLine: Record "Assembly Line";
        CompSalesLine: Record "Sales Line";
        CompItem: Record Item;
        Resource: Record Resource;
        Currency: Record Currency;
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
        UnitPrice: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRollUpPrice(SalesLine, Rec, IsHandled);
        if IsHandled then
            exit;

        SalesLine.TestField(Quantity);
        SalesLine.TestField("Qty. to Asm. to Order (Base)");
        if not HideConfirm then
            if not Confirm(Text001) then
                exit;
        if not AsmExistsForSalesLine(SalesLine) then
            exit;
        if not GetAsmHeader() then
            exit;

        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            SalesHeader.TestField("Currency Factor");
            Currency.Get(SalesHeader."Currency Code");
            Currency.TestField("Unit-Amount Rounding Precision");
        end;

        AssemblyLine.SetRange("Document Type", AsmHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AsmHeader."No.");
        if AssemblyLine.Find('-') then
            repeat
                if AssemblyLine.Type in [AssemblyLine.Type::Item, AssemblyLine.Type::Resource] then begin
                    CompSalesLine := SalesLine;
                    CompSalesLine."Line No." := 0;
                    CompSalesLine.Quantity := 0;
                    CompSalesLine."Quantity (Base)" := 0;

                    CompSalesLine."No." := AssemblyLine."No.";
                    CompSalesLine."Variant Code" := AssemblyLine."Variant Code";
                    CompSalesLine."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";

                    case AssemblyLine.Type of
                        AssemblyLine.Type::Item:
                            begin
                                CompItem.Get(CompSalesLine."No.");
                                CompSalesLine.Type := CompSalesLine.Type::Item;
                                CompSalesLine."Gen. Prod. Posting Group" := CompItem."Gen. Prod. Posting Group";
                                CompSalesLine."Tax Group Code" := CompItem."Tax Group Code";
                                CompSalesLine.Validate("VAT Prod. Posting Group", CompItem."VAT Prod. Posting Group");
                            end;
                        AssemblyLine.Type::Resource:
                            begin
                                Resource.Get(CompSalesLine."No.");
                                CompSalesLine.Type := CompSalesLine.Type::Resource;
                                CompSalesLine."Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
                                CompSalesLine."Tax Group Code" := Resource."Tax Group Code";
                                CompSalesLine.Validate("VAT Prod. Posting Group", Resource."VAT Prod. Posting Group");
                            end;
                    end;

                    CompSalesLine.Quantity := AssemblyLine.Quantity;
                    CompSalesLine."Quantity (Base)" := AssemblyLine."Quantity (Base)";
                    CompSalesLine."Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
                    CompSalesLine."Unit Price" := 0;
                    CompSalesLine."Allow Line Disc." := false;

                    OnRollUpPriceOnBeforeFindSalesLinePrice(SalesHeader, CompSalesLine, AssemblyLine);

                    CompSalesLine.GetLineWithPrice(LineWithPrice);
                    LineWithPrice.SetLine(PriceType::Sale, SalesHeader, CompSalesLine);
                    PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
                    CompSalesLine.ApplyPrice(SalesLine.FieldNo("No."), PriceCalculation);

                    OnRollUpPriceOnAfterFindSalesLinePrice(SalesHeader, CompSalesLine);

                    UnitPrice += CompSalesLine."Unit Price" * AssemblyLine.Quantity;
                end;
            until AssemblyLine.Next() = 0;

        UnitPrice := Round(UnitPrice / AsmHeader.Quantity, Currency."Unit-Amount Rounding Precision");
        SalesLine.Validate("Unit Price", UnitPrice);
        OnRollUpPriceOnBeforeModifySalesline(SalesLine);
        SalesLine.Modify(true);
    end;

    procedure RollUpCost(var SalesLine: Record "Sales Line")
    var
        AsmLine: Record "Assembly Line";
        UnitCost: Decimal;
    begin
        SalesLine.TestField(Quantity);
        SalesLine.TestField("Qty. to Asm. to Order (Base)");
        if not HideConfirm then
            if not Confirm(Text002) then
                exit;
        if not AsmExistsForSalesLine(SalesLine) then
            exit;
        if not GetAsmHeader() then
            exit;

        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        if AsmLine.Find('-') then
            repeat
                UnitCost += AsmLine."Cost Amount";
            until AsmLine.Next() = 0;

        SalesLine.Validate("Unit Cost (LCY)", Round(UnitCost / AsmHeader.Quantity, 0.00001));
        OnRollUpCostOnBeforeModifySalesLine(SalesLine);
        SalesLine.Modify(true);
    end;

    procedure ShowAsm(SalesLine: Record "Sales Line")
    begin
        SalesLine.TestField("Qty. to Asm. to Order (Base)");
        if AsmExistsForSalesLine(SalesLine) then begin
            GetAsmHeader();
            case "Document Type" of
                "Document Type"::Quote:
                    PAGE.RunModal(PAGE::"Assembly Quote", AsmHeader);
                "Document Type"::"Blanket Order":
                    PAGE.RunModal(PAGE::"Blanket Assembly Order", AsmHeader);
                "Document Type"::Order:
                    PAGE.RunModal(PAGE::"Assembly Order", AsmHeader);
            end;
        end;
    end;

    local procedure ShowAsm(JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.TestField("Qty. to Assemble (Base)");
        if AsmExistsForJobPlanningLine(JobPlanningLine) then begin
            GetAsmHeader();
            case AsmHeader."Document Type" of
                AsmHeader."Document Type"::Quote:
                    Page.RunModal(Page::"Assembly Quote", AsmHeader);
                AsmHeader."Document Type"::Order:
                    Page.RunModal(Page::"Assembly Order", AsmHeader);
            end;
        end;
    end;

    procedure ShowAsmDocument()
    var
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        case Rec.Type of
            Rec.Type::Sale:
                begin
                    SalesLine.Get(Rec."Document Type", Rec."Document No.", Rec."Document Line No.");
                    ShowAsm(SalesLine);
                end;
            Rec.Type::Job:
                begin
                    JobPlanningLine.Get(Rec."Job No.", Rec."Job Task No.", Rec."Document Line No.");
                    ShowAsm(JobPlanningLine);
                end;
        end;
    end;

    procedure ShowAsmToOrderLines(SalesLine: Record "Sales Line")
    var
        AsmLine: Record "Assembly Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowAsmToOrderLines(SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.TestField("Qty. to Asm. to Order (Base)");
        if AsmExistsForSalesLine(SalesLine) then begin
            AsmLine.FilterGroup := 2;
            AsmLine.SetRange("Document Type", "Assembly Document Type");
            AsmLine.SetRange("Document No.", "Assembly Document No.");
            AsmLine.FilterGroup := 0;
            PAGE.RunModal(PAGE::"Assemble-to-Order Lines", AsmLine);
        end;
    end;

    procedure ShowAsmToJobPlanningLines(JobPlanningLine: Record "Job Planning Line")
    var
        AsmLine: Record "Assembly Line";
    begin
        JobPlanningLine.TestField("Qty. to Assemble (Base)");
        if AsmExistsForJobPlanningLine(JobPlanningLine) then begin
            AsmLine.FilterGroup := 2;
            AsmLine.SetRange("Document Type", "Assembly Document Type");
            AsmLine.SetRange("Document No.", "Assembly Document No.");
            AsmLine.FilterGroup := 0;
            PAGE.RunModal(PAGE::"Assemble-to-Order Lines", AsmLine);
        end;
    end;

    procedure ShowSales(AssemblyHeader: Record "Assembly Header")
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSales(AssemblyHeader, IsHandled);
        if IsHandled then
            exit;

        if GetATOLink(AssemblyHeader) then begin
            SalesHeader.Get(Rec."Document Type", Rec."Document No.");
            case "Document Type" of
                "Document Type"::Quote:
                    PAGE.RunModal(PAGE::"Sales Quote", SalesHeader);
                "Document Type"::"Blanket Order":
                    PAGE.RunModal(PAGE::"Blanket Sales Order", SalesHeader);
                "Document Type"::Order:
                    PAGE.RunModal(PAGE::"Sales Order", SalesHeader);
            end;
        end;
    end;

    procedure ShowJobPlanningLines()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", Rec."Job No.");
        JobPlanningLine.SetRange("Job Task No.", Rec."Job Task No.");
        JobPlanningLine.SetRange("Line No.", Rec."Document Line No.");
        Page.RunModal(Page::"Job Planning Lines", JobPlanningLine);
    end;

    procedure SalesLineCheckAvailShowWarning(SalesLine: Record "Sales Line"; var TempAsmHeader: Record "Assembly Header" temporary; var TempAsmLine: Record "Assembly Line" temporary): Boolean
    var
        AsmLine: Record "Assembly Line";
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineCheckAvailShowWarning(SalesLine, IsHandled);
        if IsHandled then
            exit(false);

        if SalesLine."Qty. to Assemble to Order" = 0 then
            exit(false);

        SalesSetup.Get();
        if not SalesSetup."Stockout Warning" then
            exit(false);

        TempAsmHeader.Init();
        TempAsmHeader."Document Type" := SalesLine."Document Type";
        if SalesLine.AsmToOrderExists(AsmHeader) then
            TempAsmHeader := AsmHeader;
        TransAvailSalesLineToAsmHeader(TempAsmHeader, SalesLine);
        TempAsmHeader.Insert();

        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        if SalesLine.AsmToOrderExists(AsmHeader) and not AsmLine.IsEmpty() then
            exit(TransAvailAsmLinesToAsmLines(AsmHeader, TempAsmHeader, TempAsmLine, false));
        exit(TransAvailBOMCompToAsmLines(TempAsmHeader, TempAsmLine));
    end;

    procedure ATOCopyCheckAvailShowWarning(FromAsmHeader: Record "Assembly Header"; SalesLine: Record "Sales Line"; var TempAsmHeader: Record "Assembly Header" temporary; var TempAsmLine: Record "Assembly Line" temporary; Recalculate: Boolean): Boolean
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if SalesLine."Qty. to Assemble to Order" = 0 then
            exit(false);

        SalesSetup.Get();
        if not SalesSetup."Stockout Warning" then
            exit(false);

        TempAsmHeader.Init();
        TempAsmHeader."Document Type" := SalesLine."Document Type";
        TransAvailSalesLineToAsmHeader(TempAsmHeader, SalesLine);
        TempAsmHeader.Insert();

        if not Recalculate then
            exit(TransAvailAsmLinesToAsmLines(FromAsmHeader, TempAsmHeader, TempAsmLine, true));
        exit(TransAvailBOMCompToAsmLines(TempAsmHeader, TempAsmLine));
    end;

    procedure PstdATOCopyCheckAvailShowWarn(FromPostedAsmHeader: Record "Posted Assembly Header"; SalesLine: Record "Sales Line"; var TempAsmHeader: Record "Assembly Header" temporary; var TempAsmLine: Record "Assembly Line" temporary; Recalculate: Boolean): Boolean
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if SalesLine."Qty. to Assemble to Order" = 0 then
            exit(false);

        SalesSetup.Get();
        if not SalesSetup."Stockout Warning" then
            exit(false);

        TempAsmHeader.Init();
        TempAsmHeader."Document Type" := SalesLine."Document Type";
        TransAvailSalesLineToAsmHeader(TempAsmHeader, SalesLine);
        TempAsmHeader.Insert();

        if not Recalculate then
            exit(TransAvailPstdAsmLnsToAsmLns(FromPostedAsmHeader, TempAsmHeader, TempAsmLine));
        exit(TransAvailBOMCompToAsmLines(TempAsmHeader, TempAsmLine));
    end;

    local procedure TransAvailSalesLineToAsmHeader(var NewAsmHeader: Record "Assembly Header"; SalesLine: Record "Sales Line")
    begin
        NewAsmHeader."Item No." := SalesLine."No.";
        NewAsmHeader."Variant Code" := SalesLine."Variant Code";
        NewAsmHeader."Location Code" := SalesLine."Location Code";
        NewAsmHeader."Bin Code" := SalesLine."Bin Code";
        NewAsmHeader."Due Date" := SalesLine."Shipment Date";
        NewAsmHeader.ValidateDates(NewAsmHeader.FieldNo("Due Date"), true);
        NewAsmHeader."Unit of Measure Code" := SalesLine."Unit of Measure Code";
        NewAsmHeader."Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        NewAsmHeader.Quantity := SalesLine."Qty. to Assemble to Order" - AsmHeader."Assembled Quantity";
        NewAsmHeader."Quantity (Base)" := SalesLine."Qty. to Asm. to Order (Base)" - AsmHeader."Assembled Quantity (Base)";

        OnTransAvailSalesLineToAsmHeaderOnBeforeNewAsmHeaderInitRemainingQty(NewAsmHeader, SalesLine, AsmHeader);
        NewAsmHeader.InitRemainingQty();
    end;

    local procedure TransAvailAsmLinesToAsmLines(FromAsmHeader: Record "Assembly Header"; var ToAsmHeader: Record "Assembly Header"; var ToAsmLine: Record "Assembly Line"; InitQtyConsumed: Boolean): Boolean
    var
        FromAsmLine: Record "Assembly Line";
        ShowAsmWarning: Boolean;
    begin
        FromAsmLine.SetRange("Document Type", FromAsmHeader."Document Type");
        FromAsmLine.SetRange("Document No.", FromAsmHeader."No.");
        FromAsmLine.SetRange(Type, FromAsmLine.Type::Item);
        if FromAsmLine.Find('-') then
            repeat
                ToAsmLine := FromAsmLine;
                if InitQtyConsumed then begin
                    ToAsmLine."Consumed Quantity" := 0;
                    ToAsmLine."Consumed Quantity (Base)" := 0;
                end;
                TransAvailAsmHeaderToAsmLine(ToAsmLine, ToAsmHeader);
                UpdateAsmLineQty(ToAsmLine, ToAsmHeader."Qty. per Unit of Measure" * ToAsmHeader."Remaining Quantity");

                if ToAsmLine.UpdateAvailWarning() then
                    ShowAsmWarning := true;
                ToAsmLine.Insert();
            until FromAsmLine.Next() = 0;

        exit(ShowAsmWarning);
    end;

    procedure TransAvailBOMCompToAsmLines(var ToAsmHeader: Record "Assembly Header"; var ToAsmLine: Record "Assembly Line"): Boolean
    var
        BOMComponent: Record "BOM Component";
        ShowAsmWarning: Boolean;
    begin
        BOMComponent.SetRange("Parent Item No.", ToAsmHeader."Item No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        if BOMComponent.Find('-') then
            repeat
                ToAsmLine.Init();
                ToAsmLine."Line No." += 10000;
                TransAvailAsmHeaderToAsmLine(ToAsmLine, ToAsmHeader);
                TransAvailBOMCompToAsmLine(ToAsmLine, BOMComponent);
                UpdateAsmLineQty(ToAsmLine, ToAsmHeader."Qty. per Unit of Measure" * ToAsmHeader."Remaining Quantity");

                if ToAsmLine.UpdateAvailWarning() then
                    ShowAsmWarning := true;
                ToAsmLine.Insert();
            until BOMComponent.Next() = 0;

        exit(ShowAsmWarning);
    end;

    local procedure TransAvailPstdAsmLnsToAsmLns(FromPostedAsmHeader: Record "Posted Assembly Header"; var ToAsmHeader: Record "Assembly Header"; var ToAsmLine: Record "Assembly Line"): Boolean
    var
        FromPostedAsmLine: Record "Posted Assembly Line";
        ShowAsmWarning: Boolean;
    begin
        FromPostedAsmLine.SetRange("Document No.", FromPostedAsmHeader."No.");
        FromPostedAsmLine.SetRange(Type, FromPostedAsmLine.Type::Item);
        if FromPostedAsmLine.Find('-') then
            repeat
                ToAsmLine.TransferFields(FromPostedAsmLine);
                TransAvailAsmHeaderToAsmLine(ToAsmLine, ToAsmHeader);
                UpdateAsmLineQty(ToAsmLine, ToAsmHeader."Qty. per Unit of Measure" * ToAsmHeader."Remaining Quantity");

                if ToAsmLine.UpdateAvailWarning() then
                    ShowAsmWarning := true;
                ToAsmLine.Insert();
            until FromPostedAsmLine.Next() = 0;

        exit(ShowAsmWarning);
    end;

    local procedure TransAvailAsmHeaderToAsmLine(var AsmLine: Record "Assembly Line"; var NewAsmHeader: Record "Assembly Header")
    begin
        AsmLine."Document Type" := NewAsmHeader."Document Type";
        AsmLine."Document No." := NewAsmHeader."No.";

        if NewAsmHeader."Location Code" <> AsmHeader."Location Code" then begin
            AsmLine."Location Code" := NewAsmHeader."Location Code";
            if AsmLine.Type = AsmLine.Type::Item then
                AsmLine."Bin Code" := AsmLine.FindBin();
        end;
        if NewAsmHeader."Due Date" <> AsmHeader."Due Date" then
            AsmLine."Due Date" := NewAsmHeader."Starting Date";
        OnAfterTransAvailAsmHeaderToAsmLine(AsmLine, NewAsmHeader);
    end;

    local procedure TransAvailBOMCompToAsmLine(var AsmLine: Record "Assembly Line"; BOMComponent: Record "BOM Component")
    var
        ItemUOM: Record "Item Unit of Measure";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransAvailBOMCompToAsmLine(AsmLine, BOMComponent, IsHandled);
        if not IsHandled then begin
            AsmLine.Type := AsmLine.Type::Item;
            AsmLine."No." := BOMComponent."No.";
            AsmLine."Variant Code" := BOMComponent."Variant Code";
            AsmLine."Quantity per" := BOMComponent."Quantity per";
            AsmLine."Unit of Measure Code" := BOMComponent."Unit of Measure Code";
            if not ItemUOM.Get(BOMComponent."No.", BOMComponent."Unit of Measure Code") then
                ItemUOM.Init();
            AsmLine."Qty. per Unit of Measure" := ItemUOM."Qty. per Unit of Measure";
        end;
        OnAfterTransAvailBOMCompToAsmLine(AsmLine, BOMComponent);
    end;

    local procedure UpdateAsmLineQty(var AsmLine: Record "Assembly Line"; QtyFactor: Decimal)
    begin
        AsmLine.Quantity := AsmLine."Quantity per" * QtyFactor;
        AsmHeader.RoundQty(AsmLine.Quantity);
        AsmLine."Quantity (Base)" := Round(AsmLine.Quantity * AsmLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        AsmLine.InitRemainingQty();
    end;

    procedure AsmExistsForSalesLine(SalesLine: Record "Sales Line"): Boolean
    begin
        Reset();
        SetCurrentKey(Type, "Document Type", "Document No.", "Document Line No.");
        SetRange(Type, Type::Sale);
        SetRange("Document Type", SalesLine."Document Type");
        SetRange("Document No.", SalesLine."Document No.");
        SetRange("Document Line No.", SalesLine."Line No.");
        exit(FindFirst());
    end;

    procedure AsmExistsForJobPlanningLine(JobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        Reset();
        SetCurrentKey(Type, "Job No.", "Job Task No.", "Document Line No.");
        SetRange(Type, Type::Job);
        SetRange("Job No.", JobPlanningLine."Job No.");
        SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        SetRange("Document Line No.", JobPlanningLine."Line No.");
        if JobPlanningLine.Status = JobPlanningLine.Status::Order then
            SetRange("Document Type", "Document Type"::Order)
        else
            SetRange("Document Type", "Document Type"::Quote);
        exit(FindFirst());
    end;

    procedure AsmExistsForWhseShptLine(WhseShptLine: Record "Warehouse Shipment Line"): Boolean
    var
        SalesLine: Record "Sales Line";
        AsmExists, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeAsmExistsForWhseShptLine(Rec, WhseShptLine, AsmExists, IsHandled);
        if IsHandled then
            exit(AsmExists);

        WhseShptLine.TestField("Assemble to Order", true);
        WhseShptLine.TestField("Source Type", DATABASE::"Sales Line");
        SalesLine.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.", WhseShptLine."Source Line No.");
        exit(AsmExistsForSalesLine(SalesLine));
    end;

    local procedure AsmExistsForInvtPickLine(InvtPickWhseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        InvtPickWhseActivityLine.TestField("Assemble to Order", true);
        InvtPickWhseActivityLine.TestField("Source Type", DATABASE::"Sales Line");
        InvtPickWhseActivityLine.TestField("Activity Type", InvtPickWhseActivityLine."Activity Type"::"Invt. Pick");
        SalesLine.Get(
          InvtPickWhseActivityLine."Source Subtype", InvtPickWhseActivityLine."Source No.", InvtPickWhseActivityLine."Source Line No.");
        exit(AsmExistsForSalesLine(SalesLine));
    end;

    procedure GetAsmHeader() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAsmHeader(Rec, AsmHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (AsmHeader."Document Type" = "Assembly Document Type") and
           (AsmHeader."No." = "Assembly Document No.")
        then
            exit(true);
        exit(AsmHeader.Get("Assembly Document Type", "Assembly Document No."));
    end;

    procedure GetATOLink(AssemblyHeader: Record "Assembly Header") LinkFound: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetATOLink(Rec, AssemblyHeader, LinkFound, IsHandled);
        if IsHandled then
            exit(LinkFound);
        LinkFound := Get(AssemblyHeader."Document Type", AssemblyHeader."No.") and (Type <> Type::Job);
        if LinkFound then
            TestField(Type, Type::Sale);
    end;

    local procedure GetMin(a: Decimal; b: Decimal): Decimal
    begin
        if a < b then
            exit(a);
        exit(b);
    end;

    local procedure GetMax(a: Decimal; b: Decimal): Decimal
    begin
        if a > b then
            exit(a);
        exit(b);
    end;

    local procedure MaxQtyToAsm(SalesLine: Record "Sales Line"; AssemblyHeader: Record "Assembly Header") Result: Decimal
    begin
        Result := GetMin(SalesLine."Qty. to Ship", AssemblyHeader."Remaining Quantity");
        OnAfterMaxQtyToAsm(SalesLine, AssemblyHeader, Result);
    end;

    local procedure MaxQtyToAsmBase(SalesLine: Record "Sales Line"; AssemblyHeader: Record "Assembly Header") Result: Decimal
    begin
        Result := GetMin(SalesLine."Qty. to Ship (Base)", AssemblyHeader."Remaining Quantity (Base)");
        OnAfterMaxQtyToAsmBase(SalesLine, AssemblyHeader, Result);
    end;

    local procedure MinQtyToAsm(SalesLine: Record "Sales Line"; AssemblyHeader: Record "Assembly Header"): Decimal
    var
        UnshippedNonATOQty: Decimal;
    begin
        UnshippedNonATOQty := SalesLine."Outstanding Quantity" - AssemblyHeader."Remaining Quantity";
        exit(GetMax(SalesLine."Qty. to Ship" - UnshippedNonATOQty, 0));
    end;

    procedure CheckQtyToAsm(AssemblyHeader: Record "Assembly Header")
    var
        SalesLine: Record "Sales Line";
        Location: Record Location;
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WMSMgt: Codeunit "WMS Management";
        MaxQty: Decimal;
        MinQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyToAsm(AssemblyHeader, IsHandled);
        if IsHandled then
            exit;

        if GetATOLink(AssemblyHeader) then begin
            SalesLine.Get("Document Type", "Document No.", "Document Line No.");

            if Location.Get(AssemblyHeader."Location Code") then
                if Location."Require Shipment" then begin
                    AssemblyHeader.CalcFields("Assemble to Order");
                    if WMSMgt.ATOWhseShptExists(SalesLine) then
                        Error(
                          Text007, WhseShptLine.TableCaption(), AssemblyHeader."Document Type", AssemblyHeader.FieldCaption("Quantity to Assemble"),
                          WhseShptLine.FieldCaption("Qty. to Ship"));
                end else
                    if Location."Require Pick" then
                        if WMSMgt.ATOInvtPickExists(SalesLine) then
                            Error(Text005, WhseActivityLine."Activity Type"::"Invt. Pick", AssemblyHeader."Document Type");

            MinQty := MinQtyToAsm(SalesLine, AssemblyHeader);
            MaxQty := MaxQtyToAsm(SalesLine, AssemblyHeader);
            if (AssemblyHeader."Quantity to Assemble" < MinQty) or (AssemblyHeader."Quantity to Assemble" > MaxQty) then
                Error(
                  Text004, AssemblyHeader.FieldCaption("Quantity to Assemble"), MinQty, MaxQty, SalesLine.FieldCaption("Qty. to Ship"),
                  SalesLine.TableCaption());
        end;
    end;

    procedure InitQtyToAsm(AssemblyHeader: Record "Assembly Header"; var QtyToAsm: Decimal; var QtyToAsmBase: Decimal)
    var
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToAsm(AssemblyHeader, QtyToAsm, QtyToAsmBase, IsHandled);
        if IsHandled then
            exit;

        if GetATOLink(AssemblyHeader) then begin
            SalesLine.Get("Document Type", "Document No.", "Document Line No.");
            QtyToAsm := MaxQtyToAsm(SalesLine, AssemblyHeader);
            QtyToAsmBase := MaxQtyToAsmBase(SalesLine, AssemblyHeader);
        end else begin
            if ("Job No." = '') or ("Job Task No." = '') then
                exit;
            JobPlanningLine.Get("Job No.", "Job Task No.", "Document Line No.");
            QtyToAsm := AssemblyHeader."Remaining Quantity";
            QtyToAsmBase := AssemblyHeader."Remaining Quantity (Base)";
        end;
    end;

    local procedure AsmReopenIfReleased()
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        ReleaseAssemblyDoc: Codeunit "Release Assembly Document";
    begin
        if AsmHeader.Status <> AsmHeader.Status::Released then
            exit;
        if not HideConfirm then
            if not Confirm(Text006, false, AsmHeader.Status::Open) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
        ReleaseAssemblyDoc.Reopen(AsmHeader);
    end;

    local procedure GetWindowOpenTextSale(SalesLine: Record "Sales Line"): Text
    begin
        exit(StrSubstNo(Text000,
            SalesLine.TableCaption(),
            ConstructKeyTextSalesLine(SalesLine),
            AsmHeader.TableCaption(),
            ConstructKeyTextAsmHeader()));
    end;

    local procedure GetWindowOpenTextJob(JobPlanningLine: Record "Job Planning Line"): Text
    begin
        exit(StrSubstNo(Text000,
            JobPlanningLine.TableCaption(),
            ConstructKeyTextJobPlanningLine(JobPlanningLine),
            AsmHeader.TableCaption(),
            ConstructKeyTextAsmHeader()));
    end;

    local procedure GetWindowOpenTextWhseShpt(WhseShptLine: Record "Warehouse Shipment Line"): Text
    begin
        exit(StrSubstNo(Text000,
            WhseShptLine.TableCaption(),
            ConstructKeyTextWhseShptLine(WhseShptLine),
            AsmHeader.TableCaption(),
            ConstructKeyTextAsmHeader()));
    end;

    local procedure GetWindowOpenTextInvtPick(InvtPickWhseActivityLine: Record "Warehouse Activity Line"): Text
    begin
        exit(StrSubstNo(Text000,
            InvtPickWhseActivityLine.TableCaption(),
            ConstructKeyTextInvtPickLine(InvtPickWhseActivityLine),
            AsmHeader.TableCaption(),
            ConstructKeyTextAsmHeader()));
    end;

    local procedure ConstructKeyTextAsmHeader(): Text
    var
        DocTypeText: Text;
        DocNoText: Text;
    begin
        DocTypeText := StrSubstNo(Text008, AsmHeader.FieldCaption("Document Type"), AsmHeader."Document Type");
        DocNoText := StrSubstNo(Text008, AsmHeader.FieldCaption("No."), AsmHeader."No.");
        exit(StrSubstNo(Text008, DocTypeText, DocNoText));
    end;

    local procedure ConstructKeyTextSalesLine(SalesLine: Record "Sales Line"): Text
    var
        DocTypeText: Text;
        DocNoText: Text;
        LineNoText: Text;
    begin
        DocTypeText := StrSubstNo(Text008, SalesLine.FieldCaption("Document Type"), SalesLine."Document Type");
        DocNoText := StrSubstNo(Text008, SalesLine.FieldCaption("Document No."), SalesLine."Document No.");
        LineNoText := StrSubstNo(Text008, SalesLine.FieldCaption("Line No."), SalesLine."Line No.");
        exit(StrSubstNo(Text008, StrSubstNo(Text008, DocTypeText, DocNoText), LineNoText));
    end;

    local procedure ConstructKeyTextJobPlanningLine(JobPlanningLine: Record "Job Planning Line"): Text
    var
        JobTaskNoText, JobNoText, LineNoText : Text;
    begin
        JobNoText := StrSubstNo(Text008, JobPlanningLine.FieldCaption("Job No."), JobPlanningLine."Job No.");
        JobTaskNoText := StrSubstNo(Text008, JobPlanningLine.FieldCaption("Job Task No."), JobPlanningLine."Job Task No.");
        LineNoText := StrSubstNo(Text008, JobPlanningLine.FieldCaption("Line No."), JobPlanningLine."Line No.");
        exit(StrSubstNo(Text008, StrSubstNo(Text008, JobNoText, JobTaskNoText), LineNoText));
    end;

    local procedure ConstructKeyTextWhseShptLine(WhseShptLine: Record "Warehouse Shipment Line"): Text
    var
        NoText: Text;
        LineNoText: Text;
    begin
        NoText := StrSubstNo(Text008, WhseShptLine.FieldCaption("No."), WhseShptLine."No.");
        LineNoText := StrSubstNo(Text008, WhseShptLine.FieldCaption("Line No."), WhseShptLine."Line No.");
        exit(StrSubstNo(Text008, NoText, LineNoText));
    end;

    local procedure ConstructKeyTextInvtPickLine(InvtPickWhseActivityLine: Record "Warehouse Activity Line"): Text
    var
        ActTypeText: Text;
        NoText: Text;
        LineNoText: Text;
    begin
        ActTypeText :=
          StrSubstNo(Text008, InvtPickWhseActivityLine.FieldCaption("Activity Type"), InvtPickWhseActivityLine."Activity Type");
        NoText := StrSubstNo(Text008, InvtPickWhseActivityLine.FieldCaption("No."), InvtPickWhseActivityLine."No.");
        LineNoText := StrSubstNo(Text008, InvtPickWhseActivityLine.FieldCaption("Line No."), InvtPickWhseActivityLine."Line No.");
        exit(StrSubstNo(Text008, StrSubstNo(Text008, ActTypeText, NoText), LineNoText));
    end;

    procedure ShowAsmOrders(SalesHeader: Record "Sales Header")
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyHeader: Record "Assembly Header" temporary;
    begin
        TempAssemblyHeader.DeleteAll();

        AssembleToOrderLink.SetCurrentKey(Type, "Document Type", "Document No.", "Document Line No.");
        AssembleToOrderLink.SetRange(Type, AssembleToOrderLink.Type::Sale);
        AssembleToOrderLink.SetRange("Document Type", SalesHeader."Document Type");
        AssembleToOrderLink.SetRange("Document No.", SalesHeader."No.");
        if AssembleToOrderLink.FindSet() then
            repeat
                if not TempAssemblyHeader.Get(AssembleToOrderLink."Assembly Document Type", AssembleToOrderLink."Assembly Document No.") then
                    if AssemblyHeader.Get(AssembleToOrderLink."Assembly Document Type", AssembleToOrderLink."Assembly Document No.") then begin
                        TempAssemblyHeader := AssemblyHeader;
                        TempAssemblyHeader.Insert();
                    end;
            until AssembleToOrderLink.Next() = 0;

        PAGE.Run(PAGE::"Assembly Orders", TempAssemblyHeader);
    end;

    procedure ShowAsmOrders(Job: Record Job; JobTaskNo: Code[20])
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyHeader: Record "Assembly Header" temporary;
    begin
        TempAssemblyHeader.DeleteAll();

        AssembleToOrderLink.SetCurrentKey(Type, "Job No.", "Job Task No.", "Document Line No.");
        AssembleToOrderLink.SetRange(Type, AssembleToOrderLink.Type::Job);
        AssembleToOrderLink.SetRange("Job No.", Job."No.");
        if JobTaskNo <> '' then
            AssembleToOrderLink.SetRange("Job Task No.", JobTaskNo);
        if AssembleToOrderLink.FindSet() then
            repeat
                if not TempAssemblyHeader.Get(AssembleToOrderLink."Assembly Document Type", AssembleToOrderLink."Assembly Document No.") then
                    if AssemblyHeader.Get(AssembleToOrderLink."Assembly Document Type", AssembleToOrderLink."Assembly Document No.") then begin
                        TempAssemblyHeader := AssemblyHeader;
                        TempAssemblyHeader.Insert();
                    end;
            until AssembleToOrderLink.Next() = 0;

        PAGE.Run(PAGE::"Assembly Orders", TempAssemblyHeader);
    end;

    local procedure RecalcAutoReserve(AsmHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", AsmHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AsmHeader."No.");
        if AssemblyLine.FindSet() then
            repeat
                AsmHeader.AutoReserveAsmLine(AssemblyLine);
            until AssemblyLine.Next() = 0;
    end;

    procedure SetHideConfirm(NewHideConfirm: Boolean)
    begin
        HideConfirm := NewHideConfirm;
    end;

    local procedure JobPlanningLineIsNotCorrect(var NewJobPlanningLine: Record "Job Planning Line"): Boolean
    var
        NewJobPlanningLine2: Record "Job Planning Line";
    begin
        if NewJobPlanningLine."Qty. to Assemble" = 0 then
            exit(true);
        if not NewJobPlanningLine2.Get(NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Task No.", NewJobPlanningLine."Line No.") then
            exit(true);
    end;

    local procedure CheckJobStatus(Job: Record Job)
    begin
        if Job.Status = Job.Status::Completed then
            Error(CreateAsmForJobErr);
    end;

    local procedure AssignAssembleToOrderData(var NewJobPlanningLine: Record "Job Planning Line"; Job: Record Job)
    begin
        if Job.Status = Job.Status::Open then begin
            InsertAsmHeader(AsmHeader, "Assembly Document Type"::Order, '');
            "Document Type" := "Document Type"::Order;
        end else
            if Job.Status in [Job.Status::Quote, Job.Status::Planning] then begin
                InsertAsmHeader(AsmHeader, "Assembly Document Type"::Quote, '');
                "Document Type" := "Document Type"::Quote;
            end;
        "Assembly Document Type" := AsmHeader."Document Type";
        "Assembly Document No." := AsmHeader."No.";
        Type := Type::Job;
        "Document No." := NewJobPlanningLine."Document No.";
        "Job No." := NewJobPlanningLine."Job No.";
        "Job Task No." := NewJobPlanningLine."Job Task No.";
        "Document Line No." := NewJobPlanningLine."Line No.";
    end;

    local procedure AssignGlobalDimensionsFromJobTask(var NewJobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
    begin
        if not JobTask.Get(NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Task No.") then
            exit;
        AsmHeader."Shortcut Dimension 1 Code" := JobTask."Global Dimension 1 Code";
        AsmHeader."Shortcut Dimension 2 Code" := JobTask."Global Dimension 2 Code";
        AsmHeader.Modify(true);
    end;

    local procedure DeleteAssembleToOrderLink(var NewJobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        if not GetAsmHeader() then begin
            Delete();
            InsertAsmHeader(AsmHeader, "Assembly Document Type", "Assembly Document No.");
        end else begin
            if not NeedsSynchronization(NewJobPlanningLine) then
                exit(false);
            AsmReopenIfReleased();
            Delete();
        end;
        exit(true);
    end;

    local procedure InsertAssembeToOrderLinkIfInvtAdjmtEntryOrderExist()
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Assembly);
        InvtAdjmtEntryOrder.SetRange("Order No.", "Assembly Document No.");
        if ("Assembly Document Type" = "Assembly Document Type"::Order) and not InvtAdjmtEntryOrder.IsEmpty() then
            Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAsm(var AsmHeader: Record "Assembly Header"; var AssembleToOrderLink: Record "Assemble-to-Order Link"; var SalesLine: Record "Sales Line"; AsmExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMaxQtyToAsm(SalesLine: Record "Sales Line"; AssemblyHeader: Record "Assembly Header"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMaxQtyToAsmBase(SalesLine: Record "Sales Line"; AssemblyHeader: Record "Assembly Header"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRemoveTrackingFromReservation(var ReservationEntry: Record "Reservation Entry"; var TrackingSpecification: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransAvailAsmHeaderToAsmLine(var AssemblyLine: Record "Assembly Line"; var NewAssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAsmHeaderInsert(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAsmHeaderModify(var AssemblyHeader: Record "Assembly Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeUOM(var AssemblyHeader: Record "Assembly Header"; NewUOMCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeDate(var AssemblyHeader: Record "Assembly Header"; NewDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetATOLink(var AssembleToOrderLink: Record "Assemble-to-Order Link"; var AssemblyHeader: Record "Assembly Header"; var LinkFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAsmHeader(var AssemblyHeader: Record "Assembly Header"; NewDocType: Option; NewDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeNeedsSynchronization(AssemblyHeader: Record "Assembly Header"; SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeNeedsSynchronizationForProjectPlanningLine(AssemblyHeader: Record "Assembly Header"; JobPlanningLine: Record "Job Planning Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemoveTrackingFromReservation(var ReservEntry: Record "Reservation Entry"; ItemTrackingCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReserveAsmToSale(var SalesLine: Record "Sales Line"; QtyToReserve: Decimal; QtyToReserveBase: Decimal; var IsHandled: Boolean; var AssembletoOrderLink: Record "Assemble-to-Order Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineCheckAvailShowWarning(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAsmToOrderLines(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransAvailBOMCompToAsmLine(var AssemblyLine: Record "Assembly Line"; BOMComponent: Record "BOM Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAsm(var NewSalesLine: Record "Sales Line"; AsmExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyAsmToNewAsmOrderOnToAsmOrderLineInsert(FromAssemblyLine: Record "Assembly Line"; var ToAssemblyLineOrder: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeAsmOrderLinkedToSalesOrderLineOnBeforeCheckDocumentType(var AssembleToOrderLink: Record "Assemble-to-Order Link"; var ToAssemblyHeader: Record "Assembly Header"; FromAssemblyHeader: Record "Assembly Header"; ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveTrackingFromReservationOnAfterSetTracking(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreItemTrackingOnAfterCreateReservEntryFrom(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreItemTrackingOnBeforeTrackingSpecificationLoop(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRollUpPriceOnAfterFindSalesLinePrice(var SalesHeader: Record "Sales Header"; var CompSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRollUpPriceOnBeforeFindSalesLinePrice(var SalesHeader: Record "Sales Header"; var CompSalesLine: Record "Sales Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRollUpPriceOnBeforeModifySalesline(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeAsmFromSalesLineOnAfterGetAsmHeader(var NewSalesLine: Record "Sales Line"; var AssemblyHeader: Record "Assembly Header"; var ShowWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeAsmFromSalesLineOnBeforeChangeQty(var AssemblyHeader: Record "Assembly Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAsmOnBeforeSynchronizeAsmFromSalesLine(var AssembleToOrderLink: Record "Assemble-to-Order Link"; var AssemblyHeader: Record "Assembly Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAsmOnAfterCalcShouldDeleteAsm(var NewSalesLine: Record "Sales Line"; var ShouldDeleteAsm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAsmOnBeforeAsmReOpenIfReleased(var AssembleToOrderLink: Record "Assemble-to-Order Link"; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransAvailBOMCompToAsmLine(var AsmLine: Record "Assembly Line"; BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransAvailSalesLineToAsmHeaderOnBeforeNewAsmHeaderInitRemainingQty(var NewAsmHeader: Record "Assembly Header"; SalesLine: Record "Sales Line"; AsmHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReserveAsmToSale(var AssembletoOrderLink: Record "Assemble-to-Order Link"; var AsmHeader: Record "Assembly Header"; var SalesLine: Record "Sales Line"; var TrackingSpecification: Record "Tracking Specification"; QtyToReserve: Decimal; QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRollUpPrice(var SalesLine: Record "Sales Line"; var AssembleToOrderLink: Record "Assemble-to-Order Link"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToAsmFromWhseShptLine(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean; var ShowWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAsmExistsForWhseShptLine(var AssembleToOrderLink: Record "Assemble-to-Order Link"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var AsmExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSales(AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToAsm(AssemblyHeader: Record "Assembly Header"; var QtyToAsm: Decimal; var QtyToAsmBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyToAsm(AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRollUpCostOnBeforeModifySalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAsmHeader(AssembleToOrderLink: Record "Assemble-to-Order Link"; var AssemblyHeader: Record "Assembly Header"; var HeaderFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyToAsmFromSalesLineOnBeforeUpdateQtyToAsm(var SalesLine: Record "Sales Line"; var ShowWindow: Boolean)
    begin
    end;
}
