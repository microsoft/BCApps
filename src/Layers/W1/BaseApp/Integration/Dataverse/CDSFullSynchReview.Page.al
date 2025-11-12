// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 7208 "CDS Full Synch. Review"
{
    Caption = 'Dataverse Full Synchronization Review', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Full Synch. Review Line";
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Editable = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name.';
                    Editable = false;
                }
                field("BC Page Id"; BCPageName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Business Central';
                    Tooltip = 'Open the selected page';
                    Width = 10;
                    trigger OnDrillDown()
                    begin
                        Page.Run(BCPageId);
                        CurrPage.Update();
                    end;
                }
                field("CDS Page Id"; CDSPageName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dataverse', Locked = true;
                    ToolTip = 'Open the selected page and present the existing Dataverse records.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    Width = 10;
                    trigger OnDrillDown()
                    begin

                        case CDSPageId of
                            Page::"CRM TransactionCurrency List":
                                OpenCRMTransactionCurrenciesListPage();
                            Page::"CDS Couple Salespersons":
                                OpenCRMSystemUserListPage();
                            Page::"CRM Contact List":
                                OpenCRMContactListPage();
                            Page::"CRM Payment Terms List":
                                OpenCRMPaymentTermsListPage();
                            Page::"CRM Freight Terms List":
                                OpenCRMFreightTermsListPage();
                            Page::"CRM Shipping Method List":
                                OpenCRMShippingMethodListPage();
                            else
                                OpenCRMAccountListPage();
                        end;

                    end;
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the direction in which data will synchronize.';
                }
                field("Initial Synchronization Recommendation"; InitialSynchRecommendation)
                {
                    Caption = 'Recommendation';
                    ApplicationArea = Suite;
                    Enabled = (Rec."Initial Synch Recommendation" = Rec."Initial Synch Recommendation"::"Couple Records");
                    StyleExpr = InitialSynchRecommendationStyle;
                    ToolTip = 'Specifies the recommended action for the initial synchronization.';

                    trigger OnDrillDown()
                    var
                        IntegrationFieldMapping: Record "Integration Field Mapping";
                        IntegrationTableMapping: Record "Integration Table Mapping";
                    begin
                        if not (InitialSynchRecommendation in [MatchBasedCouplingTxt, CouplingCriteriaSelectedTxt]) then
                            exit;

                        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                        case BCPageId of
                            Page::"Currencies":
                                IntegrationTableMapping.SetRange("Table ID", Database::Currency);
                            Page::"Salespersons/Purchasers":
                                IntegrationTableMapping.SetRange("Table ID", Database::"Salesperson/Purchaser");
                            Page::"Contact List":
                                IntegrationTableMapping.SetRange("Table ID", Database::Contact);
                            Page::"Vendor List":
                                IntegrationTableMapping.SetRange("Table ID", Database::Vendor);
                            Page::"Customer List":
                                IntegrationTableMapping.SetRange("Table ID", Database::Customer);
                            Page::"Payment Terms":
                                IntegrationTableMapping.SetRange("Table ID", Database::"Payment Terms");
                            Page::"Shipment Methods":
                                IntegrationTableMapping.SetRange("Table ID", Database::"Shipment Method");
                            Page::"Shipping Agents":
                                IntegrationTableMapping.SetRange("Table ID", Database::"Shipping Agent");
                            else
                                exit;
                        end;
                        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
                        if not IntegrationTableMapping.FindFirst() then
                            exit;
                        IntegrationFieldMapping.SetMatchBasedCouplingFilters(IntegrationTableMapping);
                        if Page.RunModal(Page::"Match Based Coupling Criteria", IntegrationFieldMapping) = Action::LookupOK then
                            CurrPage.Update(false);
                    end;
                }
                field("Multi Company Synch. Enabled"; Rec."Multi Company Synch. Enabled")
                {
                    ApplicationArea = Suite;
                    Visible = true;
                    ToolTip = 'Specifies if the multi-company synchronization should be enabled for the corresponding integration table mapping.';

                    trigger OnValidate()
                    begin
                        Message(RefreshToApplyTxt);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Refresh)
            {

                Caption = 'Refresh recommendation';

                action(RefreshRecommendations)
                {
                    ApplicationArea = Suite;
                    Caption = 'Refresh recommendation';
                    Image = Refresh;
                    ToolTip = 'Refresh the initial synchronization recommendations.';

                    trigger OnAction()
                    begin
                        Rec.DeleteAll();
                        Rec.Generate();
                        Commit();
                    end;
                }
            }
            group(Sync)
            {
                action(ScheduleFullSynch)
                {
                    ApplicationArea = Suite;
                    Caption = 'Recommend Full Synchronization';
                    Enabled = ActionRecommendFullSynchEnabled;
                    Image = RefreshLines;
                    ToolTip = 'Recommend full synchronization job for the selected line.';

                    trigger OnAction()
                    begin
                        Rec."Initial Synch Recommendation" := Rec."Initial Synch Recommendation"::"Full Synchronization";
                        Rec.Modify();
                        CurrPage.Update();
                    end;
                }
                action(ToggleMultiCompany)
                {
                    ApplicationArea = Suite;
                    Caption = 'Toggle Multi-Company Synchronization';
                    Visible = MultiCompanyCheckboxEnabled;
                    Image = ToggleBreakpoint;
                    ToolTip = 'Toggle multi-company synchronization for this table mapping.';

                    trigger OnAction()
                    begin
                        Rec.Validate("Multi Company Synch. Enabled", (not Rec."Multi Company Synch. Enabled"));
                        Commit();

                        Rec.DeleteAll();
                        Rec.Generate();
                        Commit();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RefreshRecommendations_Promoted; RefreshRecommendations)
                {
                }
                actionref(ScheduleFullSynch_Promoted; ScheduleFullSynch)
                {
                }
                actionref(ToggleMultiCompany_Promoted; ToggleMultiCompany)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        MultiCompanyCheckboxEnabled := CDSIntegrationImpl.MultipleCompaniesConnected();
    end;

    trigger OnAfterGetRecord()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        ActionStartEnabled := (not Rec.IsThereActiveSessionInProgress()) and Rec.IsThereBlankStatusLine();
        ActionRecommendFullSynchEnabled := (not Rec.IsThereActiveSessionInProgress()) and (Rec."Initial Synch Recommendation" = Rec."Initial Synch Recommendation"::"Couple Records");
        if Rec."Initial Synch Recommendation" <> Rec."Initial Synch Recommendation"::"Couple Records" then
            InitialSynchRecommendation := Format(Rec."Initial Synch Recommendation")
        else begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Rec.Name);
            IntegrationFieldMapping.SetRange("Use For Match-Based Coupling", true);
            if IntegrationFieldMapping.IsEmpty() then
                InitialSynchRecommendation := MatchBasedCouplingTxt
            else
                InitialSynchRecommendation := CouplingCriteriaSelectedTxt
        end;

        if InitialSynchRecommendation = CouplingCriteriaSelectedTxt then
            InitialSynchRecommendationStyle := 'Favorable'
        else
            InitialSynchRecommendationStyle := Rec.GetInitialSynchRecommendationStyleExpression(Format(Rec."Initial Synch Recommendation"));
        GetCDSPageId();
        GetBCPageId();
        GetCDSPageName();
        GetBCPageName();
    end;

    trigger OnInit()
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
        Commit();
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [Obsolete('Replaced by SetConnectionSetup(NewCDSConnectionSetup: Record "CDS Connection Setup"; NewUserPassword: SecretText)', '25.0')]
    procedure SetConnectionSetup(NewCDSConnectionSetup: Record "CDS Connection Setup"; NewUserPassword: Text)
    var
        NewUserPasswordAsSecretText: SecretText;
    begin
        NewUserPasswordAsSecretText := NewUserPassword;
        SetConnectionSetup(NewCDSConnectionSetup, NewUserPasswordAsSecretText);
    end;
