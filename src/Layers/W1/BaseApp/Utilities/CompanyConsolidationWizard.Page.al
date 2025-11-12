#if not CLEAN25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Currency;
using System.Environment;
using System.Environment.Configuration;
using System.Utilities;

page 1826 "Company Consolidation Wizard"
{
    Caption = 'Company Consolidation';
    PageType = NavigatePage;
    ObsoleteReason = 'Wizard deprecated due to low usage and to unify how DemoData is applied on new companies. Consolidation companies can be created as normal Business Central companies.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    layout
    {
        area(content)
        {
            group(Control6)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control8)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control10)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to the Company Consolidation Assisted Setup Guide")
                {
                    Caption = 'Welcome to the Company Consolidation Assisted Setup Guide';
                    Visible = FirstStepVisible;
                    group(Control12)
                    {
                        InstructionalText = 'This assisted setup guide helps you get ready to run a consolidation report. You will create or choose a company to keep the consolidated transactions in, and choose the companies and accounts to consolidate.';
                        ShowCaption = false;
                        Visible = FirstStepVisible;
                    }
                }
            }
            group(Control27)
            {
                ShowCaption = false;
                Visible = ConsolidatedStepVisible;
                group("Consolidated Company")
                {
                    Caption = 'Consolidated Company';
                    InstructionalText = 'Create or choose the company that will contain the consolidated transactions. Creating a company will require that you create the setups needed for consolidation reports.';
                    Visible = ConsolidatedStepVisible;
                    field(SelectCompanyOption; SelectCompanyOption)
                    {
                        ApplicationArea = Suite;
                        Caption = 'I want to';
                        OptionCaption = 'Create a new company,Use an existing company';

                        trigger OnValidate()
                        begin
                            if SelectCompanyOption = SelectCompanyOption::"Use an existing company" then begin
                                SelectCompanyInstructions := SelectCompanyUseExistingTxt;
                                ThatsItInstructions := ThatsItUseExistingTxt;
                            end else begin
                                SelectCompanyInstructions := SelectCompanyCreateTxt;
                                ThatsItInstructions := ThatsItCreateTxt;
                            end;
                        end;
                    }
                }
            }
            group(Control31)
            {
                ShowCaption = false;
                Visible = SelectCompanyVisible;
                group(Control32)
                {
                    Caption = 'Select Company';
                    field(SelectCompanyInstructions; SelectCompanyInstructions)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Select Company';
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("Select Company"; SelectCompanyName)
                    {
                        ApplicationArea = Suite;
                        AssistEdit = true;
                        Caption = 'Select Company';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            SelectedCompany: Record Company;
                            AccessibleCompanies: Page "Accessible Companies";
                        begin
                            AccessibleCompanies.Initialize();

                            if SelectedCompany.Get(CompanyName) then
                                AccessibleCompanies.SetRecord(SelectedCompany);

                            AccessibleCompanies.LookupMode(true);

                            if AccessibleCompanies.RunModal() = Action::LookupOK then begin
                                AccessibleCompanies.GetRecord(SelectedCompany);
                                SelectCompanyName := SelectedCompany.Name;
                                ConsolidatedCompany := SelectCompanyName;
                            end;
                        end;
                    }
                }
            }
            group(Control13)
            {
                ShowCaption = false;
                Visible = CreationStepVisible;
                group("Specify some basic information")
                {
                    Caption = 'Specify some basic information';
                    Visible = CreationStepVisible;
                    group(Control20)
                    {
                        InstructionalText = 'Enter a name for the company.';
                        ShowCaption = false;
                        field(CompanyName; NewCompanyName)
                        {
                            ApplicationArea = Suite;
                            ShowCaption = false;
                            ShowMandatory = true;

                            trigger OnValidate()
                            begin
                                if Company.Get(NewCompanyName) then
                                    Error(CompanyAlreadyExistsErr);

                                NewCompany := true;
                            end;
                        }
                    }
                    group("Select the data and setup to get started.")
                    {
                        Caption = 'Select the data and setup to get started.';
                        field(CompanyData; NewCompanyData)
                        {
                            ApplicationArea = Suite;
                            OptionCaption = 'Standard Data (Recommended),None (For Advanced Users Only)';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                UpdateDataDescription();
                            end;
                        }
                        field(NewCompanyDataDescription; NewCompanyDataDescription)
                        {
                            ApplicationArea = Suite;
                            Editable = false;
                            MultiLine = true;
                            ShowCaption = false;
                        }
                    }
                }
            }
            group(Control39)
            {
                ShowCaption = false;
                Visible = SetupBusUnitsVisible;
                group("Choose the source companies")
                {
                    Caption = 'Choose the source companies';
                    InstructionalText = 'Choose the companies to consolidate transactions from.';
                    Visible = SetupBusUnitsVisible;
                    part(Companies; "Business Units Setup Subform")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Companies';
                    }
                }
            }
            group("<Control25>")
            {
                Caption = '<Control25>';
                Visible = BusinessUnitsVisible;
                group("Set up the consolidated company")
                {
                    Caption = 'Set up the consolidated company';
                    Visible = BusinessUnitsVisible;
                    field(SetupBusinessUnitsLbl; SetupBusinessUnitsLbl)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("Code"; BusinessUnitCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Business Unit Code';
                        ShowMandatory = true;

                        trigger OnValidate()
                        var
                            BusinessUnit: Record "Business Unit";
                        begin
                            BusinessUnitInformation.Reset();
                            BusinessUnitInformation.SetRange(Code, BusinessUnitCode);
                            if BusinessUnitInformation.FindFirst() then
                                Error(RecordExistsErr);

                            if not NewCompany then begin
                                BusinessUnit.ChangeCompany(ConsolidatedCompany);
                                BusinessUnit.Reset();
                                BusinessUnit.SetRange(Code, BusinessUnitCode);
                                if not BusinessUnit.IsEmpty() then
                                    Error(RecordExistsErr);
                            end;
                        end;
                    }
                    field(Name; BusinessUnitName)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                        Editable = false;
                    }
                    field("Company Name"; BusinessUnitCompanyName)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Company Name';
                        Editable = false;
                        TableRelation = Company.Name;
                    }
                    field("Currency Code"; BusinessUnitCurrencyCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Currency Code';
                        TableRelation = Currency;
                    }
                    field("Currency Exchange Rate Table"; BusinessUnitExchRtTable)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Currency Exchange Rate Table';
                        OptionCaption = 'Local,Business Unit';
                    }
                    field("Starting Date"; BusinessUnitStartingDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                    }
                    field("Ending Date"; BusinessUnitEndingDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Ending Date';
                    }
                }
            }
            group(Control42)
            {
                ShowCaption = false;
                Visible = BusinessUnitsVisible2;
                group(Control43)
                {
                    Caption = 'Set up the consolidated company';
                    Visible = BusinessUnitsVisible2;
                    field(SetupBusinessUnits; SetupBusinessUnitsLbl)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field(BusinessCode; BusinessUnitCode2)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Code';
                        Editable = false;
                    }
                    field(ExchRateGainsAcc; BusinessUnitExchRateGains)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Exch. Rate Gains Acc.';
                        TableRelation = "Consolidation Account";
                    }
                    field(ExchRateLossesAcc; BusinessUnitExchRateLosses)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Exch. Rate Losses Acc.';
                        TableRelation = "Consolidation Account";
                    }
                    field(CompExchRateGainsAcc; BusinessUnitCompExchRateGains)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Comp.Exch. Rate Gains Acc.';
                        TableRelation = "Consolidation Account";
                    }
                    field(CompExchRateLosses; BusinessUnitCompExchRateLosses)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Comp. Exch. Rate Losses Acc.';
                        TableRelation = "Consolidation Account";
                    }
                    field(EquityExchRateGains; BusinessUnitEquityExchRateGains)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Equity Exch. Rate Gains Acc.';
                        TableRelation = "Consolidation Account";
                    }
                    field(EquityExchRateLosses; BusinessUnitEquityExchRateLosses)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Equity Exch. Rate Losses Acc.';
                        TableRelation = "Consolidation Account";
                    }
                    field(ResidualAccount; BusinessUnitResidualAccount)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Residual Account';
                        TableRelation = "Consolidation Account";
                    }
                    field(MinorityExchRateGains; BusinessUnitMinorityExchRateGains)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Minority Exch. Rate Gains';
                        TableRelation = "Consolidation Account";
                    }
                    field(MinorityExchRateLosses; BusinessUnitMinorityExchRateLosses)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Minority Exch. Rate Losses';
                        TableRelation = "Consolidation Account";
                    }
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    Visible = FinalStepVisible;
                    field(ThatsItInstructions; ThatsItInstructions)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Thats It Instructions';
                        Editable = false;
                        ShowCaption = false;
                        Visible = FinalStepVisible;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    CreateAction();
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Company Consolidation Wizard");
                    if SelectCompanyOption = SelectCompanyOption::"Create a new company" then
                        Message(AfterCreateCompanyMsg);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnClosePage()
    begin
        DeleteTempRecords();
    end;

    trigger OnInit()
    begin
        if not BusinessUnitSetup.WritePermission then
            Error(PermissionsErr);
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    var
        ObsoletionNotification: Notification;
    begin
        ObsoletionNotification.Message := ObsoletionMsg;
        ObsoletionNotification.Send();
        Step := Step::Start;
        NewCompanyData := NewCompanyData::"Standard Data";
        UpdateDataDescription();
        EnableControls();
        ConsolidatedAccountsCreated := false;
        ThatsItInstructions := ThatsItCreateTxt;
        DeleteTempRecords();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = ACTION::OK) and (not Finished) then
            if not Confirm(SetupNotCompletedQst, false) then
                Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        BusinessUnitSetup: Record "Business Unit Setup";
        BusinessUnitInformation: Record "Business Unit Information";
        Company: Record Company;
        ConsolidationTest: Report "Consolidation - Test";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Consolidated,Select,Creation,"Business Units Setup","Business Units","Business Units 2",Finish;
        ConsolidatedCompany: Text[50];
        BusinessUnitCode: Code[20];
        BusinessUnitCode2: Code[20];
        BusinessUnitName: Text[30];
        BusinessUnitCompanyName: Text[30];
        BusinessUnitCurrencyCode: Code[10];
        BusinessUnitExchRtTable: Option "Local","Business Unit";
        BusinessUnitStartingDate: Date;
        BusinessUnitEndingDate: Date;
        BusinessUnitExchRateGains: Code[20];
        BusinessUnitExchRateLosses: Code[20];
        BusinessUnitCompExchRateGains: Code[20];
        BusinessUnitCompExchRateLosses: Code[20];
        BusinessUnitEquityExchRateGains: Code[20];
        BusinessUnitEquityExchRateLosses: Code[20];
        BusinessUnitResidualAccount: Code[20];
        BusinessUnitMinorityExchRateGains: Code[20];
        BusinessUnitMinorityExchRateLosses: Code[20];
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        CreationStepVisible: Boolean;
        FinalStepVisible: Boolean;
        ConsolidatedStepVisible: Boolean;
        SelectCompanyVisible: Boolean;
        BusinessUnitsVisible: Boolean;
        BusinessUnitsVisible2: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        SetupNotCompletedQst: Label 'The setup has not yet been completed.\\Are you sure that you want to exit?';
        NewCompanyName: Text[30];
        NewCompanyData: Option "Standard Data","None";
        CompanyAlreadyExistsErr: Label 'A company with that name already exists. Try a different name.';
        SelectCompanyOption: Option "Create a new company","Use an existing company";
        NewCompanyDataDescription: Text;
        SelectCompanyName: Text[30];
        SpecifyCompanyNameErr: Label 'To continue, you must specify a name for the company.';
        NoDataTxt: Label '\Want to set things up yourself?\\Create a company that does not contain data, and is not already set up for use. For example, select this option when you want to use your own data, and set things up yourself.';
        TrialPeriodTxt: Label '\\You will be able to use this company for a 30-day trial period.';
        SetupBusUnitsVisible: Boolean;
        BackActionBusUnit2: Boolean;
        CreatingBusinessUnitsMsg: Label 'Creating Business Units...';
        RecordExistsErr: Label 'The record already exists.';
        MaxNumberOfSteps: Integer;
        StepCaptionTxt: Label 'Business Unit %1 of %2', Comment = '%1 =The current business unit''s position in the list of all available business units being processed. %2=The total number of all available business units being processed.';
        StepIndex: Integer;
        EmptyCompanyNameErr: Label 'You must choose a company.';
        Finished: Boolean;
        NewCompany: Boolean;
        CompanyConsolidationTxt: Label 'Company Consolidation';
        NoBusinessUnitsSelectedErr: Label 'No companies have been selected. You must select at least one to consolidate.';
        SelectCompanyInstructions: Text;
        SelectCompanyUseExistingTxt: Label 'Select the company that will be used as the consolidated company.';
        SelectCompanyCreateTxt: Label 'Select the Company information that will be used to create the consolidated company.';
        ThatsItInstructions: Text;
        ThatsItUseExistingTxt: Label 'Choose Finish to create the business units. This can take a few minutes to complete.';
        ThatsItCreateTxt: Label 'Choose Finish to create the company. This can take a few minutes to complete.';
        CreateNewCompanyTxt: Label 'Create New Company';
        SetupBusinessUnitsLbl: Label 'Specify settings for the business unit that will be set up in the consolidated company.';
        ConsolidatedAccountsCreated: Boolean;
        NoBusinessUnitCodeEnteredErr: Label 'Enter a Business Unit Code.';
        NoPermissionsErr: Label 'You do not have permissions to create a new company. Contact your system administrator.';
        PermissionsErr: Label 'You do not have permissions to run this wizard.';
        AfterCreateCompanyMsg: Label 'Here is a tip. After you finish this assisted setup guide you can test your settings before you actually transfer data. To run a test, sign in to the company you just created, go to the Business Units page, and then choose the Test Database action.';
        ObsoletionMsg: Label 'This wizard will be removed in an upcoming release. You can create companies for consolidation in the Companies page. The setup of the consolidated companies is done in the Business Units page.';

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::Consolidated:
                ShowConsolidatedStep();
            Step::Select:
                ShowSelectStep();
            Step::Creation:
                ShowCreationStep();
            Step::"Business Units Setup":
                ShowBusinessUnitsSetup();
            Step::"Business Units":
                ShowBusinessUnits();
            Step::"Business Units 2":
                ShowBusinessUnits2();
            Step::Finish:
                ShowFinalStep();
        end;
    end;

    local procedure CreateAction()
    begin
        if NewCompanyName <> '' then begin
            AssistedCompanySetup.CreateNewCompany(NewCompanyName);
            AssistedCompanySetup.SetUpNewCompany(NewCompanyName, Enum::"Company Demo Data Type"::"Create New - No Data");
            ConsolidatedCompany := NewCompanyName;
        end;
        CreateBusinessUnits();

        if SelectCompanyOption = SelectCompanyOption::"Use an existing company" then
            RunConsolidationTestDatabaseReport();
        Finished := true;
    end;

    local procedure NextStep(Backwards: Boolean)
    var
        BusinessUnitSetup2: Record "Business Unit Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Company: Record Company;
        FakeCompanyName: Text[30];
        FakeCompanyCreated: Boolean;
        FakeCompanySet: Boolean;
    begin
        if (Step = Step::Creation) and not Backwards then
            if NewCompanyName = '' then
                Error(SpecifyCompanyNameErr);

        if Step = Step::Creation then
            if SelectCompanyOption = SelectCompanyOption::"Create a new company" then
                Step := Step - 1;

        if Step = Step::Select then
            if not Backwards then begin
                if (SelectCompanyName = '') and (SelectCompanyOption = SelectCompanyOption::"Use an existing company") then
                    Error(EmptyCompanyNameErr);
                Step := Step + 1
            end;

        if (Step = Step::Consolidated) and not Backwards then
            if SelectCompanyOption = SelectCompanyOption::"Create a new company" then begin
                FakeCompanyName := 'ConsolidatedCompany9999';

                if NewCompanyName = '' then begin
                    FakeCompanySet := true;
                    NewCompanyName := FakeCompanyName;
                end;

                if not Company.Get(NewCompanyName) then begin
                    FakeCompanyCreated := true;
                    Company.Init();
                    Company.Name := NewCompanyName;
                    Company.Insert();
                end;

                if not GeneralLedgerSetup.ChangeCompany(NewCompanyName) then begin
                    NewCompanyName := '';
                    Error(NoPermissionsErr);
                end;
                if not GeneralLedgerSetup.WritePermission then begin
                    NewCompanyName := '';
                    Error(NoPermissionsErr);
                end;

                if FakeCompanyCreated then
                    Commit();
                RemoveCompanyRecord(Company, FakeCompanyName, FakeCompanyCreated, FakeCompanySet);
                Step := Step + 1;
            end;

        if Step = Step::"Business Units" then
            if BusinessUnitCode = '' then
                Error(NoBusinessUnitCodeEnteredErr);

        if Step = Step::"Business Units 2" then
            if not Backwards then begin
                BackActionBusUnit2 := false;
                SaveBusinessUnitInformation();
                UpdateBusinessUnitSetupComplete(BusinessUnitCompanyName, true);
                BusinessUnitSetup.SetRange(Completed, false);
                if BusinessUnitSetup.FindFirst() then
                    Step := Step - 2;
            end else
                BackActionBusUnit2 := true;

        if Step = Step::"Business Units Setup" then begin
            BusinessUnitSetup2.Reset();
            BusinessUnitSetup2.SetFilter(Include, '=TRUE');
            if BusinessUnitSetup2.Count = 0 then
                Error(NoBusinessUnitsSelectedErr);
        end;

        if (Step = Step::"Business Units") and Backwards then begin
            StepIndex := StepIndex - 1;
            UpdateBusinessUnitSetupComplete(BusinessUnitCompanyName, false);
        end;

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;

        BackActionEnabled := false;
    end;

    local procedure ShowConsolidatedStep()
    begin
        ConsolidatedStepVisible := true;
        CurrPage.Caption := CompanyConsolidationTxt;
    end;

    local procedure ShowSelectStep()
    begin
        SelectCompanyVisible := true;
        CurrPage.Caption := CompanyConsolidationTxt;
    end;

    local procedure ShowCreationStep()
    begin
        CreationStepVisible := true;
        CurrPage.Caption := CreateNewCompanyTxt;
    end;

    local procedure ShowBusinessUnitsSetup()
    begin
        if not BusinessUnitSetup.FindFirst() then
            BusinessUnitSetup.FillTable(SelectCompanyName);
        CurrPage.Caption := CompanyConsolidationTxt;
        SetupBusUnitsVisible := true;

        BackActionEnabled := false;
    end;

    local procedure ShowBusinessUnits()
    var
        Company: Record Company;
        ConsolidationAccount: Record "Consolidation Account";
    begin
        if not ConsolidatedAccountsCreated then begin
            if SelectCompanyOption = SelectCompanyOption::"Use an existing company" then
                ConsolidationAccount.PopulateConsolidationAccountsForExistingCompany(ConsolidatedCompany);
            if SelectCompanyOption = SelectCompanyOption::"Create a new company" then
                if NewCompanyData = NewCompanyData::"Standard Data" then
                    ConsolidationAccount.PopulateAccounts();
            ConsolidatedAccountsCreated := true
        end;

        BusinessUnitsVisible := true;
        BackActionEnabled := false;
        if not BackActionBusUnit2 then begin
            StepIndex := StepIndex + 1;
            ClearBusinessUnitInformation();
            BusinessUnitSetup.Reset();
            BusinessUnitSetup.SetFilter(Include, '=TRUE');
            MaxNumberOfSteps := BusinessUnitSetup.Count();
            BusinessUnitSetup.SetFilter(Completed, '=FALSE');
            CurrPage.Caption := StrSubstNo(StepCaptionTxt, StepIndex, MaxNumberOfSteps);
            if BusinessUnitSetup.FindFirst() then begin
                BusinessUnitCompanyName := BusinessUnitSetup."Company Name";
                Company.Get(BusinessUnitCompanyName);
                BusinessUnitName := CopyStr(Company."Display Name", 1, 30);
            end;
        end;
    end;

    local procedure ShowBusinessUnits2()
    begin
        BusinessUnitsVisible2 := true;
        BackActionEnabled := true;
        BusinessUnitCode2 := BusinessUnitCode;
    end;

    local procedure ShowFinalStep()
    begin
        FinalStepVisible := true;
        NextActionEnabled := false;
        FinishActionEnabled := true;
        BackActionEnabled := false;
        CurrPage.Caption := CompanyConsolidationTxt;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        SelectCompanyVisible := false;
        CreationStepVisible := false;
        SetupBusUnitsVisible := false;
        BusinessUnitsVisible := false;
        BusinessUnitsVisible2 := false;
        FinalStepVisible := false;
        ConsolidatedStepVisible := false;
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

    local procedure SaveBusinessUnitInformation()
    begin
        BusinessUnitInformation.Init();
        BusinessUnitInformation.Validate(Code, BusinessUnitCode);
        BusinessUnitInformation.Validate(Name, BusinessUnitName);
        BusinessUnitInformation.Validate("Company Name", BusinessUnitCompanyName);
        BusinessUnitInformation.Validate("Currency Code", BusinessUnitCurrencyCode);
        BusinessUnitInformation.Validate("Currency Exchange Rate Table", BusinessUnitExchRtTable);
        BusinessUnitInformation.Validate("Starting Date", BusinessUnitStartingDate);
        BusinessUnitInformation.Validate("Ending Date", BusinessUnitEndingDate);
        BusinessUnitInformation.Validate("Exch. Rate Gains Acc.", BusinessUnitExchRateGains);
        BusinessUnitInformation.Validate("Exch. Rate Losses Acc.", BusinessUnitExchRateLosses);
        BusinessUnitInformation.Validate("Comp. Exch. Rate Gains Acc.", BusinessUnitCompExchRateGains);
        BusinessUnitInformation.Validate("Comp. Exch. Rate Losses Acc.", BusinessUnitCompExchRateLosses);
        BusinessUnitInformation.Validate("Equity Exch. Rate Gains Acc.", BusinessUnitEquityExchRateGains);
        BusinessUnitInformation.Validate("Equity Exch. Rate Losses Acc.", BusinessUnitEquityExchRateLosses);
        BusinessUnitInformation.Validate("Residual Account", BusinessUnitResidualAccount);
        BusinessUnitInformation.Validate("Minority Exch. Rate Gains Acc.", BusinessUnitMinorityExchRateGains);
        BusinessUnitInformation.Validate("Minority Exch. Rate Losses Acc", BusinessUnitMinorityExchRateLosses);
        BusinessUnitInformation.Insert();
    end;

    local procedure ClearBusinessUnitInformation()
    begin
        Clear(BusinessUnitCode);
        Clear(BusinessUnitName);
        Clear(BusinessUnitCompanyName);
        Clear(BusinessUnitCurrencyCode);
        Clear(BusinessUnitExchRtTable);
        Clear(BusinessUnitStartingDate);
        Clear(BusinessUnitEndingDate);
        Clear(BusinessUnitExchRateGains);
        Clear(BusinessUnitExchRateLosses);
        Clear(BusinessUnitCompExchRateGains);
        Clear(BusinessUnitCompExchRateLosses);
        Clear(BusinessUnitEquityExchRateGains);
        Clear(BusinessUnitEquityExchRateLosses);
        Clear(BusinessUnitResidualAccount);
        Clear(BusinessUnitMinorityExchRateGains);
        Clear(BusinessUnitMinorityExchRateLosses);
    end;

    local procedure UpdateBusinessUnitSetupComplete(CompanyName: Text[30]; CompletedStatus: Boolean)
    begin
        BusinessUnitSetup.Get(CompanyName);
        BusinessUnitSetup.Completed := CompletedStatus;
        BusinessUnitSetup.Modify();
    end;

    local procedure DeleteTempRecords()
    var
        ConsolidationAccount: Record "Consolidation Account";
    begin
        BusinessUnitSetup.Reset();
        BusinessUnitSetup.DeleteAll();
        BusinessUnitInformation.Reset();
        BusinessUnitInformation.DeleteAll();
        ConsolidationAccount.Reset();
        ConsolidationAccount.DeleteAll();
    end;

    local procedure CreateBusinessUnits()
    var
        BusinessUnit: Record "Business Unit";
        Window: Dialog;
    begin
        Window.Open(CreatingBusinessUnitsMsg);

        BusinessUnit.ChangeCompany(ConsolidatedCompany);
        BusinessUnitInformation.Reset();
        if BusinessUnitInformation.Find('-') then
            repeat
                BusinessUnit.Init();
                BusinessUnit.Code := BusinessUnitInformation.Code;
                BusinessUnit.Name := BusinessUnitInformation.Name;
                BusinessUnit."Company Name" := BusinessUnitInformation."Company Name";
                BusinessUnit."Currency Code" := BusinessUnitInformation."Currency Code";
                BusinessUnit."Currency Exchange Rate Table" := BusinessUnitInformation."Currency Exchange Rate Table";
                BusinessUnit."Starting Date" := BusinessUnitInformation."Starting Date";
                BusinessUnit."Ending Date" := BusinessUnitInformation."Ending Date";
                BusinessUnit."Exch. Rate Gains Acc." := BusinessUnitInformation."Exch. Rate Gains Acc.";
                BusinessUnit."Exch. Rate Losses Acc." := BusinessUnitInformation."Exch. Rate Losses Acc.";
                BusinessUnit."Comp. Exch. Rate Gains Acc." := BusinessUnitInformation."Comp. Exch. Rate Gains Acc.";
                BusinessUnit."Comp. Exch. Rate Losses Acc." := BusinessUnitInformation."Comp. Exch. Rate Losses Acc.";
                BusinessUnit."Equity Exch. Rate Gains Acc." := BusinessUnitInformation."Equity Exch. Rate Gains Acc.";
                BusinessUnit."Equity Exch. Rate Losses Acc." := BusinessUnitInformation."Equity Exch. Rate Losses Acc.";
                BusinessUnit."Residual Account" := BusinessUnitInformation."Residual Account";
                BusinessUnit."Minority Exch. Rate Gains Acc." := BusinessUnitInformation."Minority Exch. Rate Gains Acc.";
                BusinessUnit."Minority Exch. Rate Losses Acc" := BusinessUnitInformation."Minority Exch. Rate Losses Acc";

                BusinessUnit.Insert();
            until BusinessUnitInformation.Next() = 0;

        Commit();

        Window.Close();
    end;

    local procedure UpdateDataDescription()
    var
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        case NewCompanyData of
            NewCompanyData::"Standard Data":
                NewCompanyDataDescription := '';
            NewCompanyData::None:
                NewCompanyDataDescription := NoDataTxt;
        end;

        if TenantLicenseState.IsPaidMode() then
            exit;

        case NewCompanyData of
            NewCompanyData::"Standard Data",
          NewCompanyData::None:
                NewCompanyDataDescription += TrialPeriodTxt;
        end;
    end;

    local procedure RunConsolidationTestDatabaseReport()
    begin
        ConsolidationTest.SetConsolidatedCompany(CopyStr(ConsolidatedCompany, 1, 30));
        ConsolidationTest.Run();
    end;

    procedure RemoveCompanyRecord(var Company: Record Company; FakeCompanyName: Text[30]; FakeCompanyCreated: Boolean; FakeCompanySet: Boolean)
    begin
        if FakeCompanyCreated then begin
            Company.SetRange(Name, FakeCompanyName);
            Company.Delete();
        end;

        if FakeCompanySet then
            NewCompanyName := '';
    end;
}

#endif