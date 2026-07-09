// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using System.Environment;
using System.Environment.Configuration;
using System.Utilities;

page 27010 "Mexican CFDI Wizard"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Set up Mexican CFDI information';
    PageType = NavigatePage;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinalStepVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
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
                Visible = TopBannerVisible and FinalStepVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control25)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to the assisted setup guide for Mexican CFDI reporting")
                {
                    Caption = 'Welcome to the assisted setup guide for Mexican CFDI reporting';
                    Visible = FirstStepVisible;
                    group(Control1020000)
                    {
                        InstructionalText = 'This guide helps you set up the Mexican CFDI features for reporting information to SAT.';
                        ShowCaption = false;
                        Visible = FirstStepVisible;
                    }
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                Visible = PopulateStepVisible;
                group("Get the information that SAT requires")
                {
                    Caption = 'Get the information that SAT requires';
                    Visible = PopulateStepVisible;
                    group(Control1020001)
                    {
                        InstructionalText = 'Click Next to get the information that SAT requires for CFDI reporting.';
                        ShowCaption = false;
                        Visible = PopulateStepVisible;
                    }
                }
            }
            group(Control1020004)
            {
                ShowCaption = false;
                Visible = MapStepVisible;
                group("Map Information to SAT requirements")
                {
                    Caption = 'Map Information to SAT requirements';
                    Visible = MapStepVisible;
                    group(Control1020002)
                    {
                        InstructionalText = 'Click Next to map your country codes and units of measure to the values that SAT requires.';
                        ShowCaption = false;
                        Visible = MapStepVisible;
                    }
                }
            }
            group(Control1020007)
            {
                ShowCaption = false;
                Visible = CompanyStepVisible;
                group("Set company SAT information")
                {
                    Caption = 'Set company SAT information';
                    Visible = CompanyStepVisible;
                    group(Control1020005)
                    {
                        InstructionalText = 'You will need to set your SAT Postal Code and SAT Tax Regime Classification for your company.';
                        ShowCaption = false;
                        Visible = CompanyStepVisible;
                        field(PostCode; PostCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'SAT Postal Code';
                            Visible = CompanyStepVisible;

                            trigger OnValidate()
                            begin
                                NextActionEnabled := (PostCode <> '') and (TaxScheme <> '');
                            end;
                        }
                        field(TaxScheme; TaxScheme)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'SAT Tax Regime Classification';
                            TableRelation = "SAT Tax Scheme"."SAT Tax Scheme";
                            Visible = CompanyStepVisible;

                            trigger OnValidate()
                            begin
                                NextActionEnabled := (PostCode <> '') and (TaxScheme <> '');
                            end;
                        }
                    }
                }
            }
            group(Control1020020)
            {
                ShowCaption = false;
                Visible = PaymentTermsStepVisible;
                group("Map your payment terms to those that SAT requires.")
                {
                    Caption = 'Map your payment terms to those that SAT requires.';
                    Visible = PaymentTermsStepVisible;
                    part("Payment Terms"; "SAT Payment Terms Subform")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Terms';
                        Visible = PaymentTermsStepVisible;
                    }
                }
            }
            group(Control1020025)
            {
                ShowCaption = false;
                Visible = PaymentMethodsStepVisible;
                group("Map your payment methods to those that SAT requires.")
                {
                    Caption = 'Map your payment methods to those that SAT requires.';
                    Visible = PaymentMethodsStepVisible;
                    part("Payment Methods"; "SAT Payment Methods Subform")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Methods';
                        Visible = PaymentMethodsStepVisible;
                    }
                }
            }
            group(Control1020017)
            {
                ShowCaption = false;
                Visible = ItemStepVisible;
                group("Set the SAT Item Classification for each item you will be using in your sales documents")
                {
                    Caption = 'Set the SAT Item Classification for each item you will be using in your sales documents';
                    Visible = ItemStepVisible;
                    part(Control1020019; "SAT Item Subform")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = ItemStepVisible;
                    }
                }
            }
            group(Control1020028)
            {
                ShowCaption = false;
                Visible = CustomerStepVisible;
                group("Set up SAT information for each customer you will be using in your sales documents")
                {
                    Caption = 'Set up SAT information for each customer you will be using in your sales documents';
                    Visible = CustomerStepVisible;
                    part(Control1020026; "SAT Customer Subform")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = CustomerStepVisible;
                    }
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Control1020010)
                    {
                        InstructionalText = 'You still have Country Codes that have not had their SAT Country Codes set.';
                        ShowCaption = false;
                        Visible = FinalStepVisible and not AllCountriesMapped;
                    }
                    group(Control1020016)
                    {
                        InstructionalText = 'You still have Units of Measure that have not had their SAT Unit of Measure Codes set.';
                        ShowCaption = false;
                        Visible = FinalStepVisible and not AllUofMsMapped;
                    }
                    group(Control1020011)
                    {
                        InstructionalText = 'Choose Finish to complete this assisted setup guide.';
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
                ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    Finished := true;
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Mexican CFDI Wizard");
                    FinishAction();
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
        CompanyInformation: Record "Company Information";
    begin
        Step := Step::Start;
        EnableControls();
        if CompanyInformation.FindFirst() then begin
            PostCode := CompanyInformation."SAT Postal Code";
            TaxScheme := CompanyInformation."SAT Tax Regime Classification";
        end;
        GeneralLdegerSetup.Get();
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
        GeneralLdegerSetup: Record "General Ledger Setup";
        Step: Option Start,Populate,Map,Company,PaymentMethods,PaymentTerms,Item,Customer,Finish;
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        PopulateStepVisible: Boolean;
        MapStepVisible: Boolean;
        CompanyStepVisible: Boolean;
        PaymentTermsStepVisible: Boolean;
        PaymentMethodsStepVisible: Boolean;
        ItemStepVisible: Boolean;
        CustomerStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        SetupNotCompletedQst: Label 'The setup has not yet been completed.\\Are you sure that you want to exit?';
        Finished: Boolean;
        AllCountriesMapped: Boolean;
        AllUofMsMapped: Boolean;
        PostCode: Code[10];
        TaxScheme: Code[10];

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::Populate:
                ShowPopulateStep();
            Step::Map:
                ShowMapStep();
            Step::Company:
                ShowCompanyStep();
            Step::PaymentTerms:
                ShowPaymentTermsStep();
            Step::PaymentMethods:
                ShowPaymentMethodsStep();
            Step::Item:
                ShowItemStep();
            Step::Customer:
                ShowCustomerStep();
            Step::Finish:
                ShowFinalStep();
        end;
    end;

    local procedure FinishAction()
    begin
        GeneralLdegerSetup.Modify(true);
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    var
        SATUtilities: Codeunit "SAT Utilities";
    begin
        // find out if system data already entered.  Then move by 2.
        if (Step = Step::Start) and (not Backwards) then begin
            if not ConfirmCustomerConsent() then
                exit;
            if DoesSATInfoAlreadyExist() then begin
                Step := Step + 2;
                EnableControls();
                exit;
            end;
        end;
        if (Step = Step::Map) and Backwards then
            if DoesSATInfoAlreadyExist() then begin
                Step := Step - 2;
                EnableControls();
                exit;
            end;

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        if (Step = Step::Company) and (not Backwards) then  // Came from Map step, need to run the mapping
            MapSATInformation();
        if (Step = Step::PaymentMethods) and (not Backwards) then // Came from Company Info setting, save the values
            SetCompanyInformation();
        if (Step = Step::Map) and (not Backwards) then begin// Came from Populate setting, save the values
            SATUtilities.PopulateSATInformation();
            SATUtilities.PopulatePACWebServiceData();
        end;
        EnableControls();
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;
        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowPopulateStep()
    begin
        FirstStepVisible := false;
        PopulateStepVisible := true;
        MapStepVisible := false;
        CompanyStepVisible := false;
        PaymentTermsStepVisible := false;
        PaymentMethodsStepVisible := false;
        ItemStepVisible := false;
        CustomerStepVisible := false;
        FinishActionEnabled := false;
    end;

    local procedure ShowMapStep()
    begin
        BackActionEnabled := false;
        FirstStepVisible := false;
        PopulateStepVisible := false;
        MapStepVisible := true;
        CompanyStepVisible := false;
        PaymentTermsStepVisible := false;
        PaymentMethodsStepVisible := false;
        ItemStepVisible := false;
        CustomerStepVisible := false;
        FinishActionEnabled := false;
    end;

    local procedure ShowCompanyStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := (PostCode <> '') or (TaxScheme <> '');

        FirstStepVisible := false;
        PopulateStepVisible := false;
        MapStepVisible := false;
        CompanyStepVisible := true;
        PaymentTermsStepVisible := false;
        PaymentMethodsStepVisible := false;
        ItemStepVisible := false;
        CustomerStepVisible := false;
        FinishActionEnabled := false;
    end;

    local procedure ShowPaymentTermsStep()
    begin
        FirstStepVisible := false;
        PopulateStepVisible := false;
        MapStepVisible := false;
        CompanyStepVisible := false;
        PaymentTermsStepVisible := true;
        PaymentMethodsStepVisible := false;
        ItemStepVisible := false;
        CustomerStepVisible := false;
        FinishActionEnabled := false;
    end;

    local procedure ShowPaymentMethodsStep()
    begin
        FirstStepVisible := false;
        PopulateStepVisible := false;
        MapStepVisible := false;
        CompanyStepVisible := false;
        PaymentTermsStepVisible := false;
        PaymentMethodsStepVisible := true;
        ItemStepVisible := false;
        CustomerStepVisible := false;
        FinishActionEnabled := false;
    end;

    local procedure ShowItemStep()
    begin
        FirstStepVisible := false;
        PopulateStepVisible := false;
        MapStepVisible := false;
        CompanyStepVisible := false;
        PaymentTermsStepVisible := false;
        PaymentMethodsStepVisible := false;
        ItemStepVisible := true;
        CustomerStepVisible := false;
        FinishActionEnabled := false;
    end;

    local procedure ShowCustomerStep()
    begin
        FirstStepVisible := false;
        PopulateStepVisible := false;
        MapStepVisible := false;
        CompanyStepVisible := false;
        PaymentTermsStepVisible := false;
        PaymentMethodsStepVisible := false;
        ItemStepVisible := false;
        CustomerStepVisible := true;
        FinishActionEnabled := false;
    end;

    local procedure ShowFinalStep()
    begin
        FinalStepVisible := true;
        BackActionEnabled := false;
        NextActionEnabled := false;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := true;
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        PopulateStepVisible := false;
        MapStepVisible := false;
        CompanyStepVisible := false;
        PaymentTermsStepVisible := false;
        PaymentMethodsStepVisible := false;
        ItemStepVisible := false;
        CustomerStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType)) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
        EnableControls();
    end;

    local procedure DoesSATInfoAlreadyExist(): Boolean
    var
        SATRelationshipType: Record "SAT Relationship Type";
        SATState: Record "SAT State";
    begin
        if SATRelationshipType.IsEmpty() then
            exit(false);
        if SATState.IsEmpty() then
            exit(false);
        exit(true);
    end;

    local procedure MapSATInformation()
    var
        CountryRegion: Record "Country/Region";
        UnitOfMeasure: Record "Unit of Measure";
        SATUtilities: Codeunit "SAT Utilities";
    begin
        CountryRegion.SetRange("SAT Country Code", '');
        if CountryRegion.FindFirst() then begin
            SATUtilities.MapCountryCodes();
            CountryRegion.SetRange("SAT Country Code", '');
            if CountryRegion.FindFirst() then
                AllCountriesMapped := false
            else
                AllCountriesMapped := true;
        end else
            AllCountriesMapped := true;

        UnitOfMeasure.SetRange("SAT UofM Classification", '');
        if UnitOfMeasure.FindFirst() then begin
            SATUtilities.MapUnitsofMeasure();
            UnitOfMeasure.SetRange("SAT UofM Classification", '');
            if UnitOfMeasure.FindFirst() then
                AllUofMsMapped := false
            else
                AllUofMsMapped := true;
        end else
            AllUofMsMapped := true;
    end;

    local procedure SetCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then begin
            CompanyInformation."SAT Postal Code" := PostCode;
            CompanyInformation."SAT Tax Regime Classification" := TaxScheme;
            CompanyInformation.Modify();
        end;
    end;

    local procedure ConfirmCustomerConsent(): Boolean
    begin
        GeneralLdegerSetup.Get();
        GeneralLdegerSetup.Validate("CFDI Enabled", true);
        exit(GeneralLdegerSetup."CFDI Enabled");
    end;
}

