// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

page 5351 "CRM Sales Quote List"
{
    ApplicationArea = Suite;
    Caption = 'Sales Quotes - Microsoft Dynamics 365 Sales';
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "CRM Quote";
    SourceTableView = where(StateCode = filter(Active | Won));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(StateCode; Rec.StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    OptionCaption = 'Draft,Active,Won,Closed';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(TotalAmount; Rec.TotalAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(EffectiveFrom; Rec.EffectiveFrom)
                {
                    ApplicationArea = Suite;
                    Caption = 'Effective From';
                    ToolTip = 'Specifies which date the sales quote is valid from.';
                }
                field(EffectiveTo; Rec.EffectiveTo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Effective To';
                    ToolTip = 'Specifies which date the sales quote is valid to.';
                }
                field(ClosedOn; Rec.ClosedOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Closed On';
                    ToolTip = 'Specifies the date when quote was closed.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Sales record is coupled to Business Central.';
                }
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
                action(CRMGoToQuote)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quote';
                    Image = CoupledQuote;
                    ToolTip = 'Open the selected Dynamics 365 Sales quote.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(DATABASE::"CRM Quote", Rec.QuoteId));
                    end;
                }
            }
            group(ActionGroupNAV)
            {
                Caption = 'Business Central';
                Visible = CRMIntegrationEnabled;
                action(ProcesseInNAV)
                {
                    ApplicationArea = Suite;
                    Caption = 'Process in Business Central';
                    Enabled = HasRecords and CRMIntegrationEnabled;
                    Image = New;
                    ToolTip = 'Create a sales quote in Business Central for the quote entity in Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        OrderSalesHeader: Record "Sales Header";
                        CRMQuoteToSalesQuote: Codeunit "CRM Quote to Sales Quote";
                        PageManagement: Codeunit "Page Management";
                    begin
                        if Rec.IsEmpty() then
                            exit;

                        if Coupled = 'Yes' then
                            Error(AlreadyProcessedErr);

                        if CRMQuoteToSalesQuote.ProcessInNAV(Rec, SalesHeader) then begin
                            Commit();
                            if SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.") then begin
                                OrderSalesHeader.SetRange("Quote No.", SalesHeader."No.");
                                if OrderSalesHeader.FindFirst() then
                                    PageManagement.PageRun(OrderSalesHeader)
                                else
                                    PageManagement.PageRun(SalesHeader)
                            end;
                        end;
                    end;
                }
                action(ShowOnlyUncoupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Hide Coupled Quotes';
                    Enabled = HasRecords;
                    Image = FilterLines;
                    ToolTip = 'Do not show coupled quotes.';

                    trigger OnAction()
                    begin
                        Rec.MarkedOnly(true);
                    end;
                }
                action(ShowAll)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Coupled Quotes';
                    Enabled = HasRecords;
                    Image = ClearFilter;
                    ToolTip = 'Show coupled quotes.';

                    trigger OnAction()
                    begin
                        Rec.MarkedOnly(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ProcesseInNAV_Promoted; ProcesseInNAV)
                {
                }
                group(Category_Synchronize)
                {
                    Caption = 'Synchronize';

                    actionref(CRMGoToQuote_Promoted; CRMGoToQuote)
                    {
                    }
                }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Dynamics 365 Sales', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HasRecords := not IsNullGuid(Rec.QuoteId);
    end;

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        BlankGUID: Guid;
        Style: Integer;
    begin
        CRMIntegrationRecord.SetRange("CRM ID", Rec.QuoteId);
        if CRMIntegrationRecord.FindFirst() then begin
            if CurrentlyCoupledCRMQuote.QuoteId = Rec.QuoteId then
                Style := 1
            else
                if Rec.StateCode = Rec.StateCode::Active then
                    Style := 2
                else
                    if Rec.StateCode = Rec.StateCode::Won then
                        if CRMIntegrationRecord."Integration ID" = BlankGUID then
                            Style := 2
                        else
                            Style := 3;
        end else
            Style := 3;

        if Style = 1 then begin
            Coupled := 'Current';
            FirstColumnStyle := 'Strong';
            Rec.Mark(true);
        end else
            if Style = 2 then begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end else
                if Style = 3 then begin
                    Coupled := 'No';
                    FirstColumnStyle := 'None';
                    Rec.Mark(true);
                end;
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        CDSCompany: Record "CDS Company";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
        MultipleCompanies: Boolean;
    begin
        CRMIntegrationEnabled := CRMConnectionSetup.IsEnabled();
        MultipleCompanies := (CDSCompany.Count() > 1);
        Rec.FilterGroup(2);
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            if not MultipleCompanies then
                Rec.SetFilter(CompanyId, '%1|%2', CDSCompany.CompanyId, EmptyGuid)
            else begin
                Rec.SetRange(CompanyId, CDSCompany.CompanyId);
                ShowMultipleCompanyNotification();
            end;
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMQuote: Record "CRM Quote";
        CRMIntegrationEnabled: Boolean;
        HasRecords: Boolean;
        Coupled: Text;
        FirstColumnStyle: Text;
        AlreadyProcessedErr: Label 'The current record has already been processed in Business Central.';
        MultipleCompanyNotificationLbl: Label 'You are connected to Dynamics 365 Sales from multiple companies. This page shows only Dynamics 365 Sales quotes with Company field set to this Business Central company. To see all quotes, change the filter on the page, or set their Company field in Dynamics 365 Sales.', Comment = 'Dynamics 365 Sales should not be translated';
        LearnMoreLbl: Label 'Learn more';

    procedure SetCurrentlyCoupledCRMQuote(CRMQuote: Record "CRM Quote")
    begin
        CurrentlyCoupledCRMQuote := CRMQuote;
    end;

    local procedure ShowMultipleCompanyNotification()
    var
        MultipleCompanyNotification: Notification;
    begin
        MultipleCompanyNotification.Id := GetMultipleCompanyNotificationId();
        MultipleCompanyNotification.Message(MultipleCompanyNotificationLbl);
        MultipleCompanyNotification.Scope(NotificationScope::LocalScope);
        MultipleCompanyNotification.AddAction(LearnMoreLbl, Codeunit::"CRM Integration Management", 'MultipleCompanyLearnMore');
        MultipleCompanyNotification.Send();
    end;

    local procedure GetMultipleCompanyNotificationId(): Guid
    begin
        exit('76df9d19-549b-4cb8-8d81-43f2007e0188');
    end;
}

