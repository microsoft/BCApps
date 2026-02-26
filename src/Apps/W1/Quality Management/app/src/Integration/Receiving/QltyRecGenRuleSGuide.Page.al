// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Receiving;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Journal;

page 20461 "Qlty. Rec. Gen. Rule S. Guide"
{
    Caption = 'Receipt Quality Inspection Rule Setup Guide';
    PageType = NavigatePage;
    UsageCategory = None;
    ApplicationArea = QualityManagement;
    SourceTable = "Qlty. Management Setup";

    layout
    {
        area(Content)
        {
            group(StepWhichTemplate)
            {
                Caption = ' ';
                ShowCaption = false;
                Visible = (StepWhichTemplateCounter = CurrentStepCounter);

                group(StepWhichTemplate_Instruction1)
                {
                    InstructionalText = 'Define a rule for item tracking related inspections when products are received.';
                    Caption = ' ';
                    ShowCaption = false;
                }
                group(StepWhichTemplate_Instruction2)
                {
                    InstructionalText = 'Which Quality Inspection template do you want to use?';
                    Caption = ' ';
                    ShowCaption = false;
                }
                field(ChoosechooseTemplate; TemplateCode)
                {
                    ApplicationArea = All;
                    Caption = 'Choose template';
                    ToolTip = 'Specifies which Quality Inspection template do you want to use?';
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditQltyInspectionTemplate(TemplateCode);
                    end;
                }
                group(whatType)
                {
                    Caption = ' ';
                    ShowCaption = false;
                    InstructionalText = 'What type of receiving rule are you making?';
                    field(ChooseForPurchase; IsPurchaseLine)
                    {
                        ApplicationArea = All;
                        Caption = 'Purchase Line';
                        ToolTip = 'Specifies to create a rule for a purchase order. Check this box if you want this rule apply to receiving a purchase order.';

                        trigger OnValidate()
                        begin
                            if not IsPurchaseLine then
                                IsPurchaseLine := true;
                            IsReturnReceipt := not IsPurchaseLine;
                            IsWarehouseReceipt := not IsPurchaseLine;
                            IsTransferLine := not IsPurchaseLine;
                        end;
                    }
                    field(ChooseForSalesReturn; IsReturnReceipt)
                    {
                        ApplicationArea = All;
                        Caption = 'Return Receipt';
                        ToolTip = 'Specifies to create a rule for a return receipt. Check this box to if you want this rule to apply to a return receipt.';

                        trigger OnValidate()
                        begin
                            if not IsReturnReceipt then
                                IsReturnReceipt := true;
                            IsPurchaseLine := not IsReturnReceipt;
                            IsWarehouseReceipt := not IsReturnReceipt;
                            IsTransferLine := not IsReturnReceipt;
                        end;
                    }
                    field(ChooseForWarehouseReceipt; IsWarehouseReceipt)
                    {
                        ApplicationArea = All;
                        Caption = 'Warehouse Receipt';
                        ToolTip = 'Specifies to create a rule for a warehouse journal line. Check this box if you want this rule apply to receiving via a warehouse receipt.';

                        trigger OnValidate()
                        begin
                            if not IsWarehouseReceipt then
                                IsWarehouseReceipt := true;
                            IsPurchaseLine := not IsWarehouseReceipt;
                            IsReturnReceipt := not IsWarehouseReceipt;
                            IsTransferLine := not IsWarehouseReceipt;
                        end;
                    }
                    field(ChooseForTransfer; IsTransferLine)
                    {
                        ApplicationArea = All;
                        Caption = 'Transfer Line';
                        ToolTip = 'Specifies to create a rule for a transfer. Check this box if you want this rule apply to receiving a transfer.';

                        trigger OnValidate()
                        begin
                            if not IsTransferLine then
                                IsTransferLine := true;
                            IsPurchaseLine := not IsTransferLine;
                            IsWarehouseReceipt := not IsTransferLine;
                            IsReturnReceipt := not IsTransferLine;
                        end;
                    }
                }
            }
            group(StepWhichPurchaseLine)
            {
                Caption = ' ';
                ShowCaption = false;
                InstructionalText = 'An inspection should be created for receiving lines when these filters match. You can choose other fields on the last step.';
                Visible = (StepWhichLineCounter = CurrentStepCounter);

                group(LocationWrapper)
                {
                    ShowCaption = false;
                    Visible = IsPurchaseLine or IsReturnReceipt or IsWarehouseReceipt;

                    field(ChoosechooseLocationCode; LocationCodeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Location';
                        ToolTip = 'Specifies the location';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditLocation(LocationCodeFilter);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(LocationFilerErr, GetLastErrorText());
                        end;
                    }
                }
                group(PurchaseFieldsWrapper)
                {
                    ShowCaption = false;
                    Visible = IsPurchaseLine;

                    field(ChooseVendorNoFilter; VendorNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Vendor No.';
                        ToolTip = 'Specifies which Vendor?';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditVendor(VendorNoFilter);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(VendorFilterErr, GetLastErrorText());
                        end;
                    }
                    field(ChoosePurchasingCode; PurchasingCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Purchasing Code';
                        ToolTip = 'Specifies a purchasing code filter.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditPurchasingCode(PurchasingCode);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(PurchasingCodeErr, GetLastErrorText());
                        end;
                    }
                }
                group(CustomerFieldsWrapper)
                {
                    ShowCaption = false;
                    Visible = IsReturnReceipt;
                    field(ChooseCustomerNoFilter; CustomerNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Customer No.';
                        ToolTip = 'Specifies which Customer?';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditCustomer(CustomerNoFilter);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(CustomerFilterErr, GetLastErrorText());
                        end;
                    }
                    field(ChooseReturnReasonCode; ReturnReasonCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Return Reason Code';
                        ToolTip = 'Specifies a return reason filter.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditReturnReasonCode(ReturnReasonCode);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(ReturnReasonFilterErr, GetLastErrorText());
                        end;
                    }
                }
                group(TransferFieldsWrapper)
                {
                    ShowCaption = false;
                    Visible = IsTransferLine;

                    field(ChooseTransferFromCode; TransferFromCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Transfer From Location';
                        ToolTip = 'Specifies a transfer-from location filter.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditLocation(TransferFromCode);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(TransferFromFilterErr, GetLastErrorText());
                        end;
                    }
                    field(ChooseTransferToCode; TransferToCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Transfer To Location';
                        ToolTip = 'Specifies a transfer-to location filter.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditLocation(TransferToCode);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(TransferToFilterErr, GetLastErrorText());
                        end;
                    }
                }
                group(WarehouseReceiptFieldsWrapper)
                {
                    ShowCaption = false;
                    Visible = IsWarehouseReceipt;

                    field(ChoosechooseToZone; ToZoneCodeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'To Zone';
                        ToolTip = 'Specifies a Zone filter.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditZone(LocationCodeFilter, ToZoneCodeFilter);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(ToZoneFilterErr, GetLastErrorText());
                        end;
                    }
                    field(ChoosechooseToBin; ToBinCodeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Bin';
                        ToolTip = 'Specifies a Bin filter.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditBin(LocationCodeFilter, ToZoneCodeFilter, ToBinCodeFilter);
                        end;

                        trigger OnValidate()
                        begin
                            ClearLastError();
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(ToBinFilterErr, GetLastErrorText());
                        end;
                    }
                }
                field(ChooseAdvanced; 'Click here to choose advanced fields...')
                {
                    ApplicationArea = All;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        UpdateFullTextRuleStringsFromFilters();
                        if IsPurchaseLine then
                            AssistEditFullPurchaseLineFilter();

                        if IsReturnReceipt then
                            AssistEditFullSalesReturnLineFilter();

                        UpdateTableVariablesFromRecordFilters();
                    end;
                }
            }
            group(StepWhichItem)
            {
                Caption = ' ';
                ShowCaption = false;
                InstructionalText = 'Does it matter which items? You can optionally limit this to only items that match this criteria.';
                Visible = (StepWhichItemFilterCounter = CurrentStepCounter);

                field(ChooseItemNoFilter; ItemNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Specific Item';
                    ToolTip = 'Specifies a specific Item';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditItemNo(ItemNoFilter);
                    end;

                    trigger OnValidate()
                    begin
                        ClearLastError();
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(ItemFilterErr, GetLastErrorText());
                    end;
                }
                field(ChooseCategoryCodeFilter; CategoryCodeFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Category';
                    ToolTip = 'Specifies a specific category';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditItemCategory(CategoryCodeFilter);
                    end;

                    trigger OnValidate()
                    begin
                        ClearLastError();
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(ItemCategoryFilterErr, GetLastErrorText());
                    end;
                }
                field(ChooseInventoryPostingGroupCode; InventoryPostingGroupCode)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Posting Group';
                    ToolTip = 'Specifies a specific Inventory Posting Group';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditInventoryPostingGroup(InventoryPostingGroupCode);
                    end;

                    trigger OnValidate()
                    begin
                        ClearLastError();
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(InventoryPostingGroupErr, GetLastErrorText());
                    end;
                }
                field(ChooseAdvanced_Item; 'Click here to choose advanced fields...')
                {
                    ApplicationArea = All;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        UpdateFullTextRuleStringsFromFilters();
                        AssistEditFullItemFilter();
                        UpdateTableVariablesFromRecordFilters();
                    end;
                }
            }
            group(StepDone)
            {
                Caption = ' ';
                InstructionalText = '';
                ShowCaption = false;
                Visible = (StepDoneCounter = CurrentStepCounter);

                group(StepDone_Instruction1)
                {
                    Caption = ' ';
                    InstructionalText = 'We have an Inspection Generation Rule ready. Click ''Finish'' to save this to the system.';
                    ShowCaption = false;
                }
                group(StepDone_Instruction2)
                {
                    Caption = ' ';
                    InstructionalText = 'Please review and set any additional filters you may need, for example if you want to limit this to specific items.';
                    ShowCaption = false;
                }
                group(WrapPurchaseLineRule)
                {
                    ShowCaption = false;
                    Visible = IsPurchaseLine;

                    field(ChoosePurchaseLineRuleFilter; PurchaseLineRule)
                    {
                        ApplicationArea = All;
                        Caption = 'Filters';
                        ToolTip = 'Specifies a complete filter. Please review and set any additional filters you may need.';
                        MultiLine = true;

                        trigger OnAssistEdit()
                        begin
                            AssistEditFullPurchaseLineFilter();
                        end;
                    }
                }
                group(WrapTransferLineRule)
                {
                    ShowCaption = false;
                    Visible = IsTransferLine;

                    field(ChooseTransferLineRuleFilter; TransferLineRule)
                    {
                        ApplicationArea = All;
                        Caption = 'Filters';
                        ToolTip = 'Specifies a complete filter. Please review and set any additional filters you may need.';
                        MultiLine = true;

                        trigger OnAssistEdit()
                        begin
                            AssistEditFullTransferLineFilter();
                        end;
                    }
                }
                group(WrapWarehouseJournalLineRule)
                {
                    ShowCaption = false;
                    Visible = IsWarehouseReceipt;

                    field(ChooseWarehouseJournalLineRuleFilter; WarehouseJournalLineRule)
                    {
                        ApplicationArea = All;
                        Caption = 'Filters';
                        ToolTip = 'Specifies a complete filter. Please review and set any additional filters you may need.';
                        MultiLine = true;

                        trigger OnAssistEdit()
                        begin
                            AssistEditFullWarehouseJournalLineFilter();
                        end;
                    }
                }
                group(WrapSalesLineRule)
                {
                    ShowCaption = false;
                    Visible = IsReturnReceipt;

                    field(ChooseSalesReturnLineRuleFilter; SalesReturnLineRule)
                    {
                        ApplicationArea = All;
                        Caption = 'Filters';
                        ToolTip = 'Specifies a complete filter. Please review and set any additional filters you may need.';
                        MultiLine = true;

                        trigger OnAssistEdit()
                        begin
                            AssistEditFullSalesReturnLineFilter();
                        end;
                    }
                }
                field(ChooseFilters_Item; ItemRule)
                {
                    ApplicationArea = All;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies a complete filter. Please review and set any additional filters you may need.';
                    MultiLine = true;

                    trigger OnAssistEdit()
                    begin
                        AssistEditFullItemFilter();
                    end;
                }
                group(bAutomaticallyCreateInspection)
                {
                    ShowCaption = false;
                    InstructionalText = 'Do you want to automatically create inspections when these are received?  This will set the activation trigger for this rule and set the default trigger value for new inspection generation rules of this record type.';

                    group(WrapAutoPurchaseLine)
                    {
                        ShowCaption = false;
                        Visible = IsPurchaseLine;

                        field(ChooseeAutomaticallyCreateInspectionPurchase; QltyPurchaseTrigger)
                        {
                            ApplicationArea = All;
                            Caption = 'Automatically Create Inspection';
                            ToolTip = 'Specifies whether to automatically create an inspection when product is received via a purchase order.';
                        }
                    }
                    group(WrapAutoTransferLine)
                    {
                        ShowCaption = false;
                        Visible = IsTransferLine;

                        field(ChooseeAutomaticallyCreateInspectionTransfer; QltyTransferTrigger)
                        {
                            ApplicationArea = All;
                            Caption = 'Automatically Create Inspection';
                            ToolTip = 'Specifies whether to automatically create an inspection when product is received via a transfer order.';
                        }
                    }
                    group(WrapAutoWarehouseReceipt)
                    {
                        ShowCaption = false;
                        Visible = IsWarehouseReceipt;

                        field(ChooseeAutomaticallyCreateInspectionWarehouseReceipt; QltyWhseReceiveTrigger)
                        {
                            ApplicationArea = All;
                            Caption = 'Automatically Create Inspection';
                            ToolTip = 'Specifies whether to automatically create an inspection when product is received via a warehouse receipt.';
                        }
                    }
                    group(WrapAutoSalesReturn)
                    {
                        ShowCaption = false;
                        Visible = IsReturnReceipt;

                        field(ChooseeAutomaticallyCreateInspectionSalesReturn; QltySalesReturnTrigger)
                        {
                            ApplicationArea = All;
                            Caption = 'Automatically Create Inspection';
                            ToolTip = 'Specifies whether to automatically create an inspection when product is received via a sales return.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Back)
            {
                Caption = 'Back';
                ToolTip = 'Back';
                Enabled = IsIsBackEnabledd;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    BackAction();
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                ToolTip = 'Next';
                Enabled = IsIsNextEnabledd;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    NextAction();
                end;
            }
            action(Finish)
            {
                Caption = 'Finish';
                ToolTip = 'Finish';
                Enabled = IsIsFinishEnabledd;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempReturnSalesLine: Record "Sales Line" temporary;
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        TempTransferLine: Record "Transfer Line" temporary;
        TempItem: Record "Item" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        CurrentStepCounter: Integer;
        LocationCodeFilter: Code[20];
        TemplateCode: Code[20];
        VendorNoFilter: Code[20];
        CustomerNoFilter: Code[20];
        PurchasingCode: Code[20];
        ReturnReasonCode: Code[20];
        ItemNoFilter: Code[20];
        CategoryCodeFilter: Code[20];
        InventoryPostingGroupCode: Code[20];
        TransferFromCode: Code[20];
        TransferToCode: Code[20];
        ToZoneCodeFilter: Code[20];
        ToBinCodeFilter: Code[20];
        QltyPurchaseTrigger: Enum "Qlty. Purchase Order Trigger";
        QltyTransferTrigger: Enum "Qlty. Transfer Order Trigger";
        QltyWhseReceiveTrigger: Enum "Qlty. Whse. Receipt Trigger";
        QltySalesReturnTrigger: Enum "Qlty. Sales Return Trigger";
        PurchaseLineRule: Text[2048];
        SalesReturnLineRule: Text[2048];
        ItemRule: Text[2048];
        TransferLineRule: Text[2048];
        WarehouseJournalLineRule: Text[2048];
        IsReturnReceipt: Boolean;
        IsPurchaseLine: Boolean;
        IsIsBackEnabledd: Boolean;
        IsIsNextEnabledd: Boolean;
        IsIsFinishEnabledd: Boolean;
        IsMovingForward: Boolean;
        IsWarehouseReceipt: Boolean;
        IsTransferLine: Boolean;
        StepWhichTemplateCounter: Integer;
        StepWhichLineCounter: Integer;
        StepWhichItemFilterCounter: Integer;
        StepDoneCounter: Integer;
        MaxStep: Integer;
        LocationFilerErr: Label 'This Location filter needs an adjustment. Location codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        VendorFilterErr: Label 'This Vendor No. filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        PurchasingCodeErr: Label 'This Purchasing Code filter needs an adjustment. Purchasing codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        CustomerFilterErr: Label 'This Customer No. filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ReturnReasonFilterErr: Label 'This Return Reason code filter needs an adjustment. Return Reason codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        TransferFromFilterErr: Label 'This Transfer From Location filter needs an adjustment. Location codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        TransferToFilterErr: Label 'This Transfer To Location filter needs an adjustment. Location codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        ToZoneFilterErr: Label 'This To Zone filter needs an adjustment. Zone codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        ToBinFilterErr: Label 'This To Bin filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ItemFilterErr: Label 'This Item filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ItemCategoryFilterErr: Label 'This Item Category filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        InventoryPostingGroupErr: Label 'This Inventory Posting Group filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        AlreadyThereQst: Label 'You already have at least one rule with these same conditions. Are you sure you want to proceed?';
        YouMustChooseATemplateFirstMsg: Label 'Please choose a template before proceeding.';
        FilterLengthErr: Label 'This filter is too long and must be less than %1 characters.', Comment = '%1=filter string maximum length';

    trigger OnInit();
    begin
        QltyManagementSetup.Get();
        StepWhichTemplateCounter := 1;
        StepWhichLineCounter := 2;
        StepWhichItemFilterCounter := 3;
        StepDoneCounter := 4;

        InitializeDefaultValues();

        IsPurchaseLine := true;

        QltyPurchaseTrigger := QltyManagementSetup."Purchase Order Trigger";
        QltyTransferTrigger := QltyManagementSetup."Transfer Order Trigger";
        QltySalesReturnTrigger := QltyManagementSetup."Sales Return Trigger";
        QltyWhseReceiveTrigger := QltyManagementSetup."Warehouse Receipt Trigger";
        MaxStep := StepDoneCounter;
    end;

    trigger OnOpenPage();
    begin
        ChangeToStep(StepWhichTemplateCounter);
        Commit();
    end;

    /// <summary>
    /// Intended to help initialize default values.
    /// </summary>
    local procedure InitializeDefaultValues()
    begin
        InitializeDefaultTemplate();
    end;

    local procedure InitializeDefaultTemplate()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        if TemplateCode <> '' then
            exit;

        QltyInspectionTemplateHdr.SetCurrentKey(SystemModifiedAt);
        QltyInspectionTemplateHdr.Ascending(false);
        if QltyInspectionTemplateHdr.FindFirst() then
            TemplateCode := QltyInspectionTemplateHdr.Code;
    end;

    local procedure ChangeToStep(Step: Integer);
    begin
        if Step < 1 then
            Step := 1;

        if Step > MaxStep then
            Step := MaxStep;

        IsMovingForward := Step > CurrentStepCounter;

        if IsMovingForward then
            LeavingStepMovingForward(CurrentStepCounter, Step);

        case Step of
            StepWhichTemplateCounter:
                begin
                    IsIsBackEnabledd := false;
                    IsIsNextEnabledd := true;
                    IsIsFinishEnabledd := false;
                end;
            StepWhichLineCounter:
                begin
                    IsIsBackEnabledd := true;
                    IsIsNextEnabledd := true;
                    IsIsFinishEnabledd := false;
                end;
            StepWhichItemFilterCounter:
                begin
                    IsIsBackEnabledd := true;
                    IsIsNextEnabledd := true;
                    IsIsFinishEnabledd := false;
                end;
            StepDoneCounter:
                begin
                    IsIsBackEnabledd := true;
                    IsIsNextEnabledd := false;
                    IsIsFinishEnabledd := true;
                    UpdateFullTextRuleStringsFromFilters();
                end;
        end;

        CurrentStepCounter := Step;

        CurrPage.Update(true);
    end;

    local procedure LeavingStepMovingForward(LeavingThisStep: Integer; var MovingToThisStep: Integer);
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        if LeavingThisStep = StepWhichTemplateCounter then
            if MovingToThisStep = StepWhichLineCounter then
                if not QltyInspectionTemplateHdr.Get(TemplateCode) then begin
                    Message(YouMustChooseATemplateFirstMsg);
                    MovingToThisStep := StepWhichTemplateCounter;
                end;
    end;

    local procedure AssistEditFullPurchaseLineFilter()
    begin
        TempQltyInspectionGenRule."Source Table No." := Database::"Purchase Line";
        TempQltyInspectionGenRule."Condition Filter" := PurchaseLineRule;

        if TempQltyInspectionGenRule.AssistEditConditionTableFilter() then begin
            PurchaseLineRule := TempQltyInspectionGenRule."Condition Filter";

            TempPurchaseLine.SetView(PurchaseLineRule);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure AssistEditFullSalesReturnLineFilter()
    begin
        TempQltyInspectionGenRule."Source Table No." := Database::"Sales Line";
        TempQltyInspectionGenRule."Condition Filter" := SalesReturnLineRule;

        if TempQltyInspectionGenRule.AssistEditConditionTableFilter() then begin
            SalesReturnLineRule := TempQltyInspectionGenRule."Condition Filter";

            TempReturnSalesLine.SetView(SalesReturnLineRule);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure AssistEditFullTransferLineFilter()
    begin
        TempQltyInspectionGenRule."Source Table No." := Database::"Transfer Line";
        TempQltyInspectionGenRule."Condition Filter" := TransferLineRule;

        if TempQltyInspectionGenRule.AssistEditConditionTableFilter() then begin
            TransferLineRule := TempQltyInspectionGenRule."Condition Filter";

            TempTransferLine.SetView(TransferLineRule);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure AssistEditFullWarehouseJournalLineFilter()
    begin
        TempQltyInspectionGenRule."Source Table No." := Database::"Warehouse Journal Line";
        TempQltyInspectionGenRule."Condition Filter" := WarehouseJournalLineRule;

        if TempQltyInspectionGenRule.AssistEditConditionTableFilter() then begin
            WarehouseJournalLineRule := TempQltyInspectionGenRule."Condition Filter";

            TempWarehouseJournalLine.SetView(WarehouseJournalLineRule);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure AssistEditFullItemFilter()
    begin
        TempQltyInspectionGenRule."Item Filter" := ItemRule;
        if TempQltyInspectionGenRule.AssistEditConditionItemFilter() then begin
            ItemRule := TempQltyInspectionGenRule."Item Filter";

            TempItem.SetView(ItemRule);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure CleanUpWhereClause()
    begin
        if IsPurchaseLine then
            PurchaseLineRule := QltyFilterHelpers.CleanUpWhereClause2048(PurchaseLineRule);

        if IsReturnReceipt then
            SalesReturnLineRule := QltyFilterHelpers.CleanUpWhereClause2048(SalesReturnLineRule);

        if IsTransferLine then
            TransferLineRule := QltyFilterHelpers.CleanUpWhereClause2048(TransferLineRule);

        if IsWarehouseReceipt then
            WarehouseJournalLineRule := QltyFilterHelpers.CleanUpWhereClause2048(WarehouseJournalLineRule);

        ItemRule := QltyFilterHelpers.CleanUpWhereClause2048(ItemRule);
    end;

    local procedure BackAction();
    begin
        CurrPage.Update(true);
        ChangeToStep(CurrentStepCounter - 1);
    end;

    local procedure NextAction();
    begin
        CurrPage.Update(true);
        ChangeToStep(CurrentStepCounter + 1);
    end;

    local procedure FinishAction();
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ExistingQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        if not QltyInspectionGenRule.Get(TempQltyInspectionGenRule.RecordId()) then begin
            QltyInspectionGenRule.Init();
            QltyInspectionGenRule.SetEntryNo();
            QltyInspectionGenRule.UpdateSortOrder();
            QltyInspectionGenRule."Source Table No." := 0;
            QltyInspectionGenRule.Insert(true);
        end;
        QltyInspectionGenRule.Validate("Template Code", TemplateCode);

        QltyManagementSetup.Get();

        case true of
            IsPurchaseLine:
                begin
                    QltyInspectionGenRule."Source Table No." := Database::"Purchase Line";
                    QltyInspectionGenRule.Intent := QltyInspectionGenRule.Intent::Purchase;
                    QltyInspectionGenRule."Condition Filter" := PurchaseLineRule;
                    QltyInspectionGenRule.SetIntentAndDefaultTriggerValuesFromSetup();
                    QltyInspectionGenRule."Purchase Order Trigger" := QltyPurchaseTrigger;
                    QltyManagementSetup."Purchase Order Trigger" := QltyPurchaseTrigger;
                end;
            IsReturnReceipt:
                begin
                    QltyInspectionGenRule."Source Table No." := Database::"Sales Line";
                    QltyInspectionGenRule.Intent := QltyInspectionGenRule.Intent::"Sales Return";
                    QltyInspectionGenRule."Condition Filter" := SalesReturnLineRule;
                    QltyInspectionGenRule.SetIntentAndDefaultTriggerValuesFromSetup();
                    QltyInspectionGenRule."Sales Return Trigger" := QltySalesReturnTrigger;
                    QltyManagementSetup."Sales Return Trigger" := QltySalesReturnTrigger;
                end;
            IsTransferLine:
                begin
                    QltyInspectionGenRule."Source Table No." := Database::"Transfer Line";
                    QltyInspectionGenRule.Intent := QltyInspectionGenRule.Intent::Transfer;
                    QltyInspectionGenRule."Condition Filter" := TransferLineRule;
                    QltyInspectionGenRule.SetIntentAndDefaultTriggerValuesFromSetup();
                    QltyInspectionGenRule."Transfer Order Trigger" := QltyTransferTrigger;
                    QltyManagementSetup."Transfer Order Trigger" := QltyTransferTrigger;
                end;
            IsWarehouseReceipt:
                begin
                    QltyInspectionGenRule."Source Table No." := Database::"Warehouse Journal Line";
                    QltyInspectionGenRule.Intent := QltyInspectionGenRule.Intent::"Warehouse Receipt";
                    QltyInspectionGenRule."Condition Filter" := WarehouseJournalLineRule;
                    QltyInspectionGenRule.SetIntentAndDefaultTriggerValuesFromSetup();
                    QltyInspectionGenRule."Warehouse Receipt Trigger" := QltyWhseReceiveTrigger;
                    QltyManagementSetup."Warehouse Receipt Trigger" := QltyWhseReceiveTrigger;
                end;
        end;

        QltyManagementSetup.Modify(false);
        QltyInspectionGenRule."Item Filter" := ItemRule;
        QltyInspectionGenRule.Modify();

        ExistingQltyInspectionGenRule.SetRange("Template Code", QltyInspectionGenRule."Template Code");
        ExistingQltyInspectionGenRule.SetRange("Source Table No.", QltyInspectionGenRule."Source Table No.");
        ExistingQltyInspectionGenRule.SetRange("Condition Filter", QltyInspectionGenRule."Condition Filter");
        ExistingQltyInspectionGenRule.SetRange("Item Filter", QltyInspectionGenRule."Item Filter");
        if ExistingQltyInspectionGenRule.Count() > 1 then
            if not Confirm(AlreadyThereQst) then
                Error('');

        CurrPage.Close();
    end;

    /// <summary>
    /// Start the setup guide using this generation rule as a pre-requisite.
    /// Use this to edit an existing rule.
    /// You can also use it to start a new rule with a default template by supplying a template filter.
    /// </summary>
    /// <param name="QltyInspectionGenRule"></param>
    /// <returns></returns>
    internal procedure RunModalWithGenerationRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Action
    begin
        TempQltyInspectionGenRule := QltyInspectionGenRule;
        Clear(TempPurchaseLine);
        Clear(TempItem);

        if QltyInspectionGenRule."Source Table No." = Database::"Purchase Line" then begin
            TempPurchaseLine.SetView(TempQltyInspectionGenRule."Condition Filter");
            IsPurchaseLine := true;
            IsReturnReceipt := false;
            IsTransferLine := false;
            IsWarehouseReceipt := false;
        end;
        if QltyInspectionGenRule."Source Table No." = Database::"Sales Line" then begin
            TempReturnSalesLine.SetView(TempQltyInspectionGenRule."Condition Filter");
            IsPurchaseLine := false;
            IsReturnReceipt := true;
            IsTransferLine := false;
            IsWarehouseReceipt := false;
        end;
        if QltyInspectionGenRule."Source Table No." = Database::"Transfer Line" then begin
            TempTransferLine.SetView(TempQltyInspectionGenRule."Condition Filter");
            IsTransferLine := true;
            IsPurchaseLine := false;
            IsReturnReceipt := false;
            IsWarehouseReceipt := false;
        end;
        if QltyInspectionGenRule."Source Table No." = Database::"Warehouse Journal Line" then begin
            TempWarehouseJournalLine.SetView(TempQltyInspectionGenRule."Condition Filter");
            IsWarehouseReceipt := true;
            IsPurchaseLine := false;
            IsReturnReceipt := false;
            IsTransferLine := false;
        end;
        TempItem.SetView(TempQltyInspectionGenRule."Item Filter");
        UpdateTableVariablesFromRecordFilters();

        TemplateCode := QltyInspectionGenRule.GetTemplateCodeFromRecordOrFilter(false);
        UpdateFullTextRuleStringsFromFilters();

        exit(CurrPage.RunModal());
    end;

    [TryFunction]
    local procedure UpdateFullTextRuleStringsFromFilters()
    begin
        if IsPurchaseLine then begin
            TempPurchaseLine.SetFilter("Location Code", LocationCodeFilter);
            TempPurchaseLine.SetFilter("Buy-from Vendor No.", VendorNoFilter);
            TempPurchaseLine.SetFilter("Purchasing Code", PurchasingCode);
            PurchaseLineRule := CopyStr(QltyFilterHelpers.CleanUpWhereClause2048(TempPurchaseLine.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));
        end;

        if IsReturnReceipt then begin
            TempReturnSalesLine.SetFilter("Location Code", LocationCodeFilter);
            TempReturnSalesLine.SetFilter("Return Reason Code", ReturnReasonCode);
            TempReturnSalesLine.SetFilter("Sell-to Customer No.", CustomerNoFilter);
            SalesReturnLineRule := CopyStr(QltyFilterHelpers.CleanUpWhereClause2048(TempReturnSalesLine.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));
        end;

        if IsTransferLine then begin
            TempTransferLine.SetFilter("Transfer-to Code", TransferToCode);
            TempTransferLine.SetFilter("Transfer-from Code", TransferFromCode);
            TransferLineRule := CopyStr(QltyFilterHelpers.CleanUpWhereClause2048(TempTransferLine.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));
        end;

        if IsWarehouseReceipt then begin
            TempWarehouseJournalLine.SetRange("Whse. Document Type", TempWarehouseJournalLine."Whse. Document Type"::Receipt);
            TempWarehouseJournalLine.SetFilter("Location Code", LocationCodeFilter);
            TempWarehouseJournalLine.SetFilter("To Zone Code", ToZoneCodeFilter);
            TempWarehouseJournalLine.SetFilter("To Bin Code", ToBinCodeFilter);
            WarehouseJournalLineRule := CopyStr(QltyFilterHelpers.CleanUpWhereClause2048(TempWarehouseJournalLine.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));
        end;

        TempItem.SetFilter("No.", ItemNoFilter);
        TempItem.SetFilter("Item Category Code", CategoryCodeFilter);
        TempItem.SetFilter("Inventory Posting Group", InventoryPostingGroupCode);

        ItemRule := CopyStr(QltyFilterHelpers.CleanUpWhereClause2048(TempItem.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Item Filter"));

        CleanUpWhereClause();

        if StrLen(QltyFilterHelpers.CleanUpWhereClause2048(TempReturnSalesLine.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Condition Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));

        if StrLen(QltyFilterHelpers.CleanUpWhereClause2048(TempTransferLine.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Condition Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));

        if StrLen(QltyFilterHelpers.CleanUpWhereClause2048(TempWarehouseJournalLine.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Condition Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));

        if StrLen(QltyFilterHelpers.CleanUpWhereClause2048(TempItem.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Item Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Item Filter"));
    end;

    local procedure UpdateTableVariablesFromRecordFilters()
    begin
        if IsPurchaseLine then begin
            LocationCodeFilter := CopyStr(TempPurchaseLine.GetFilter("Location Code"), 1, MaxStrLen(LocationCodeFilter));
            VendorNoFilter := CopyStr(TempPurchaseLine.GetFilter("Buy-from Vendor No."), 1, MaxStrLen(VendorNoFilter));
            PurchasingCode := CopyStr(TempPurchaseLine.GetFilter("Purchasing Code"), 1, MaxStrLen(PurchasingCode));
        end;

        if IsReturnReceipt then begin
            LocationCodeFilter := CopyStr(TempReturnSalesLine.GetFilter("Location Code"), 1, MaxStrLen(LocationCodeFilter));
            ReturnReasonCode := CopyStr(TempReturnSalesLine.GetFilter("Return Reason Code"), 1, MaxStrLen(ReturnReasonCode));
            CustomerNoFilter := CopyStr(TempReturnSalesLine.GetFilter("Sell-to Customer No."), 1, MaxStrLen(CustomerNoFilter));
        end;

        if IsTransferLine then begin
            TransferFromCode := CopyStr(TempTransferLine.GetFilter("Transfer-from Code"), 1, MaxStrLen(TransferFromCode));
            TransferToCode := CopyStr(TempTransferLine.GetFilter("Transfer-To Code"), 1, MaxStrLen(TransferToCode));
        end;

        if IsWarehouseReceipt then begin
            LocationCodeFilter := CopyStr(TempWarehouseJournalLine.GetFilter("Location Code"), 1, MaxStrLen(LocationCodeFilter));
            ToZoneCodeFilter := CopyStr(TempWarehouseJournalLine.GetFilter("To Zone Code"), 1, MaxStrLen(ToZoneCodeFilter));
            ToBinCodeFilter := CopyStr(TempWarehouseJournalLine.GetFilter("To Bin Code"), 1, MaxStrLen(ToBinCodeFilter));
        end;

        ItemNoFilter := CopyStr(TempItem.GetFilter("No."), 1, MaxStrLen(ItemNoFilter));
        CategoryCodeFilter := CopyStr(TempItem.GetFilter("Item Category Code"), 1, MaxStrLen(CategoryCodeFilter));
        InventoryPostingGroupCode := CopyStr(TempItem.GetFilter("Inventory Posting Group"), 1, MaxStrLen(InventoryPostingGroupCode));
    end;
}