// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using System.Environment;
using System.Globalization;

page 5094 "Marketing Setup"
{
    ApplicationArea = Basic, Suite, RelationshipMgmt;
    Caption = 'Marketing Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Marketing Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Visible = not SoftwareAsAService;
                field("Attachment Storage Type"; Rec."Attachment Storage Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies how you want to store attachments. The following options exist:';

                    trigger OnValidate()
                    begin
                        AttachmentStorageTypeOnAfterVa();
                    end;
                }
                field("Attachment Storage Location"; Rec."Attachment Storage Location")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = AttachmentStorageLocationEnabl;
                    ToolTip = 'Specifies the drive and path to the location where you want attachments stored if you selected Disk File in the Attachment Storage Type field.';

                    trigger OnValidate()
                    begin
                        AttachmentStorageLocationOnAft();
                    end;
                }
            }
            group(Inheritance)
            {
                Caption = 'Inheritance';
                group(Inherit)
                {
                    Caption = 'Inherit';
                    field("Inherit Salesperson Code"; Rec."Inherit Salesperson Code")
                    {
                        ApplicationArea = Suite, RelationshipMgmt;
                        Caption = 'Salesperson Code';
                        ToolTip = 'Specifies that you want to copy the salesperson code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Territory Code"; Rec."Inherit Territory Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Territory Code';
                        ToolTip = 'Specifies that you want to copy the territory code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Country/Region Code"; Rec."Inherit Country/Region Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Country/Region Code';
                        ToolTip = 'Specifies that you want to copy the country/region code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Language Code"; Rec."Inherit Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Language Code';
                        ToolTip = 'Specifies that you want to copy the language code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Address Details"; Rec."Inherit Address Details")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Address Details';
                        ToolTip = 'Specifies that you want to copy the address details from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Communication Details"; Rec."Inherit Communication Details")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Communication Details';
                        ToolTip = 'Specifies that you want to copy the communication details, such as telex and fax numbers, from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                }
            }
            group(Defaults)
            {
                Caption = 'Defaults';
                group(Default)
                {
                    Caption = 'Default';
                    field("Default Salesperson Code"; Rec."Default Salesperson Code")
                    {
                        ApplicationArea = Suite, RelationshipMgmt;
                        Caption = 'Salesperson Code';
                        ToolTip = 'Specifies the salesperson code to assign automatically to contacts when they are created.';
                    }
                    field("Default Territory Code"; Rec."Default Territory Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Territory Code';
                        ToolTip = 'Specifies the territory code to automatically assign to contacts when they are created.';
                    }
                    field("Default Country/Region Code"; Rec."Default Country/Region Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Country/Region Code';
                        ToolTip = 'Specifies the country/region code to assign automatically to contacts when they are created.';
                    }
                    field("Default Language Code"; Rec."Default Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Language Code';
                        ToolTip = 'Specifies the language code to assign automatically to contacts when they are created.';
                    }
                    field("Default Format Region"; Rec."Default Format Region")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Format Region Code';
                        ToolTip = 'Specifies the region format to assign automatically to contacts when they are created.';
                    }
                    field("Default Correspondence Type"; Rec."Default Correspondence Type")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Correspondence Type';
                        ToolTip = 'Specifies the preferred type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';
                    }
                    field("Def. Company Salutation Code"; Rec."Def. Company Salutation Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Company Salutation Code';
                        ToolTip = 'Specifies the salutation code to assign automatically to contact companies when they are created.';
                    }
                    field("Default Person Salutation Code"; Rec."Default Person Salutation Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Person Salutation Code';
                        ToolTip = 'Specifies the salutation code to assign automatically to contact persons when they are created.';
                    }
                    field("Default Sales Cycle Code"; Rec."Default Sales Cycle Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Sales Cycle Code';
                        ToolTip = 'Specifies the sales cycle code to automatically assign to opportunities when they are created.';
                    }
                    field("Default To-do Date Calculation"; Rec."Default To-do Date Calculation")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Task Date Calculation';
                        ToolTip = 'Specifies the task date calculation formula to use to calculate the ending date for tasks in Business Central if you haven''t entered any due date in the Outlook task. If you leave the field blank, today''s date is applied.';
                    }
                }
            }
            group(Interactions)
            {
                Caption = 'Interactions';
                field("Mergefield Language ID"; Rec."Mergefield Language ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the language ID of the Windows language to use for naming the merge fields shown when editing an attachment in Microsoft Word.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Language: Codeunit Language;
                    begin
                        Language.LookupApplicationLanguageId(Rec."Mergefield Language ID");
                    end;
                }
                group("Bus. Relation Code for")
                {
                    Caption = 'Bus. Relation Code for';
                    field("Bus. Rel. Code for Customers"; Rec."Bus. Rel. Code for Customers")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Customers';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a customer.';
                    }
                    field("Bus. Rel. Code for Vendors"; Rec."Bus. Rel. Code for Vendors")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Vendors';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a vendor.';
                    }
                    field("Bus. Rel. Code for Bank Accs."; Rec."Bus. Rel. Code for Bank Accs.")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Bank Accounts';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a bank account.';
                    }
                    field("Bus. Rel. Code for Employees"; Rec."Bus. Rel. Code for Employees")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Employees';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also an employee.';
                    }
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Contact Nos."; Rec."Contact Nos.")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to contacts.';
                }
                field("Campaign Nos."; Rec."Campaign Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to campaigns.';
                }
                field("Segment Nos."; Rec."Segment Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to segments.';
                }
                field("To-do Nos."; Rec."To-do Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to tasks.';
                }
                field("Opportunity Nos."; Rec."Opportunity Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to opportunities.';
                }
            }
            group(Duplicates)
            {
                Caption = 'Duplicates';
                field("Maintain Dupl. Search Strings"; Rec."Maintain Dupl. Search Strings")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the automatic update of search strings used to search for duplicates. You can set up search strings in the Duplicate Search String Setup table.';
                }
                field("Autosearch for Duplicates"; Rec."Autosearch for Duplicates")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that you want to search automatically for duplicates each time a contact is created or modified.';
                }
                field("Search Hit %"; Rec."Search Hit %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the level of precision to apply when searching for duplicates.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Setup")
            {
                Caption = '&Setup';
                Image = Setup;
                action("Duplicate Search String Setup")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Duplicate Search String Setup';
                    Image = CompareContacts;
                    RunObject = Page "Duplicate Search String Setup";
                    ToolTip = 'View or edit the list of search strings to use when searching for duplicates.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Email Logging Using Graph API")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Email Logging Setup';
                    Image = Setup;
                    ToolTip = 'Open the Email Logging Setup window.';

                    trigger OnAction()
                    begin
                        OnRunEmailLoggingSetup();
                    end;
                }
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        SoftwareAsAService := EnvironmentInfo.IsSaaSInfrastructure();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        AttachmentStorageLocationEnabl := Rec."Attachment Storage Type" = Enum::"Attachment Storage Type"::"Disk File";

    end;

    var
        AttachmentStorageLocationEnabl: Boolean;
        SoftwareAsAService: Boolean;

    procedure SetAttachmentStorageType()
    begin
        if (Rec."Attachment Storage Type" = "Attachment Storage Type"::Embedded) or
           (Rec."Attachment Storage Location" <> '')
        then begin
            Rec.Modify();
            Commit();
            REPORT.Run(REPORT::"Relocate Attachments");
        end;
    end;

    procedure SetAttachmentStorageLocation()
    begin
        if Rec."Attachment Storage Location" <> '' then begin
            Rec.Modify();
            Commit();
            REPORT.Run(REPORT::"Relocate Attachments");
        end;
    end;

    local procedure AttachmentStorageTypeOnAfterVa()
    begin
        AttachmentStorageLocationEnabl := Rec."Attachment Storage Type" = Enum::"Attachment Storage Type"::"Disk File";
        SetAttachmentStorageType();
    end;

    local procedure AttachmentStorageLocationOnAft()
    begin
        SetAttachmentStorageLocation();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunEmailLoggingSetup()
    begin
    end;
}

