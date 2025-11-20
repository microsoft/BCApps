// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Reports;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Integration.Dataverse;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using System.Email;
using System.Integration.Word;
using System.IO;

page 5050 "Contact Card"
{
    Caption = 'Contact Card';
    PageType = ListPlus;
    SourceTable = Contact;

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
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    AssistEdit = true;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the contact. If the contact is a person, you can click the field to see the Name Details window.';

                    trigger OnAssistEdit()
                    var
                        Contact: Record Contact;
                        IsHandled: Boolean;
                    begin
                        CurrPage.SaveRecord();
                        Commit();

                        Contact := Rec;
                        Contact.SetRecFilter();
                        IsHandled := false;
                        OnAssistEditNameOnAfterContactSetRecFilter(Contact, IsHandled);
                        if not IsHandled then
                            if Contact.Type = Contact.Type::Person then begin
                                Clear(NameDetails);
                                NameDetails.SetTableView(Contact);
                                NameDetails.SetRecord(Contact);
                                NameDetails.RunModal();
                            end else begin
                                Clear(CompanyDetails);
                                CompanyDetails.SetTableView(Contact);
                                CompanyDetails.SetRecord(Contact);
                                CompanyDetails.RunModal();
                            end;
                        Rec := Contact;
                        CurrPage.Update(false);
                    end;
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of contact, either company or person.';

                    trigger OnValidate()
                    begin
                        TypeOnAfterValidate();
                    end;
                }
                group(ParentCompanyInfo)
                {
                    ShowCaption = false;
                    field("Company No."; Rec."Company No.")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        ToolTip = 'Specifies the number for the contact''s company.';
                    }
                    field("Company Name"; Rec."Company Name")
                    {
                        ApplicationArea = All;
                        AssistEdit = true;
                        Enabled = CompanyNameEnable;
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the company. If the contact is a person, Specifies the name of the company for which this contact works. This field is not editable.';

                        trigger OnAssistEdit()
                        begin
                            CurrPage.SaveRecord();
                            Commit();
                            Rec.LookupCompany();
                            CurrPage.Update(false);
                        end;
                    }
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the contact''s job title.';
                    Visible = false;
                }
                field("Contact Business Relation"; Rec."Contact Business Relation")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Business Relation';
                    ToolTip = 'Specifies the type of the existing business relation.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowBusinessRelation(Enum::"Contact Business Relation Link To Table"::" ", true);
                        CurrPage.Update(false);
                    end;
                }
                field(IntegrationCustomerNo; IntegrationCustomerNo)
                {
                    ApplicationArea = All;
                    Caption = 'Integration Customer No.';
                    ToolTip = 'Specifies the number of a customer that is integrated through Dynamics 365 Sales.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        Customer: Record Customer;
                        ContactBusinessRelation: Record "Contact Business Relation";
                    begin
                        if not (IntegrationCustomerNo = '') then begin
                            Customer.Get(IntegrationCustomerNo);
                            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
                            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                            ContactBusinessRelation.SetRange("No.", Customer."No.");
                            if ContactBusinessRelation.FindFirst() then
                                Rec.Validate("Company No.", ContactBusinessRelation."Contact No.");
                        end else
                            Rec.Validate("Company No.", '');
                    end;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the salesperson who normally handles this contact.';
                }
                field("Salutation Code"; Rec."Salutation Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the salutation code that will be used when you interact with the contact. The salutation code is only used in Word documents. To see a list of the salutation codes already defined, click the field.';
                }
                field("Organizational Level Code"; Rec."Organizational Level Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = OrganizationalLevelCodeEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies the organizational code for the contact, for example, top management. This field is valid for persons only.';
                }
                field(LastDateTimeModified; Rec.GetLastDateTimeModified())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last DateTime Modified';
                    Importance = Additional;
                    ToolTip = 'Specifies the date and time when the contact card was last modified. This field is not editable.';
                }
                field("Date of Last Interaction"; Rec."Date of Last Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the date of the last interaction involving the contact, for example, a received or sent mail, e-mail, or phone call. This field is not editable.';

                    trigger OnDrillDown()
                    var
                        InteractionLogEntry: Record "Interaction Log Entry";
                    begin
                        InteractionLogEntry.SetCurrentKey("Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed");
                        InteractionLogEntry.SetRange("Contact Company No.", Rec."Company No.");
                        InteractionLogEntry.SetFilter("Contact No.", Rec."Lookup Contact No.");
                        InteractionLogEntry.SetRange("Attempt Failed", false);
                        if InteractionLogEntry.FindLast() then
                            PAGE.Run(0, InteractionLogEntry);
                    end;
                }
                field("Last Date Attempted"; Rec."Last Date Attempted")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the contact was last contacted, for example, when you tried to call the contact, with or without success. This field is not editable.';

                    trigger OnDrillDown()
                    var
                        InteractionLogEntry: Record "Interaction Log Entry";
                    begin
                        InteractionLogEntry.SetCurrentKey("Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed");
                        InteractionLogEntry.SetRange("Contact Company No.", Rec."Company No.");
                        InteractionLogEntry.SetFilter("Contact No.", Rec."Lookup Contact No.");
                        InteractionLogEntry.SetRange("Initiated By", InteractionLogEntry."Initiated By"::Us);
                        if InteractionLogEntry.FindLast() then
                            PAGE.Run(0, InteractionLogEntry);
                    end;
                }
                field("Next Task Date"; Rec."Next Task Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the date of the next task involving the contact.';
                }
                field("Exclude from Segment"; Rec."Exclude from Segment")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies if the contact should be excluded from segments:';
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                }
                field(Minor; Rec.Minor)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the person''s age is below the definition of adulthood as recognized by law. Data for minors is blocked until a parent or guardian of the minor provides parental consent. You unblock the data by choosing the Parental Consent Received check box.';

                    trigger OnValidate()
                    begin
                        SetParentalConsentReceivedEnable();
                    end;
                }
                field("Parental Consent Received"; Rec."Parental Consent Received")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ParentalConsentReceivedEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies that a parent or guardian of the minor has provided their consent to allow the minor to use this service. When this check box is selected, data for the minor can be processed.';
                }
                field("Registration Number"; Rec."Registration Number")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Enabled = RegistrationNumberEnabled;
                    ToolTip = 'Specifies the registration number of the contact. You can enter a maximum of 20 characters, both numbers and letters.';
                }
            }
            part(ContactIntEntriesSubform; "Contact Int. Entries Subform")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'History';
                SubPageLink = "Contact Company No." = field("Company No."),
                                "Contact No." = field("No.");
            }
            group(Communication)
            {
                Caption = 'Communication';
                group(Control37)
                {
                    Caption = 'Address';
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the contact''s address.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the address.';
                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                        end;
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the city where the contact is located.';
                    }
                    group(CountyGroup)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the state, province or county as a part of the address.';
                        }
                    }
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;
                        ToolTip = 'Specifies the contact''s address on your preferred map website.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update(true);
                            Rec.DisplayMap();
                        end;
                    }
                }
                group(ContactDetails)
                {
                    Caption = 'Contact';
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the contact''s phone number.';
                    }
                    field("Mobile Phone No."; Rec."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the contact''s mobile telephone number.';
                    }
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        ExtendedDatatype = EMail;
                        Importance = Promoted;
                        ToolTip = 'Specifies the email address of the contact.';
                    }
                    field("Fax No."; Rec."Fax No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the contact''s fax number.';
                    }
                    field("Home Page"; Rec."Home Page")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the contact''s web site.';
                    }
                    field("Correspondence Type"; Rec."Correspondence Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the preferred type of correspondence for the interaction.';
                    }
                    field("Language Code"; Rec."Language Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    }
                    field("Format Region"; Rec."Format Region")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the format region that is used when formatting dates and numbers on documents to foreign business partner, such as an total amount on an order date.';
                    }
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Enabled = CurrencyCodeEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the contact.';
                }
                field("Territory Code"; Rec."Territory Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the territory code for the contact.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    Enabled = VATRegistrationNoEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies the contact''s VAT registration number. This field is valid for companies only.';

                    trigger OnDrillDown()
                    var
                        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                    begin
                        VATRegistrationLogMgt.AssistEditContactVATReg(Rec);
                    end;
                }
            }
            part("Profile Questionnaire"; "Contact Card Subform")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Profile Questionnaire';
                SubPageLink = "Contact No." = field("No.");
            }
        }
        area(factboxes)
        {
            part(Control41; "Contact Picture")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = not IsOfficeAddin;
            }
            part(Control31; "Contact Statistics FactBox")
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
                        ToolTip = 'View or edit the contact''s business relations, such as customers, vendors, banks, lawyers, consultants, competitors, and so on.';

                        trigger OnAction()
                        begin
                            Rec.ShowBusinessRelations();
                        end;
                    }
                    action("Industry Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Industry Groups';
                        Image = IndustryGroups;
                        ToolTip = 'View or edit the industry groups, such as Retail or Automobile, that the contact belongs to.';

                        trigger OnAction()
                        var
                            ContactIndustryGroupRec: Record "Contact Industry Group";
                        begin
                            Rec.CheckContactType(Rec.Type::Company);
                            ContactIndustryGroupRec.SetRange("Contact No.", Rec."Company No.");
                            PAGE.Run(PAGE::"Contact Industry Groups", ContactIndustryGroupRec);
                        end;
                    }
                    action("Web Sources")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Web Sources';
                        Image = Web;
                        ToolTip = 'View a list of the web sites with information about the contact.';

                        trigger OnAction()
                        var
                            ContactWebSourceRec: Record "Contact Web Source";
                        begin
                            Rec.CheckContactType(Rec.Type::Company);
                            ContactWebSourceRec.SetRange("Contact No.", Rec."Company No.");
                            PAGE.Run(PAGE::"Contact Web Sources", ContactWebSourceRec);
                        end;
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
                Enabled = (Rec.Type <> Rec.Type::Company) and (Rec."Company No." <> '');
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                action(CRMGotoContact)
                {
                    ApplicationArea = Suite;
                    Caption = 'Contact';
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
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Dataverse.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
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
                    RunObject = Page "Contact List";
                    RunPageLink = "Company No." = field("Company No.");
                    ToolTip = 'View a list of all contacts.';
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
                    ToolTip = 'View information about the customer that is associated with the selected record.';

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
                    ToolTip = 'View information about the vendor that is associated with the selected record.';

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
                    ToolTip = 'View information about the bank account that is associated with the selected record.';

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
                    ToolTip = 'View information about the employee that is associated with the selected record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::Employee, false);
                    end;
                }
                action("Online Map")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        Rec.DisplayMap();
                    end;
                }
                action("Office Customer/Vendor")
                {
                    ApplicationArea = All;
                    Caption = 'Customer/Vendor';
                    Image = ContactReference;
                    ToolTip = 'View the related customer, vendor, or bank account.';
                    Visible = IsOfficeAddin;

                    trigger OnAction()
                    begin
                        Rec.ShowBusinessRelation(Enum::"Contact Business Relation Link To Table"::" ", false);
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
                action("Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Oppo&rtunities';
                    Image = OpportunityList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Contact Company No." = field("Company No."),
                                  "Contact No." = filter(<> ''),
                                  "Contact No." = field(filter("Lookup Contact No."));
                    RunPageView = sorting("Contact Company No.", "Contact No.");
                    ToolTip = 'View the sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
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
                    RunPageView = sorting("Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed");
                    ToolTip = 'View postponed interactions for the contact.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action(SalesQuotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales &Quotes';
                    Image = Quote;
                    RunObject = Page "Sales Quotes";
                    RunPageLink = "Sell-to Contact No." = field("No.");
                    RunPageView = sorting("Document Type", "Sell-to Contact No.");
                    ToolTip = 'View sales quotes that exist for the contact.';
                }
                action(PurchaseQuotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Quotes';
                    Image = Quote;
                    RunObject = Page "Purchase Quotes";
                    RunPageLink = "Buy-from Contact No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Contact No.");
                    ToolTip = 'View purchase quotes that exist for the contact.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Contact Company No." = field("Company No."),
                                  "Contact No." = filter(<> ''),
                                  "Contact No." = field(filter("Lookup Contact No."));
                    RunPageView = sorting("Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed");
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
                action("Print Cover &Sheet")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Print Cover &Sheet';
                    Image = PrintCover;
                    ToolTip = 'View cover sheets to send to your contact.';

                    trigger OnAction()
                    var
                        Cont: Record Contact;
                    begin
                        Cont := Rec;
                        Cont.SetRecFilter();
                        REPORT.Run(REPORT::"Contact - Cover Sheet", true, false, Cont);
                    end;
                }
                group("Create as")
                {
                    Caption = 'Create as';
                    Image = CustomerContact;
                    action(CreateCustomer)
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
                    action(CreateVendor)
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
                    action(CreateBank)
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
                    action(Customer)
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
                    action(Vendor)
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
                    action(Bank)
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
                action("Apply Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Ellipsis = true;
                    Image = ApplyTemplate;
                    ToolTip = 'Select a defined template to quickly create a new record.';

                    trigger OnAction()
                    var
                        ConfigTemplateMgt: Codeunit "Config. Template Management";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        ConfigTemplateMgt.UpdateFromTemplateSelection(RecRef);
                    end;
                }
                action(MergeDuplicate)
                {
                    AccessByPermission = TableData "Merge Duplicates Buffer" = RIMD;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Merge With';
                    Ellipsis = true;
                    Image = ItemSubstitution;
                    ToolTip = 'Merge two contact records into one. Before merging, review which field values you want to keep or override. The merge action cannot be undone.';

                    trigger OnAction()
                    var
                        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
                    begin
                        TempMergeDuplicatesBuffer.Show(DATABASE::Contact, Rec."No.");
                    end;
                }
                action(CreateAsCustomer)
                {
                    ApplicationArea = All;
                    Caption = 'Create as Customer';
                    Image = Customer;
                    ToolTip = 'Create a new customer based on this contact.';
                    Visible = IsOfficeAddin;

                    trigger OnAction()
                    begin
                        Rec.CreateCustomerFromTemplate(Rec.ChooseNewCustomerTemplate());
                    end;
                }
                action(CreateAsVendor)
                {
                    ApplicationArea = All;
                    Caption = 'Create as Vendor';
                    Image = Vendor;
                    ToolTip = 'Create a new vendor based on this contact.';
                    Visible = IsOfficeAddin;

                    trigger OnAction()
                    begin
                        Rec.CreateVendor();
                    end;
                }
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
            action(WordTemplate)
            {
                ApplicationArea = All;
                Caption = 'Apply Word Template';
                ToolTip = 'Apply a Word template on the contact.';
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
            action(ContactCoverSheet)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Contact Cover Sheet';
                Image = "Report";
                ToolTip = 'Print or save cover sheets to send to one or more of your contacts.';

                trigger OnAction()
                var
                    Contact: Record Contact;
                    ContactCoverSheetReportID: Integer;
                begin
                    Contact := Rec;
                    Contact.SetRecFilter();
                    ContactCoverSheetReportID := REPORT::"Contact Cover Sheet";
                    OnBeforePrintContactCoverSheet(ContactCoverSheetReportID);
                    REPORT.Run(ContactCoverSheetReportID, true, false, Contact);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreateAsCustomer_Promoted; CreateAsCustomer)
                {
                }
                actionref(CreateAsVendor_Promoted; CreateAsVendor)
                {
                }
                actionref("Create Opportunity_Promoted"; "Create Opportunity")
                {
                }
                group(Category_Interaction)
                {
                    Caption = 'Interaction';
                    ShowAs = SplitButton;

                    actionref("Create &Interaction_Promoted"; "Create &Interaction")
                    {
                    }
                    actionref(MakePhoneCall_Promoted; MakePhoneCall)
                    {
                    }
                    actionref(Email_Promoted; Email)
                    {
                    }
                }
                actionref(NewSalesQuote_Promoted; NewSalesQuote)
                {
                }
                actionref(NewPurchaseQuote_Promoted; NewPurchaseQuote)
                {
                }
                actionref("Apply Template_Promoted"; "Apply Template")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Contact', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref(RelatedCustomer_Promoted; RelatedCustomer)
                {
                }
                actionref("Pro&files_Promoted"; "Pro&files")
                {
                }
                actionref(RelatedVendor_Promoted; RelatedVendor)
                {
                }
                actionref("Office Customer/Vendor_Promoted"; "Office Customer/Vendor")
                {
                }
                actionref(RelatedEmployee_Promoted; RelatedEmployee)
                {
                }
                actionref(RelatedBank_Promoted; RelatedBank)
                {
                }
                actionref(SalesQuotes_Promoted; SalesQuotes)
                {
                }
                actionref(PurchaseQuotes_Promoted; PurchaseQuotes)
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
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref(ContactCoverSheet_Promoted; ContactCoverSheet)
                {
                }
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

    trigger OnAfterGetRecord()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CRMIntegrationEnabled or CDSIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
            if Rec."No." <> xRec."No." then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;

        if Rec."Contact Business Relation" = Rec."Contact Business Relation"::" " then
            Rec.UpdateBusinessRelation();

        xRec := Rec;
        EnableFields();
        SetEnabledRelatedActions();

        if Rec.Type = Rec.Type::Person then
            IntegrationFindCustomerNo()
        else
            IntegrationCustomerNo := '';
    end;

    trigger OnInit()
    begin
        OrganizationalLevelCodeEnable := true;
        CompanyNameEnable := true;
        VATRegistrationNoEnable := true;
        CurrencyCodeEnable := true;
        RegistrationNumberEnabled := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnNewRecord(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec.GetFilter("Company No.") <> '' then begin
            Rec."Company No." := Rec.GetRangeMax("Company No.");
            Rec.Type := Rec.Type::Person;
            Contact.Get(Rec."Company No.");
            Rec.InheritCompanyToPersonData(Contact);
        end;
    end;

    trigger OnOpenPage()
    var
        OfficeManagement: Codeunit "Office Management";
    begin
        OnBeforeOnOpenPage(Rec);

        IsOfficeAddin := OfficeManagement.IsAvailable();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        SetNoFieldVisible();
        SetParentalConsentReceivedEnable();
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        FormatAddress: Codeunit "Format Address";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        CompanyDetails: Page "Company Details";
        NameDetails: Page "Name Details";
        IntegrationCustomerNo: Code[20];
        CurrencyCodeEnable: Boolean;
        VATRegistrationNoEnable: Boolean;
        CompanyNameEnable: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        RelatedCustomerEnabled: Boolean;
        RelatedVendorEnabled: Boolean;
        RelatedBankEnabled: Boolean;
        RelatedEmployeeEnabled: Boolean;
        ShowMapLbl: Label 'Show Map';
        IsCountyVisible: Boolean;
        NoFieldVisible: Boolean;
        RegistrationNumberEnabled: Boolean;

    protected var
        OrganizationalLevelCodeEnable: Boolean;
        ParentalConsentReceivedEnable: Boolean;
        CompanyGroupEnabled: Boolean;
        PersonGroupEnabled: Boolean;
        ExtendedPriceEnabled: Boolean;
        IsOfficeAddin: Boolean;

    local procedure EnableFields()
    begin
        CompanyGroupEnabled := Rec.Type = Rec.Type::Company;
        PersonGroupEnabled := Rec.Type = Rec.Type::Person;
        CurrencyCodeEnable := Rec.Type = Rec.Type::Company;
        VATRegistrationNoEnable := Rec.Type = Rec.Type::Company;
        CompanyNameEnable := Rec.Type = Rec.Type::Person;
        OrganizationalLevelCodeEnable := Rec.Type = Rec.Type::Person;
        RegistrationNumberEnabled := Rec.Type = Rec.Type::Company;

        OnAfterEnableFields(CompanyGroupEnabled, PersonGroupEnabled, CurrencyCodeEnable, VATRegistrationNoEnable, CompanyNameEnable, OrganizationalLevelCodeEnable);
    end;

    local procedure SetEnabledRelatedActions()
    begin
        Rec.HasBusinessRelations(RelatedCustomerEnabled, RelatedVendorEnabled, RelatedBankEnabled, RelatedEmployeeEnabled)
    end;

    local procedure IntegrationFindCustomerNo()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "Contact No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", Rec."Company No.");
        if ContactBusinessRelation.FindFirst() then
            IntegrationCustomerNo := ContactBusinessRelation."No."
        else
            IntegrationCustomerNo := '';
    end;

    local procedure TypeOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.ContactNoIsVisible();
    end;

    local procedure SetParentalConsentReceivedEnable()
    begin
        if Rec.Minor then
            ParentalConsentReceivedEnable := true
        else begin
            Rec."Parental Consent Received" := false;
            ParentalConsentReceivedEnable := false;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEnableFields(var CompanyGroupEnabled: Boolean; var PersonGroupEnabled: Boolean; var CurrencyCodeEnable: Boolean; var VATRegistrationNoEnable: Boolean; var CompanyNameEnable: Boolean; var OrganizationalLevelCodeEnable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintContactCoverSheet(var ContactCoverSheetReportID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditNameOnAfterContactSetRecFilter(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnNewRecord(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var Contact: Record Contact)
    begin
    end;
}

