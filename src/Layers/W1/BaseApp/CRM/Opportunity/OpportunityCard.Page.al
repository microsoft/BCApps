// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Reports;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.Foundation.Attachment;
using Microsoft.Integration.Dataverse;
using Microsoft.Sales.Document;

page 5124 "Opportunity Card"
{
    Caption = 'Opportunity Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = Opportunity;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the opportunity.';
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = ContactNoEditable;
                    ToolTip = 'Specifies the number of the contact that this opportunity is linked to.';

                    trigger OnValidate()
                    var
                        Contact: Record Contact;
                    begin
                        if Rec."Contact No." <> '' then
                            if Contact.Get(Rec."Contact No.") then
                                Contact.CheckIfPrivacyBlockedGeneric();
                        ContactNoOnAfterValidate();
                    end;
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the contact to which this opportunity is linked. The program automatically fills in this field when you have entered a number in the No. field.';
                }
                field(ContactPhoneNo; GlobalContact."Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Phone No.';
                    Importance = Additional;
                    Editable = false;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the contact to which this opportunity is linked.';
                }
                field(ContactMobilePhoneNo; GlobalContact."Mobile Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Mobile Phone No.';
                    Importance = Additional;
                    Editable = false;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the contact to which this opportunity is linked.';
                }
                field(ContactEmail; GlobalContact."E-Mail")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Email';
                    Importance = Additional;
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the contact to which this opportunity is linked.';
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the company of the contact person to which this opportunity is linked. The program automatically fills in this field when you have entered a number in the Contact Company No. field.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Editable = SalespersonCodeEditable;
                    ToolTip = 'Specifies the code of the salesperson that is responsible for the opportunity.';
                }
                field("Sales Document Type"; Rec."Sales Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SalesDocumentTypeEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the type of the sales document (Quote, Order, Posted Invoice). The combination of Sales Document No. and Sales Document Type specifies which sales document is assigned to the opportunity.';
                    ValuesAllowed = " ", Quote, Order;
                }
                field("Sales Document No."; Rec."Sales Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SalesDocumentNoEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the sales document that has been created for this opportunity.';
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = CampaignNoEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the campaign to which this opportunity is linked.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = PriorityEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the priority of the opportunity. There are three options:';
                }
                field("Sales Cycle Code"; Rec."Sales Cycle Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = SalesCycleCodeEditable;
                    ToolTip = 'Specifies the code of the sales cycle that the opportunity is linked to.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the opportunity. There are four options:';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies that the opportunity is closed.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the date that the opportunity was created.';
                }
                field("Date Closed"; Rec."Date Closed")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the date the opportunity was closed.';
                }
                field("Segment No."; Rec."Segment No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the segment (if any) that is linked to the opportunity.';
                }
            }
            part(Control25; "Opportunity Subform")
            {
                ApplicationArea = RelationshipMgmt;
                SubPageLink = "Opportunity No." = field("No.");
            }
        }
        area(factboxes)
        {
            part(Control7; "Opportunity Statistics FactBox")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Statistics';
                SubPageLink = "No." = field("No.");
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Opportunity),
                              "No." = field("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Oppo&rtunity")
            {
                Caption = 'Oppo&rtunity';
                Image = Opportunity;
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Opportunity Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Opportunity No." = field("No.");
                    RunPageView = sorting("Opportunity No.", Date);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Opportunity No." = field("No.");
                    RunPageView = sorting("Opportunity No.", Date);
                    ToolTip = 'View postponed interactions for opportunities.';
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Opportunity No." = field("No."),
                                  "System To-do Type" = filter(Organizer);
                    RunPageView = sorting("Opportunity No.");
                    ToolTip = 'View all marketing tasks that involve the opportunity.';
                }
                action("Co&mments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const(Opportunity),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Show Sales Quote")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Show Sales Quote';
                    Image = Quote;
                    ToolTip = 'Show the assigned sales quote.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        if (Rec."Sales Document Type" <> Rec."Sales Document Type"::Quote) or
                           (Rec."Sales Document No." = '')
                        then
                            Error(Text001);

                        if SalesHeader.Get(SalesHeader."Document Type"::Quote, Rec."Sales Document No.") then
                            PAGE.Run(PAGE::"Sales Quote", SalesHeader)
                        else
                            Error(Text002, Rec."Sales Document No.");
                    end;
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                action(CRMGotoOpportunity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunity';
                    Image = CoupledContactPerson;
                    ToolTip = 'Open the coupled Dynamics 365 Sales opportunity.';

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
                    ToolTip = 'Send or get updated data to or from Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        Opportunity: Record Opportunity;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        OpportunityRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Opportunity);
                        Opportunity.Next();

                        if Opportunity.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Opportunity.RecordId)
                        else begin
                            OpportunityRecordRef.GetTable(Opportunity);
                            CRMIntegrationManagement.UpdateMultipleNow(OpportunityRecordRef);
                        end
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
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales opportunity.';

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
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales opportunity.';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(Rec.RecordId);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the opportunity table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Activate the First Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activate First Stage';
                    Image = "Action";
                    ToolTip = 'Specify if the opportunity is to be activated. The status is set to In Progress.';
                    Visible = not Started;

                    trigger OnAction()
                    begin
                        Rec.StartActivateFirstStage();
                        CurrPage.Update(true);
                    end;
                }
                action(Update)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Update';
                    Image = Refresh;
                    ToolTip = 'Update all the actions that are related to your opportunity.';
                    Visible = Started;

                    trigger OnAction()
                    begin
                        Rec.UpdateOpportunity();
                    end;
                }
                action(CloseOpportunity)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Close';
                    Image = Close;
                    ToolTip = 'Close all the actions that are related to your opportunity.';
                    Visible = Started;

                    trigger OnAction()
                    begin
                        Rec.CloseOpportunity();
                    end;
                }
                action(CreateSalesQuote)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Sales &Quote';
                    Enabled = OppInProgress;
                    Image = Allocate;
                    ToolTip = 'Create a new sales quote with the opportunity inserted as the customer.';

                    trigger OnAction()
                    begin
                        Rec.CreateQuote();
                    end;
                }
                action("Print Details")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Print Details';
                    Image = Print;
                    ToolTip = 'View information about your sales stages, activities and planned tasks for an opportunity.';

                    trigger OnAction()
                    var
                        Opp: Record Opportunity;
                    begin
                        Opp := Rec;
                        Opp.SetRecFilter();
                        REPORT.Run(REPORT::"Opportunity - Details", true, false, Opp);
                    end;
                }
                action("Create &Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create &Interaction';
                    Image = CreateInteraction;
                    ToolTip = 'Create an interaction with a specified opportunity.';

                    trigger OnAction()
                    var
                        TempSegmentLine: Record "Segment Line" temporary;
                    begin
                        TempSegmentLine.CreateInteractionFromOpp(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Activate the First Stage_Promoted"; "Activate the First Stage")
                {
                }
                actionref(Update_Promoted; Update)
                {
                }
                actionref(CreateSalesQuote_Promoted; CreateSalesQuote)
                {
                }
                actionref(CloseOpportunity_Promoted; CloseOpportunity)
                {
                }
                actionref("Show Sales Quote_Promoted"; "Show Sales Quote")
                {
                }
                actionref("Create &Interaction_Promoted"; "Create &Interaction")
                {
                }
                actionref("Postponed &Interactions_Promoted"; "Postponed &Interactions")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Opportunity', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Interaction Log E&ntries_Promoted"; "Interaction Log E&ntries")
                {
                }
                actionref("T&asks_Promoted"; "T&asks")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CRMIntegrationEnabled;

                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(CRMGotoOpportunity_Promoted; CRMGotoOpportunity)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
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
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Contact: Record Contact;
    begin
        if Rec."Contact No." <> '' then
            if Contact.Get(Rec."Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        if Rec."Contact Company No." <> '' then
            if Contact.Get(Rec."Contact Company No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        UpdateEditable();
        OppInProgress := Rec.Status = Rec.Status::"In Progress";
        OppNo := Rec."No.";
    end;

    trigger OnAfterGetRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CRMIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);

        GlobalContact.GetOrClear(Rec."Contact No.");
    end;

    trigger OnInit()
    begin
        ContactNoEditable := true;
        PriorityEditable := true;
        CampaignNoEditable := true;
        SalespersonCodeEditable := true;
        SalesDocumentTypeEditable := true;
        SalesDocumentNoEditable := true;
        SalesCycleCodeEditable := true;
        Started := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Creation Date" := WorkDate();
        if Rec."Segment No." = '' then
            Rec.SetSegmentFromFilter();
        if Rec."Contact No." = '' then
            Rec.SetContactFromFilter();
        if Rec."Campaign No." = '' then
            Rec.SetCampaignFromFilter();
        Rec.SetDefaultSalesCycle();
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        OppNo := Rec."No.";
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Rec.Get(Rec."No.") then
            if (Rec."No." <> OppNo) and (Rec.Status = Rec.Status::"Not Started") then
                Rec.StartActivateFirstStage();
    end;

    var
        GlobalContact: Record Contact;
#pragma warning disable AA0074
        Text001: Label 'There is no sales quote assigned to this opportunity.';
#pragma warning disable AA0470
        Text002: Label 'Sales quote %1 doesn''t exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        OppNo: Code[20];
        SalesCycleCodeEditable: Boolean;
        SalesDocumentNoEditable: Boolean;
        SalesDocumentTypeEditable: Boolean;
        SalespersonCodeEditable: Boolean;
        CampaignNoEditable: Boolean;
        PriorityEditable: Boolean;
        ContactNoEditable: Boolean;
        Started: Boolean;
        OppInProgress: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;

    local procedure UpdateEditable()
    begin
        Started := (Rec.Status <> "Opportunity Status"::"Not Started");
        SalesCycleCodeEditable := Rec.Status = "Opportunity Status"::"Not Started";
        SalespersonCodeEditable := IsStatusLessThanWon();
        CampaignNoEditable := IsStatusLessThanWon();
        PriorityEditable := IsStatusLessThanWon();
        ContactNoEditable := IsStatusLessThanWon();
        SalesDocumentNoEditable := Rec.Status = "Opportunity Status"::"In Progress";
        SalesDocumentTypeEditable := Rec.Status = "Opportunity Status"::"In Progress";
    end;

    local procedure IsStatusLessThanWon(): Boolean
    begin
        exit(Rec.Status.AsInteger() < "Opportunity Status"::Won.AsInteger());
    end;

    local procedure ContactNoOnAfterValidate()
    begin
        Rec.CalcFields("Contact Name", "Contact Company Name");
    end;
}

