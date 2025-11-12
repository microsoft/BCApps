// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.CRM.Contact;

page 1630 "Office Contact Details Dlg"
{
    Caption = 'Create New Contact';
    PageType = StandardDialog;
    SourceTable = Contact;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control7)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact. If the contact is a person, you can click the field to see the Name Details window.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the email address of the contact.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of contact, either company or person.';

                    trigger OnValidate()
                    begin
                        AssociateToCompany := Rec.Type = Rec.Type::Person;
                        AssociateEnabled := Rec.Type = Rec.Type::Person;
                        if Rec.Type = Rec.Type::Company then begin
                            Clear(Rec."Company No.");
                            Clear(Rec."Company Name");
                        end;
                    end;
                }
                field("Associate to Company"; AssociateToCompany)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Associate to Company';
                    Enabled = AssociateEnabled;
                    ToolTip = 'Specifies whether the contact is associated with a company.';

                    trigger OnValidate()
                    begin
                        if not AssociateToCompany then begin
                            Clear(Rec."Company No.");
                            Clear(Rec."Company Name");
                        end;
                    end;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Company';
                    Enabled = AssociateToCompany;
                    ToolTip = 'Specifies the name of the company. If the contact is a person, it specifies the name of the company for which this contact works.';

                    trigger OnAssistEdit()
                    begin
                        Rec.LookupCompany();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        AssociateToCompany := Rec.Type = Rec.Type::Person;
        AssociateEnabled := AssociateToCompany;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            if AssociateToCompany and (Rec."Company Name" = '') then
                Error(MustSpecifyCompanyErr);
    end;

    protected var
        AssociateEnabled: Boolean;
        AssociateToCompany: Boolean;

    var
        MustSpecifyCompanyErr: Label 'You must specify the name of the company because the contact is a person and associated with a company.';

}

