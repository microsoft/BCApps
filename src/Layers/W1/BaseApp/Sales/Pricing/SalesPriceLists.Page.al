// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;

page 7015 "Sales Price Lists"
{
    Caption = 'Sales Price Lists';
    CardPageID = "Sales Price List";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Sales Price Lists';
    AboutText = 'Manage and update sales price lists for items and services, including setting prices, discounts, validity periods, and assignment to customers or groups.';
    QueryCategory = 'Sales Price Lists';
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = where("Source Group" = const(Customer), "Price Type" = const(Sale));
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code';
                    ToolTip = 'Specifies the unique identifier of the price list.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and can be edited (when Allow Editing Active Price is enabled) and used for price calculations.';
                }
                field("Allow Updating Defaults"; Rec."Allow Updating Defaults")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether users can change the values in the fields on the price list lines that contain default values from the header. This does not affect the ability to allow line or invoice discounts.';
                }
                field(Defines; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Defines';
                    ToolTip = 'Specifies whether the price list defines prices, discounts, or both.';
                }
                field("Currency Code"; CurrRec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency';
                    ToolTip = 'Specifies the currency that is used on the price list.';
                }
                field(SourceGroup; Rec."Source Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assign-to Group';
                    Visible = false;
                    ToolTip = 'Specifies whether the prices come from groups of customers, vendors or projects.';
                }
                field(SourceType; CurrRec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assign-to Type';
                    ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';
                }
                field(SourceNo; CurrRec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assign-to';
                    ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
                }
                field("Starting Date"; CurrRec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; CurrRec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date when the sales price agreement ends.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Enabled = CRMIntegrationAllowed;
                Visible = CRMIntegrationEnabled;
                action(CRMGoToPricelevel)
                {
                    ApplicationArea = Suite;
                    Caption = 'Pricelevel';
                    Image = CoupledItem;
                    ToolTip = 'View price information introduced through synchronization with Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            PriceListHeader: Record "Price List Header";
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(PriceListHeader);
                            RecRef.GetTable(PriceListHeader);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the price list header table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';

                group(Category_Coupling)
                {
                    Caption = 'Coupling';
                    ShowAs = SplitButton;

                    actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                    {
                    }
                    actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                    {
                    }
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(CRMGoToPricelevel_Promoted; CRMGoToPricelevel)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureDisabled();
    end;

    trigger OnAfterGetRecord()
    begin
        CurrRec := Rec;
        OnAfterSetCurrRecOnAfterGetRecord(Rec, CurrRec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CRMIntegrationAllowed := Rec.IsCRMIntegrationAllowed(StatusActiveFilterApplied, AllowUpdatingDefaultsFilterApplied);
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);

        CurrRec := Rec;
        OnAfterSetCurrRecOnAfterGetCurrRecord(Rec, CurrRec);
    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        if CRMIntegrationEnabled then
            if IntegrationTableMapping.Get('PLHEADER-PRICE') then begin
                StatusActiveFilterApplied := true;
                AllowUpdatingDefaultsFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field20=1(1)');
            end;
    end;

    var
        CurrRec: Record "Price List Header";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationAllowed: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        StatusActiveFilterApplied: Boolean;
        AllowUpdatingDefaultsFilterApplied: Boolean;

    procedure SetRecordFilter(var PriceListHeader: Record "Price List Header")
    begin
        Rec.FilterGroup := 2;
        Rec.CopyFilters(PriceListHeader);
        Rec.SetRange("Source Group", Rec."Source Group"::Customer);
        Rec.SetRange("Price Type", Rec."Price Type"::Sale);
        Rec.FilterGroup := 0;
    end;

    procedure SetSource(PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    var
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceUXManagement.SetPriceListsFilters(Rec, PriceSourceList, AmountType);
    end;

    procedure SetAsset(PriceAsset: Record "Price Asset"; AmountType: Enum "Price Amount Type")
    var
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceUXManagement.SetPriceListsFilters(Rec, PriceAsset."Price Type", AmountType);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrRecOnAfterGetRecord(var PriceListHeader: Record "Price List Header"; var PriceListHeaderCurrRec: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrRecOnAfterGetCurrRecord(var PriceListHeader: Record "Price List Header"; var PriceListHeaderCurrRec: Record "Price List Header")
    begin
    end;
}
