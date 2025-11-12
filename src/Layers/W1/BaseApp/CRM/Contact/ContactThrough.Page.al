// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

page 5145 "Contact Through"
{
    Caption = 'Contact Through';
    DataCaptionFields = "Contact No.", Name;
    Editable = false;
    PageType = List;
    SourceTable = "Communication Method";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the contact to which the phone number is related. There are two options:';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the phone number or e-mail address.';
                }
                field(Number; Rec.Number)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the telephone number.';
                    Visible = NumberVisible;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = RelationshipMgmt;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the contact''s email address.';
                    Visible = EmailVisible;
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
    }

    trigger OnInit()
    begin
        EmailVisible := true;
        NumberVisible := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.SetFilter(Number, '<>''''');
        if Rec.Find('-') then begin
            CurrPage.Caption := Text000;
            NumberVisible := true;
            EmailVisible := false;
        end else begin
            Rec.Reset();
            Rec.SetFilter("E-Mail", '<>''''');
            if Rec.Find('-') then begin
                CurrPage.Caption := Text001;
                NumberVisible := false;
                EmailVisible := true;
            end else
                CurrPage.Close();
        end;
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Contact Phone Numbers';
        Text001: Label 'Contact Emails';
#pragma warning restore AA0074
        NumberVisible: Boolean;
        EmailVisible: Boolean;
}

