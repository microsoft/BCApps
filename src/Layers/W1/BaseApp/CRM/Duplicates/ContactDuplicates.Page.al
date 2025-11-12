// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

using Microsoft.CRM.Contact;

page 5134 "Contact Duplicates"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Duplicate Contacts';
    DataCaptionFields = "Contact No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Contact Duplicate";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the contact for which a duplicate has been found.';
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact for which a duplicate has been found.';
                }
                field("Duplicate Contact No."; Rec."Duplicate Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the contact number of the duplicate that was found.';
                }
                field("Duplicate Contact Name"; Rec."Duplicate Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    DrillDownPageID = "Contact Card";
                    ToolTip = 'Specifies the name of the contact that has been identified as a possible duplicate.';
                }
                field("Separate Contacts"; Rec."Separate Contacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the two contacts are not true duplicates, but separate contacts.';

                    trigger OnValidate()
                    begin
                        SeparateContactsOnAfterValidat();
                    end;
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
        area(processing)
        {
            action(GenerateDuplicateSearchString)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Generate Duplicate Search String';
                Image = CompareContacts;
                ToolTip = 'Create a duplicate search string for contacts to be used when searching for duplicate contact entries.';

                trigger OnAction()
                begin
                    REPORT.Run(REPORT::"Generate Dupl. Search String");
                end;
            }
            action(ContactDuplicateDetails)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'View';
                Image = View;
                ToolTip = 'View details of the contacts that were detected as duplicates.';

                trigger OnAction()
                var
                    ContactDuplicateDetails: Page "Contact Duplicate Details";
                begin
                    ContactDuplicateDetails.SetContactNo(Rec."Contact No.", Rec."Duplicate Contact No.");
                    ContactDuplicateDetails.Run();
                end;
            }
            action(MergeDuplicate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Merge Contacts';
                Enabled = not Rec."Separate Contacts";
                Ellipsis = true;
                Image = ItemSubstitution;
                ToolTip = 'Merge two contact records into one. Before merging, review which field values you want to keep or override. The merge action cannot be undone.';

                trigger OnAction()
                var
                    MergeDuplBuffer: Record "Merge Duplicates Buffer";
                    MergeDuplicate: Page "Merge Duplicate";
                begin
                    MergeDuplBuffer.Validate("Table ID", DATABASE::Contact);
                    MergeDuplBuffer.Current := Rec."Contact No.";
                    MergeDuplBuffer.Duplicate := Rec."Duplicate Contact No.";
                    MergeDuplicate.Set(MergeDuplBuffer);
                    MergeDuplicate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(MergeDuplicate_Promoted; MergeDuplicate)
                {
                }
                actionref(GenerateDuplicateSearchString_Promoted; GenerateDuplicateSearchString)
                {
                }
                actionref(ContactDuplicateDetails_Promoted; ContactDuplicateDetails)
                {
                }
            }
        }
    }

    local procedure SeparateContactsOnAfterValidat()
    begin
        CurrPage.Update();
    end;
}

