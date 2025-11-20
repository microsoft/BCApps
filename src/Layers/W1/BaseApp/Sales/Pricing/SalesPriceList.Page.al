// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Pricing;

page 7016 "Sales Price List"
{
    Caption = 'Sales Price List';
    PageType = ListPlus;
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = where("Price Type" = const(Sale));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(LeftColumn)
                {
                    ShowCaption = false;
                    field(Code; Rec.Code)
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the unique identifier of the price list.';
                        Editable = CodeIsEditable;

                        trigger OnAssistEdit()
                        begin
                            if Rec.AssistEditCode(xRec) then
                                CurrPage.Update();
                        end;

                        trigger OnValidate()
                        begin
                            if Rec.Code <> '' then
                                CurrPage.Update();
                        end;
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        ShowMandatory = true;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the description of the price list.';
                    }
                    field(SourceType; SourceType)
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        Caption = 'Assign-to Type';
                        Editable = PriceListIsEditable;
                        Visible = not IsJobGroup;
                        ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                        trigger OnValidate()
                        begin
                            ValidateSourceType(SourceType.AsInteger());
                            CurrPage.Update(true);
                        end;
                    }
                    field(JobSourceType; JobSourceType)
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        Caption = 'Assign-to Type';
                        Editable = PriceListIsEditable;
                        Visible = IsJobGroup;
                        ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                        trigger OnValidate()
                        begin
                            ValidateSourceType(JobSourceType.AsInteger());
                            CurrPage.Update(true);
                        end;
                    }
                    group(AssignToParentNoGroup)
                    {
                        ShowCaption = false;
                        Visible = ParentSourceNoVisible;
                        field(AssignToParentNo; Rec."Assign-to Parent No.")
                        {
                            ApplicationArea = All;
                            Importance = Promoted;
                            Editable = PriceListIsEditable;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
                            trigger OnValidate()
                            begin
                                CurrPage.Update(true);
                            end;
                        }
                    }
                    field(SourceNo; Rec."Source No.")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        Enabled = SourceNoEnabled;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
                        Visible = UseCustomLookup;
                        ShowMandatory = SourceNoEnabled;

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;

                        trigger OnLookup(var Text: Text): Boolean;
                        begin
                            if Rec.LookupSourceNo() then
                                CurrPage.Update(true);
                        end;
                    }
                    field(AssignToNo; Rec."Assign-to No.")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        Enabled = SourceNoEnabled;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
                        Visible = not UseCustomLookup;
                        ShowMandatory = SourceNoEnabled;

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    group(Tax)
                    {
                        Caption = 'VAT';
                        field(VATBusPostingGrPrice; Rec."VAT Bus. Posting Gr. (Price)")
                        {
                            ApplicationArea = All;
                            Importance = Additional;
                            Editable = PriceListIsEditable;
                            ToolTip = 'Specifies the default VAT business posting group code.';

                            trigger OnValidate()
                            begin
                                CurrPage.Update(true);
                            end;
                        }
                        field(PriceIncludesVAT; Rec."Price Includes VAT")
                        {
                            ApplicationArea = All;
                            Importance = Additional;
                            Editable = PriceListIsEditable;
                            ToolTip = 'Specifies the if prices include VAT.';

                            trigger OnValidate()
                            begin
                                CurrPage.Update(true);
                            end;
                        }
                    }
                    group(View)
                    {
                        Caption = 'View';
                        Visible = ViewGroupIsVisible;
                        field(AmountType; ViewAmountType)
                        {
                            ApplicationArea = All;
                            Caption = 'View Columns for';
                            ToolTip = 'Specifies the amount type filter that defines the columns shown in the price list lines.';
                            trigger OnValidate()
                            begin
                                Rec.Validate("Amount Type", ViewAmountType);
                                CurrPage.Lines.Page.SetSubFormLinkFilter(ViewAmountType);
                            end;
                        }
                    }
                }
                group(RightColumn)
                {
                    ShowCaption = false;
                    field(Status; Rec.Status)
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and can be edited (when Allow Editing Active Price is enabled) and used for price calculations.';

                        trigger OnValidate()
                        begin
                            PriceListIsEditable := Rec.IsEditable();
                        end;
                    }
                    field(CurrencyCode; Rec."Currency Code")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the currency code of the price list.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    field(StartingDate; Rec."Starting Date")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the date from which the price is valid.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    field(EndingDate; Rec."Ending Date")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the last date that the price is valid.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    group(LineDefaults)
                    {
                        Caption = 'Line Defaults';
                        field(AllowUpdatingDefaults; Rec."Allow Updating Defaults")
                        {
                            ApplicationArea = All;
                            Importance = Additional;
                            Editable = PriceListIsEditable;
                            ToolTip = 'Specifies whether users can change the values in the fields on the price list lines that contain default values from the header. This does not affect the ability to allow line or invoice discounts.';
                            trigger OnValidate()
                            begin
                                CurrPage.Lines.Page.SetHeader(Rec);
                                CurrPage.Update(true);
                            end;
                        }
                        field(AllowInvoiceDisc; Rec."Allow Invoice Disc.")
                        {
                            ApplicationArea = All;
                            Importance = Additional;
                            Editable = PriceListIsEditable;
                            ToolTip = 'Specifies whether invoice discount is allowed. You can change this value on the lines.';

                            trigger OnValidate()
                            begin
                                CurrPage.Update(true);
                            end;
                        }
                        field(AllowLineDisc; Rec."Allow Line Disc.")
                        {
                            ApplicationArea = All;
                            Importance = Additional;
                            Editable = PriceListIsEditable;
                            ToolTip = 'Specifies whether line discounts are allowed. You can change this value on the lines.';

                            trigger OnValidate()
                            begin
                                CurrPage.Update(true);
                            end;
                        }
                    }
                }
            }
            part(Lines; "Price List Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = PriceListIsEditable;
                SubPageLink = "Price List Code" = field(Code);
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
        area(Processing)
        {
            action(SuggestLines)
            {
                ApplicationArea = Basic, Suite;
                Enabled = PriceListIsEditable;
                Ellipsis = true;
                Image = SuggestItemPrice;
                Caption = 'Suggest Lines';
                ToolTip = 'Creates the sales price list lines based on the unit price in the product cards, like item or resource. Change the price list status to ''Draft'' to run this action.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "Price List Management";
                begin
                    PriceListManagement.AddLines(Rec);
                end;
            }
            action(CopyLines)
            {
                ApplicationArea = Basic, Suite;
                Enabled = PriceListIsEditable and CopyLinesEnabled;
                Ellipsis = true;
                Image = CopyWorksheet;
                Caption = 'Copy Lines';
                ToolTip = 'Copies the lines from the existing price list. New prices can be adjusted by a factor and rounded differently. Change the price list status to ''Draft'' to run this action unless Allow Editing Active Price is enabled.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "Price List Management";
                begin
                    PriceListManagement.CopyLines(Rec);
                end;
            }
            action(VerifyLines)
            {
                ApplicationArea = Basic, Suite;
                Visible = PriceListIsEditable and (Rec.Status = Rec.Status::Active);
                Ellipsis = true;
                Image = CheckDuplicates;
                Caption = 'Verify Lines';
                ToolTip = 'Checks data consistency in the new and modified price list lines. Finds the duplicate price lines and suggests the resolution of the line conflicts.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "Price List Management";
                begin
                    PriceListManagement.ActivateDraftLines(Rec);
                end;
            }
        }
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
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(VerifyLines_Promoted; VerifyLines)
                {
                }
                actionref(CopyLines_Promoted; CopyLines)
                {
                }
                actionref(SuggestLines_Promoted; SuggestLines)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CRMIntegrationEnabled;

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
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
                actionref(CRMGoToPricelevel_Promoted; CRMGoToPricelevel)
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

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        PriceListLine: Record "Price List Line";
        PriceListManagement: Codeunit "Price List Management";
        DefaultSourceGroup: Enum "Price Source Group";
    begin
        UseCustomLookup := PriceListLine.UseCustomizedLookup();
        CopyLinesEnabled := PriceListManagement.VerifySourceGroupInLines();
        DefaultSourceGroup := GetSourceGroupFilter();
        UpdateSourceType(DefaultSourceGroup);
        PriceUXManagement.GetFirstSourceFromFilter(
            Rec, OriginalPriceSource, GetDefaultSourceType(DefaultSourceGroup));
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        if CRMIntegrationEnabled then
            if IntegrationTableMapping.Get('PLHEADER-PRICE') then begin
                StatusActiveFilterApplied := true;
                AllowUpdatingDefaultsFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field20=1(1)');
            end;
    end;

    local procedure GetSourceGroupFilter() SourceGroup: Enum "Price Source Group";
    var
        SourceGroupFilter: Text;
    begin
        Rec.FilterGroup(2);
        SourceGroupFilter := Rec.GetFilter("Source Group");
        Rec.FilterGroup(0);
        if SourceGroupFilter = '' then
            exit(SourceGroup::Customer);
        if not Evaluate(SourceGroup, SourceGroupFilter) then
            exit(SourceGroup::Customer);
    end;

    trigger OnAfterGetCurrRecord()
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        CRMIntegrationAllowed := Rec.IsCRMIntegrationAllowed(StatusActiveFilterApplied, AllowUpdatingDefaultsFilterApplied);
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
        Rec.SyncDropDownLookupFields();
        PriceListIsEditable := Rec.IsEditable();
        CodeIsEditable := PriceListIsEditable and (Rec.Code = '');
        UpdateSourceType(Rec."Source Group");
        SetSourceNoEnabled();
        ViewAmountType := Rec."Amount Type";
        ViewGroupIsVisible := true;
        if Rec.HasDraftLines() then
            PriceListManagement.SendVerifyLinesNotification(Rec);

        CurrPage.Lines.Page.SetHeader(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DefaultAmountType: Enum "Price Amount Type";
    begin
        Rec.CopyFrom(OriginalPriceSource);
        UpdateSourceType(Rec."Source Group");
        if PriceUXManagement.IsAmountTypeFiltered(Rec, DefaultAmountType) then
            Rec."Amount Type" := DefaultAmountType
        else
            Rec."Amount Type" := OriginalPriceSource.GetDefaultAmountType();
        ViewAmountType := Rec."Amount Type";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean;
    var
        PriceListManagement: Codeunit "Price List Management";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnQueryClosePageOnBeforeDraftLineCheck(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Rec.Find() then
            if Rec.HasDraftLines() then begin
                PriceListManagement.SendVerifyLinesNotification(Rec);
                exit(false);
            end;
        exit(true)
    end;

    trigger OnClosePage()
    begin
        if Rec.Find() then
            if Rec.Code <> '' then
                Rec.UpdateAmountType();
    end;

    local procedure UpdateSourceType(SourceGroup: Enum "Price Source Group")
    begin
        case SourceGroup of
            SourceGroup::Customer:
                begin
                    IsJobGroup := false;
                    SourceType := "Sales Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                end;
            SourceGroup::Job:
                begin
                    IsJobGroup := true;
                    JobSourceType := "Job Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                end;
            else
                OnUpdateSourceTypeOnCaseElse(Rec, SourceType, IsJobGroup);
        end;
    end;

    local procedure GetDefaultSourceType(SourceGroup: Enum "Price Source Group") DefaultSourceType: Enum "Price Source Type";
    begin
        case SourceGroup of
            SourceGroup::Customer:
                DefaultSourceType := Rec."Source Type"::"All Customers";
            SourceGroup::Job:
                DefaultSourceType := Rec."Source Type"::"All Jobs";
        end;
        OnAfterGetDefaultSourceType(SourceGroup, DefaultSourceType);
    end;

    var
        OriginalPriceSource: Record "Price Source";
        PriceUXManagement: Codeunit "Price UX Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationAllowed: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        StatusActiveFilterApplied: Boolean;
        AllowUpdatingDefaultsFilterApplied: Boolean;
        JobSourceType: Enum "Job Price Source Type";
        SourceType: Enum "Sales Price Source Type";
        ViewAmountType: Enum "Price Amount Type";

    protected var
        CodeIsEditable: Boolean;
        IsJobGroup: Boolean;
        ParentSourceNoEnabled: Boolean;
        ParentSourceNoVisible: Boolean;
        SourceNoEnabled: Boolean;
        PriceListIsEditable: Boolean;
        CopyLinesEnabled: Boolean;
        ViewGroupIsVisible: Boolean;
        UseCustomLookup: Boolean;

    protected procedure SetSourceNoEnabled()
    var
        PriceSource: Record "Price Source";
    begin
        Rec.CopyTo(PriceSource);
        ParentSourceNoEnabled := PriceSource.IsParentSourceAllowed();
        SourceNoEnabled := Rec.IsSourceNoAllowed();
        ParentSourceNoVisible := ParentSourceNoEnabled and not UseCustomLookup;
    end;

    protected procedure ValidateSourceType(SourceType2: Integer)
    begin
        Rec.Validate("Source Type", SourceType2);
        SetSourceNoEnabled();
        CurrPage.SaveRecord();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateSourceTypeOnCaseElse(PriceListHeader: Record "Price List Header"; var SourceType: Enum "Sales Price Source Type"; var IsJobGroup: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetDefaultSourceType(PriceSourceGroup: Enum "Price Source Group"; var DefaultPriceSourceType: Enum "Price Source Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQueryClosePageOnBeforeDraftLineCheck(PriceListHeader: Record "Price List Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
