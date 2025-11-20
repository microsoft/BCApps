// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment;
using System.Environment.Configuration;
using System.IO;
using System.Utilities;

page 1877 "VAT Setup Wizard"
{
    Caption = 'VAT Setup';
    PageType = NavigatePage;
    Permissions = TableData "VAT Setup Posting Groups" = rimd,
                  TableData "VAT Assisted Setup Templates" = rimd,
                  TableData "VAT Assisted Setup Bus. Grp." = rimd;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinalStepVisible;
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and FinalStepVisible;
            }
            group("<MediaRepositoryDone>")
            {
                Visible = FirstStepVisible;
                group("Welcome to VAT Setup")
                {
                    Caption = 'Welcome to VAT Setup';
                    Visible = FirstStepVisible;
                    group(Control28)
                    {
                        InstructionalText = 'This assisted setup guide helps you automate VAT calculations for sales and purchase documents.';
                        ShowCaption = false;
                    }
                    group(Control27)
                    {
                        InstructionalText = 'You will set up the VAT rates that apply to customers, vendors, and items in different markets, and then specify the accounts to post VAT to. If you sometimes use VAT rates that deviate from standard rates, there''s also an option to enter clauses that explain why to tax authorities.';
                        ShowCaption = false;
                    }
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    group(Control22)
                    {
                        InstructionalText = 'Choose Next to get started.';
                        ShowCaption = false;
                    }
                }
            }
            group(Control2)
            {
                ShowCaption = false;
                Visible = VATBusPostGrpPartStepVisible;
                group("VAT Business Posting Groups")
                {
                    Caption = 'VAT Business Posting Groups';
                    InstructionalText = 'VAT business posting groups specify where you do business, or the type of business you do. See the options from a VAT perspective, and choose all that apply. In the next steps, you''ll specify the VAT types to use for customers, vendors, and items in those markets.';
                }
                part("VAT Bus. Post. Grp Part"; "VAT Bus. Post. Grp Part")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = ' ';
                }
            }
            group("VAT Product Posting Setup")
            {
                Caption = 'VAT Product Posting Setup';
                Visible = VATProdPostGrpPartStepVisible;
                group("VAT Rates for Items and Services")
                {
                    Caption = 'VAT Rates for Items and Services';
                    InstructionalText = 'Specify types of products (items and services) that you buy or sell, and the VAT rates that apply. If the default VAT rates aren''t correct, you can adjust them. You can also add lines if you use reduced VAT rates when buying or selling.';
                    Visible = VATProdRatesStepVisible;
                }
                group("G/L Accounts for VAT Amounts")
                {
                    Caption = 'G/L Accounts for VAT Amounts';
                    InstructionalText = 'Get a clear picture of your finances by assigning G/L accounts for sales, purchases, and reversed charges VAT amounts to VAT product posting groups. For example, this lets you compare the VAT amount figures you''ll report to VAT authorities to the figures posted in your general ledger.';
                    Visible = VATProdAccountStepVisible;
                }
                group("Optional: Clauses for Non-Standard VAT Rates")
                {
                    Caption = 'Optional: Clauses for Non-Standard VAT Rates';
                    InstructionalText = 'Some tax authorities require explanations, and sometimes even references to regulatory statues, when non-standard VAT rates, such as reduced or zero, are used on invoices. You can enter the clauses, and they will be printed on sales documents that use non-standard VAT rates.';
                    Visible = VATProdClausesStepVisible;
                }
                part(VATProdPostGrpPart; "VAT Product Posting Grp Part")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = ' ';
                }
            }
            group("Assign VAT Setup to Customer, Vendor, and Item Templates")
            {
                Caption = 'Assign VAT Setup to Customer, Vendor, and Item Templates';
                Visible = TemplateStepVisible;
                group("Default VAT Rates on Customer Templates")
                {
                    Caption = 'Default VAT Rates on Customer Templates';
                    InstructionalText = 'Specify default VAT rates for customer templates. When assigned to customers, customer templates apply default settings for posting things like revenue, costs, receivables, payables, inventory, and VAT rates.';
                    Visible = CustomerTemplateStepVisible;
                }
                group(Control18)
                {
                    InstructionalText = 'Choose Next to do the same thing for vendor templates.';
                    ShowCaption = false;
                    Visible = CustomerTemplateStepVisible;
                }
                group("Default VAT Rates on Vendor Templates")
                {
                    Caption = 'Default VAT Rates on Vendor Templates';
                    InstructionalText = 'Specify default VAT rates for vendor templates. When assigned to vendors, vendor templates apply default settings for posting, including VAT rates.';
                    Visible = VendorTemplateStepVisible;
                }
                group(Control29)
                {
                    InstructionalText = 'Choose Next to repeat this for item templates.';
                    ShowCaption = false;
                    Visible = VendorTemplateStepVisible;
                }
                group("Default VAT Rates on Item Templates")
                {
                    Caption = 'Default VAT Rates on Item Templates';
                    InstructionalText = 'Specify default VAT rates for item templates. When assigned to items, item templates apply default settings for posting, including VAT rates.';
                    Visible = ItemTemplateStepVisible;
                }
                part(VATAssistedSetupTemplate; "VAT Assisted Setup Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = ' ';
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = ManualVATStepVisible or FinalStepVisible;
                group("Manual setup required")
                {
                    Caption = 'Manual setup required';
                    Visible = ManualVATStepVisible;
                    group(Control32)
                    {
                        InstructionalText = 'Looks like you''ve already posted one or more transactions that include VAT. To avoid mistakes, you''ll have to manually set up VAT calculations.';
                        ShowCaption = false;
                        Visible = ManualVATStepVisible;
                    }
                    group(Control24)
                    {
                        InstructionalText = 'To do that now, choose a VAT posting setup. In the VAT Posting Setup window, add or edit the VAT business posting group, VAT product posting group, and other details as needed.';
                        ShowCaption = false;
                        Visible = ManualVATStepVisible;
                    }
                }
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'VAT is set up and ready to go.';
                    Visible = FinalStepVisible;
                }
                group(Control30)
                {
                    InstructionalText = 'To apply the settings, choose Finish.';
                    ShowCaption = false;
                    Visible = FinalStepVisible;
                }
                group(Control25)
                {
                    InstructionalText = 'To review your VAT settings later, open the VAT Setup window.';
                    ShowCaption = false;
                    Visible = FinalStepVisible;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if AutoVATSetupIsAllowed then
                        FinishAction()
                    else
                        CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        AutoVATSetupIsAllowed := WizardIsAllowed();
        if not AutoVATSetupIsAllowed then
            Step := Step::Finish;

        WizardNotification.Id := Format(CreateGuid());
        EnableControls();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if WizardIsAllowed() and GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"VAT Setup Wizard") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        ClientTypeManagement: Codeunit "Client Type Management";
        WizardNotification: Notification;
        Step: Option Start,VATBusPostingGroup,VATProdPostingRates,VATProdPostingAccounts,VATProdPostingClauses,CustomerTemplates,VendorTemplates,ItemTemplates,Finish;
        TopBannerVisible: Boolean;
        ManualVATStepVisible: Boolean;
        FirstStepVisible: Boolean;
        VATBusPostGrpPartStepVisible: Boolean;
        VATProdPostGrpPartStepVisible: Boolean;
        VATProdClausesStepVisible: Boolean;
        VATProdRatesStepVisible: Boolean;
        VATProdAccountStepVisible: Boolean;
        CustomerTemplateStepVisible: Boolean;
        VendorTemplateStepVisible: Boolean;
        ItemTemplateStepVisible: Boolean;
        TemplateStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        NAVNotSetUpQst: Label 'VAT has not been set up.\\Are you sure you want to exit?';
        NoBusPostingGroupErr: Label 'You must to have at least one VAT business posting group.';
        VATAssistedRatesMsg: Label 'You must select at least one item or service.';
        VATAssistedBusPostingGrpMsg: Label 'You must select at least one VAT business posting group.';
        AutoVATSetupIsAllowed: Boolean;
        InvalidVATBusGrpMsg: Label '%1 is not valid VAT Business group.', Comment = '%1 is code for vat bus group which is not valid anymore ';
        InvaledVATProductMsg: Label '%1 is not valid VAT product group.', Comment = '%1 is code for vat product group which is not valid anymore ';
        EmptyGLAccountsWarning: Boolean;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::VATBusPostingGroup:
                ShowVATBusPostingGroup();
            Step::VATProdPostingRates:
                ShowProdRatesGroup();
            Step::VATProdPostingAccounts:
                ShowProdAccountGroup();
            Step::VATProdPostingClauses:
                ShowProdClausesGroup();
            Step::CustomerTemplates:
                ShowCustomerTemplatesStep();
            Step::VendorTemplates:
                ShowVendorTemplatesStep();
            Step::ItemTemplates:
                ShowItemTemplatesStep();
            Step::Finish:
                if AutoVATSetupIsAllowed then
                    ShowFinishStep()
                else
                    ShowManualStep();
        end;
    end;

    local procedure FinishAction()
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if not AutoVATSetupIsAllowed then
            exit;
        ClearVATProdPostingGrp();
        ClearVATBusPostingGrp();
        ClearVATSetup();

        VATAssistedSetupBusGrp.SetRange(Selected, true);
        VATAssistedSetupBusGrp.SetRange(Default, false);

        VATSetupPostingGroups.SetRange(Selected, true);
        VATSetupPostingGroups.SetRange(Default, false);

        if not VATAssistedSetupBusGrp.FindSet() then
            Error(NoBusPostingGroupErr);

        repeat
            AddVATBusPostingGrp(VATAssistedSetupBusGrp.Code, VATAssistedSetupBusGrp.Description);
            if VATSetupPostingGroups.FindSet() then
                repeat
                    CreateVATPostingSetupLines(VATSetupPostingGroups, VATAssistedSetupBusGrp.Code);
                until VATSetupPostingGroups.Next() = 0;
        until VATAssistedSetupBusGrp.Next() = 0;

        CreatVATSetupWithoutBusPostingGrp();

        UpdateTemplates();

        ClearGenBusPostingGrpInvalidDefaults();
        ClearGenProdPostingGrpInvalidDefaults();

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"VAT Setup Wizard");
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        HideNotification();

        if Backwards then
            Step := Step - 1
        else
            if StepValidation() then
                Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowManualStep()
    begin
        ManualVATStepVisible := true;
        BackActionEnabled := false;
        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;
        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowVATBusPostingGroup()
    begin
        VATBusPostGrpPartStepVisible := true;
    end;

    local procedure ShowProdClausesGroup()
    begin
        VATProdPostGrpPartStepVisible := true;
        VATProdClausesStepVisible := true;
        CurrPage.VATProdPostGrpPart.PAGE.ShowVATClauses();
    end;

    local procedure ShowProdRatesGroup()
    begin
        VATProdPostGrpPartStepVisible := true;
        VATProdRatesStepVisible := true;
        CurrPage.VATProdPostGrpPart.PAGE.ShowVATRates();
    end;

    local procedure ShowProdAccountGroup()
    begin
        VATProdPostGrpPartStepVisible := true;
        VATProdAccountStepVisible := true;
        CurrPage.VATProdPostGrpPart.PAGE.ShowVATAccounts();
    end;

    local procedure ShowCustomerTemplatesStep()
    begin
        CustomerTemplateStepVisible := true;
        TemplateStepVisible := true;
        CurrPage.VATAssistedSetupTemplate.PAGE.ShowCustomerTemplate();
        NextActionEnabled := true;
    end;

    local procedure ShowVendorTemplatesStep()
    begin
        VendorTemplateStepVisible := true;
        TemplateStepVisible := true;
        CurrPage.VATAssistedSetupTemplate.PAGE.ShowVendorTemplate();
        NextActionEnabled := true;
    end;

    local procedure ShowItemTemplatesStep()
    begin
        ItemTemplateStepVisible := true;
        TemplateStepVisible := true;
        CurrPage.VATAssistedSetupTemplate.PAGE.ShowItemTemplate();
        NextActionEnabled := true;
    end;

    local procedure ShowFinishStep()
    begin
        FinalStepVisible := true;
        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        VATProdPostGrpPartStepVisible := false;
        VATBusPostGrpPartStepVisible := false;
        VATProdClausesStepVisible := false;
        VATProdRatesStepVisible := false;
        VATProdAccountStepVisible := false;
        CustomerTemplateStepVisible := false;
        VendorTemplateStepVisible := false;
        ItemTemplateStepVisible := false;
        TemplateStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            TopBannerVisible := MediaRepositoryDone.Image.HasValue;
    end;

    local procedure ClearVATSetup()
    var
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATClause.DeleteAll();
        VATPostingSetup.DeleteAll();
    end;

    local procedure AddVATProdPostingGroups(GroupCode: Code[20]; GroupDesc: Text[100])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if VATProductPostingGroup.Get(GroupCode) then
            exit;
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Validate(Code, GroupCode);
        VATProductPostingGroup.Validate(Description, GroupDesc);
        VATProductPostingGroup.Insert(true);
    end;

    local procedure AddVATBusPostingGrp(VATBusPostingCode: Code[20]; VATBusPostingDesc: Text[100])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        if VATBusinessPostingGroup.Get(VATBusPostingCode) then
            exit;

        VATBusinessPostingGroup.Validate(Code, VATBusPostingCode);
        VATBusinessPostingGroup.Validate(Description, VATBusPostingDesc);
        VATBusinessPostingGroup.Insert(true);
    end;

    local procedure AddVATClause(ClauseCode: Code[20]; ClauseDescription: Text[250])
    var
        VATClause: Record "VAT Clause";
    begin
        if VATClause.Get(ClauseCode) then
            exit;

        VATClause.Init();
        VATClause.Validate(Code, ClauseCode);
        VATClause.Validate(Description, ClauseDescription);
        VATClause.Insert(true);
    end;

    local procedure AddVATPostingGroup(VATSetupPostingGroups: Record "VAT Setup Posting Groups"; IsService: Boolean; VATBusPostingGrpCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        AddVATProdPostingGroups(VATSetupPostingGroups."VAT Prod. Posting Group",
          VATSetupPostingGroups."VAT Prod. Posting Grp Desc.");
        InitVATPostingSetup(VATPostingSetup, VATSetupPostingGroups, VATBusPostingGrpCode);
        VATPostingSetup.Validate("EU Service", IsService);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATSetupPostingGroups."VAT Prod. Posting Group");
        if VATSetupPostingGroups."VAT %" = 100 then
            VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Insert();
    end;

    local procedure InitVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATSetupPostingGroups: Record "VAT Setup Posting Groups"; VATBusPostingGrpCode: Code[20])
    begin
        VATPostingSetup.Init();
        VATPostingSetup.TransferFields(VATSetupPostingGroups);
        VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusPostingGrpCode);
        if VATSetupPostingGroups."VAT Clause Desc" <> '' then
            VATPostingSetup."VAT Clause Code" := VATSetupPostingGroups."VAT Prod. Posting Group";
    end;

    local procedure CreateVATPostingSetupLines(VATSetupPostingGroups: Record "VAT Setup Posting Groups"; VATBusPostingGrpCode: Code[20])
    var
        IsService: Boolean;
    begin
        if VATSetupPostingGroups."VAT Clause Desc" <> '' then
            AddVATClause(VATSetupPostingGroups."VAT Prod. Posting Group", VATSetupPostingGroups."VAT Clause Desc");

        IsService := VATSetupPostingGroups."Application Type" = VATSetupPostingGroups."Application Type"::Services;
        AddVATPostingGroup(VATSetupPostingGroups, IsService, VATBusPostingGrpCode);
    end;

    local procedure WizardIsAllowed(): Boolean
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        Customer.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        Vendor.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        Item.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        exit(VATEntry.IsEmpty() and Customer.IsEmpty() and Vendor.IsEmpty() and Item.IsEmpty);
    end;

    local procedure StepValidation(): Boolean
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates";
        ErrorMessage: Text;
        ValidationErrorMsg: Text;
    begin
        case Step of
            Step::VATBusPostingGroup:
                if not VATAssistedSetupBusGrp.ValidateVATBusGrp() then
                    ErrorMessage := VATAssistedBusPostingGrpMsg;
            Step::VATProdPostingRates:
                if not VATSetupPostingGroups.ValidateVATRates() then
                    ErrorMessage := VATAssistedRatesMsg;
            Step::VATProdPostingAccounts:
                if not EmptyGLAccountsWarning then begin
                    VATSetupPostingGroups.ValidateGLAccountsExist(ErrorMessage);
                    EmptyGLAccountsWarning := true;
                end;
            Step::CustomerTemplates:
                if not VATAssistedSetupTemplates.ValidateCustomerTemplate(ValidationErrorMsg) then
                    ErrorMessage := StrSubstNo(InvalidVATBusGrpMsg, ValidationErrorMsg);
            Step::VendorTemplates:
                if not VATAssistedSetupTemplates.ValidateVendorTemplate(ValidationErrorMsg) then
                    ErrorMessage := StrSubstNo(InvalidVATBusGrpMsg, ValidationErrorMsg);
            Step::ItemTemplates:
                if not VATAssistedSetupTemplates.ValidateItemTemplate(ValidationErrorMsg) then
                    ErrorMessage := StrSubstNo(InvaledVATProductMsg, ValidationErrorMsg);
        end;

        if ErrorMessage = '' then
            exit(true);

        TrigerNotification(ErrorMessage);
        exit(false);
    end;

    local procedure UpdateTemplates()
    var
        VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates";
        Customer: Record Customer;
        Item: Record Item;
    begin
        VATAssistedSetupTemplates.Reset();
        if not VATAssistedSetupTemplates.FindSet() then
            exit;

        repeat
            if
               (VATAssistedSetupTemplates."Table ID" = DATABASE::Customer) or
               (VATAssistedSetupTemplates."Table ID" = DATABASE::Vendor)
            then
                AddOrUpdateConfigTemplateLine(VATAssistedSetupTemplates.Code, Customer.FieldNo("VAT Bus. Posting Group"),
                  VATAssistedSetupTemplates."Default VAT Bus. Posting Grp",
                  VATAssistedSetupTemplates."Table ID")
            else
                if VATAssistedSetupTemplates."Table ID" = DATABASE::Item then
                    AddOrUpdateConfigTemplateLine(VATAssistedSetupTemplates.Code, Item.FieldNo("VAT Prod. Posting Group"),
                      VATAssistedSetupTemplates."Default VAT Prod. Posting Grp",
                      VATAssistedSetupTemplates."Table ID");
        until VATAssistedSetupTemplates.Next() = 0;
    end;

    local procedure AddOrUpdateConfigTemplateLine(TemplateCode: Code[10]; FieldID: Integer; DefaultValue: Text[250]; TableId: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        if ConfigTemplateLine.GetLine(ConfigTemplateLine, TemplateCode, FieldID) then begin
            if DefaultValue = '' then begin
                ConfigTemplateLine.Delete();
                exit;
            end;
            ConfigTemplateLine."Default Value" := DefaultValue;
            ConfigTemplateLine.Modify();
        end else
            if DefaultValue <> '' then
                ConfigTemplateManagement.InsertConfigTemplateLine(TemplateCode, FieldID, DefaultValue, TableId);
    end;

    local procedure TrigerNotification(NotificationMsg: Text)
    begin
        WizardNotification.Recall();
        WizardNotification.Message(NotificationMsg);
        WizardNotification.Send();
    end;

    local procedure CreatVATSetupWithoutBusPostingGrp()
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        if VATAssistedSetupBusGrp.Get('', false) then
            exit;

        VATSetupPostingGroups.SetRange(Selected, true);
        VATSetupPostingGroups.SetRange(Default, false);

        if VATSetupPostingGroups.FindSet() then
            repeat
                CreateVATPostingSetupLines(VATSetupPostingGroups, '');
            until VATSetupPostingGroups.Next() = 0;
    end;

    local procedure HideNotification()
    begin
        CurrPage.VATProdPostGrpPart.PAGE.HideNotification();
        CurrPage."VAT Bus. Post. Grp Part".PAGE.HideNotification();
        WizardNotification.Message := '';
        WizardNotification.Recall();

        if Step::VATProdPostingAccounts <> Step then
            EmptyGLAccountsWarning := false;
    end;

    local procedure ClearVATProdPostingGrp()
    var
        Item: Record Item;
        VATProductPostingGroup: Record "VAT Product Posting Group";
        ShouldDelete: Boolean;
    begin
        if VATProductPostingGroup.FindSet() then
            repeat
                Item.SetRange("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                ShouldDelete := Item.IsEmpty();
                OnBeforeDeleteVATProdPostingGroup(VATProductPostingGroup, ShouldDelete);
                if ShouldDelete then
                    VATProductPostingGroup.Delete();
            until VATProductPostingGroup.Next() = 0;
    end;

    local procedure ClearVATBusPostingGrp()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        if not VATBusinessPostingGroup.FindSet() then
            exit;

        repeat
            Customer.SetRange("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
            Vendor.SetRange("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
            if (Vendor.IsEmpty()) and (Customer.IsEmpty()) then
                VATBusinessPostingGroup.Delete();
        until VATBusinessPostingGroup.Next() = 0;
    end;

    local procedure ClearGenBusPostingGrpInvalidDefaults()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        if GenBusinessPostingGroup.IsEmpty() then
            exit;

        GenBusinessPostingGroup.FindSet(true);
        repeat
            if not VATBusinessPostingGroup.Get(GenBusinessPostingGroup."Def. VAT Bus. Posting Group") then begin
                GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", '');
                GenBusinessPostingGroup.Modify();
            end;
        until GenBusinessPostingGroup.Next() = 0;
    end;

    local procedure ClearGenProdPostingGrpInvalidDefaults()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if GenProductPostingGroup.IsEmpty() then
            exit;

        GenProductPostingGroup.FindSet(true);
        repeat
            if not VATProductPostingGroup.Get(GenProductPostingGroup."Def. VAT Prod. Posting Group") then begin
                GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", '');
                GenProductPostingGroup.Modify();
            end;
        until GenProductPostingGroup.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteVATProdPostingGroup(var VATProductPostingGroup: Record "VAT Product Posting Group"; var ShouldDelete: Boolean)
    begin
    end;
}

