// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using System.Environment;
using System.Utilities;

/// <summary>
/// Manage the size of your database. The guide will suggest ways to clean up expired records.
/// </summary>

page 9040 "Data Administration Guide"
{
    Caption = 'Data Administration Guide';
    PageType = NavigatePage;
    LinksAllowed = false;
    ShowFilter = false;
    Extensible = true;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            group(Banner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinishVisible;
                field(TopBanner; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(BannerDone)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and FinishVisible;
                field(TopBannerDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(Intro)
            {
                ShowCaption = false;
                Visible = CurrentPage = CurrentPage::Introduction;

                group(Intro1)
                {
                    Visible = CurrentPage = CurrentPage::Introduction;
                    ShowCaption = false;
                    InstructionalText = 'Welcome to the Data Administration guide. This guide will help you clean up various types of data in a company. You can run this guide again for each company.';
                }
                group(Intro2)
                {
                    Visible = CurrentPage = CurrentPage::Introduction;
                    ShowCaption = false;
                    InstructionalText = 'Over time, data accumulates in the database and not all of it stays relevant. For example, you may have log entries, copies of companies, or ledger entries that you no longer need. This guide will help you remove unneeded data in a safe way.';
                }
                group(Intro3)
                {
                    Visible = CurrentPage = CurrentPage::Introduction;
                    ShowCaption = false;
                    InstructionalText = 'You can run this guide again for each company.';
                }
            }
            group(RetentionPolicies)
            {
                Visible = CurrentPage = CurrentPage::RetenPolIntro;
                Caption = 'Retention Policies';
                InstructionalText = 'You can set up retention policies to automatically remove expired records. Click the link below to view the current list of retention policies and set up new ones.';

                field(RetenPolSetupCount; StrSubstNo(EnabledRetentionPolicyCountTxt, EnabledRetentionPolicyCount(), MaxRetentionPolicyCount()))
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                }
                field(RetentionPolicySetupList; OpenRetentionPolicySetupListTxt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Page.Runmodal(Page::"Retention Policy Setup List");
                    end;
                }
                group(RetentionPoliciesDocs)
                {
                    ShowCaption = false;
                    Visible = CurrentPage = CurrentPage::RetenPolIntro;

                    field(RetentionPoliciesDocsField; RetentionPoliciesDocsTxt)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(RetentionPoliciesUrlTxt);
                        end;
                    }
                }
            }
            group(Companies)
            {
                Visible = CurrentPage = CurrentPage::CompaniesIntro;
                Caption = 'Unused Companies';
                InstructionalText = 'Companies take up a lot of space in the database. If you no longer need an evaluation company, for example, consider deleting it. Click the link below to open the list of companies.';

                field(NonProdCompanyCount; StrSubstNo(NonProductionCompanyCountTxt, NonProductionCompanyCount()))
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                }
                field(CompaniesListLink; OpenCompaniesListTxt)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Page.RunModal(Page::Companies);
                    end;
                }
            }
            group(DateCompressionIntro)
            {
                Visible = CurrentPage = CurrentPage::DateCompressionIntro;
                Caption = 'Date Compression';
                InstructionalText = 'Over time, ledger entries can increase the size of your database. Use date compression to summarize the entries from a specific period of time, and keep only the most important information. Before you compress data, be sure that the dates are outside the period of time that your local authorities require you to keep detailed records.';
            }
            group(DefaultDateCompressionOptions)
            {
                ShowCaption = false;
                Visible = CurrentPage = CurrentPage::DateCompressionIntro;
                InstructionalText = 'The guide will run date compression using default options for a high level of compression. For more control over the details to keep, skip this step and compress each type of entry individually.';
            }
            group(DateCompressionWarning)
            {
                Visible = CurrentPage = CurrentPage::DateCompressionIntro;
                ShowCaption = false;
                InstructionalText = 'Date compression cannot be undone. Before you start, we recommend that you create a backup of the database.';
                field(DateCompressionDocs; DateCompressionDocsTxt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(DateCompressionUrlTxt);
                    end;
                }
            }
            group(DateCompressionEntrySelection)
            {
                ShowCaption = false;
                Visible = CurrentPage = CurrentPage::DateCompressionSelection;
                group(Fixed)
                {
                    Caption = 'Date Compression: Select entries';
                    InstructionalText = 'Choose which entries you would like to date compress:';

                    field(DateCompressGLEntries; DateComprSettingsBuffer."Compress G/L Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Entries';
                        ToolTip = 'G/L Entries';
                    }
                    field(DateCompressVATEntries; DateComprSettingsBuffer."Compress VAT Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Entries';
                        ToolTip = 'VAT Entries';
                    }
                    field(DateCompressBankAccLedgerEntries; DateComprSettingsBuffer."Compr. Bank Acc. Ledg Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Ledger Entries';
                        ToolTip = 'Bank Account Ledger Entries';
                    }
                    field(DateCompressGLBudgetEntries; DateComprSettingsBuffer."Compress G/L Budget Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Budget Entries';
                        ToolTip = 'G/L Budget Entries';
                    }
                    field(DateCompressCustomerLedgEntries; DateComprSettingsBuffer."Compr. Customer Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Ledger Entries';
                        ToolTip = 'Customer Ledger Entries';
                    }
                    field(DateCompressVendorLedgEntries; DateComprSettingsBuffer."Compress Vendor Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Ledger Entries';
                        ToolTip = 'Vendor Ledger Entries';
                    }
                    field(DateCompressResourceLedgEntries; DateComprSettingsBuffer."Compr. Resource Ledger Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Ledger Entries';
                        ToolTip = 'Resource Ledger Entries';
                    }
                    field(DateCompressFALedgEntries; DateComprSettingsBuffer."Compress FA Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Fixed Asset Ledger Entries';
                        ToolTip = 'Fixed Asset Ledger Entries';
                    }
                    field(DateCompressMaintenanceLedgEntries; DateComprSettingsBuffer."Compr. Maintenance Ledg. Entr.")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Maintenance Ledger Entries';
                        ToolTip = 'FA Maintenance Ledger Entries';
                    }
                    field(DateCompressInsuranceLedgEntries; DateComprSettingsBuffer."Compr. Insurance Ledg. Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Insurance Ledger Entries';
                        ToolTip = 'FA Insurance Ledger Entries';
                    }
                    field(DateCompressWarehouseEntries; DateComprSettingsBuffer."Compress Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Entries';
                        ToolTip = 'Warehouse Entries';
                    }
                    field(DateCompressItemBudgetEntries; DateComprSettingsBuffer."Compress Item Budget Entries")
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Item Budget Entries';
                        ToolTip = 'Item Budget Entries';
                    }
                }
            }
            group(DateCompressionOptions)
            {
                ShowCaption = false;
                Visible = CurrentPage = CurrentPage::DateCompressionOptions;

                group(DateCompressionOptionsSub)
                {
                    Caption = 'Date Compression: Options';
                    InstructionalText = 'Select the options to be used to compress entries. Please consult with your accountant about mandatory retention periods for ledger entries.';

                    field(StartingDate; DateComprSettingsBuffer."Starting Date")
                    {
                        ApplicationArea = All;
                        Caption = 'Starting Date';
                        ClosingDates = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(DateComprSettingsBuffer."Starting Date", DateComprSettingsBuffer."Ending Date");
                        end;
                    }
                    field(EndingDate; DateComprSettingsBuffer."Ending Date")
                    {
                        ApplicationArea = All;
                        Caption = 'Ending Date';
                        ClosingDates = true;
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(DateComprSettingsBuffer."Starting Date", DateComprSettingsBuffer."Ending Date");
                        end;
                    }
                    field(PeriodLength; DateComprSettingsBuffer."Period Length")
                    {
                        ApplicationArea = All;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(EntryDescription; DateComprSettingsBuffer.Description)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a text that accompanies the entries that result from the compression. The default description is Date Compressed.';
                        ShowMandatory = true;
                    }
                }
            }
            group(DateCompressionOptions2)
            {
                ShowCaption = false;
                Visible = CurrentPage = CurrentPage::DateCompressionOptions2;
                group(RetainDimensions)
                {
                    Caption = 'Date Compression: Options';
                    InstructionalText = 'Select the dimension information that you want to retain. The compressed entries will be summarized by the dimensions you select. Selecting more dimensions will result in less compression. Dimensions used in analysis views will be retained automatically.';
                    field(RetainDimText;
                    DateComprSettingsBuffer."Retain Dimensions")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Retain Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies which dimension information you want to retain when the entries are compressed. The more dimension information that you choose to retain, the more detailed the compressed entries are. Any dimension code specified in an Analisys View will be retained.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(8 /*ObjectType::Page*/, Page::"Data Administration Guide", DateComprSettingsBuffer."Retain Dimensions");
                        end;
                    }
                }
                group(EmptyRegisters)
                {
                    ShowCaption = false;
                    InstructionalText = 'Enable this option to delete any empty registers after date compressing entries:';

                    field(DeleteEmptyRegisters; DateComprSettingsBuffer."Delete Empty Registers")
                    {
                        ApplicationArea = All;
                        Caption = 'Delete Empty Registers';
                        ToolTip = 'Delete empty registers after date compressing entries.';
                    }
                }
            }
            group(DateCompressionRun)
            {
                Caption = 'Date Compression: Run';
                Visible = CurrentPage = CurrentPage::DateCompressionRun;
                InstructionalText = 'Analysis Views must be up to date before compressing ledger entries. When you click Next, the analysis views will be updated and the selected ledger entries will be compressed using the options you specified.';
            }
            group(DateCompressionResult)
            {
                Caption = 'Date Compression: Result';
                Visible = CurrentPage = CurrentPage::DateCompressionResult;

                field(DateCompressionRemovedEntries; StrSubstNo(DateCompressionRemovedEntriesTxt, DateComprSettingsBuffer."No. of Records Removed", DateComprSettingsBuffer."Saved Space (MB)"))
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    ToolTip = 'The number of entries removed and database space saved by date compression in the last run.';
                    MultiLine = true;
                }
            }
            group(Conclusion)
            {
                Visible = CurrentPage = CurrentPage::Conclusion;
                ShowCaption = false;
                InstructionalText = 'All done. You can always re-run this guide to clean up more records. Click Finish to close the guide.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Skip)
            {
                ApplicationArea = All;
                Caption = 'Skip';
                Visible = SkipVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep();
                end;
            }
            action(Previous)
            {
                ApplicationArea = All;
                Caption = 'Previous';
                Enabled = PreviousEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    PreviousPage();
                end;
            }
            action(Next)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextEnabled;
                Visible = NextVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextPage();
                end;
            }
            action(DateCompress)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Visible = CurrentPage = CurrentPage::DateCompressionRun;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    DateCompression: Codeunit "Date Compression";
                begin
                    DateCompression.RunDateCompression(DateComprSettingsBuffer);
                    NextPage();
                end;
            }
            action(Finish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Visible = FinishVisible;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishGuide();
                end;
            }
        }
    }

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DimSelectionBuf: Record "Dimension Selection Buffer";
        ClientTypeManagement: Codeunit "Client Type Management";
        Pages: List of [Enum "Data Administration Guide Page"];
        SkipTo: Dictionary of [Enum "Data Administration Guide Page", Enum "Data Administration Guide Page"];
        HideNext: List of [Enum "Data Administration Guide Page"];
        CurrentPage: Enum "Data Administration Guide Page";
        PrevPage: Enum "Data Administration Guide Page";
        PreviousEnabled: Boolean;
        SkipVisible: Boolean;
        NextEnabled: Boolean;
        NextVisible: Boolean;
        FinishVisible: Boolean;
        TopBannerVisible: Boolean;
        OpenCompaniesListTxt: Label 'Open the list of companies.';
        OpenRetentionPolicySetupListTxt: Label 'Open the list of retention policies.';
        EnabledRetentionPolicyCountTxt: Label '%1 out of %2 available retention policies are enabled.', Comment = '%1 and %2 are integers as in: 3 out of 5 available...';
        NonProductionCompanyCountTxt: Label 'There are %1 non-production companies in the database.', Comment = '%1 is an integer.';
        DateCompressionDocsTxt: Label 'Click here to learn more about date compression in Business Central.';
        DateCompressionUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2158496';
        DateCompressionRemovedEntriesTxt: Label 'Date compression has reduced the number of entries by %1 which has freed up %2 MB of space in the database.', Comment = '%1 = integer number of entries, %2 = decimal MB of space saved.';
        TelemOpenDataAdminGuideLbl: Label 'The Data Administration Guide was opened.', Locked = true;
        TelemNavigateDataAdminGuideLbl: Label 'The user navigated on the Data Administration Guide.', Locked = true;
        TelemSkipDataAdminGuideLbl: Label 'The user skipped to next step on the Data Administration Guide.', Locked = true;
        TelemCloseDataAdminGuideLbl: Label 'The Data Administration Guide was closed.', Locked = true;
        RetentionPoliciesDocsTxt: Label 'Click here to learn more about retention policies in Business Central.';
        RetentionPoliciesUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2163439';

    trigger OnOpenPage()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        InitGuide();
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;

        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        SendTelemetryOnOpenPage();
    end;

    trigger OnClosePage()
    begin
        SendTelemetryOnClosePage();
    end;

    local procedure UpdateControls()
    begin
        SkipVisible := SkipTo.ContainsKey(CurrentPage);
        PreviousEnabled := Pages.IndexOf(CurrentPage) > 1;
        NextEnabled := Pages.IndexOf(CurrentPage) < Pages.Count();
        NextVisible := not HideNext.Contains(CurrentPage);
        FinishVisible := Pages.IndexOf(CurrentPage) = Pages.Count();
        OnAfterUpdateControls(CurrentPage);
        SendTelemetryOnUpdateControls();
    end;

    local procedure PreviousPage()
    begin
        if PrevPage <> PrevPage::Blank then begin
            CurrentPage := PrevPage;
            PrevPage := PrevPage::Blank;
        end else
            Pages.Get(Pages.IndexOf(CurrentPage) - 1, CurrentPage);
        UpdateControls();
    end;

    local procedure NextStep()
    begin
        PrevPage := CurrentPage;
        SkipTo.Get(CurrentPage, CurrentPage);
        SendTelemetryOnSkip();
        UpdateControls();
    end;

    protected procedure NextPage()
    begin
        Pages.Get(Pages.IndexOf(CurrentPage) + 1, CurrentPage);
        UpdateControls();
    end;

    local procedure FinishGuide()
    begin
        CurrPage.Close();
    end;

    local procedure InitGuide()
    begin
        LoadPages();
        Pages.Get(1, CurrentPage);
        UpdateControls();
    end;

    local procedure LoadPages()
    begin
        Pages.Add(CurrentPage::Introduction);
        Pages.Add(CurrentPage::RetenPolIntro);
        Pages.Add(CurrentPage::CompaniesIntro);
        Pages.Add(CurrentPage::DateCompressionIntro);
        Pages.Add(CurrentPage::DateCompressionSelection);
        Pages.Add(CurrentPage::DateCompressionOptions);
        Pages.Add(CurrentPage::DateCompressionOptions2);
        Pages.Add(CurrentPage::DateCompressionRun);
        Pages.Add(CurrentPage::DateCompressionResult);
        Pages.Add(CurrentPage::Conclusion);

        SkipTo.Add(CurrentPage::DateCompressionIntro, CurrentPage::Conclusion);
        SkipTo.Add(CurrentPage::DateCompressionRun, CurrentPage::Conclusion);

        HideNext.Add(CurrentPage::DateCompressionRun);

        OnAfterLoadPages(Pages, SkipTo, HideNext);
    end;

    local procedure MaxRetentionPolicyCount(): Integer
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        AllowedTables: List of [Integer];
    begin
        RetenPolAllowedTables.GetAllowedTables(AllowedTables);
        exit(AllowedTables.Count());
    end;

    local procedure EnabledRetentionPolicyCount(): Integer
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        RetentionPolicySetup.SetRange(Enabled, true);
        exit(RetentionPolicySetup.Count());
    end;

    local procedure NonProductionCompanyCount(): Integer
    var
        Company: Record Company;
    begin
        Company.SetRange("Evaluation Company", false);
        exit(Company.Count());
    end;

    local procedure SendTelemetryOnOpenPage()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        // TelemetryDimensions.Add('CompanyName', CompanyName()); // OrganizationIdentifiableInformation
        TelemetryDimensions.Add('Pages', Format(Pages, 0, 9));

        Session.LogMessage('0000F54', TelemOpenDataAdminGuideLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    local procedure SendTelemetryOnSkip()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        // TelemetryDimensions.Add('CompanyName', CompanyName());
        TelemetryDimensions.Add('PreviousPage', Format(PrevPage, 0, 9));
        TelemetryDimensions.Add('CurrentPage', Format(CurrentPage, 0, 9));

        Session.LogMessage('0000F55', TelemSkipDataAdminGuideLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;


    local procedure SendTelemetryOnUpdateControls()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        // TelemetryDimensions.Add('CompanyName', CompanyName());
        TelemetryDimensions.Add('PreviousPage', Format(PrevPage, 0, 9));
        TelemetryDimensions.Add('CurrentPage', Format(CurrentPage, 0, 9));

        Session.LogMessage('0000F56', TelemNavigateDataAdminGuideLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    local procedure SendTelemetryOnClosePage()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        // TelemetryDimensions.Add('CompanyName', CompanyName());
        TelemetryDimensions.Add('CurrentPage', Format(CurrentPage, 0, 9));

        Session.LogMessage('0000F57', TelemCloseDataAdminGuideLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    /// <summary>
    /// Use this event to add new pages to the guide.
    /// </summary>
    /// <param name="Pages">The list of pages that make up the guide.</param>
    /// <param name="SkipTo">A dictionary which defines which pages allow skipping to another page. The dictionary key is the page from which you can skip, the value is the page to which you can skip.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterLoadPages(var GuidePages: List of [Enum "Data Administration Guide Page"]; var SkipTo: Dictionary of [Enum "Data Administration Guide Page", Enum "Data Administration Guide Page"]; var HideNext: List of [Enum "Data Administration Guide Page"])
    begin
    end;

    /// <summary>
    /// Use this event to set the visibility of pages in the guide.
    /// </summary>
    /// <param name="CurrentPage">The current page of the guide.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateControls(CurrentPage: Enum "Data Administration Guide Page");
    begin
    end;
}