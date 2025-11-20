namespace System.Integration;

using Microsoft.CRM.Duplicates;
using Microsoft.Finance.GeneralLedger.Account;
using System.Apps;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Setup;
using Microsoft.Utilities;
using System.Environment;
using System.Environment.Configuration;
using System.Utilities;

page 1808 "Data Migration Wizard"
{
    AdditionalSearchTerms = 'implementation,data setup,rapid start,quickbooks';
    ApplicationArea = Basic, Suite;
    Caption = 'Data Migration';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Data Migrator Registration";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not DoneVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and DoneVisible;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                Visible = IntroVisible;
                group("Welcome to Data Migration assisted setup guide")
                {
                    Caption = 'Welcome to Data Migration assisted setup guide';
                    InstructionalText = 'You can import data from other finance solutions and other data sources, provided that the corresponding extension is available to handle the conversion. To see a list of available extensions, choose the Open Extension Management button.';
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to choose your data source.';
                }
            }
            group(Control56)
            {
                ShowCaption = false;
                Visible = ChooseSourceVisible;
                group("Choose your data source")
                {
                    Caption = 'Choose your data source';
                    InstructionalText = 'Which finance app do you want to migrate data from?';
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        TableRelation = "Data Migrator Registration".Description;

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"Data Migrators", Rec) = ACTION::LookupOK then begin
                                Text := Rec.Description;
                                Clear(DataMigrationSettingsVisible);
                                Rec.OnHasSettings(DataMigrationSettingsVisible);
                                exit;
                            end;
                        end;
                    }
                }
            }
            group(Control12)
            {
                ShowCaption = false;
                Visible = ImportVisible;
                group(Instructions)
                {
                    Caption = 'Instructions';
                    InstructionalText = 'To prepare the data for migration, follow these steps:';
                    Visible = Instructions <> '';
                    field(InstructionsLabel; Instructions)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
                group(Settings)
                {
                    Caption = 'Settings';
                    InstructionalText = 'You can change the import settings for this data source by choosing Settings in the actions below.';
                    Visible = DataMigrationSettingsVisible;
                }
            }
            group(Control14)
            {
                ShowCaption = false;
                Visible = ApplyVisible;
                part(DataMigrationEntities; "Data Migration Entities")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data is ready for migration';
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = ShowPostingOptions;
                    grid(Control57)
                    {
                        GridLayout = Columns;
                        ShowCaption = false;
                        field(BallancesPostingOption; BallancesPostingOption)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Opening balances';
                            ShowMandatory = true;
                            ToolTip = 'Specifies what to do with opening balances. We can post them for you, or you can review balances in journals and post them yourself.';

                            trigger OnValidate()
                            begin
                                SetPosting();
                            end;
                        }
                        group(Control60)
                        {
                            ShowCaption = false;
                            Visible = BallancesPostingOption = BallancesPostingOption::"Post balances for me";
                            field(PostingDate; PostingDate)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Post to ledger on';
                                ToolTip = 'Specifies the date to post the journal on.';

                                trigger OnValidate()
                                begin
                                    SetPosting();
                                end;
                            }
                        }
                    }
                }
            }
            group("POSTING GROUP SETUP")
            {
                Caption = 'POSTING GROUP SETUP';
                Visible = PostingGroupIntroVisible;
                group("Welcome to Posting Group Setup")
                {
                    Caption = 'Welcome to Posting Group Setup';
                    InstructionalText = 'For posting accounts, you can specify the general ledger accounts that you want to post sales and purchase transactions to.';
                }
                group(Control47)
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to create posting accounts for purchasing and sales transactions.';
                }
            }
            group(Control46)
            {
                InstructionalText = 'Select the accounts to use when posting.';
                ShowCaption = false;
                Visible = FirstAccountSetupVisible;
                field("Sales Account"; SalesAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Sales Credit Memo Account"; SalesCreditMemoAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Credit Memo Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Sales Line Disc. Account"; SalesLineDiscAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Line Disc. Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Sales Inv. Disc. Account"; SalesInvDiscAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Inv. Disc. Account';
                    TableRelation = "G/L Account"."No.";
                }
                label(".")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    HideValue = true;
                    ShowCaption = false;
                }
                field("Purch. Account"; PurchAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purch. Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Purch. Credit Memo Account"; PurchCreditMemoAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purch. Credit Memo Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Purch. Line Disc. Account"; PurchLineDiscAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purch. Line Disc. Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Purch. Inv. Disc. Account"; PurchInvDiscAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purch. Inv. Disc. Account';
                    TableRelation = "G/L Account"."No.";
                }
                label("..")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    HideValue = true;
                    ShowCaption = false;
                }
                group(Control50)
                {
                    InstructionalText = 'When importing items, the following accounts need to be entered';
                    ShowCaption = false;
                    Visible = FirstAccountSetupVisible;
                }
                field("COGS Account"; COGSAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'COGS Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Inventory Adjmt. Account"; InventoryAdjmtAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Adjmt. Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Inventory Account"; InventoryAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Account';
                    TableRelation = "G/L Account"."No.";
                }
            }
            group(Control33)
            {
                InstructionalText = 'Select the accounts to use when posting.';
                ShowCaption = false;
                Visible = SecondAccountSetupVisible;
                group(Control32)
                {
                    InstructionalText = 'Customers';
                    ShowCaption = false;
                }
                field("Receivables Account"; ReceivablesAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receivables Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Service Charge Acc."; ServiceChargeAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service Charge Acc.';
                    TableRelation = "G/L Account"."No.";
                }
                group(Control29)
                {
                    InstructionalText = 'Vendors';
                    ShowCaption = false;
                }
                field("Payables Account"; PayablesAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payables Account';
                    TableRelation = "G/L Account"."No.";
                }
                field("Purch. Service Charge Acc."; PurchServiceChargeAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purch. Service Charge Acc.';
                    TableRelation = "G/L Account"."No.";
                }
            }
            group(Control9)
            {
                ShowCaption = false;
                Visible = DoneVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'You have completed the Data Migration assisted setup guide.';
                    Visible = not ShowErrorsVisible;
                }
                group(Control58)
                {
                    ShowCaption = false;
                    Visible = ThatsItText <> '';
                    field(ThatsItText; ThatsItText)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                    group(Control62)
                    {
                        ShowCaption = false;
                        Visible = EnableTogglingOverviewPage;
                        field(ShowOverviewPage; ShowOverviewPage)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'View the status when finished';
                            ShowCaption = true;
                        }
                    }
                }
                group("Duplicate contacts?")
                {
                    Caption = 'Duplicate contacts?';
                    InstructionalText = 'We found some contacts that were duplicated. You can review the list, and decide what to do with them.';
                    Visible = ShowDuplicateContactsText;
                    field(DuplicateContacts; DuplicateContactsLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            PAGE.Run(PAGE::"Contact Duplicates");
                        end;
                    }
                }
                group("Import completed with errors")
                {
                    Caption = 'Import completed with errors';
                    InstructionalText = 'There were errors during import of your data. For more details, choose Show Errors in the actions below.';
                    Visible = ShowErrorsVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionOpenExtensionManagement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Extension Management';
                Image = Setup;
                InFooterBar = true;
                RunObject = Page "Extension Management";
                Visible = Step = Step::Intro;
            }
            action(ActionDownloadTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download Template';
                Image = "Table";
                InFooterBar = true;
                Visible = DownloadTemplateVisible and (Step = Step::Import);

                trigger OnAction()
                var
                    Handled: Boolean;
                begin
                    Rec.OnDownloadTemplate(Handled);
                    if not Handled then
                        Error('');
                end;
            }
            action(ActionDataMigrationSettings)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Settings';
                Image = Setup;
                InFooterBar = true;
                Visible = DataMigrationSettingsVisible and (Step = Step::Import);

                trigger OnAction()
                var
                    Handled: Boolean;
                begin
                    Rec.OnOpenSettings(Handled);
                    if not Handled then
                        Error('');
                end;
            }
            action(ActionOpenAdvancedApply)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advanced';
                Image = Apply;
                InFooterBar = true;
                Visible = OpenAdvancedApplyVisible and (Step = Step::Apply);

                trigger OnAction()
                var
                    Handled: Boolean;
                begin
                    Rec.OnOpenAdvancedApply(TempDataMigrationEntity, Handled);
                    CurrPage.DataMigrationEntities.PAGE.CopyToSourceTable(TempDataMigrationEntity);
                    if not Handled then
                        Error('');
                end;
            }
            action(ActionShowErrors)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Errors';
                Image = ErrorLog;
                InFooterBar = true;
                Visible = ShowErrorsVisible and ((Step = Step::Done) or (Step = Step::ShowPostingGroupDoneStep));

                trigger OnAction()
                var
                    Handled: Boolean;
                begin
                    Rec.OnShowErrors(Handled);
                    if not Handled then
                        Error('');
                end;
            }
            separator(Action22)
            {
            }
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    case Step of
                        Step::Apply:
                            TempDataMigrationEntity.DeleteAll();
                    end;
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;
                Visible = not ApplyButtonVisible;

                trigger OnAction()
                begin
                    NextAction();
                end;
            }
            action(ActionApply)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Migrate';
                Enabled = ApplyButtonEnabled;
                Image = NextRecord;
                InFooterBar = true;
                Visible = ApplyButtonVisible;

                trigger OnAction()
                begin
                    NextAction();
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Data Migration Wizard");
                    CurrPage.Close();
                    if ShowOverviewPage then
                        PAGE.Run(PAGE::"Data Migration Overview");
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    var
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
    begin
        Rec.OnRegisterDataMigrator();
        if Rec.FindFirst() then;
        ResetWizardControls();
        ShowIntroStep();
        DataMigrationMgt.CheckMigrationInProgress(false);
        ShowCostingMethodNotification();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"Data Migration Wizard") then
                if not Confirm(DataImportNotCompletedQst, false) then
                    Error('');
    end;

    var
        TempDataMigrationEntity: Record "Data Migration Entity" temporary;
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,ChooseSource,Import,Apply,Done,PostingGroupIntro,AccountSetup1,AccountSetup2,ShowPostingGroupDoneStep;
        BallancesPostingOption: Option " ","Post balances for me","Review balances first";
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        ApplyButtonVisible: Boolean;
        ApplyButtonEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        ChooseSourceVisible: Boolean;
        ImportVisible: Boolean;
        ApplyVisible: Boolean;
        DoneVisible: Boolean;
        DataImportNotCompletedQst: Label 'Data Migration has not been completed.\\Are you sure that you want to exit?';
        DownloadTemplateVisible: Boolean;
        DataMigrationSettingsVisible: Boolean;
        OpenAdvancedApplyVisible: Boolean;
        ShowErrorsVisible: Boolean;
        PostingGroupIntroVisible: Boolean;
        FirstAccountSetupVisible: Boolean;
        SecondAccountSetupVisible: Boolean;
        AccountSetupVisible: Boolean;
        ShowPostingOptions: Boolean;
        ShowDuplicateContactsText: Boolean;
        Instructions: Text;
        ThatsItText: Text;
        TotalNoOfMigrationRecords: Integer;
        SalesAccount: Code[20];
        SalesCreditMemoAccount: Code[20];
        SalesLineDiscAccount: Code[20];
        SalesInvDiscAccount: Code[20];
        PurchAccount: Code[20];
        PurchCreditMemoAccount: Code[20];
        PurchLineDiscAccount: Code[20];
        PurchInvDiscAccount: Code[20];
        COGSAccount: Code[20];
        InventoryAdjmtAccount: Code[20];
        InventoryAccount: Code[20];
        ReceivablesAccount: Code[20];
        ServiceChargeAccount: Code[20];
        PayablesAccount: Code[20];
        PurchServiceChargeAccount: Code[20];
        PostingDate: Date;
        DuplicateContactsLbl: Label 'Review duplicate contacts';
        BallancesPostingErr: Label 'We need to know what to do with opening balances. You can:\\Let us post opening balances to the general ledger and item ledger for you, on a date you choose\\Review opening balances in journals first, and then post them yourself.';
        MissingAccountingPeriodeErr: Label 'Posting date %1 is not within an open accounting period. To see open periods, go to the Accounting Periods page.', Comment = '%1 = Posting Date';
        EnableTogglingOverviewPage: Boolean;
        ShowOverviewPage: Boolean;
        CostingMethodNotificationMsg: Label 'Verify the costing method before you import items. %1 is currently selected.', Comment = '%1 = Default Costing Method';
        CostingMethodNotificationActionMsg: Label 'Change the selection';

    local procedure NextAction()
    var
        Handled: Boolean;
        ShowBalance: Boolean;
        HideSelected: Boolean;
        ListOfAccounts: array[11] of Code[20];
    begin
        case Step of
            Step::ChooseSource:
                begin
                    Rec.OnGetInstructions(Instructions, Handled);
                    if not Handled then
                        Error('');
                end;
            Step::Import:
                begin
                    Rec.OnShowBalance(ShowBalance);
                    Rec.OnHideSelected(HideSelected);
                    CurrPage.DataMigrationEntities.PAGE.SetShowBalance(ShowBalance);
                    CurrPage.DataMigrationEntities.PAGE.SetHideSelected(HideSelected);
                    Rec.OnValidateSettings();
                    Rec.OnDataImport(Handled);
                    if not Handled then
                        Error('');
                    Rec.OnSelectDataToApply(TempDataMigrationEntity, Handled);
                    CurrPage.DataMigrationEntities.PAGE.CopyToSourceTable(TempDataMigrationEntity);
                    TotalNoOfMigrationRecords := GetTotalNoOfMigrationRecords(TempDataMigrationEntity);
                    if not Handled then
                        Error('');
                end;
            Step::Apply:
                begin
                    if ShowPostingOptions then
                        if BallancesPostingOption = BallancesPostingOption::" " then
                            Error(BallancesPostingErr);
                    CurrPage.DataMigrationEntities.PAGE.CopyFromSourceTable(TempDataMigrationEntity);
                    Rec.OnApplySelectedData(TempDataMigrationEntity, Handled);
                    if not Handled then
                        Error('');
                end;
            Step::AccountSetup1:
                begin
                    ListOfAccounts[1] := SalesAccount;
                    ListOfAccounts[2] := SalesCreditMemoAccount;
                    ListOfAccounts[3] := SalesLineDiscAccount;
                    ListOfAccounts[4] := SalesInvDiscAccount;
                    ListOfAccounts[5] := PurchAccount;
                    ListOfAccounts[6] := PurchCreditMemoAccount;
                    ListOfAccounts[7] := PurchLineDiscAccount;
                    ListOfAccounts[8] := PurchInvDiscAccount;
                    ListOfAccounts[9] := COGSAccount;
                    ListOfAccounts[10] := InventoryAdjmtAccount;
                    ListOfAccounts[11] := InventoryAccount;
                    Rec.OnGLPostingSetup(ListOfAccounts);
                end;
            Step::AccountSetup2:
                begin
                    ListOfAccounts[1] := ReceivablesAccount;
                    ListOfAccounts[2] := ServiceChargeAccount;
                    ListOfAccounts[3] := PayablesAccount;
                    ListOfAccounts[4] := PurchServiceChargeAccount;
                    Rec.OnCustomerVendorPostingSetup(ListOfAccounts);
                end;
        end;
        NextStep(false);
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        ResetWizardControls();

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::ChooseSource:
                ShowChooseSourceStep();
            Step::Import:
                ShowImportStep();
            Step::Apply:
                ShowApplyStep();
            Step::Done:
                ShowDoneStep();
            Step::PostingGroupIntro:
                ShowPostingGroupIntroStep();
            Step::AccountSetup1:
                ShowFirstAccountStep();
            Step::AccountSetup2:
                ShowSecondAccountStep();
            Step::ShowPostingGroupDoneStep:
                ShowPostingGroupDoneStep();
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        IntroVisible := true;
        BackEnabled := false;
        PostingGroupIntroVisible := false;
    end;

    local procedure ShowChooseSourceStep()
    begin
        ChooseSourceVisible := true;
    end;

    local procedure ShowImportStep()
    begin
        ImportVisible := true;
        Rec.OnHasTemplate(DownloadTemplateVisible);
        Rec.OnHasSettings(DataMigrationSettingsVisible);
    end;

    local procedure ShowApplyStep()
    begin
        ApplyVisible := true;
        ShowPostingOptions := false;
        NextEnabled := false;
        ApplyButtonVisible := true;
        ApplyButtonEnabled := TotalNoOfMigrationRecords > 0;
        Rec.OnHasAdvancedApply(OpenAdvancedApplyVisible);
        Rec.OnShowPostingOptions(ShowPostingOptions);
        if ShowPostingOptions then begin
            PostingDate := WorkDate();
            CurrPage.DataMigrationEntities.PAGE.SetPostingInfromation(
              BallancesPostingOption = BallancesPostingOption::"Post balances for me", PostingDate);
        end;
    end;

    local procedure ShowDoneStep()
    begin
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;
        BackEnabled := false;
        Rec.OnPostingGroupSetup(AccountSetupVisible);
        if AccountSetupVisible then begin
            TempDataMigrationEntity.Reset();
            TempDataMigrationEntity.SetRange("Table ID", 15);
            TempDataMigrationEntity.SetRange(Selected, true);
            if TempDataMigrationEntity.FindFirst() then begin
                DoneVisible := false;
                NextEnabled := true;
                FinishEnabled := false;
                NextStep(false);
            end;
        end;
        Rec.OnHasErrors(ShowErrorsVisible);
        Rec.OnShowDuplicateContactsText(ShowDuplicateContactsText);
        Rec.OnShowThatsItMessage(ThatsItText);

        Rec.OnEnableTogglingDataMigrationOverviewPage(EnableTogglingOverviewPage);
        if EnableTogglingOverviewPage then
            ShowOverviewPage := true;
    end;

    local procedure ShowPostingGroupIntroStep()
    begin
        DoneVisible := false;
        BackEnabled := false;
        NextEnabled := true;
        PostingGroupIntroVisible := true;
        FirstAccountSetupVisible := false;
        SecondAccountSetupVisible := false;
        FinishEnabled := false;
    end;

    local procedure ShowFirstAccountStep()
    begin
        DoneVisible := false;
        BackEnabled := false;
        NextEnabled := true;
        FirstAccountSetupVisible := true;
        SecondAccountSetupVisible := false;
        PostingGroupIntroVisible := false;
        FinishEnabled := false;
    end;

    local procedure ShowSecondAccountStep()
    begin
        DoneVisible := false;
        BackEnabled := true;
        NextEnabled := true;
        PostingGroupIntroVisible := false;
        FirstAccountSetupVisible := false;
        SecondAccountSetupVisible := true;
        FinishEnabled := false;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        ApplyButtonVisible := false;
        ApplyButtonEnabled := false;
        FinishEnabled := false;
        DownloadTemplateVisible := false;
        DataMigrationSettingsVisible := false;
        OpenAdvancedApplyVisible := false;
        ShowErrorsVisible := false;
        PostingGroupIntroVisible := false;
        FirstAccountSetupVisible := false;
        SecondAccountSetupVisible := false;

        // Tabs
        IntroVisible := false;
        ChooseSourceVisible := false;
        ImportVisible := false;
        ApplyVisible := false;
        DoneVisible := false;
    end;

    local procedure GetTotalNoOfMigrationRecords(var DataMigrationEntity: Record "Data Migration Entity") TotalCount: Integer
    begin
        if DataMigrationEntity.FindSet() then
            repeat
                TotalCount += DataMigrationEntity."No. of Records";
            until DataMigrationEntity.Next() = 0;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure ShowPostingGroupDoneStep()
    begin
        DoneVisible := true;
        BackEnabled := false;
        NextEnabled := false;
        Rec.OnHasErrors(ShowErrorsVisible);
        FinishEnabled := true;
    end;

    local procedure SetPosting()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if BallancesPostingOption = BallancesPostingOption::"Post balances for me" then
            if AccountingPeriod.GetFiscalYearStartDate(PostingDate) = 0D then
                Error(MissingAccountingPeriodeErr, PostingDate);

        CurrPage.DataMigrationEntities.PAGE.SetPostingInfromation(
          BallancesPostingOption = BallancesPostingOption::"Post balances for me", PostingDate);
    end;

    local procedure ShowCostingMethodNotification()
    var
        InventorySetup: Record "Inventory Setup";
        CostingMethodNotification: Notification;
    begin
        if InventorySetup.Get() then begin
            CostingMethodNotification.Message(StrSubstNo(CostingMethodNotificationMsg, InventorySetup."Default Costing Method"));
            CostingMethodNotification.AddAction(CostingMethodNotificationActionMsg, Codeunit::"Company Setup Notification", 'OpenCostingMethodConfigurationPage');
            CostingMethodNotification.Send();
        end;
    end;
}

