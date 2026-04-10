// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Analysis;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using System.Environment;
using System.Globalization;

report 795 "Adjust Cost - Item Entries"
{
    AdditionalSearchTerms = 'cost forwarding';
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Cost - Item Entries';
    Permissions = TableData "Item Ledger Entry" = rimd,
                  TableData "Item Application Entry" = r,
                  TableData "Value Entry" = rimd,
                  TableData "Avg. Cost Adjmt. Entry Point" = rimd;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FilterItemNo; ItemNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item No. Filter';
                        Editable = FilterItemNoEditable;
                        ToolTip = 'Specifies a filter to run the Adjust Cost - Item Entries batch job for only certain items. You can leave this field blank to run the batch job for all items.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ItemList: Page "Item List";
                        begin
                            ItemList.LookupMode := true;
                            if ItemList.RunModal() = ACTION::LookupOK then
                                Text := ItemList.GetSelectionFilter()
                            else
                                exit(false);

                            exit(true);
                        end;
                    }
                    field(FilterItemCategory; ItemCategoryFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Category Filter';
                        Editable = FilterItemCategoryEditable;
                        TableRelation = "Item Category";
                        ToolTip = 'Specifies a filter to run the Adjust Cost - Item Entries batch job for only certain item categories. You can leave this field blank to run the batch job for all item categories.';
                    }
                    field(Post; PostToGL)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post to G/L';
                        Enabled = PostEnable;
                        ToolTip = 'Specifies that inventory values created during the Adjust Cost - Item Entries batch job are posted to the inventory accounts in the general ledger. The option is only available if the Automatic Cost Posting check box is selected in the Inventory Setup window.';

                        trigger OnValidate()
                        var
                            ObjTransl: Record "Object Translation";
                        begin
                            if not PostToGL then
                                Message(
                                  ResynchronizeInfoMsg,
                                  ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, REPORT::"Post Inventory Cost to G/L"));
                        end;
                    }
                    field("Item-by-Item Adjustment"; ByItemCommit)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item-by-Item Adjustment';
                        ToolTip = 'Specifies if you want to commit the transaction after processing each individual item in the cost adjustment. This ensures that items already adjusted are saved even if the process is interrupted on one of the subsequent items.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        var
            ClientTypeManagement: Codeunit "Client Type Management";
        begin
            FilterItemCategoryEditable := true;
            FilterItemNoEditable := true;
            PostEnable := true;
            if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then begin
                InvtSetup.Get();
                PostToGL := InvtSetup."Automatic Cost Posting";
            end;
        end;

        trigger OnOpenPage()
        begin
            InvtSetup.Get();
            PostToGL := InvtSetup."Automatic Cost Posting";
            PostEnable := PostToGL;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        Item: Record Item;
    begin
        OnBeforePreReport(ItemNoFilter, ItemCategoryFilter, PostToGL, Item);

        if not LockTables() then
            CurrReport.Quit();

        if (ItemNoFilter <> '') and (ItemCategoryFilter <> '') then
            Error(ItemOrCategoryFilterErr);

        if ItemNoFilter <> '' then
            Item.SetFilter("No.", ItemNoFilter);
        if ItemCategoryFilter <> '' then
            Item.SetFilter("Item Category Code", ItemCategoryFilter);

        InvtSetup.Get();
        if InvtSetup."Cost Adjustment Logging" <> InvtSetup."Cost Adjustment Logging"::Disabled then
            RunCostAdjustmentWithLogging(Item)
        else
            RunCostAdjustment(Item);

        OnAfterPreReport();
    end;

    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        PostEnable: Boolean;
        FilterItemNoEditable: Boolean;
        FilterItemCategoryEditable: Boolean;

        ItemOrCategoryFilterErr: Label 'You must not use Item No. Filter and Item Category Filter at the same time.';
        ResynchronizeInfoMsg: Label 'Your general and item ledgers will no longer be synchronized after running the cost adjustment. You must run the %1 report to synchronize them again.', Comment = '%1: Adjust Cost - Item Entries';

    protected var
        ItemNoFilter: Text[250];
        ItemCategoryFilter: Text[250];
        PostToGL: Boolean;
        ByItemCommit: Boolean;

    local procedure LockTables(): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        ItemApplicationEntry.LockTable();
        if ItemApplicationEntry.GetLastEntryNo() = 0 then
            exit(false);

        ItemLedgerEntry.LockTable();
        if ItemLedgerEntry.GetLastEntryNo() = 0 then
            exit(false);

        ValueEntry.LockTable();
        if ValueEntry.GetLastEntryNo() = 0 then
            exit(false);

        AvgCostEntryPointHandler.LockBuffer();

        exit(true);
    end;

    local procedure RunCostAdjustment(var Item: Record Item)
    var
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        InvtAdjmtHandler.SetFilterItem(Item);
        SetCostAdjustmentParameters(CostAdjustmentParamsMgt);
        InvtAdjmtHandler.MakeInventoryAdjustment(CostAdjustmentParamsMgt);

        if PostToGL then
            UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
    end;

    local procedure RunCostAdjustmentWithLogging(var Item: Record Item)
    var
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
        CostAdjustmentSubscribers: Codeunit "Cost Adjustment Subscribers";
        CostAdjustmentItemRunner: Codeunit "Cost Adjustment Item Runner";
        Success: Boolean;
    begin
        Commit();
        BindSubscription(CostAdjustmentSubscribers);

        OnBeforeRunCostAdjustment();
        SetCostAdjustmentParameters(CostAdjustmentParamsMgt);
        CostAdjustmentItemRunner.SetParameters(CostAdjustmentParamsMgt);
        Success := CostAdjustmentItemRunner.Run(Item);
        if Success then
            RegisterSuccess()
        else
            RegisterFailure();
        OnAfterRunCostAdjustment(Item);

        Commit();
        if not Success then
            Error(GetLastErrorText());

        UnbindSubscription(CostAdjustmentSubscribers);
    end;

    procedure InitializeRequest(NewItemNoFilter: Text[250]; NewItemCategoryFilter: Text[250])
    begin
        ItemNoFilter := NewItemNoFilter;
        ItemCategoryFilter := NewItemCategoryFilter;
    end;

    procedure SetPostToGL(NewPostToGL: Boolean)
    begin
        PostToGL := NewPostToGL;
    end;

    local procedure SetCostAdjustmentParameters(var CostAdjustmentParamMgt: Codeunit "Cost Adjustment Params Mgt.");
    var
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
    begin
        CostAdjustmentParameter.Init();
        CostAdjustmentParameter."Online Adjustment" := false;
        CostAdjustmentParameter."Post to G/L" := PostToGL;
        CostAdjustmentParameter."Item-By-Item Commit" := ByItemCommit;
        OnAfterSetCostAdjustmentParameter(CostAdjustmentParameter);

        CostAdjustmentParamMgt.SetParameters(CostAdjustmentParameter);
        OnAfterSetCostAdjustmentParameterOnAfterSetParameters(CostAdjustmentParamMgt);
    end;

    local procedure RegisterSuccess()
    begin
        OnRegisterSuccess();
    end;

    local procedure RegisterFailure()
    begin
        OnRegisterFailure();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPreReport()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePreReport(ItemNoFilter: Text[250]; ItemCategoryFilter: Text[250]; PostToGL: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCostAdjustment()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunCostAdjustment(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterSuccess()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterFailure()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCostAdjustmentParameter(var CostAdjustmentParameter: Record "Cost Adjustment Parameter")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCostAdjustmentParameterOnAfterSetParameters(var CostAdjustmentParamMgt: Codeunit "Cost Adjustment Params Mgt.")
    begin
    end;
}