#endif

    [Scope('OnPrem')]
    procedure SetConnectionSetup(NewCDSConnectionSetup: Record "CDS Connection Setup"; NewUserPassword: SecretText)
    begin
        CDSConnectionSetup := NewCDSConnectionSetup;
        UserPassword := NewUserPassword;
    end;

    local procedure GetCDSPageId()
    begin
        case Rec.Name of
            'CONTACT':
                CDSPageId := 5342;
            'CURRENCY':
                CDSPageId := 5345;
            'CUSTOMER':
                CDSPageId := 5341;
            'SALESPEOPLE':
                CDSPageId := 7209;
            'VENDOR':
                CDSPageId := 5341;
            'PAYMENT TERMS':
                CDSPageId := 7210;
            'SHIPMENT METHOD':
                CDSPageId := 7211;
            'SHIPPING AGENT':
                CDSPageId := 7212;
        end;
    end;

    local procedure GetBCPageId()
    begin
        case Rec.Name of
            'CONTACT':
                BCPageId := Page::"Contact List";
            'CURRENCY':
                BCPageId := Page::Currencies;
            'CUSTOMER':
                BCPageId := Page::"Customer List";
            'SALESPEOPLE':
                BCPageId := Page::"Salespersons/Purchasers";
            'VENDOR':
                BCPageId := Page::"Vendor List";
            'PAYMENT TERMS':
                BCPageId := Page::"Payment Terms";
            'SHIPMENT METHOD':
                BCPageId := Page::"Shipment Methods";
            'SHIPPING AGENT':
                BCPageId := Page::"Shipping Agents";
        end;
    end;

    local procedure GetCDSPageName()
    begin
        case Rec.Name of
            'CONTACT':
                CDSPageName := 'Contacts';
            'CURRENCY':
                CDSPageName := 'Transaction Currencies';
            'CUSTOMER':
                CDSPageName := 'Accounts';
            'SALESPEOPLE':
                CDSPageName := 'Users';
            'VENDOR':
                CDSPageName := 'Accounts';
            'PAYMENT TERMS':
                CDSPageName := 'Payment Terms';
            'SHIPMENT METHOD':
                CDSPageName := 'Freight Terms';
            'SHIPPING AGENT':
                CDSPageName := 'Shipping Methods';
        end;
    end;

    local procedure GetBCPageName()
    begin
        case Rec.Name of
            'CONTACT':
                BCPageName := 'Contacts';
            'CURRENCY':
                BCPageName := 'Currencies';
            'CUSTOMER':
                BCPageName := 'Customers';
            'SALESPEOPLE':
                BCPageName := 'Salespeople/Purchasers';
            'VENDOR':
                BCPageName := 'Vendors';
            'PAYMENT TERMS':
                BCPageName := 'Payment Terms';
            'SHIPMENT METHOD':
                BCPageName := 'Shipment Methods';
            'SHIPPING AGENT':
                BCPageName := 'Shipping Agents';
        end;
    end;

    local procedure OpenCRMContactListPage()
    var
        CRMContact: Record "CRM Contact";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMContactList: Page "CRM Contact List";
    begin
        CRMContact.Reset();
        CRMContact.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Contact"));
        if not CRMContact.FindSet() then;
        CRMContactList.SetRecord(CRMContact);
        CRMContactList.SetTableView(CRMContact);
        CRMContactList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMTransactionCurrenciesListPage()
    var
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMTransactionCurrencyList: Page "CRM TransactionCurrency List";
    begin
        CRMTransactionCurrency.Reset();
        CRMTransactionCurrency.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Transactioncurrency"));
        if not CRMTransactionCurrency.FindSet() then;
        CRMTransactionCurrencyList.SetRecord(CRMTransactionCurrency);
        CRMTransactionCurrencyList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMAccountListPage()
    var
        CRMAccount: Record "CRM Account";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMAccountList: Page "CRM Account List";
    begin
        CRMAccount.Reset();
        CRMAccount.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Account"));
        if BCPageId = PAGE::"Customer List" then
            CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Customer)
        else
            CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Vendor);
        if not CRMAccount.FindSet() then;
        CRMAccountList.SetTableView(CRMAccount);
        CRMAccountList.SetRecord(CRMAccount);
        CRMAccountList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMSystemUserListPage()
    var
        CRMSystemUser: Record "CRM Systemuser";
        CRMSystemuserList: Page "CRM Systemuser List";
    begin
        if CRMSystemUser.FindSet() then;
        CRMSystemuserList.SetRecord(CRMSystemUser);
        CRMSystemuserList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMPaymentTermsListPage()
    var
        CRMPaymentTermsList: Page "CRM Payment Terms List";
    begin
        CRMPaymentTermsList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMFreightTermsListPage()
    var
        CRMPFreightTermsList: Page "CRM Freight Terms List";
    begin
        CRMPFreightTermsList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMShippingMethodListPage()
    var
        CRMShippingMethodList: Page "CRM Shipping Method List";
    begin
        CRMShippingMethodList.Run();
        CurrPage.Update();
    end;

    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        UserPassword: SecretText;
        ActionStartEnabled: Boolean;
        ActionRecommendFullSynchEnabled: Boolean;
        MultiCompanyCheckboxEnabled: Boolean;
        BCPageId: Integer;
        CDSPageId: Integer;
        CDSPageName: Text;
        BCPageName: Text;
        InitialSynchRecommendation: Text;
        InitialSynchRecommendationStyle: Text;
        MatchBasedCouplingTxt: Label 'Select Coupling Criteria';
        CouplingCriteriaSelectedTxt: Label 'Review Selected Coupling Criteria';
        RefreshToApplyTxt: Label 'Choose action ''Refresh recommendation'' to apply the change.';
}

