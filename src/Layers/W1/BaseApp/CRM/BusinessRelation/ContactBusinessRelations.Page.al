// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.CRM.Contact;

page 5061 "Contact Business Relations"
{
    Caption = 'Contact Business Relations';
    DataCaptionFields = "Contact No.";
    DataCaptionExpression = CaptionExpr;
    PageType = List;
    SourceTable = "Contact Business Relation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Business Relation Code"; Rec."Business Relation Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the business relation code.';
                }
                field("Business Relation Description"; Rec."Business Relation Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the description for the business relation you have assigned to the contact. This field is not editable.';
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = not FilteredContact;
                    ToolTip = 'Specifies the name of the contact.';
                }
                field("Link to Table"; Rec."Link to Table")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = not FilteredLinkToTable;
                    ToolTip = 'Specifies the name of the table to which the contact is linked. There are four possible options: &lt;blank&gt;, Vendor, Customer, and Bank Account.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(RelationName; Rec.GetName())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the involved entry or record.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowRelatedCardPage();
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
        area(Navigation)
        {
            action(OpenCardPage)
            {
                ApplicationArea = RelationshipMgmt;
                Image = Card;
                Caption = 'Open Card Page';
                ToolTip = 'Open the card page for the current business relation.';

                trigger OnAction()
                begin
                    Rec.ShowRelatedCardPage();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenCardPage_Promoted; OpenCardPage)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("Contact No.") <> '' then begin
            Rec.CopyFilter("Contact No.", DefaultContact."No.");
            DefaultContact.SetRange(Type, DefaultContact.Type::Company);
            FilteredContact := DefaultContact.FindFirst();
        end;
        FilteredLinkToTable := Rec.GetFilter("Link to Table") <> '';
        if FilteredLinkToTable then begin
            FilteredLinkToTable := Evaluate(DefaultLinkToTable, Rec.GetFilter("Link to Table"));
            CaptionExpr := Format(DefaultLinkToTable);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if FilteredContact then
            Rec."Contact No." := DefaultContact."No.";
        if FilteredLinkToTable then
            Rec."Link to Table" := DefaultLinkToTable;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact(Rec."Contact No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact(Rec."Contact No.");
    end;

    trigger OnModifyRecord(): Boolean
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact(Rec."Contact No.");
    end;

    var
        DefaultContact: Record Contact;
        DefaultLinkToTable: Enum "Contact Business Relation Link To Table";
        CaptionExpr: Text;
        FilteredContact: Boolean;
        FilteredLinkToTable: Boolean;
}

