// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Contact;
using System.Environment;

page 5150 "Contact Segment List"
{
    Caption = 'Contact Segment List';
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = "Segment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Segment No."; Rec."Segment No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the segment to which this segment line belongs.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the segment line.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date the segment line was created.';
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the contact to which this segment line applies.';
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact to which the segment line applies. The program automatically fills in this field when you fill in the Contact No. field on the line.';
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
            group("&Segment")
            {
                Caption = '&Segment';
                Image = Segment;
                action("&Card")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page Segment;
                    RunPageLink = "No." = field("Segment No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the contact segment.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Contact Name");
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

    local procedure GetCaption() Result: Text
    var
        Contact: Record Contact;
        SourceFilter: Text;
    begin
        if Rec.GetFilter("Contact Company No.") <> '' then begin
            SourceFilter := Rec.GetFilter("Contact Company No.");
            if MaxStrLen(Contact."Company No.") >= StrLen(SourceFilter) then
                if Contact.Get(SourceFilter) then
                    Result := StrSubstNo('%1 %2', Contact."No.", Contact.Name);
        end;

        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone then
            Result := StrSubstNo('%1 %2', CurrPage.Caption, Result);
    end;
}

