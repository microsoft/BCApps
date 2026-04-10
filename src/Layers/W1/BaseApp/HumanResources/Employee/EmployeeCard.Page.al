// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Analysis;
using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Setup;
using Microsoft.Utilities;
using System.Email;

page 5200 "Employee Card"
{
    Caption = 'Employee Card';
    PageType = Card;
    SourceTable = Employee;

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
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit();
                    end;
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ShowMandatory = true;
                }
                field("Middle Name"; Rec."Middle Name")
                {
                    ApplicationArea = BasicHR;
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = BasicHR;
                    ShowMandatory = true;
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                }
                field(Initials; Rec.Initials)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Gender; Rec.Gender)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Phone No.2"; Rec."Phone No.")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Company Phone No.';
                }
                field("Company E-Mail"; Rec."Company E-Mail")
                {
                    ApplicationArea = BasicHR;
                    ExtendedDatatype = EMail;
                }
                field("Board Member"; Rec."Board Member")
                {
                    ApplicationArea = BasicHR;
                }
                field("Manager Role"; Rec."Manager Role")
                {
                    ApplicationArea = BasicHR;
                }
                field(Nationality; Rec.Nationality)
                {
                    ApplicationArea = BasicHR;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = BasicHR;
                    Importance = Additional;
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = BasicHR;
                    Importance = Additional;
                }
            }
            group("Address & Contact")
            {
                Caption = 'Address & Contact';
                group(Control13)
                {
                    ShowCaption = false;
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = BasicHR;
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = BasicHR;
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = BasicHR;
                    }
                    group(Control31)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = BasicHR;
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = BasicHR;
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = BasicHR;

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                        end;
                    }
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = BasicHR;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;
                        ToolTip = 'Specifies the employee''s address on your preferred online map.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update(true);
                            Rec.DisplayMap();
                        end;
                    }
                }
                group(Control7)
                {
                    ShowCaption = false;
                    field("Mobile Phone No."; Rec."Mobile Phone No.")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Private Phone No.';
                        Importance = Promoted;
                    }
                    field(Pager; Rec.Pager)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(Extension; Rec.Extension)
                    {
                        ApplicationArea = BasicHR;
                        Importance = Promoted;
                    }
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Direct Phone No.';
                        Importance = Promoted;
                        ToolTip = 'Specifies the employee''s telephone number.';
                    }
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Private Email';
                        Importance = Promoted;
                    }
                    field("Alt. Address Code"; Rec."Alt. Address Code")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Alt. Address Start Date"; Rec."Alt. Address Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Alt. Address End Date"; Rec."Alt. Address End Date")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                field("Employment Date"; Rec."Employment Date")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                }
                field("Inactive Date"; Rec."Inactive Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Cause of Inactivity Code"; Rec."Cause of Inactivity Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Termination Date"; Rec."Termination Date")
                {
                    ApplicationArea = BasicHR;
                }
                field("Grounds for Term. Code"; Rec."Grounds for Term. Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Emplymt. Contract Code"; Rec."Emplymt. Contract Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statistics Group Code"; Rec."Statistics Group Code")
                {
                    ApplicationArea = Suite;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = BasicHR;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Engagement Type"; Rec."Engagement Type")
                {
                    ApplicationArea = BasicHR;
                }
                field("Collective Bargain. Agmt. Info"; Rec."Collective Bargain. Agmt. Info")
                {
                    ApplicationArea = BasicHR;
                }
            }
            group(Personal)
            {
                Caption = 'Personal';
                field("Birth Date"; Rec."Birth Date")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                }
                field("Social Security No."; Rec."Social Security No.")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    MaskType = Concealed;
                }
                field("Union Code"; Rec."Union Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Union Membership No."; Rec."Union Membership No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Employee Posting Group"; Rec."Employee Posting Group")
                {
                    ApplicationArea = BasicHR;
                    LookupPageID = "Employee Posting Groups";
                }
                field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = IsAllowMultiplePostingGroupsVisible;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = BasicHR;
                    Importance = Additional;
                }
                field("Application Method"; Rec."Application Method")
                {
                    ApplicationArea = BasicHR;
                }
                field("Bank Branch No."; Rec."Bank Branch No.")
                {
                    ApplicationArea = BasicHR;
                    MaskType = Concealed;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = BasicHR;
                    MaskType = Concealed;
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = BasicHR;
                    MaskType = Concealed;
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = BasicHR;
                    MaskType = Concealed;
                }
            }
            group("Payroll")
            {
                Caption = 'Payroll';
                field("Emp. Payroll"; Rec.Payroll)
                {
                    ApplicationArea = BasicHR;
                }
                field("Payroll Currency Code"; Rec."Payroll Currency Code")
                {
                    ApplicationArea = BasicHR;
                }
                field("Payroll (LCY)"; Rec."Payroll (LCY)")
                {
                    ApplicationArea = BasicHR;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ToolTip = 'Specifies the value of the Payroll (LCY) field.';
                }
                field("Working Type"; Rec."Working Type")
                {
                    ApplicationArea = BasicHR;
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = BasicHR;
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the value of the Working Hours field.';
                }
            }
        }
        area(factboxes)
        {
            part(Control3; "Employee Picture")
            {
                ApplicationArea = BasicHR;
                SubPageLink = "No." = field("No.");
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Employee),
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
            group("E&mployee")
            {
                Caption = 'E&mployee';
                Image = Employee;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = const(Employee),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5200),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("&Picture")
                {
                    ApplicationArea = BasicHR;
                    Caption = '&Picture';
                    Image = Picture;
                    RunObject = Page "Employee Picture";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View or add a picture of the employee or, for example, the company''s logo.';
                }
                action(AlternativeAddresses)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Alternate Addresses';
                    Image = Addresses;
                    RunObject = Page "Alternative Address List";
                    RunPageLink = "Employee No." = field("No.");
                    ToolTip = 'Open the list of addresses that are registered for the employee.';
                }
                action("&Relatives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Relatives';
                    Image = Relatives;
                    RunObject = Page "Employee Relatives";
                    RunPageLink = "Employee No." = field("No.");
                    ToolTip = 'Open the list of relatives that are registered for the employee.';
                }
                action("Mi&sc. Article Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mi&sc. Article Information';
                    Image = Filed;
                    RunObject = Page "Misc. Article Information";
                    RunPageLink = "Employee No." = field("No.");
                    ToolTip = 'Open the list of miscellaneous articles that are registered for the employee.';
                }
                action("&Confidential Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Confidential Information';
                    Image = Lock;
                    RunObject = Page "Confidential Information";
                    RunPageLink = "Employee No." = field("No.");
                    ToolTip = 'Open the list of any confidential information that is registered for the employee.';
                }
                action("Q&ualifications")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Q&ualifications';
                    Image = Certificate;
                    RunObject = Page "Employee Qualifications";
                    RunPageLink = "Employee No." = field("No.");
                    ToolTip = 'Open the list of qualifications that are registered for the employee.';
                }
                action("A&bsences")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'A&bsences';
                    Image = Absence;
                    RunObject = Page "Employee Absences";
                    RunPageLink = "Employee No." = field("No.");
                    ToolTip = 'View absence information for the employee.';
                }
                separator(Action23)
                {
                }
                action("Absences by Ca&tegories")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Absences by Ca&tegories';
                    Image = AbsenceCategory;
                    RunObject = Page "Empl. Absences by Categories";
                    RunPageLink = "No." = field("No."),
                                  "Employee No. Filter" = field("No.");
                    ToolTip = 'View categorized absence information for the employee.';
                }
                action("Misc. Articles &Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Misc. Articles &Overview';
                    Image = FiledOverview;
                    RunObject = Page "Misc. Articles Overview";
                    ToolTip = 'View miscellaneous articles that are registered for the employee.';
                }
                action("Co&nfidential Info. Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&nfidential Info. Overview';
                    Image = ConfidentialOverview;
                    RunObject = Page "Confidential Info. Overview";
                    ToolTip = 'View confidential information that is registered for the employee.';
                }
                separator(Action61)
                {
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Ledger E&ntries';
                    Image = VendorLedger;
                    RunObject = Page "Employee Ledger Entries";
                    RunPageLink = "Employee No." = field("No.");
                    RunPageView = sorting("Employee No.")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
                action(PayEmployee)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Pay Employee';
                    Image = SuggestVendorPayments;
                    RunObject = Page "Employee Ledger Entries";
                    RunPageLink = "Employee No." = field("No."),
                                  "Remaining Amount" = filter(< 0),
                                  "Applies-to ID" = filter('');
                    ToolTip = 'View employee ledger entries for the record with remaining amount that have not been paid yet.';
                }
                action(Contact)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Image = ContactPerson;
                    ToolTip = 'View or edit detailed information about the contact person at the employee.';

                    trigger OnAction()
                    var
                        ContBusRel: Record "Contact Business Relation";
                        Contact: Record Contact;
                    begin
                        if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Employee, Rec."No.") then begin
                            Contact.Get(ContBusRel."Contact No.");
                            Page.Run(Page::"Contact Card", Contact);
                        end;
                    end;
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Sent Emails")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to this employee.';

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::Employee, Rec.SystemId);
                    end;
                }
            }
        }
        area(Processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ApplyTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Ellipsis = true;
                    Image = ApplyTemplate;
                    ToolTip = 'Apply a template to update the entity with your standard settings for a certain type of entity.';

                    trigger OnAction()
                    var
                        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
                    begin
                        EmployeeTemplMgt.UpdateEmployeeFromTemplate(Rec);
                    end;
                }
                action(SaveAsTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Save as Template';
                    Ellipsis = true;
                    Image = Save;
                    ToolTip = 'Save the employee card as a template that can be reused to create new employee cards. Employee templates contain preset information to help you fill fields on employee cards.';

                    trigger OnAction()
                    var
                        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
                    begin
                        EmployeeTemplMgt.SaveAsTemplate(Rec);
                    end;
                }
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this employee.';

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::Employee, Rec.SystemId);
                    if Rec."Company E-Mail" <> '' then
                        TempEmailitem."Send to" := Rec."Company E-Mail"
                    else
                        TempEmailitem."Send to" := Rec."E-Mail";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Email_Promoted; Email)
                {
                }
                actionref(PayEmployee_Promoted; PayEmployee)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Employee', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Attachments_Promoted; Attachments)
                {
                }
                actionref(Contact_Promoted; Contact)
                {
                }
                actionref("Sent Emails_Promoted"; "Sent Emails")
                {
                }
                actionref("&Picture_Promoted"; "&Picture")
                {
                }
                actionref("&Confidential Information_Promoted"; "&Confidential Information")
                {
                }
                actionref("Q&ualifications_Promoted"; "Q&ualifications")
                {
                }
                actionref("A&bsences_Promoted"; "A&bsences")
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
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
        }
    }

    trigger OnOpenPage()
    begin
        SetNoFieldVisible();
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        HumanResourcesSetup.Get();
        IsAllowMultiplePostingGroupsVisible := HumanResourcesSetup."Allow Multiple Posting Groups";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed then
            if Rec."No." = '' then
                if DocumentNoVisibility.EmployeeNoSeriesIsDefault() then
                    NewMode := true;
    end;

    trigger OnAfterGetCurrRecord()
    var
        Employee: Record Employee;
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
    begin
        if not NewMode then
            exit;
        NewMode := false;

        if EmployeeTemplMgt.InsertEmployeeFromTemplate(Employee) then begin
            Rec.Copy(Employee);
            CurrPage.Update();
        end else
            if EmployeeTemplMgt.TemplatesAreNotEmpty() then
                CurrPage.Close();
    end;

    var
        HumanResourcesSetup: Record "Human Resources Setup";
        FormatAddress: Codeunit "Format Address";
        NoFieldVisible: Boolean;
        IsCountyVisible: Boolean;
        NewMode: Boolean;
        IsAllowMultiplePostingGroupsVisible: Boolean;

        ShowMapLbl: Label 'Show on Map';

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.EmployeeNoIsVisible();
    end;
}
