// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Reports;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.Integration.Dataverse;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using System.Email;
using System.Integration.Word;
using System.Text;

page 5052 "Contact List"
{
    ApplicationArea = Basic, Suite, Service;
    Caption = 'Contacts';
    CardPageID = "Contact Card";
    DataCaptionFields = "Company No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Contacts';
    AboutText = 'Manage and organize business relationships by storing contact details for people and companies, linking them to customers, vendors, employees, or bank accounts, and tracking communication and interaction history for efficient relationship management.';
    SourceTable = Contact;
    SourceTableView = sorting("Company Name", "Company No.", Type, Name);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the name of the contact. If the contact is a person, you can click the field to see the Name Details window.';
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name.';
                    Visible = false;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the company. If the contact is a person, Specifies the name of the company for which this contact works. This field is not editable.';
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the contact''s job title.';
                    Visible = false;
                }
                field("Business Relation"; Rec."Contact Business Relation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the existing business relation.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s phone number.';
                }
                field("Mobile Phone No."; Rec."Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s mobile telephone number.';
                    Visible = false;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the contact''s email.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s fax number.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the salesperson who normally handles this contact.';
                }
                field("Territory Code"; Rec."Territory Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the territory code for the contact.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the contact.';
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                    Visible = false;
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
                field(Minor; Rec.Minor)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the person''s age is below the definition of adulthood as recognized by law. Data for minors is blocked until a parent or guardian of the minor provides parental consent. You unblock the data by selecting the Parental Consent Received check box.';
                    Visible = false;
                }
                field("Parental Consent Received"; Rec."Parental Consent Received")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that a parent or guardian of the minor has provided their consent to allow the minor to use this service. When this check box is selected, data for the minor can be processed.';
                    Visible = false;
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the contact is coupled to a contact in Dataverse.';
                    Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                }
            }
        }
        area(factboxes)
        {
            part(Control128; "Contact Statistics FactBox")
            {
                ApplicationArea = RelationshipMgmt;
                SubPageLink = "No." = field("No."),
                              "Date Filter" = field("Date Filter");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("C&ontact")
            {
                Caption = 'C&ontact';
                Image = ContactPerson;
                group("Comp&any")
                {
                    Caption = 'Comp&any';
                    Enabled = CompanyGroupEnabled;
                    Image = Company;
                    action("Business Relations")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Business Relations';
                        Image = BusinessRelation;
                        RunObject = Page "Contact Business Relations";
                        RunPageLink = "Contact No." = field("Company No.");
                        ToolTip = 'View or edit the contact''s business relations, such as customers, vendors, banks, lawyers, consultants, competitors, and so on.';
                    }
                    action("Industry Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Industry Groups';
                        Image = IndustryGroups;
                        RunObject = Page "Contact Industry Groups";
                        RunPageLink = "Contact No." = field("Company No.");
                        ToolTip = 'View or edit the industry groups, such as Retail or Automobile, that the contact belongs to.';
                    }
                    action("Web Sources")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Web Sources';
                        Image = Web;
                        RunObject = Page "Contact Web Sources";
                        RunPageLink = "Contact No." = field("Company No.");
                        ToolTip = 'View a list of the web sites with information about the contacts.';
                    }
                }
                group("P&erson")
                {
                    Caption = 'P&erson';
                    Enabled = PersonGroupEnabled;
                    Image = User;
                    action("Job Responsibilities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Job Responsibilities';
                        Image = Job;
                        ToolTip = 'View or edit the contact''s job responsibilities.';

                        trigger OnAction()
                        var
                            ContJobResp: Record "Contact Job Responsibility";
                        begin
                            Rec.CheckContactType(Rec.Type::Person);
                            ContJobResp.SetRange("Contact No.", Rec."No.");
                            PAGE.RunModal(PAGE::"Contact Job Responsibilities", ContJobResp);
                        end;
                    }
                }
                action("Pro&files")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Pro&files';
                    Image = Answers;
                    ToolTip = 'Open the Profile Questionnaires window.';

                    trigger OnAction()
                    var
                        ProfileManagement: Codeunit ProfileManagement;
                    begin
                        ProfileManagement.ShowContactQuestionnaireCard(Rec, '', 0);
                    end;
                }
                action("&Picture")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = '&Picture';
                    Image = Picture;
                    RunObject = Page "Contact Picture";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View or add a picture of the contact person or, for example, the company''s logo.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const(Contact),
                                  "No." = field("No."),
                                  "Sub No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
                group("Alternati&ve Address")
                {
                    Caption = 'Alternati&ve Address';
                    Image = Addresses;
                    action(Card)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Card';
                        Image = EditLines;
                        RunObject = Page "Contact Alt. Address List";
                        RunPageLink = "Contact No." = field("No.");
                        ToolTip = 'View or change detailed information about the contact.';
                    }
                    action("Date Ranges")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date Ranges';
                        Image = DateRange;
                        RunObject = Page "Contact Alt. Addr. Date Ranges";
                        RunPageLink = "Contact No." = field("No.");
                        ToolTip = 'Specify date ranges that apply to the contact''s alternate address.';
                    }
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dataverse';
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                action(CRMGotoContact)
                {
                    ApplicationArea = Suite;
                    Caption = 'Contact';
                    Enabled = (Rec.Type <> Rec.Type::Company) and (Rec."Company No." <> '');
                    Image = CoupledContactPerson;
                    ToolTip = 'Open the coupled Dataverse contact.';

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
                    Enabled = (Rec.Type <> Rec.Type::Company) and (Rec."Company No." <> '');
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Dataverse.';

                    trigger OnAction()
                    var
                        Contact: Record Contact;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        ContactRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Contact);
                        Contact.Next();

                        if Contact.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Contact.RecordId)
                        else begin
                            ContactRecordRef.GetTable(Contact);
                            CRMIntegrationManagement.UpdateMultipleNow(ContactRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Enabled = (Rec.Type <> Rec.Type::Company) and (Rec."Company No." <> '');
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse contact.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledContactPerson;
                        ToolTip = 'Couple contacts to contacts in Dataverse based on criteria.';

                        trigger OnAction()
                        var
                            Contact: Record Contact;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Contact);
                            RecRef.GetTable(Contact);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse contact.';

                        trigger OnAction()
                        var
                            Contact: Record Contact;
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Contact);
                            RecRef.GetTable(Contact);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                group(Create)
                {
                    Caption = 'Create';
                    Image = NewCustomer;
                    action(CreateInCRM)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Contact in Dataverse';
                        Enabled = (Rec.Type <> Rec.Type::Company) and (Rec."Company No." <> '');
                        Image = NewCustomer;
                        ToolTip = 'Create a contact in Dataverse that is linked to a contact in your company.';

                        trigger OnAction()
                        var
                            Contact: Record Contact;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CurrPage.SetSelectionFilter(Contact);
                            CRMIntegrationManagement.CreateNewRecordsInCRM(Contact);
                        end;
                    }
                    action(CreateFromCRM)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Contact in Business Central';
                        Image = NewCustomer;
                        ToolTip = 'Create a contact here in your company that is linked to the Dataverse contact.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.CreateNewContactFromCRM();
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the contact table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
            group("Related Information")
            {
                Caption = 'Related Information';
                Image = Users;
                action("Relate&d Contacts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Relate&d Contacts';
                    Image = Users;
                    ToolTip = 'View a list of all contacts.';

                    trigger OnAction()
                    var
                        Contact: Record Contact;
                        ContactList: Page "Contact List";
                    begin
                        Contact.SetRange("Company No.", Rec."Company No.");
                        ContactList.SetTableView(Contact);
                        ContactList.Run();
                    end;
                }
                action("Segmen&ts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segmen&ts';
                    Image = Segment;
                    RunObject = Page "Contact Segment List";
                    RunPageLink = "Contact Company No." = field("Company No."),
                                  "Contact No." = filter(<> ''),
                                  "Contact No." = field(filter("Lookup Contact No."));
                    RunPageView = sorting("Contact No.", "Segment No.");
                    ToolTip = 'View the segments that are related to the contact.';
                }
                action("Mailing &Groups")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Mailing &Groups';
                    Image = DistributionGroup;
                    RunObject = Page "Contact Mailing Groups";
                    RunPageLink = "Contact No." = field("No.");
                    ToolTip = 'View or edit the mailing groups that the contact is assigned to, for example, for sending price lists or Christmas cards.';
                }
                action(RelatedCustomer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Image = Customer;
                    Enabled = RelatedCustomerEnabled;
                    ToolTip = 'View the related customer that is associated with the current record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::Customer, false);
                    end;
                }
                action(RelatedVendor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor';
                    Image = Vendor;
                    Enabled = RelatedVendorEnabled;
                    ToolTip = 'View the related vendor that is associated with the current record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::Vendor, false);
                    end;
                }
                action(RelatedBank)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account';
                    Image = BankAccount;
                    Enabled = RelatedBankEnabled;
                    ToolTip = 'View the related bank account that is associated with the current record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::"Bank Account", false);
                    end;
                }
                action(RelatedEmployee)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee';
                    Image = Employee;
                    Enabled = RelatedEmployeeEnabled;
                    ToolTip = 'View the related employee that is associated with the current record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::Employee, false);
                    end;
                }
            }
            group(Prices)
            {
                Caption = 'Prices';
                action(PriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Price Lists';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lists for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, Enum::"Price Type"::Sale, Enum::"Price Amount Type"::Any);
                    end;
                }
                action(PriceLines)
                {
                    AccessByPermission = TableData "Sales Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lines for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Price);
                    end;
                }
                action(DiscountLines)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Discount);
                    end;
                }
                action(PriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = false;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, PriceType::Sale, AmountType::Discount);
                    end;
                }
            }
            group(Tasks)
            {
                Caption = 'Tasks';
                Image = Task;
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Contact Company No." = field("Company No."),
                                  "Contact No." = field(filter("Lookup Contact No.")),
                                  "System To-do Type" = filter(Organizer | "Contact Attendee");
                    RunPageView = sorting("Contact Company No.", Date, "Contact No.", Closed);
                    ToolTip = 'View all marketing tasks that involve the contact person.';
                }
                action("Open Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Open Oppo&rtunities';
                    Image = OpportunityList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Contact Company No." = field("Company No."),
                                  "Contact No." = filter(<> ''),
                                  "Contact No." = field(filter("Lookup Contact No.")),
                                  Status = filter("Not Started" | "In Progress");
                    RunPageView = sorting("Contact Company No.", "Contact No.");
                    Scope = Repeater;
                    ToolTip = 'View the open sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Contact Company No." = field("Company No."),
                                  "Contact No." = filter(<> ''),
                                  "Contact No." = field(filter("Lookup Contact No."));
                    RunPageView = sorting("Contact Company No.", "Contact No.");
                    ToolTip = 'View postponed interactions for the contact.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action(ShowSalesQuotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales &Quotes';
                    Image = Quote;
                    RunObject = Page "Sales Quotes";
                    RunPageLink = "Sell-to Contact No." = field("No.");
                    RunPageView = sorting("Document Type", "Sell-to Contact No.");
                    ToolTip = 'View sales quotes that exist for the contact.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Closed Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Closed Oppo&rtunities';
                    Image = OpportunityList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Contact Company No." = field("Company No."),
                                  "Contact No." = filter(<> ''),
                                  "Contact No." = field(filter("Lookup Contact No.")),
                                  Status = filter(Won | Lost);
                    RunPageView = sorting("Contact Company No.", "Contact No.");
                    ToolTip = 'View the closed sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Contact Company No." = field("Company No."),
                                  "Contact No." = filter(<> ''),
                                  "Contact No." = field(filter("Lookup Contact No."));
                    RunPageView = sorting("Contact Company No.", "Contact No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Contact Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Sent Emails")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to this contact.';

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::Contact, Rec.SystemId);
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
                action(MakePhoneCall)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Make &Phone Call';
                    Image = Calls;
                    Scope = Repeater;
                    ToolTip = 'Call the selected contact.';

                    trigger OnAction()
                    var
                        TAPIManagement: Codeunit TAPIManagement;
                    begin
                        TAPIManagement.DialContCustVendBank(DATABASE::Contact, Rec."No.", Rec.GetDefaultPhoneNo(), '');
                    end;
                }
                action("Launch &Web Source")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Launch &Web Source';
                    Image = LaunchWeb;
                    ToolTip = 'Search for information about the contact online.';

                    trigger OnAction()
                    var
                        ContactWebSource: Record "Contact Web Source";
                    begin
                        ContactWebSource.SetRange("Contact No.", Rec."Company No.");
                        if PAGE.RunModal(PAGE::"Web Source Launch", ContactWebSource) = ACTION::LookupOK then
                            ContactWebSource.Launch();
                    end;
                }
                group("Create as")
                {
                    Caption = 'Create as';
                    Image = CustomerContact;
                    action(Customer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer';
                        Image = Customer;
                        ToolTip = 'Create the contact as a customer.';

                        trigger OnAction()
                        begin
                            Rec.CreateCustomer();
                        end;
                    }
                    action(Vendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor';
                        Image = Vendor;
                        ToolTip = 'Create the contact as a vendor.';

                        trigger OnAction()
                        begin
                            Rec.CreateVendor();
                        end;
                    }
                    action(Bank)
                    {
                        AccessByPermission = TableData "Bank Account" = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank';
                        Image = Bank;
                        ToolTip = 'Create the contact as a bank.';

                        trigger OnAction()
                        begin
                            Rec.CreateBankAccount();
                        end;
                    }
                    action(CreateEmployee)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee';
                        Image = Employee;
                        ToolTip = 'Create the contact as an employee.';

                        trigger OnAction()
                        begin
                            Rec.CreateEmployee();
                        end;
                    }
                }
                group("Link with existing")
                {
                    Caption = 'Link with existing';
                    Image = Links;
                    action(Action63)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer';
                        Image = Customer;
                        ToolTip = 'Link the contact to an existing customer.';

                        trigger OnAction()
                        begin
                            Rec.CreateCustomerLink();
                        end;
                    }
                    action(Action64)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor';
                        Image = Vendor;
                        ToolTip = 'Link the contact to an existing vendor.';

                        trigger OnAction()
                        begin
                            Rec.CreateVendorLink();
                        end;
                    }
                    action(Action65)
                    {
                        AccessByPermission = TableData "Bank Account" = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank';
                        Image = Bank;
                        ToolTip = 'Link the contact to an existing bank.';

                        trigger OnAction()
                        begin
                            Rec.CreateBankAccountLink();
                        end;
                    }
                    action(LinkEmployee)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee';
                        Image = Employee;
                        ToolTip = 'Link the contact to an existing employee.';

                        trigger OnAction()
                        begin
                            Rec.CreateEmployeeLink();
                        end;
                    }
                }
            }
            action("Export Contact")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Contact';
                Image = Export;
                ToolTip = 'Export Contact';
                Enabled = ExportContactEnabled;

                trigger OnAction()
                var
                    Contact: Record Contact;
                    ExportContact: XMLport "Export Contact";
                begin
                    CurrPage.SetSelectionFilter(Contact);
                    ExportContact.SetTableView(Contact);
                    ExportContact.Run();
                end;
            }
            action("Create &Interaction")
            {
                AccessByPermission = TableData Attachment = R;
                ApplicationArea = RelationshipMgmt;
                Caption = 'Create &Interaction';
                Image = CreateInteraction;
                ToolTip = 'Create an interaction with a specified contact.';

                trigger OnAction()
                begin
                    Rec.CreateInteraction();
                end;
            }
            action("Create Opportunity")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Create Opportunity';
                Image = NewOpportunity;
                RunObject = Page "Opportunity Card";
                RunPageLink = "Contact No." = field("No."),
                              "Contact Company No." = field("Company No.");
                RunPageMode = Create;
                ToolTip = 'Register a sales opportunity for the contact.';
            }
            action(WordTemplate)
            {
                ApplicationArea = All;
                Caption = 'Apply Word Template';
                ToolTip = 'Apply a Word template on the selected records.';
                Image = Word;

                trigger OnAction()
                var
                    Contact: Record Contact;
                    WordTemplateSelectionWizard: Page "Word Template Selection Wizard";
                begin
                    CurrPage.SetSelectionFilter(Contact);
                    WordTemplateSelectionWizard.SetData(Contact);
                    WordTemplateSelectionWizard.RunModal();
                end;
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this contact.';
                Enabled = CanSendEmail;

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::Contact, Rec.SystemId);
                    TempEmailitem."Send to" := Rec."E-Mail";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
        }
        area(creation)
        {
            action(NewSalesQuote)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Sales Quote';
                Image = NewSalesQuote;
                ToolTip = 'Offer items or services to a customer.';

                trigger OnAction()
                begin
                    Rec.CreateSalesQuoteFromContact();
                end;
            }
            action(NewPurchaseQuote)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Purchase Quote';
                Image = Quote;
                ToolTip = 'Create a new purchase quote for the vendor.';

                trigger OnAction()
                begin
                    Rec.CreatePurchaseQuoteFromContact();
                end;
            }
        }
        area(reporting)
        {
            action("Contact Labels")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Contact Labels';
                Image = "Report";
                RunObject = Report "Contact - Labels";
                ToolTip = 'View mailing labels with names and addresses of your contacts. For example, you can use the report to review contact information before you send sales and marketing campaign letters.';
            }
            action("Questionnaire Handout")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Questionnaire Handout';
                Image = "Report";
                RunObject = Report "Questionnaire - Handouts";
                ToolTip = 'View your profile questionnaire for the contact. You can print this report to have a printed copy of the questions that are within the profile questionnaire.';
            }
            action("Sales Cycle Analysis")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Sales Cycle Analysis';
                Image = "Report";
                RunObject = Report "Sales Cycle - Analysis";
                ToolTip = 'View information about your sales cycles. The report includes details about the sales cycle, such as the number of opportunities currently at that stage, the estimated and calculated current values of opportunities created using the sales cycle, and so on.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Create Opportunity_Promoted"; "Create Opportunity")
                {
                }
                actionref("Create &Interaction_Promoted"; "Create &Interaction")
                {
                }
                actionref(NewSalesQuote_Promoted; NewSalesQuote)
                {
                }
                actionref(NewPurchaseQuote_Promoted; NewPurchaseQuote)
                {
                }
                actionref(MakePhoneCall_Promoted; MakePhoneCall)
                {
                }
                actionref(Email_Promoted; Email)
                {
                }
                actionref("Export Contact_Promoted"; "Export Contact")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Contact', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref(RelatedCustomer_Promoted; RelatedCustomer)
                {
                }
                actionref(RelatedVendor_Promoted; RelatedVendor)
                {
                }
                actionref("Pro&files_Promoted"; "Pro&files")
                {
                }
                actionref(RelatedBank_Promoted; RelatedBank)
                {
                }
                actionref(RelatedEmployee_Promoted; RelatedEmployee)
                {
                }
                actionref("Open Oppo&rtunities_Promoted"; "Open Oppo&rtunities")
                {
                }
            }
            group("Category_Prices & Discounts")
            {
                Caption = 'Prices & Discounts';

                actionref(PriceLists_Promoted; PriceLists)
                {
                }
                actionref(PriceLines_Promoted; PriceLines)
                {
                }
                actionref(DiscountLines_Promoted; DiscountLines)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;

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
                    actionref(MatchBasedCoupling_Promoted; MatchBasedCoupling)
                    {
                    }
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(CRMGotoContact_Promoted; CRMGotoContact)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Contact: Record Contact;
    begin
        EnableFields();
        if CRMIntegrationEnabled or CDSIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
        SetEnabledRelatedActions();

        CurrPage.SetSelectionFilter(Contact);
        CanSendEmail := Contact.Count() = 1;
    end;

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := Rec.Type = Rec.Type::Company;
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IsHandled: Boolean;
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        OnBeforeUpdateContactBusinessRelationOnContacts(Rec, IsHandled);
    end;

    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        CanSendEmail: Boolean;
        StyleIsStrong: Boolean;
        CompanyGroupEnabled: Boolean;
        PersonGroupEnabled: Boolean;
        ExtendedPriceEnabled: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        RelatedCustomerEnabled: Boolean;
        RelatedVendorEnabled: Boolean;
        RelatedBankEnabled: Boolean;
        RelatedEmployeeEnabled: Boolean;
        ExportContactEnabled: Boolean;

    local procedure EnableFields()
    begin
        CompanyGroupEnabled := Rec.Type = Rec.Type::Company;
        PersonGroupEnabled := Rec.Type = Rec.Type::Person;
        ExportContactEnabled := Rec."No." <> '';
    end;

    local procedure SetEnabledRelatedActions()
    begin
        Rec.HasBusinessRelations(RelatedCustomerEnabled, RelatedVendorEnabled, RelatedBankEnabled, RelatedEmployeeEnabled)
    end;


    procedure GetSelectionFilter(): Text
    var
        Contact: Record Contact;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Contact);
        exit(SelectionFilterManagement.GetSelectionFilterForContact(Contact));
    end;

    procedure SetSelection(var Contact: Record Contact)
    begin
        CurrPage.SetSelectionFilter(Contact);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateContactBusinessRelationOnContacts(Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;
}
