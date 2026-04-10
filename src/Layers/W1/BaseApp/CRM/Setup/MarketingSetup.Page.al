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

                    trigger OnValidate()
                    begin
                        AttachmentStorageTypeOnAfterVa();
                    end;
                }
                field("Attachment Storage Location"; Rec."Attachment Storage Location")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = AttachmentStorageLocationEnabl;

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
                    }
                    field("Inherit Territory Code"; Rec."Inherit Territory Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Territory Code';
                    }
                    field("Inherit Country/Region Code"; Rec."Inherit Country/Region Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Country/Region Code';
                    }
                    field("Inherit Language Code"; Rec."Inherit Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Language Code';
                    }
                    field("Inherit Address Details"; Rec."Inherit Address Details")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Address Details';
                    }
                    field("Inherit Communication Details"; Rec."Inherit Communication Details")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Communication Details';
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
                    }
                    field("Default Territory Code"; Rec."Default Territory Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Territory Code';
                    }
                    field("Default Country/Region Code"; Rec."Default Country/Region Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Country/Region Code';
                    }
                    field("Default Language Code"; Rec."Default Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Language Code';
                    }
                    field("Default Format Region"; Rec."Default Format Region")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Format Region Code';
                    }
                    field("Default Correspondence Type"; Rec."Default Correspondence Type")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Correspondence Type';
                    }
                    field("Def. Company Salutation Code"; Rec."Def. Company Salutation Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Company Salutation Code';
                    }
                    field("Default Person Salutation Code"; Rec."Default Person Salutation Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Person Salutation Code';
                    }
                    field("Default Sales Cycle Code"; Rec."Default Sales Cycle Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Sales Cycle Code';
                    }
                    field("Default To-do Date Calculation"; Rec."Default To-do Date Calculation")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Task Date Calculation';
                    }
                }
            }
            group(Interactions)
            {
                Caption = 'Interactions';
                field("Mergefield Language ID"; Rec."Mergefield Language ID")
                {
                    ApplicationArea = RelationshipMgmt;

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
                    }
                    field("Bus. Rel. Code for Vendors"; Rec."Bus. Rel. Code for Vendors")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Vendors';
                    }
                    field("Bus. Rel. Code for Bank Accs."; Rec."Bus. Rel. Code for Bank Accs.")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Bank Accounts';
                    }
                    field("Bus. Rel. Code for Employees"; Rec."Bus. Rel. Code for Employees")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Employees';
                    }
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Contact Nos."; Rec."Contact Nos.")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                }
                field("Campaign Nos."; Rec."Campaign Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Segment Nos."; Rec."Segment Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("To-do Nos."; Rec."To-do Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Opportunity Nos."; Rec."Opportunity Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
            }
            group(Duplicates)
            {
                Caption = 'Duplicates';
                field("Maintain Dupl. Search Strings"; Rec."Maintain Dupl. Search Strings")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Autosearch for Duplicates"; Rec."Autosearch for Duplicates")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Search Hit %"; Rec."Search Hit %")
                {
                    ApplicationArea = RelationshipMgmt;
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

