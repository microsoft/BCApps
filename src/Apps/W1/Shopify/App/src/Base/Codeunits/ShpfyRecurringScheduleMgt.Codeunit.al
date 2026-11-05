// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.History;
using System.Automation;
using System.Azure.Identity;
using System.Threading;

codeunit 30206 "Shpfy Recurring Schedule Mgt."
{
    Access = Internal;
    Permissions = tabledata "Job Queue Category" = RIM,
                  tabledata "Job Queue Entry" = RIM;

    var
        DataItemXPathTok: Label '/ReportParameters/DataItems/DataItem[@name="%1"]', Locked = true;
        FrequencyErr: Label 'Frequency must be greater than zero for %1.', Comment = '%1 = The item for which the frequency must be greater than zero';
        JobQueueCategoryTok: Label 'SHPFY', Locked = true;
        WorkloadNotSupportedErr: Label 'The synchronization workload %1 is not supported.', Comment = '%1 = The workload that is not supported';

    internal procedure IsRecognizedSchedule(JobQueueEntry: Record "Job Queue Entry"; CurrentShopCode: Code[20]; var Workload: Enum "Shpfy Sync Workload"; var Coverage: Enum "Shpfy Sync Coverage"): Boolean
    var
        ParameterText: Text;
        ShopFilter: Text;
        ParametersDocument: XmlDocument;
    begin
        Clear(Workload);
        Clear(Coverage);
        if not IsRecurringShopifyReport(JobQueueEntry) then
            exit(false);

        ParameterText := JobQueueEntry.GetReportParameters();
        if not ParseParameters(ParameterText, ParametersDocument) then
            exit(false);
        exit(RecognizesReportSchedule(JobQueueEntry, ParametersDocument, CurrentShopCode, Workload, Coverage, ShopFilter));
    end;

    local procedure RecognizesReportSchedule(JobQueueEntry: Record "Job Queue Entry"; ParametersDocument: XmlDocument; CurrentShopCode: Code[20]; var Workload: Enum "Shpfy Sync Workload"; var Coverage: Enum "Shpfy Sync Coverage"; var ShopFilter: Text): Boolean
    begin
        case JobQueueEntry."Object ID to Run" of
            Report::"Shpfy Sync Products":
                begin
                    if not ParseProductWorkload(ParametersDocument, Workload) then
                        exit(false);
                    if not ReadShopDataItemFilter(ParametersDocument, 'Shop', '', ShopFilter) then
                        exit(false);
                end;
            Report::"Shpfy Sync Stock to Shopify":
                if not MatchesInventorySchedule(ParametersDocument, Workload, ShopFilter) then
                    exit(false);
            Report::"Shpfy Sync Orders from Shopify":
                if not MatchesOrdersSchedule(ParametersDocument, Workload, ShopFilter) then
                    exit(false);
            Report::"Shpfy Sync Shipm. to Shopify":
                exit(MatchesShipmentSchedule(ParametersDocument, Workload, Coverage));
            Report::"Shpfy Sync Customers":
                if not MatchesShopSchedule(ParametersDocument, Workload::Customers, Workload, ShopFilter) then
                    exit(false);
            Report::"Shpfy Sync Companies":
                if not MatchesShopSchedule(ParametersDocument, Workload::Companies, Workload, ShopFilter) then
                    exit(false);
            Report::"Shpfy Sync Images":
                if not MatchesImageSchedule(ParametersDocument, Workload, ShopFilter) then
                    exit(false);
            Report::"Shpfy Sync Invoices to Shpfy":
                exit(MatchesPostedInvoiceSchedule(ParametersDocument, CurrentShopCode, Workload, Coverage));
            Report::"Shpfy Sync Catalog Prices":
                if not MatchesCatalogPriceSchedule(ParametersDocument, Workload, ShopFilter) then
                    exit(false);
            else
                exit(false);
        end;
        if not DetermineShopCoverage(ShopFilter, CurrentShopCode, Coverage) then
            exit(false);
        exit(Coverage in [Coverage::"All Shops", Coverage::"Current Shop", Coverage::"Multiple Shops"]);
    end;

    local procedure MatchesInventorySchedule(ParametersDocument: XmlDocument; var Workload: Enum "Shpfy Sync Workload"; var ShopFilter: Text): Boolean
    begin
        Workload := Workload::Inventory;
        if not HasExpectedOptions(ParametersDocument, 'SkipImport,VariantIdFilter') then
            exit(false);
        if not IsFalse(GetOptionText(ParametersDocument, 'SkipImport')) then
            exit(false);
        if GetOptionText(ParametersDocument, 'VariantIdFilter') <> '' then
            exit(false);
        exit(ReadShopDataItemFilter(ParametersDocument, 'Shop', '', ShopFilter));
    end;

    local procedure MatchesOrdersSchedule(ParametersDocument: XmlDocument; var Workload: Enum "Shpfy Sync Workload"; var ShopFilter: Text): Boolean
    begin
        Workload := Workload::Orders;
        if not HasExpectedOptions(ParametersDocument, '') then
            exit(false);
        exit(ReadShopDataItemFilter(ParametersDocument, 'Shop,OrdersToImport', 'OrdersToImport', ShopFilter));
    end;

    local procedure MatchesShipmentSchedule(ParametersDocument: XmlDocument; var Workload: Enum "Shpfy Sync Workload"; var Coverage: Enum "Shpfy Sync Coverage"): Boolean
    begin
        Workload := Workload::Shipments;
        if not HasExpectedOptions(ParametersDocument, '') then
            exit(false);
        if not HasUnfilteredDataItem(ParametersDocument, 'Sales Shipment Header') then
            exit(false);
        Coverage := Coverage::"All Shops";
        exit(true);
    end;

    local procedure MatchesShopSchedule(ParametersDocument: XmlDocument; ScheduleWorkload: Enum "Shpfy Sync Workload"; var Workload: Enum "Shpfy Sync Workload"; var ShopFilter: Text): Boolean
    begin
        Workload := ScheduleWorkload;
        if not HasExpectedOptions(ParametersDocument, '') then
            exit(false);
        exit(ReadShopDataItemFilter(ParametersDocument, 'Shop', '', ShopFilter));
    end;

    local procedure MatchesImageSchedule(ParametersDocument: XmlDocument; var Workload: Enum "Shpfy Sync Workload"; var ShopFilter: Text): Boolean
    begin
        Workload := Workload::"Product Images";
        if not HasExpectedOptions(ParametersDocument, 'ProductFilterTxt') then
            exit(false);
        if GetOptionText(ParametersDocument, 'ProductFilterTxt') <> '' then
            exit(false);
        exit(ReadShopDataItemFilter(ParametersDocument, 'Shop', '', ShopFilter));
    end;

    local procedure MatchesPostedInvoiceSchedule(ParametersDocument: XmlDocument; CurrentShopCode: Code[20]; var Workload: Enum "Shpfy Sync Workload"; var Coverage: Enum "Shpfy Sync Coverage"): Boolean
    begin
        Workload := Workload::"Posted Invoices";
        if (CurrentShopCode = '') or not HasExpectedOptions(ParametersDocument, 'ShopCode') then
            exit(false);
        if GetOptionText(ParametersDocument, 'ShopCode') <> CurrentShopCode then
            exit(false);
        if not HasUnfilteredDataItem(ParametersDocument, 'SalesInvoiceHeader') then
            exit(false);
        Coverage := Coverage::"Current Shop";
        exit(true);
    end;

    local procedure MatchesCatalogPriceSchedule(ParametersDocument: XmlDocument; var Workload: Enum "Shpfy Sync Workload"; var ShopFilter: Text): Boolean
    begin
        Workload := Workload::"Catalog Prices";
        if not HasExpectedOptions(ParametersDocument, 'CompanyId,CatalogType') then
            exit(false);
        if (GetOptionText(ParametersDocument, 'CompanyId') <> '') or
           not IsDefaultCatalogType(GetOptionText(ParametersDocument, 'CatalogType'))
        then
            exit(false);
        if not ReadCodeDataItemFilter(ParametersDocument, 'Shop', ShopFilter) then
            exit(false);
        if not HasExpectedDataItems(ParametersDocument, 'Shop') and
           not ReadShopDataItemFilter(ParametersDocument, 'Shop,Catalog', 'Catalog', ShopFilter)
        then
            exit(false);
        if ShopFilter = '' then
            exit(false);
        exit(true);
    end;

    internal procedure BuildRecommendations(Shop: Record "Shpfy Shop"; var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary)
    var
        HasExistingSchedules: Boolean;
    begin
        BuildRecommendationsWithScheduleState(Shop, TempRecurringSyncBuffer, HasExistingSchedules);
    end;

    internal procedure BuildRecommendationsWithScheduleState(Shop: Record "Shpfy Shop"; var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; var HasExistingSchedules: Boolean)
    var
        ScheduledWorkloads: array[10] of Boolean;
    begin
        TempRecurringSyncBuffer.Reset();
        TempRecurringSyncBuffer.DeleteAll(false);
        HasExistingSchedules := false;
        GetScheduledWorkloads(Shop.Code, ScheduledWorkloads, HasExistingSchedules);
        BuildProductAndPriceRecommendations(Shop, TempRecurringSyncBuffer, ScheduledWorkloads);
        BuildInventoryOrderAndShipmentRecommendations(Shop, TempRecurringSyncBuffer, ScheduledWorkloads);
        BuildCustomerAndCompanyRecommendations(Shop, TempRecurringSyncBuffer, ScheduledWorkloads);
        BuildImageInvoiceAndCatalogRecommendations(Shop, TempRecurringSyncBuffer, ScheduledWorkloads);
    end;

    internal procedure GetFrequencyErrorText(RecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer"): Text
    begin
        exit(StrSubstNo(FrequencyErr, Format(RecurringSyncBuffer.Synchronization)));
    end;

    internal procedure OpenSetupTarget(Shop: Record "Shpfy Shop"; RecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer"): Boolean
    var
        ShopifyPaymentTerms: Record "Shpfy Payment Terms";
        ShopifyShopLocation: Record "Shpfy Shop Location";
    begin
        if RecurringSyncBuffer.Readiness <> RecurringSyncBuffer.Readiness::"Setup required" then
            exit(false);
        case RecurringSyncBuffer."Setup Target" of
            RecurringSyncBuffer."Setup Target"::"Shop Card":
                begin
                    Shop.SetRecFilter();
                    Page.RunModal(Page::"Shpfy Shop Card", Shop);
                end;
            RecurringSyncBuffer."Setup Target"::"Shop Locations":
                begin
                    ShopifyShopLocation.SetRange("Shop Code", Shop.Code);
                    Page.RunModal(Page::"Shpfy Shop Locations Mapping", ShopifyShopLocation);
                end;
            RecurringSyncBuffer."Setup Target"::"Payment Terms Mapping":
                begin
                    ShopifyPaymentTerms.SetRange("Shop Code", Shop.Code);
                    Page.RunModal(Page::"Shpfy Payment Terms Mapping", ShopifyPaymentTerms);
                end;
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure BuildProductAndPriceRecommendations(Shop: Record "Shpfy Shop"; var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; ScheduledWorkloads: array[10] of Boolean)
    var
        IsReady: Boolean;
        IsOutbound: Boolean;
        Workload: Enum "Shpfy Sync Workload";
        SyncDirection: Enum "Shpfy Sync Direction";
        Details: Text;
        SetupTarget: Enum "Shpfy Sync Setup Target";
        ProductsDescriptionLbl: Label 'Synchronize products in the direction selected on the Shopify Shop Card.';
        ProductsDirectionSetupLbl: Label 'Choose a Sync Item direction on the Shopify Shop Card.';
        ProductsFromShopifySetupLbl: Label 'Turn on Shopify Can Update Items or Auto Create Unknown Items on the Shopify Shop Card.';
        ProductsToShopifySetupLbl: Label 'Turn on Can Update Shopify Products on the Shopify Shop Card.';
        PricesDescriptionLbl: Label 'Send product prices to Shopify independently of full product synchronization.';
    begin
        case Shop."Sync Item" of
            Shop."Sync Item"::"To Shopify":
                begin
                    SyncDirection := SyncDirection::"Products to Shopify";
                    IsReady := Shop."Can Update Shopify Products";
                    IsOutbound := true;
                    if not IsReady then begin
                        Details := ProductsToShopifySetupLbl;
                        SetupTarget := SetupTarget::"Shop Card";
                    end;
                end;
            Shop."Sync Item"::"From Shopify":
                begin
                    SyncDirection := SyncDirection::"Products from Shopify";
                    IsReady := Shop."Shopify Can Update Items" or Shop."Auto Create Unknown Items";
                    if not IsReady then begin
                        Details := ProductsFromShopifySetupLbl;
                        SetupTarget := SetupTarget::"Shop Card";
                    end;
                end;
            else begin
                SyncDirection := SyncDirection::Products;
                Details := ProductsDirectionSetupLbl;
                SetupTarget := SetupTarget::"Shop Card";
            end;
        end;
        AddRecommendation(TempRecurringSyncBuffer, Workload::Products, SyncDirection, 1440, ProductsDescriptionLbl, IsReady, IsOutbound, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);

        Clear(Details);
        Clear(SetupTarget);
        AddRecommendation(TempRecurringSyncBuffer, Workload::Prices, SyncDirection::"Prices to Shopify", 360, PricesDescriptionLbl, true, true, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);
    end;

    local procedure BuildInventoryOrderAndShipmentRecommendations(Shop: Record "Shpfy Shop"; var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; ScheduledWorkloads: array[10] of Boolean)
    var
        IsReady: Boolean;
        Workload: Enum "Shpfy Sync Workload";
        SyncDirection: Enum "Shpfy Sync Direction";
        Details: Text;
        SetupTarget: Enum "Shpfy Sync Setup Target";
        InventoryDescriptionLbl: Label 'Send calculated Business Central inventory to Shopify for participating Shopify locations.';
        InventorySetupLbl: Label 'Get Shopify locations and choose a Stock Calculation other than Off for at least one location.';
        OrdersDescriptionLbl: Label 'Get new and updated orders from Shopify.';
        OrdersWebhooksDescriptionLbl: Label 'Auto Sync Orders imports new orders through webhooks. A daily recurring synchronization can retrieve missed or updated orders.';
        ShipmentsDescriptionLbl: Label 'Synchronize posted sales shipments that are linked to Shopify orders. One schedule processes shipments for all Shopify shops.';
    begin
        IsReady := HasParticipatingInventoryLocation(Shop.Code);
        if not IsReady then begin
            Details := InventorySetupLbl;
            SetupTarget := SetupTarget::"Shop Locations";
        end;
        AddRecommendation(TempRecurringSyncBuffer, Workload::Inventory, SyncDirection::"Inventory to Shopify", 360, InventoryDescriptionLbl, IsReady, true, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);

        Clear(Details);
        Clear(SetupTarget);
        if Shop."Order Created Webhooks" then begin
            Details := OrdersWebhooksDescriptionLbl;
            AddRecommendation(TempRecurringSyncBuffer, Workload::Orders, SyncDirection::"Orders from Shopify", 1440, Details, true, false, Shop."Allow Outgoing Requests", '', SetupTarget, ScheduledWorkloads);
        end else begin
            Details := OrdersDescriptionLbl;
            AddRecommendation(TempRecurringSyncBuffer, Workload::Orders, SyncDirection::"Orders from Shopify", 30, Details, true, false, Shop."Allow Outgoing Requests", '', SetupTarget, ScheduledWorkloads);
        end;

        Clear(Details);
        Clear(SetupTarget);
        AddRecommendation(TempRecurringSyncBuffer, Workload::Shipments, SyncDirection::"Shipments to Shopify", 120, ShipmentsDescriptionLbl, true, true, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);
    end;

    local procedure BuildCustomerAndCompanyRecommendations(Shop: Record "Shpfy Shop"; var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; ScheduledWorkloads: array[10] of Boolean)
    var
        IsReady: Boolean;
        IsOutbound: Boolean;
        Workload: Enum "Shpfy Sync Workload";
        SyncDirection: Enum "Shpfy Sync Direction";
        Details: Text;
        SetupTarget: Enum "Shpfy Sync Setup Target";
        CustomersDescriptionLbl: Label 'Synchronize customers by using the import and update settings on the Shopify Shop Card.';
        CustomersSetupLbl: Label 'Choose All Customers, or turn on a customer update option that performs synchronization.';
        CompaniesDescriptionLbl: Label 'Synchronize B2B companies by using the import and update settings on the Shopify Shop Card.';
        CompaniesSetupLbl: Label 'Choose All Companies, or turn on a company update option that performs synchronization.';
    begin
        IsReady := IsCustomerImportEnabled(Shop) or Shop."Can Update Shopify Customer";
        IsOutbound := Shop."Can Update Shopify Customer";
        SyncDirection := GetCustomerSyncDirection(Shop);
        if not IsReady then begin
            Details := CustomersSetupLbl;
            SetupTarget := SetupTarget::"Shop Card";
        end;
        AddRecommendation(TempRecurringSyncBuffer, Workload::Customers, SyncDirection, 240, CustomersDescriptionLbl, IsReady, IsOutbound, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);

        Clear(Details);
        Clear(SetupTarget);
        IsReady := IsCompanyImportEnabled(Shop) or Shop."Can Update Shopify Companies";
        IsOutbound := Shop."Can Update Shopify Companies";
        SyncDirection := GetCompanySyncDirection(Shop);
        if not IsReady then begin
            Details := CompaniesSetupLbl;
            SetupTarget := SetupTarget::"Shop Card";
        end;
        AddRecommendation(TempRecurringSyncBuffer, Workload::Companies, SyncDirection, 240, CompaniesDescriptionLbl, IsReady, IsOutbound, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);
    end;

    local procedure BuildImageInvoiceAndCatalogRecommendations(Shop: Record "Shpfy Shop"; var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; ScheduledWorkloads: array[10] of Boolean)
    var
        IsReady: Boolean;
        IsOutbound: Boolean;
        Workload: Enum "Shpfy Sync Workload";
        SyncDirection: Enum "Shpfy Sync Direction";
        Details: Text;
        SetupTarget: Enum "Shpfy Sync Setup Target";
        ImagesDescriptionLbl: Label 'Synchronize product images in the direction selected on the Shopify Shop Card.';
        ImagesDirectionSetupLbl: Label 'Choose a Sync Item Images direction on the Shopify Shop Card.';
        InvoicesDescriptionLbl: Label 'Send eligible posted sales invoices for this Shopify shop to Shopify.';
        InvoiceSetupLbl: Label 'Turn on Posted Invoice Sync and map at least one Shopify payment term or mark one payment term as primary.';
        CatalogPricesDescriptionLbl: Label 'Send prices for B2B and market catalogs for this Shopify shop.';
    begin
        case Shop."Sync Item Images" of
            Shop."Sync Item Images"::"To Shopify":
                begin
                    SyncDirection := SyncDirection::"Product images to Shopify";
                    IsReady := true;
                    IsOutbound := true;
                end;
            Shop."Sync Item Images"::"From Shopify":
                begin
                    SyncDirection := SyncDirection::"Product images from Shopify";
                    IsReady := true;
                    IsOutbound := false;
                end;
            else begin
                SyncDirection := SyncDirection::"Product images";
                IsReady := false;
                IsOutbound := false;
                Details := ImagesDirectionSetupLbl;
                SetupTarget := SetupTarget::"Shop Card";
            end;
        end;
        AddRecommendation(TempRecurringSyncBuffer, Workload::"Product Images", SyncDirection, 1440, ImagesDescriptionLbl, IsReady, IsOutbound, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);

        Clear(Details);
        Clear(SetupTarget);
        IsReady := Shop."Posted Invoice Sync" and HasInvoicePaymentTerms(Shop.Code);
        if not IsReady then begin
            Details := InvoiceSetupLbl;
            if Shop."Posted Invoice Sync" then
                SetupTarget := SetupTarget::"Payment Terms Mapping"
            else
                SetupTarget := SetupTarget::"Shop Card";
        end;
        AddRecommendation(TempRecurringSyncBuffer, Workload::"Posted Invoices", SyncDirection::"Posted invoices to Shopify", 360, InvoicesDescriptionLbl, IsReady, true, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);

        Clear(Details);
        Clear(SetupTarget);
        AddRecommendation(TempRecurringSyncBuffer, Workload::"Catalog Prices", SyncDirection::"Catalog prices to Shopify", 720, CatalogPricesDescriptionLbl, true, true, Shop."Allow Outgoing Requests", Details, SetupTarget, ScheduledWorkloads);
    end;

    internal procedure CreateSelectedSchedules(Shop: Record "Shpfy Shop"; var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary): Text
    var
        JobQueueCategory: Record "Job Queue Category";
        JobQueueEntry: Record "Job Queue Entry";
        TempCreatedJobQueueEntry: Record "Job Queue Entry" temporary;
        TempCurrentRecommendations: Record "Shpfy Recurring Sync Buffer" temporary;
        TempSelectedBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ApprovalsMgt: Codeunit "Approvals Mgmt.";
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        ApprovalRequested: Boolean;
        CreatedSchedule: Boolean;
        HasSelectedWorkload: Boolean;
        LicensedUserHandover: Boolean;
        JobQueueCategoryDescriptionTok: Label 'Shopify', Locked = true;
        ShopNoLongerExistsErr: Label 'Shop %1 no longer exists.', Comment = '%1 = Shop code';
    begin
        HasSelectedWorkload := CopySelectedRecommendations(TempRecurringSyncBuffer, TempSelectedBuffer);
        if not HasSelectedWorkload then
            exit('');
        if not Shop.Get(Shop.Code) then
            Error(ShopNoLongerExistsErr, Shop.Code);

        // Serializes concurrent Finish calls: the update lock on the SHPFY category row is held until the first commit,
        // so the recheck below sees schedules created by another session. That commit happens only after all entries are inserted.
        JobQueueCategory.ReadIsolation := IsolationLevel::UpdLock;
        JobQueueCategory.InsertRec(JobQueueCategoryTok, JobQueueCategoryDescriptionTok);
        JobQueueCategory.Get(JobQueueCategoryTok);

        BuildRecommendations(Shop, TempCurrentRecommendations);
        CreatedSchedule := CreateSchedulesForSelectedRecommendations(Shop, TempSelectedBuffer, TempCurrentRecommendations, TempCreatedJobQueueEntry);
        SetCreatedSchedulesActivationOutcome(TempCreatedJobQueueEntry, JobQueueEntry, AzureADGraphUser, ApprovalsMgt, ApprovalRequested, LicensedUserHandover);
        exit(GetScheduleCreationResult(ApprovalRequested, LicensedUserHandover, CreatedSchedule));
    end;

    local procedure CopySelectedRecommendations(var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; var TempSelectedBuffer: Record "Shpfy Recurring Sync Buffer" temporary): Boolean
    begin
        TempRecurringSyncBuffer.Reset();
        TempRecurringSyncBuffer.SetRange(Selected, true);
        if not TempRecurringSyncBuffer.FindSet(false) then
            exit(false);
        repeat
            if TempRecurringSyncBuffer.Frequency <= 0 then
                Error(FrequencyErr, Format(TempRecurringSyncBuffer.Synchronization));
            TempSelectedBuffer := TempRecurringSyncBuffer;
            TempSelectedBuffer.Insert(false);
        until TempRecurringSyncBuffer.Next() = 0;
        exit(true);
    end;

    local procedure CreateSchedulesForSelectedRecommendations(Shop: Record "Shpfy Shop"; var TempSelectedBuffer: Record "Shpfy Recurring Sync Buffer" temporary; var TempCurrentRecommendations: Record "Shpfy Recurring Sync Buffer" temporary; var TempCreatedJobQueueEntry: Record "Job Queue Entry" temporary): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        CreatedSchedule: Boolean;
    begin
        if not TempSelectedBuffer.FindSet(false) then
            exit(false);
        repeat
            if TempCurrentRecommendations.Get(TempSelectedBuffer."Entry No.") then
                if TempCurrentRecommendations.Selectable then begin
                    CreateJobQueueEntry(Shop, TempCurrentRecommendations, TempSelectedBuffer.Frequency, JobQueueEntry);
                    TempCreatedJobQueueEntry := JobQueueEntry;
                    TempCreatedJobQueueEntry.Insert(false);
                    CreatedSchedule := true;
                end;
        until TempSelectedBuffer.Next() = 0;
        exit(CreatedSchedule);
    end;

    local procedure SetCreatedSchedulesActivationOutcome(var TempCreatedJobQueueEntry: Record "Job Queue Entry" temporary; var JobQueueEntry: Record "Job Queue Entry"; AzureADGraphUser: Codeunit "Azure AD Graph User"; ApprovalsMgt: Codeunit "Approvals Mgmt."; var ApprovalRequested: Boolean; var LicensedUserHandover: Boolean)
    begin
        if not TempCreatedJobQueueEntry.FindSet(false) then
            exit;
        repeat
            JobQueueEntry.Get(TempCreatedJobQueueEntry.ID);
            SetActivationOutcome(JobQueueEntry, AzureADGraphUser, ApprovalsMgt, ApprovalRequested, LicensedUserHandover);
        until TempCreatedJobQueueEntry.Next() = 0;
    end;

    local procedure GetScheduleCreationResult(ApprovalRequested: Boolean; LicensedUserHandover: Boolean; CreatedSchedule: Boolean): Text
    var
        SchedulesCreatedMsg: Label 'Recurring Shopify synchronization is set up.';
        SchedulesNotCreatedMsg: Label 'No schedules were created because the selected workloads were already scheduled or are no longer ready.';
        SchedulesOnHoldMsg: Label 'Recurring synchronization entries were created with status On Hold. A licensed user must set them to Ready before they can run.';
        SchedulesSentForApprovalMsg: Label 'Recurring synchronization entries were created and sent for approval. They will remain on hold until approved.';
    begin
        if ApprovalRequested then
            exit(SchedulesSentForApprovalMsg);
        if LicensedUserHandover then
            exit(SchedulesOnHoldMsg);
        if not CreatedSchedule then
            exit(SchedulesNotCreatedMsg);
        exit(SchedulesCreatedMsg);
    end;

    internal procedure CreateJobQueueEntry(Shop: Record "Shpfy Shop"; RecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer"; Frequency: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        EarliestStartDateTime: DateTime;
        ReportId: Integer;
        StartingTime: Time;
    begin
        if Frequency <= 0 then
            Error(FrequencyErr, Format(RecurringSyncBuffer.Synchronization));

        ReportId := GetReportId(RecurringSyncBuffer.Workload);
        GetStartingTime(Shop, RecurringSyncBuffer.Workload, StartingTime, EarliestStartDateTime);

        JobQueueEntry.InitRecurringJob(Frequency);
        JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.Validate("Object ID to Run", ReportId);
        JobQueueEntry.Validate("Report Output Type", JobQueueEntry."Report Output Type"::"None (Processing only)");
        JobQueueEntry.Validate("Job Queue Category Code", JobQueueCategoryTok);
        JobQueueEntry.Validate("Maximum No. of Attempts to Run", 3);
        JobQueueEntry.Validate("Rerun Delay (sec.)", 60);
        if StartingTime <> 0T then
            JobQueueEntry.Validate("Starting Time", StartingTime);
        JobQueueEntry."Earliest Start Date/Time" := EarliestStartDateTime;
        JobQueueEntry.Description := CopyStr(RecurringSyncBuffer.Description, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Insert(true);
        JobQueueEntry.SetReportParameters(GetReportParameters(Shop.Code, RecurringSyncBuffer.Workload));
    end;

    local procedure SetActivationOutcome(var JobQueueEntry: Record "Job Queue Entry"; AzureADGraphUser: Codeunit "Azure AD Graph User"; ApprovalsMgt: Codeunit "Approvals Mgmt."; var ApprovalRequested: Boolean; var LicensedUserHandover: Boolean)
    begin
        if TaskScheduler.CanCreateTask() and not AzureADGraphUser.IsUserDelegated() then begin
            JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
            exit;
        end;
        if ApprovalsMgt.CheckJobQueueEntryApprovalEnabled() then begin
            Commit();
            ApprovalsMgt.OnSendJobQueueEntryForApproval(JobQueueEntry);
            if not JobQueueEntry.Get(JobQueueEntry.ID) then
                exit;
            if JobQueueEntry.Status = JobQueueEntry.Status::Ready then
                exit;
            if ApprovalsMgt.HasOpenApprovalEntries(JobQueueEntry.RecordId()) then begin
                ApprovalRequested := true;
                exit;
            end;
        end;
        LicensedUserHandover := true;
    end;

    local procedure GetReportId(Workload: Enum "Shpfy Sync Workload"): Integer
    begin
        case Workload of
            Workload::Products, Workload::Prices:
                exit(Report::"Shpfy Sync Products");
            Workload::Inventory:
                exit(Report::"Shpfy Sync Stock to Shopify");
            Workload::Orders:
                exit(Report::"Shpfy Sync Orders from Shopify");
            Workload::Shipments:
                exit(Report::"Shpfy Sync Shipm. to Shopify");
            Workload::Customers:
                exit(Report::"Shpfy Sync Customers");
            Workload::Companies:
                exit(Report::"Shpfy Sync Companies");
            Workload::"Product Images":
                exit(Report::"Shpfy Sync Images");
            Workload::"Posted Invoices":
                exit(Report::"Shpfy Sync Invoices to Shpfy");
            Workload::"Catalog Prices":
                exit(Report::"Shpfy Sync Catalog Prices");
        end;
        Error(WorkloadNotSupportedErr, Format(Workload));
    end;

    local procedure GetStartingTime(Shop: Record "Shpfy Shop"; Workload: Enum "Shpfy Sync Workload"; var StartingTime: Time; var EarliestStartDateTime: DateTime)
    var
        Hash: Codeunit "Shpfy Hash";
        StartingDate: Date;
        OffsetMinutes: Integer;
        BaseTime: Time;
    begin
        OffsetMinutes := Hash.CalcHash(Shop.Code) mod 15;
        if OffsetMinutes < 0 then
            OffsetMinutes += 15;
        case Workload of
            Workload::Products:
                BaseTime := 010000T;
            Workload::Orders:
                if Shop."Order Created Webhooks" then
                    BaseTime := 030000T
                else begin
                    GetIntervalStartingTime(OffsetMinutes, StartingTime, EarliestStartDateTime);
                    exit;
                end;
            Workload::"Product Images":
                BaseTime := 020000T;
            else begin
                GetIntervalStartingTime(OffsetMinutes, StartingTime, EarliestStartDateTime);
                exit;
            end;
        end;

        StartingDate := Today();
        EarliestStartDateTime := CreateDateTime(StartingDate, BaseTime) + OffsetMinutes * 60000;
        if EarliestStartDateTime <= CurrentDateTime() then begin
            StartingDate += 1;
            EarliestStartDateTime := CreateDateTime(StartingDate, BaseTime) + OffsetMinutes * 60000;
        end;
        StartingTime := DT2Time(EarliestStartDateTime);
    end;

    local procedure GetIntervalStartingTime(OffsetMinutes: Integer; var StartingTime: Time; var EarliestStartDateTime: DateTime)
    begin
        // Interval workloads start 1-15 minutes after Finish, so a zero shop offset never schedules an immediate run.
        // Starting Time stays blank: the dispatcher treats it as a daily lower limit, which would pause interval runs after midnight.
        EarliestStartDateTime := CurrentDateTime() + (OffsetMinutes + 1) * 60000;
        StartingTime := 0T;
    end;

    local procedure GetReportParameters(ShopCode: Code[20]; Workload: Enum "Shpfy Sync Workload"): Text
    var
        ShopifyShop: Record "Shpfy Shop";
        ReportParametersElementTok: Label '<ReportParameters>', Locked = true;
        ReportParametersRootTok: Label '<ReportParameters name="%1" id="%2">', Comment = '%1 = Report name, %2 = Report ID', Locked = true;
        ReportParametersTok: Label '<ReportParameters><Options /><DataItems>%1</DataItems></ReportParameters>', Locked = true;
        ShopDataItemTok: Label '<DataItem name="Shop">%1</DataItem>', Locked = true;
        XmlHeaderTok: Label '<?xml version="1.0" standalone="yes"?>', Locked = true;
        DataItems: Text;
        Parameters: Text;
        ReportName: Text;
        ShopDataItem: Text;
    begin
        ShopifyShop.Get(ShopCode);
        ShopifyShop.SetRecFilter();
        ShopDataItem := StrSubstNo(ShopDataItemTok, EscapeXml(ShopifyShop.GetView()));
        Parameters := GetWorkloadReportParameters(ShopCode, Workload, ShopDataItem, ReportName, DataItems);
        if Parameters = '' then
            Parameters := StrSubstNo(ReportParametersTok, DataItems);
        Parameters := Parameters.Replace(ReportParametersElementTok, StrSubstNo(ReportParametersRootTok, ReportName, Format(GetReportId(Workload), 0, 9)));
        exit(XmlHeaderTok + Parameters);
    end;

    local procedure GetWorkloadReportParameters(ShopCode: Code[20]; Workload: Enum "Shpfy Sync Workload"; ShopDataItem: Text; var ReportName: Text; var DataItems: Text): Text
    begin
        case Workload of
            Workload::Products, Workload::Prices:
                exit(GetProductReportParameters(Workload, ShopDataItem, ReportName));
            Workload::Inventory, Workload::Orders, Workload::Shipments:
                exit(GetInventoryOrderShipmentReportParameters(Workload, ShopDataItem, ReportName, DataItems));
            Workload::Customers, Workload::Companies:
                exit(GetCustomerCompanyReportParameters(Workload, ShopDataItem, ReportName, DataItems));
            Workload::"Product Images":
                exit(GetImageReportParameters(ShopDataItem, ReportName));
            Workload::"Posted Invoices":
                exit(GetPostedInvoiceReportParameters(ShopCode, ReportName));
            Workload::"Catalog Prices":
                exit(GetCatalogPriceReportParameters(ShopDataItem, ReportName));
            else
                Error(WorkloadNotSupportedErr, Format(Workload));
        end;
    end;

    local procedure GetProductReportParameters(Workload: Enum "Shpfy Sync Workload"; ShopDataItem: Text; var ReportName: Text): Text
    var
        PriceReportParametersTok: Label '<ReportParameters><Options><Field name="OnlySyncPrices">true</Field><Field name="NumberOfRecords">0</Field></Options><DataItems>%1</DataItems></ReportParameters>', Locked = true;
        ProductsReportParametersTok: Label '<ReportParameters><Options><Field name="OnlySyncPrices">false</Field><Field name="NumberOfRecords">0</Field></Options><DataItems>%1</DataItems></ReportParameters>', Locked = true;
    begin
        ReportName := 'Shpfy Sync Products';
        if Workload = Workload::Products then
            exit(StrSubstNo(ProductsReportParametersTok, ShopDataItem));
        exit(StrSubstNo(PriceReportParametersTok, ShopDataItem));
    end;

    local procedure GetInventoryOrderShipmentReportParameters(Workload: Enum "Shpfy Sync Workload"; ShopDataItem: Text; var ReportName: Text; var DataItems: Text): Text
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        InventoryReportParametersTok: Label '<ReportParameters><Options><Field name="SkipImport">false</Field><Field name="VariantIdFilter"></Field></Options><DataItems>%1</DataItems></ReportParameters>', Locked = true;
        OrdersToImportDataItemTok: Label '<DataItem name="OrdersToImport">VERSION(1) SORTING(Field1)</DataItem>', Locked = true;
        ShipmentReportParametersTok: Label '<ReportParameters><Options /><DataItems><DataItem name="Sales Shipment Header">%1</DataItem></DataItems></ReportParameters>', Locked = true;
    begin
        case Workload of
            Workload::Inventory:
                begin
                    ReportName := 'Shpfy Sync Stock to Shopify';
                    exit(StrSubstNo(InventoryReportParametersTok, ShopDataItem));
                end;
            Workload::Orders:
                begin
                    ReportName := 'Shpfy Sync Orders from Shopify';
                    DataItems := ShopDataItem + OrdersToImportDataItemTok;
                end;
            Workload::Shipments:
                begin
                    ReportName := 'Shpfy Sync Shipm. to Shopify';
                    exit(StrSubstNo(ShipmentReportParametersTok, EscapeXml(SalesShipmentHeader.GetView())));
                end;
        end;
        exit('');
    end;

    local procedure GetCustomerCompanyReportParameters(Workload: Enum "Shpfy Sync Workload"; ShopDataItem: Text; var ReportName: Text; var DataItems: Text): Text
    begin
        if Workload = Workload::Customers then
            ReportName := 'Shpfy Sync Customers'
        else
            ReportName := 'Shpfy Sync Companies';
        DataItems := ShopDataItem;
        exit('');
    end;

    local procedure GetImageReportParameters(ShopDataItem: Text; var ReportName: Text): Text
    var
        ProductImagesReportParametersTok: Label '<ReportParameters><Options><Field name="ProductFilterTxt"></Field></Options><DataItems>%1</DataItems></ReportParameters>', Locked = true;
    begin
        ReportName := 'Shpfy Sync Images';
        exit(StrSubstNo(ProductImagesReportParametersTok, ShopDataItem));
    end;

    local procedure GetPostedInvoiceReportParameters(ShopCode: Code[20]; var ReportName: Text): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedInvoicesReportParametersTok: Label '<ReportParameters><Options><Field name="ShopCode">%1</Field></Options><DataItems><DataItem name="SalesInvoiceHeader">%2</DataItem></DataItems></ReportParameters>', Comment = '%1 = Shop code, %2 = Sales Invoice Header view', Locked = true;
    begin
        ReportName := 'Shpfy Sync Invoices to Shpfy';
        exit(StrSubstNo(PostedInvoicesReportParametersTok, EscapeXml(ShopCode), EscapeXml(SalesInvoiceHeader.GetView())));
    end;

    local procedure GetCatalogPriceReportParameters(ShopDataItem: Text; var ReportName: Text): Text
    var
        ShopifyCatalog: Record "Shpfy Catalog";
        CatalogPricesReportParametersTok: Label '<ReportParameters><Options><Field name="CompanyId"></Field><Field name="CatalogType">0</Field></Options><DataItems>%1<DataItem name="Catalog">%2</DataItem></DataItems></ReportParameters>', Comment = '%1 = Shop data item, %2 = Catalog view', Locked = true;
    begin
        ReportName := 'Shpfy Sync Catalog Prices';
        exit(StrSubstNo(CatalogPricesReportParametersTok, ShopDataItem, EscapeXml(ShopifyCatalog.GetView())));
    end;

    local procedure EscapeXml(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        Value := Value.Replace('"', '&quot;');
        Value := Value.Replace('''', '&apos;');
        exit(Value);
    end;

    local procedure GetScheduledWorkloads(ShopCode: Code[20]; var ScheduledWorkloads: array[10] of Boolean; var HasExistingSchedules: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
    begin
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Report Output Type", JobQueueEntry."Report Output Type"::"None (Processing only)");
        SetShopifyReportFilter(JobQueueEntry);
        JobQueueEntry.SetLoadFields(XML, "Parameter String", "Record ID to Process");
        if JobQueueEntry.FindSet(false) then
            repeat
                if IsRecognizedSchedule(JobQueueEntry, ShopCode, Workload, Coverage) then begin
                    ScheduledWorkloads[Workload.AsInteger()] := true;
                    HasExistingSchedules := true;
                end;
            until JobQueueEntry.Next() = 0;
    end;

    internal procedure BuildExistingScheduleEntries(Shop: Record "Shpfy Shop"; var TempJobQueueEntryBuffer: Record "Job Queue Entry" temporary; var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary)
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        EntryNo: Integer;
    begin
        TempJobQueueEntryBuffer.Reset();
        TempJobQueueEntryBuffer.DeleteAll(false);
        TempRecurringSyncBuffer.Reset();
        TempRecurringSyncBuffer.DeleteAll(false);

        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Report Output Type", JobQueueEntry."Report Output Type"::"None (Processing only)");
        SetShopifyReportFilter(JobQueueEntry);
        JobQueueEntry.SetLoadFields(XML, "Parameter String", "Record ID to Process", "No. of Minutes between Runs", "Starting Time", "Earliest Start Date/Time", Status, Description, "User ID");
        if JobQueueEntry.FindSet(false) then
            repeat
                if IsRecognizedSchedule(JobQueueEntry, Shop.Code, Workload, Coverage) then begin
                    TempJobQueueEntryBuffer := JobQueueEntry;
                    TempJobQueueEntryBuffer.Insert(false);

                    EntryNo += 1;
                    TempRecurringSyncBuffer.Init();
                    TempRecurringSyncBuffer."Entry No." := EntryNo;
                    TempRecurringSyncBuffer.Workload := Workload;
                    TempRecurringSyncBuffer.Synchronization := GetScheduleDirection(Shop, Workload);
                    TempRecurringSyncBuffer."Shop Display" := GetShopDisplay(Shop, Coverage);
                    TempRecurringSyncBuffer.Frequency := JobQueueEntry."No. of Minutes between Runs";
                    TempRecurringSyncBuffer."Starting Time" := JobQueueEntry."Starting Time";
                    TempRecurringSyncBuffer."Next Run Date/Time" := JobQueueEntry."Earliest Start Date/Time";
                    TempRecurringSyncBuffer."Job Queue Status" := GetScheduleStatusDisplay(JobQueueEntry);
                    TempRecurringSyncBuffer.Description := JobQueueEntry.Description;
                    TempRecurringSyncBuffer."Job Queue Entry ID" := JobQueueEntry.ID;
                    TempRecurringSyncBuffer."User ID" := CopyStr(JobQueueEntry."User ID", 1, MaxStrLen(TempRecurringSyncBuffer."User ID"));
                    TempRecurringSyncBuffer.Insert(false);
                end;
            until JobQueueEntry.Next() = 0;
    end;

    internal procedure GetScheduleStatusDisplay(JobQueueEntry: Record "Job Queue Entry"): Text[40]
    var
        RunningLbl: Label 'Running';
    begin
        if JobQueueEntry.Status = JobQueueEntry.Status::"In Process" then
            exit(RunningLbl);
        exit(CopyStr(Format(JobQueueEntry.Status), 1, 40));
    end;

    local procedure SetShopifyReportFilter(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetFilter(
            "Object ID to Run",
            '%1|%2|%3|%4|%5|%6|%7|%8|%9',
            Report::"Shpfy Sync Products",
            Report::"Shpfy Sync Stock to Shopify",
            Report::"Shpfy Sync Orders from Shopify",
            Report::"Shpfy Sync Shipm. to Shopify",
            Report::"Shpfy Sync Customers",
            Report::"Shpfy Sync Companies",
            Report::"Shpfy Sync Images",
            Report::"Shpfy Sync Invoices to Shpfy",
            Report::"Shpfy Sync Catalog Prices");
    end;

    local procedure GetShopDisplay(Shop: Record "Shpfy Shop"; Coverage: Enum "Shpfy Sync Coverage"): Text[250]
    begin
        case Coverage of
            Coverage::"All Shops", Coverage::"Multiple Shops":
                exit(Format(Coverage));
            else
                exit(Shop.Code);
        end;
    end;

    local procedure GetScheduleDirection(Shop: Record "Shpfy Shop"; Workload: Enum "Shpfy Sync Workload"): Enum "Shpfy Sync Direction"
    var
        SyncDirection: Enum "Shpfy Sync Direction";
    begin
        case Workload of
            Workload::Products:
                case Shop."Sync Item" of
                    Shop."Sync Item"::"To Shopify":
                        exit(SyncDirection::"Products to Shopify");
                    Shop."Sync Item"::"From Shopify":
                        exit(SyncDirection::"Products from Shopify");
                    else
                        exit(SyncDirection::Products);
                end;
            Workload::Prices:
                exit(SyncDirection::"Prices to Shopify");
            Workload::Inventory:
                exit(SyncDirection::"Inventory to Shopify");
            Workload::Orders:
                exit(SyncDirection::"Orders from Shopify");
            Workload::Shipments:
                exit(SyncDirection::"Shipments to Shopify");
            Workload::Customers:
                exit(GetCustomerSyncDirection(Shop));
            Workload::Companies:
                exit(GetCompanySyncDirection(Shop));
            Workload::"Product Images":
                case Shop."Sync Item Images" of
                    Shop."Sync Item Images"::"To Shopify":
                        exit(SyncDirection::"Product images to Shopify");
                    Shop."Sync Item Images"::"From Shopify":
                        exit(SyncDirection::"Product images from Shopify");
                    else
                        exit(SyncDirection::"Product images");
                end;
            Workload::"Posted Invoices":
                exit(SyncDirection::"Posted invoices to Shopify");
            Workload::"Catalog Prices":
                exit(SyncDirection::"Catalog prices to Shopify");
        end;
        exit(SyncDirection::Undefined);
    end;

    local procedure AddRecommendation(var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; Workload: Enum "Shpfy Sync Workload"; SyncDirection: Enum "Shpfy Sync Direction"; Frequency: Integer; Description: Text; IsReady: Boolean; IsOutbound: Boolean; AllowOutgoingRequests: Boolean; Details: Text; SetupTarget: Enum "Shpfy Sync Setup Target"; ScheduledWorkloads: array[10] of Boolean)
    var
        OutboundSyncDisabledLbl: Label 'Allow Data Sync to Shopify is turned off. Turn it on before scheduling this synchronization.';
    begin
        if ScheduledWorkloads[Workload.AsInteger()] then
            exit;
        if IsOutbound and not AllowOutgoingRequests then begin
            if Details <> '' then
                Details += ' ';
            Details += OutboundSyncDisabledLbl;
            IsReady := false;
            SetupTarget := SetupTarget::"Shop Card";
        end;

        TempRecurringSyncBuffer.Init();
        TempRecurringSyncBuffer."Entry No." := Workload.AsInteger();
        TempRecurringSyncBuffer.Workload := Workload;
        TempRecurringSyncBuffer.Synchronization := SyncDirection;
        TempRecurringSyncBuffer.Description := CopyStr(Description, 1, MaxStrLen(TempRecurringSyncBuffer.Description));
        TempRecurringSyncBuffer.Frequency := Frequency;
        TempRecurringSyncBuffer.Selectable := IsReady;
        TempRecurringSyncBuffer.Selected := IsReady;
        TempRecurringSyncBuffer.Details := CopyStr(Details, 1, MaxStrLen(TempRecurringSyncBuffer.Details));
        TempRecurringSyncBuffer."Setup Target" := SetupTarget;
        if IsReady then
            TempRecurringSyncBuffer.Readiness := TempRecurringSyncBuffer.Readiness::"Not scheduled"
        else
            TempRecurringSyncBuffer.Readiness := TempRecurringSyncBuffer.Readiness::"Setup required";
        TempRecurringSyncBuffer.Insert(false);
    end;

    local procedure IsCustomerImportEnabled(Shop: Record "Shpfy Shop"): Boolean
    begin
        exit((Shop."Customer Import From Shopify" = Shop."Customer Import From Shopify"::AllCustomers) or
             ((Shop."Customer Import From Shopify" = Shop."Customer Import From Shopify"::WithOrderImport) and Shop."Shopify Can Update Customer"));
    end;

    local procedure IsCompanyImportEnabled(Shop: Record "Shpfy Shop"): Boolean
    begin
        exit((Shop."Company Import From Shopify" = Shop."Company Import From Shopify"::AllCompanies) or
             ((Shop."Company Import From Shopify" = Shop."Company Import From Shopify"::WithOrderImport) and Shop."Shopify Can Update Companies"));
    end;

    local procedure GetCustomerSyncDirection(Shop: Record "Shpfy Shop"): Enum "Shpfy Sync Direction"
    var
        SyncDirection: Enum "Shpfy Sync Direction";
        IsInbound: Boolean;
        IsOutbound: Boolean;
    begin
        IsInbound := IsCustomerImportEnabled(Shop);
        IsOutbound := Shop."Can Update Shopify Customer";
        if IsInbound and IsOutbound then
            exit(SyncDirection::"Customers to/from Shopify");
        if IsInbound then
            exit(SyncDirection::"Customers from Shopify");
        if IsOutbound then
            exit(SyncDirection::"Customers to Shopify");
        exit(SyncDirection::Customers);
    end;

    local procedure GetCompanySyncDirection(Shop: Record "Shpfy Shop"): Enum "Shpfy Sync Direction"
    var
        SyncDirection: Enum "Shpfy Sync Direction";
        IsInbound: Boolean;
        IsOutbound: Boolean;
    begin
        IsInbound := IsCompanyImportEnabled(Shop);
        IsOutbound := Shop."Can Update Shopify Companies";
        if IsInbound and IsOutbound then
            exit(SyncDirection::"Companies to/from Shopify");
        if IsInbound then
            exit(SyncDirection::"Companies from Shopify");
        if IsOutbound then
            exit(SyncDirection::"Companies to Shopify");
        exit(SyncDirection::Companies);
    end;

    local procedure HasParticipatingInventoryLocation(ShopCode: Code[20]): Boolean
    var
        ShopifyShopLocation: Record "Shpfy Shop Location";
    begin
        ShopifyShopLocation.SetRange("Shop Code", ShopCode);
        ShopifyShopLocation.SetFilter("Stock Calculation", '<>%1', Enum::"Shpfy Stock Calculation"::Disabled);
        exit(not ShopifyShopLocation.IsEmpty());
    end;

    local procedure HasInvoicePaymentTerms(ShopCode: Code[20]): Boolean
    var
        ShopifyPaymentTerms: Record "Shpfy Payment Terms";
    begin
        ShopifyPaymentTerms.SetRange("Shop Code", ShopCode);
        if ShopifyPaymentTerms.FindSet(false) then
            repeat
                if (ShopifyPaymentTerms."Payment Terms Code" <> '') or ShopifyPaymentTerms."Is Primary" then
                    exit(true);
            until ShopifyPaymentTerms.Next() = 0;
        exit(false);
    end;

    local procedure IsRecurringShopifyReport(JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        if not JobQueueEntry."Recurring Job" then
            exit(false);
        if JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Report then
            exit(false);
        if JobQueueEntry."Object ID to Run" = 0 then
            exit(false);
        if JobQueueEntry."Report Output Type" <> JobQueueEntry."Report Output Type"::"None (Processing only)" then
            exit(false);
        if JobQueueEntry."Parameter String" <> '' then
            exit(false);
        if JobQueueEntry."Record ID to Process".TableNo() <> 0 then
            exit(false);
        exit(true);
    end;

    local procedure ParseParameters(ParameterText: Text; var ParametersDocument: XmlDocument): Boolean
    var
        DataItemsXPathTok: Label '/ReportParameters/DataItems', Locked = true;
        OptionsXPathTok: Label '/ReportParameters/Options', Locked = true;
        ReportParametersXPathTok: Label '/ReportParameters', Locked = true;
        ParametersNode: XmlNode;
        DataItemsNodeList: XmlNodeList;
        OptionsNodeList: XmlNodeList;
    begin
        if ParameterText = '' then
            exit(false);
        if not ReadXml(ParameterText, ParametersDocument) then
            exit(false);
        if not ParametersDocument.SelectSingleNode(ReportParametersXPathTok, ParametersNode) then
            exit(false);
        if not ParametersDocument.SelectNodes(OptionsXPathTok, OptionsNodeList) then
            exit(false);
        if OptionsNodeList.Count() <> 1 then
            exit(false);
        if not ParametersDocument.SelectNodes(DataItemsXPathTok, DataItemsNodeList) then
            exit(false);
        if DataItemsNodeList.Count() <> 1 then
            exit(false);
        exit(true);
    end;

    [TryFunction]
    local procedure ReadXml(ParameterText: Text; var ParametersDocument: XmlDocument)
    begin
        XmlDocument.ReadFrom(ParameterText, ParametersDocument);
    end;

    local procedure ParseProductWorkload(ParametersDocument: XmlDocument; var Workload: Enum "Shpfy Sync Workload"): Boolean
    var
        NumberOfRecords: Text;
        OnlySyncPrice: Text;
    begin
        if not HasExpectedOptions(ParametersDocument, 'OnlySyncPrices,RecordCount') then
            exit(false);

        OnlySyncPrice := GetOptionText(ParametersDocument, 'OnlySyncPrices');
        NumberOfRecords := GetOptionText(ParametersDocument, 'RecordCount');
        if not IsFalseOrEmpty(OnlySyncPrice) and not IsTrue(OnlySyncPrice) then
            exit(false);
        if (NumberOfRecords <> '') and (NumberOfRecords <> '0') then
            exit(false);
        if IsTrue(OnlySyncPrice) then
            Workload := Workload::Prices
        else
            Workload := Workload::Products;
        exit(true);
    end;

    local procedure HasExpectedOptions(ParametersDocument: XmlDocument; ExpectedNames: Text): Boolean
    var
        ExpectedCount: Integer;
        OptionCount: Integer;
        SeparatorPosition: Integer;
        AllOptionsXPathTok: Label '/ReportParameters/Options/*', Locked = true;
        OptionName: Text;
        OptionsNodeList: XmlNodeList;
    begin
        ExpectedCount := 0;
        while ExpectedNames <> '' do begin
            SeparatorPosition := StrPos(ExpectedNames, ',');
            if SeparatorPosition = 0 then begin
                OptionName := ExpectedNames;
                ExpectedNames := '';
            end else begin
                OptionName := CopyStr(ExpectedNames, 1, SeparatorPosition - 1);
                ExpectedNames := CopyStr(ExpectedNames, SeparatorPosition + 1);
            end;
            OptionCount := GetOptionCount(ParametersDocument, OptionName);
            if OptionCount <> 1 then
                exit(false);
            ExpectedCount += OptionCount;
        end;
        if not ParametersDocument.SelectNodes(AllOptionsXPathTok, OptionsNodeList) then
            exit(ExpectedCount = 0);
        exit(OptionsNodeList.Count() = ExpectedCount);
    end;

    local procedure HasOption(ParametersDocument: XmlDocument; OptionName: Text): Boolean
    begin
        exit(GetOptionCount(ParametersDocument, OptionName) = 1);
    end;

    local procedure GetOptionText(ParametersDocument: XmlDocument; OptionName: Text): Text
    var
        OptionNode: XmlNode;
    begin
        if not HasOption(ParametersDocument, OptionName) then
            exit('');
        ParametersDocument.SelectSingleNode(GetOptionXPath(OptionName), OptionNode);
        exit(OptionNode.AsXmlElement().InnerText());
    end;

    local procedure GetOptionCount(ParametersDocument: XmlDocument; OptionName: Text): Integer
    var
        OptionNodeList: XmlNodeList;
    begin
        if not ParametersDocument.SelectNodes(GetOptionXPath(OptionName), OptionNodeList) then
            exit(0);
        exit(OptionNodeList.Count());
    end;

    local procedure GetOptionXPath(OptionName: Text): Text
    var
        CatalogTypeXPathTok: Label '/ReportParameters/Options/Field[@name="CatalogType"] | /ReportParameters/Options/CatalogType | /ReportParameters/Options/ShopifyCatalogType', Locked = true;
        CompanyIdXPathTok: Label '/ReportParameters/Options/Field[@name="CompanyId"] | /ReportParameters/Options/CompanyId | /ReportParameters/Options/ShopifyCompanyId', Locked = true;
        OnlySyncPricesXPathTok: Label '/ReportParameters/Options/Field[@name="OnlySyncPrices"] | /ReportParameters/Options/OnlySyncPrices | /ReportParameters/Options/OnlySyncPrice', Locked = true;
        OptionXPathTok: Label '/ReportParameters/Options/%1', Locked = true;
        ProductFilterXPathTok: Label '/ReportParameters/Options/Field[@name="ProductFilterTxt"] | /ReportParameters/Options/ProductFilterTxt | /ReportParameters/Options/ProductFilter', Locked = true;
        RecordCountXPathTok: Label '/ReportParameters/Options/Field[@name="RecordCount" or @name="NumberOfRecords"] | /ReportParameters/Options/RecordCount | /ReportParameters/Options/NumberOfRecords', Locked = true;
        ShopCodeXPathTok: Label '/ReportParameters/Options/Field[@name="ShopCode"] | /ReportParameters/Options/ShopCode | /ReportParameters/Options/Shop', Locked = true;
        SkipImportXPathTok: Label '/ReportParameters/Options/Field[@name="SkipImport"] | /ReportParameters/Options/SkipImport | /ReportParameters/Options/Skip_x0020_Import', Locked = true;
        VariantIdFilterXPathTok: Label '/ReportParameters/Options/Field[@name="VariantIdFilter"] | /ReportParameters/Options/VariantIdFilter | /ReportParameters/Options/Variant_x0020_ID_x0020_Filter', Locked = true;
    begin
        case OptionName of
            'OnlySyncPrices':
                exit(OnlySyncPricesXPathTok);
            'RecordCount':
                exit(RecordCountXPathTok);
            'SkipImport':
                exit(SkipImportXPathTok);
            'VariantIdFilter':
                exit(VariantIdFilterXPathTok);
            'ProductFilterTxt':
                exit(ProductFilterXPathTok);
            'ShopCode':
                exit(ShopCodeXPathTok);
            'CompanyId':
                exit(CompanyIdXPathTok);
            'CatalogType':
                exit(CatalogTypeXPathTok);
        end;
        exit(StrSubstNo(OptionXPathTok, OptionName));
    end;

    local procedure ReadShopDataItemFilter(ParametersDocument: XmlDocument; AllowedDataItemNames: Text; AdditionalDataItemName: Text; var ShopFilter: Text): Boolean
    var
        AdditionalFilter: Text;
    begin
        if not ReadCodeDataItemFilter(ParametersDocument, 'Shop', ShopFilter) then
            exit(false);
        if AdditionalDataItemName <> '' then
            if not ReadUnfilteredDataItemText(ParametersDocument, AdditionalDataItemName, AdditionalFilter) or (AdditionalFilter <> '') then
                exit(false);
        exit(HasExpectedDataItems(ParametersDocument, AllowedDataItemNames));
    end;

    local procedure HasUnfilteredDataItem(ParametersDocument: XmlDocument; DataItemName: Text): Boolean
    var
        FilterText: Text;
    begin
        if not ReadUnfilteredDataItemText(ParametersDocument, DataItemName, FilterText) then
            exit(false);
        if FilterText <> '' then
            exit(false);
        exit(HasExpectedDataItems(ParametersDocument, DataItemName));
    end;

    local procedure ReadCodeDataItemFilter(ParametersDocument: XmlDocument; DataItemName: Text; var FilterText: Text): Boolean
    var
        FilterStart: Integer;
        DataItemFilter: Text;
    begin
        if not ReadUnfilteredDataItemText(ParametersDocument, DataItemName, DataItemFilter) then
            exit(false);
        if DataItemFilter = '' then begin
            FilterText := '';
            exit(true);
        end;
        if IsRecordView(DataItemFilter) then
            exit(ReadRecordViewFilter(DataItemFilter, DataItemName, FilterText));

        FilterStart := StrPos(DataItemFilter, 'Code=');
        if FilterStart = 0 then
            exit(false);
        if CopyStr(DataItemFilter, 1, FilterStart - 1) <> '' then
            exit(false);
        FilterText := CopyStr(DataItemFilter, FilterStart + StrLen('Code='));
        if FilterText = '' then
            exit(false);
        if FilterText.StartsWith('FILTER(') and FilterText.EndsWith(')') then begin
            FilterText := CopyStr(FilterText, StrLen('FILTER(') + 1, StrLen(FilterText) - StrLen('FILTER(') - 1);
            if FilterText = '' then
                exit(false);
        end;
        exit(true);
    end;

    local procedure ReadUnfilteredDataItemText(ParametersDocument: XmlDocument; DataItemName: Text; var FilterText: Text): Boolean
    var
        SeparatorPosition: Integer;
        DataItemText: Text;
        DataItemNode: XmlNode;
        DataItemNodeList: XmlNodeList;
    begin
        FilterText := '';
        if not ParametersDocument.SelectNodes(StrSubstNo(DataItemXPathTok, DataItemName), DataItemNodeList) then
            exit(false);
        if DataItemNodeList.Count() <> 1 then
            exit(false);
        if not ParametersDocument.SelectSingleNode(StrSubstNo(DataItemXPathTok, DataItemName), DataItemNode) then
            exit(false);

        DataItemText := DataItemNode.AsXmlElement().InnerText();
        if DataItemText = '' then
            exit(false);
        if IsRecordView(DataItemText) then begin
            if not ReadRecordViewFilter(DataItemText, DataItemName, FilterText) then
                exit(false);
            if FilterText <> '' then
                FilterText := DataItemText;
            exit(true);
        end;

        SeparatorPosition := StrPos(DataItemText, ': ');
        if SeparatorPosition = 0 then
            exit(not (StrPos(DataItemText, '=') > 0));
        FilterText := CopyStr(DataItemText, SeparatorPosition + StrLen(': '));
        exit(true);
    end;

    local procedure IsRecordView(Value: Text): Boolean
    var
        SortingPrefixTok: Label 'SORTING(', Locked = true;
        VersionPrefixTok: Label 'VERSION(', Locked = true;
    begin
        exit(Value.StartsWith(VersionPrefixTok) or Value.StartsWith(SortingPrefixTok));
    end;

    local procedure ReadRecordViewFilter(ViewText: Text; DataItemName: Text; var FilterText: Text): Boolean
    var
        DataItemRecord: RecordRef;
        CodeField: FieldRef;
        HasUnsupportedFilters: Boolean;
    begin
        case DataItemName of
            'Shop':
                DataItemRecord.Open(Database::"Shpfy Shop");
            'OrdersToImport':
                DataItemRecord.Open(Database::"Shpfy Orders to Import");
            'Catalog':
                DataItemRecord.Open(Database::"Shpfy Catalog");
            'SalesInvoiceHeader':
                DataItemRecord.Open(Database::"Sales Invoice Header");
            'Sales Shipment Header':
                DataItemRecord.Open(Database::"Sales Shipment Header");
            else
                exit(false);
        end;
        if not SetRecordView(DataItemRecord, ViewText) then begin
            DataItemRecord.Close();
            exit(false);
        end;

        FilterText := '';
        if DataItemName = 'Shop' then begin
            CodeField := DataItemRecord.Field(1);
            FilterText := CodeField.GetFilter();
            CodeField.SetRange();
        end;
        HasUnsupportedFilters := DataItemRecord.HasFilter();
        DataItemRecord.Close();
        exit(not HasUnsupportedFilters);
    end;

    [TryFunction]
    local procedure SetRecordView(var DataItemRecord: RecordRef; ViewText: Text)
    begin
        DataItemRecord.SetView(ViewText);
    end;

    local procedure HasExpectedDataItems(ParametersDocument: XmlDocument; ExpectedNames: Text): Boolean
    var
        ExpectedCount: Integer;
        SeparatorPosition: Integer;
        AllDataItemsXPathTok: Label '/ReportParameters/DataItems/DataItem', Locked = true;
        DataItemName: Text;
        DataItemsNodeList: XmlNodeList;
        ExpectedDataItemNodeList: XmlNodeList;
    begin
        ExpectedCount := 0;
        while ExpectedNames <> '' do begin
            SeparatorPosition := StrPos(ExpectedNames, ',');
            if SeparatorPosition = 0 then begin
                DataItemName := ExpectedNames;
                ExpectedNames := '';
            end else begin
                DataItemName := CopyStr(ExpectedNames, 1, SeparatorPosition - 1);
                ExpectedNames := CopyStr(ExpectedNames, SeparatorPosition + 1);
            end;
            if not ParametersDocument.SelectNodes(StrSubstNo(DataItemXPathTok, DataItemName), ExpectedDataItemNodeList) then
                exit(false);
            if ExpectedDataItemNodeList.Count() <> 1 then
                exit(false);
            ExpectedCount += 1;
        end;
        if not ParametersDocument.SelectNodes(AllDataItemsXPathTok, DataItemsNodeList) then
            exit(ExpectedCount = 0);
        exit(DataItemsNodeList.Count() = ExpectedCount);
    end;

    local procedure DetermineShopCoverage(ShopFilter: Text; CurrentShopCode: Code[20]; var Coverage: Enum "Shpfy Sync Coverage"): Boolean
    var
        CurrentShopIsIncluded: Boolean;
        MatchingShopCount: Integer;
    begin
        if ShopFilter = '' then begin
            Coverage := Coverage::"All Shops";
            exit(true);
        end;
        if CurrentShopCode = '' then
            exit(false);
        if not EvaluateShopFilter(ShopFilter, CurrentShopCode, MatchingShopCount, CurrentShopIsIncluded) then
            exit(false);
        if not CurrentShopIsIncluded then begin
            Coverage := Coverage::"Other Shops";
            exit(true);
        end;
        if MatchingShopCount > 1 then
            Coverage := Coverage::"Multiple Shops"
        else
            Coverage := Coverage::"Current Shop";
        exit(true);
    end;

    [TryFunction]
    local procedure EvaluateShopFilter(ShopFilter: Text; CurrentShopCode: Code[20]; var MatchingShopCount: Integer; var CurrentShopIsIncluded: Boolean)
    var
        ShopifyShop: Record "Shpfy Shop";
    begin
        ShopifyShop.SetFilter(Code, ShopFilter);
        MatchingShopCount := ShopifyShop.Count();
        ShopifyShop.FilterGroup(2);
        ShopifyShop.SetRange(Code, CurrentShopCode);
        ShopifyShop.FilterGroup(0);
        CurrentShopIsIncluded := not ShopifyShop.IsEmpty();
    end;

    local procedure IsFalse(Value: Text): Boolean
    begin
        exit(LowerCase(Value) in ['', 'false', 'no', '0']);
    end;

    local procedure IsFalseOrEmpty(Value: Text): Boolean
    begin
        exit(IsFalse(Value));
    end;

    local procedure IsTrue(Value: Text): Boolean
    begin
        exit(LowerCase(Value) in ['true', 'yes', '1']);
    end;

    local procedure IsDefaultCatalogType(Value: Text): Boolean
    begin
        exit(Value in ['', ' ', '0']);
    end;
}
