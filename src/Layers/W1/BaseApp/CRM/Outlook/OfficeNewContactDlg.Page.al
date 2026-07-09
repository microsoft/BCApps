// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;

page 1604 "Office New Contact Dlg"
{
    Caption = 'Do you want to add a new contact?';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = Contact;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                InstructionalText = 'The sender of this email is not among your contacts.';
                //The GridLayout property is only supported on controls of type Grid
                //GridLayout = Rows;
                ShowCaption = false;
                field(NewPersonContact; StrSubstNo(CreatePersonContactLbl, TempOfficeAddinContext.Name))
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a new person contact.';

                    trigger OnDrillDown()
                    begin
                        CreateNewContact(Rec.Type::Person);
                    end;
                }
                field(LinkContact; LinkContactLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the contacts in your company.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Contact List");
                    end;
                }
                field(Lb1; '')
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
                field(Lb2; '')
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
                field(CurrentCompany; StrSubstNo(CurrentCompanyLbl, CompanyName()))
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
                field(ChangeCompany; ChangeCompanyLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    var
                        OfficeMgt: Codeunit "Office Management";
                    begin
                        OfficeMgt.SelectAndChangeCompany();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        OfficeMgt.GetContext(TempOfficeAddinContext);
    end;

    var
        CreatePersonContactLbl: Label 'Add %1 as a contact', Comment = '%1 = Contact name';
        LinkContactLbl: Label 'View existing contacts';
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        ChangeCompanyLbl: Label 'Wrong company?';
        CurrentCompanyLbl: Label 'Current company: %1', Comment = '%1 - the name of the current company';

    local procedure NotLinked(Contact: Record Contact): Boolean
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        // Person could be linked directly or through Company No.
        ContBusRel.SetFilter("Contact No.", '%1|%2', Contact."No.", Contact."Company No.");
        ContBusRel.SetFilter("No.", '<>''''');
        exit(ContBusRel.IsEmpty);
    end;

    local procedure CreateNewContact(ContactType: Enum "Contact Type")
    var
        TempContact: Record Contact temporary;
        Contact: Record Contact;
        NameLength: Integer;
    begin
        Contact.SetRange("Search E-Mail", TempOfficeAddinContext.Email);
        if not Contact.FindFirst() then begin
            NameLength := 50;
            if StrPos(TempOfficeAddinContext.Name, ' ') = 0 then
                NameLength := 30;
            TempContact.Init();
            TempContact.Validate(Type, ContactType);
            TempContact.Validate(Name, CopyStr(TempOfficeAddinContext.Name, 1, NameLength));
            TempContact.Validate("E-Mail", TempOfficeAddinContext.Email);
            TempContact.Insert();
            Commit();
        end;

        if Action::LookupOK = Page.RunModal(Page::"Office Contact Details Dlg", TempContact) then begin
            Clear(Contact);
            Contact.TransferFields(TempContact);
            Contact.Insert(true);
            Commit();
            if NotLinked(Contact) then
                Page.Run(Page::"Contact Card", Contact)
            else
                Contact.ShowBusinessRelation(Enum::"Contact Business Relation Link To Table"::" ", false);
            CurrPage.Close();
        end;
    end;
}

