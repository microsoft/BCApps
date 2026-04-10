// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Environment;

codeunit 1636 "Office Contact Handler"
{
    TableNo = "Office Add-in Context";

    trigger OnRun()
    begin
        if (Rec.Email <> '') or (Rec."Contact No." <> '') then
            FindAndRedirectContact(Rec)
        else
            ShowContactSelection(Rec);
    end;

    var
        SelectAContactTxt: Label 'Select a contact';
        MatchingContactDifferentCompanyLbl: Label 'A matching contact was found in company "%1". Would you like to switch company and show the matching contact?', Comment = '%1 = the company name of where the contact was found';
        PageOpenTxt: Label 'Open page for the selected contact.', Locked = true;
        TelemetryCategoryTxt: Label 'AL Office Contact Handler', Locked = true;
        NoAccessCompanyTelemetryTxt: Label 'Cannot access company %1 from Outlook add-in.', Locked = true;

    local procedure FindAndRedirectContact(TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        TempCompany: Record Company temporary;
        TempOfficeContactDetails: Record "Office Contact Details" temporary;
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
    begin
        AssistedCompanySetup.GetAllowedCompaniesForCurrentUser(TempCompany);
        if TempOfficeAddinContext.Company <> '' then
            TempCompany.SetRange(Name, CopyStr(TempOfficeAddinContext.Company, 1, 30));
        if TempOfficeAddinContext."Contact No." <> '' then
            Contact.SetRange("No.", TempOfficeAddinContext."Contact No.");

        // Check if the current company has any contacts that match the filter
        FindContacts(TempOfficeAddinContext, TempOfficeContactDetails, Contact, ContactBusinessRelation, CopyStr(CompanyName(), 1, MaxStrLen(TempCompany.Name)));

        if TempOfficeContactDetails.IsEmpty() and TempCompany.FindSet() then
            repeat
                Contact.ChangeCompany(TempCompany.Name);
                ContactBusinessRelation.ChangeCompany(TempCompany.Name);
                FindContacts(TempOfficeAddinContext, TempOfficeContactDetails, Contact, ContactBusinessRelation, TempCompany.Name);
                ContactBusinessRelation.Reset();
            until TempCompany.Next() = 0;

        if TempOfficeContactDetails.IsEmpty() then begin
            Page.Run(Page::"Office New Contact Dlg");
            exit;
        end;

        if (TempOfficeContactDetails.Count() > 1) and (TempOfficeAddinContext.Command <> '') then
            TempOfficeContactDetails.SetRange("Associated Table", TempOfficeAddinContext.CommandType());

        if TempOfficeContactDetails.Count() = 1 then begin
            ChangeCompanyAndShowContact(TempOfficeContactDetails, TempOfficeAddinContext, Contact);
            exit;
        end;

        TempOfficeContactDetails.SetRange(Type, TempOfficeContactDetails.Type::"Contact Person");
        if TempOfficeContactDetails.Count() = 1 then begin
            ChangeCompanyAndShowContact(TempOfficeContactDetails, TempOfficeAddinContext, Contact);
            exit;
        end;

        TempOfficeContactDetails.SetRange(Type);
        TempOfficeContactDetails.SetRange("Associated Table");
        if TempOfficeContactDetails.Count() > 1 then
            Page.Run(Page::"Office Contact Associations", TempOfficeContactDetails);
    end;

    local procedure ChangeCompanyAndShowContact(var TempOfficeContactDetails: Record "Office Contact Details" temporary; var TempOfficeAddinContext: Record "Office Add-in Context" temporary; var Contact: Record Contact)
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        if not OfficeMgt.ChangeCompanyWithPrompt(TempOfficeContactDetails.Company, StrSubstNo(MatchingContactDifferentCompanyLbl, TempOfficeContactDetails.Company)) then begin
            Page.Run(Page::"Office New Contact Dlg");
            exit;
        end;

        TempOfficeContactDetails.FindFirst();
        ShowCustomerVendor(TempOfficeAddinContext, Contact, TempOfficeContactDetails."Associated Table", TempOfficeContactDetails.GetContactNo());
    end;

    local procedure FindContacts(TempOfficeAddinContext: Record "Office Add-in Context" temporary; var TempOfficeContactDetails: Record "Office Contact Details" temporary; var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; Company: Text[50])
    begin
        if not Contact.ReadPermission() or not ContactBusinessRelation.ReadPermission() then begin
            Session.LogMessage('0000KD7', StrSubstNo(NoAccessCompanyTelemetryTxt, Company), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            exit;
        end;

        if TempOfficeAddinContext."Contact No." <> '' then
            Contact.SetRange("No.", TempOfficeAddinContext."Contact No.")
        else
            Contact.SetRange("Search E-Mail", UPPERCASE(TempOfficeAddinContext.Email));

        if not Contact.IsEmpty() then
            CollectMultipleContacts(Contact, ContactBusinessRelation, TempOfficeContactDetails, TempOfficeAddinContext, Company);
    end;

    procedure ShowContactSelection(OfficeAddinContext: Record "Office Add-in Context")
    var
        Contact: Record Contact;
        ContactList: Page "Contact List";
    begin
        FilterContacts(OfficeAddinContext, Contact);
        ContactList.SetTableView(Contact);
        ContactList.LookupMode(true);
        ContactList.Caption(SelectAContactTxt);
        Session.LogMessage('0000J6Y', PageOpenTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
        ContactList.Run();
    end;

    procedure ShowCustomerVendor(TempOfficeAddinContext: Record "Office Add-in Context" temporary; Contact: Record Contact; AssociatedTable: Option; LinkNo: Code[20])
    var
        Customer: Record Customer;
        OfficeContactDetails: Record "Office Contact Details";
        Vendor: Record Vendor;
    begin
        case AssociatedTable of
            OfficeContactDetails."Associated Table"::Customer:
                begin
                    if TempOfficeAddinContext.CommandType() = OfficeContactDetails."Associated Table"::Vendor then
                        Page.Run(Page::"Office No Vendor Dlg", Contact)
                    else
                        if Customer.Get(LinkNo) then
                            RedirectCustomer(Customer, TempOfficeAddinContext);
                    exit;
                end;
            OfficeContactDetails."Associated Table"::Vendor:
                begin
                    if TempOfficeAddinContext.CommandType() = OfficeContactDetails."Associated Table"::Customer then
                        Page.Run(Page::"Office No Customer Dlg", Contact)
                    else
                        if Vendor.Get(LinkNo) then
                            RedirectVendor(Vendor, TempOfficeAddinContext);
                    exit;
                end;
            else
                if TempOfficeAddinContext.CommandType() = OfficeContactDetails."Associated Table"::Customer then begin
                    Page.Run(Page::"Office No Customer Dlg", Contact);
                    exit;
                end;
                if TempOfficeAddinContext.CommandType() = OfficeContactDetails."Associated Table"::Vendor then begin
                    Page.Run(Page::"Office No Vendor Dlg", Contact);
                    exit;
                end;
        end;

        Contact.Get(LinkNo);
        Page.Run(Page::"Contact Card", Contact)
    end;

    local procedure CollectMultipleContacts(var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var TempOfficeContactDetails: Record "Office Contact Details" temporary; TempOfficeAddinContext: Record "Office Add-in Context" temporary; ContactCompany: Text[50])
    begin
        FilterContactBusinessRelations(Contact, ContactBusinessRelation);
        if TempOfficeAddinContext.IsAppointment() then
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if ContactBusinessRelation.FindSet() then
            repeat
                ContactBusinessRelation.CalcFields("Business Relation Description");
                if not TempOfficeContactDetails.Get(ContactBusinessRelation."Contact No.", Contact.Type, ContactBusinessRelation."Link to Table", ContactCompany) then begin
                    Clear(TempOfficeContactDetails);
                    TempOfficeContactDetails.Init();
                    TempOfficeContactDetails.TransferFields(ContactBusinessRelation);
                    TempOfficeContactDetails."Contact Name" := Contact.Name;
                    TempOfficeContactDetails.Company := ContactCompany;
                    TempOfficeContactDetails.Type := Contact.Type;
                    TempOfficeContactDetails."Business Relation Description" := ContactBusinessRelation."Business Relation Description";
                    if ContactBusinessRelation."Link to Table".AsInteger() = TempOfficeAddinContext.CommandType() then begin
                        TempOfficeContactDetails."Contact No." := Contact."No.";
                        TempOfficeContactDetails."Associated Table" := TempOfficeAddinContext.CommandType();
                    end;
                    TempOfficeContactDetails.Insert();
                end;
            until ContactBusinessRelation.Next() = 0
        else
            if Contact.FindSet() then
                repeat
                    CreateUnlinkedContactAssociation(TempOfficeContactDetails, Contact, ContactCompany);
                until Contact.Next() = 0;
    end;

    local procedure CreateUnlinkedContactAssociation(var TempOfficeContactDetails: Record "Office Contact Details" temporary; Contact: Record Contact; ContactCompany: Text)
    begin
        Clear(TempOfficeContactDetails);
        TempOfficeContactDetails.SetRange("No.", Contact."Company No.");
        if TempOfficeContactDetails.FindFirst() and (TempOfficeContactDetails.Type = Contact.Type::Company) then
            TempOfficeContactDetails.Delete();

        if TempOfficeContactDetails.IsEmpty() then begin
            TempOfficeContactDetails.Init();
            TempOfficeContactDetails."No." := Contact."Company No.";
            if TempOfficeContactDetails."No." = '' then
                TempOfficeContactDetails."No." := Contact."No.";
            TempOfficeContactDetails."Contact No." := Contact."No.";
            TempOfficeContactDetails."Contact Name" := Contact.Name;
            TempOfficeContactDetails.Company := CopyStr(ContactCompany, 1, 50);
            TempOfficeContactDetails.Type := Contact.Type;
            TempOfficeContactDetails.Insert();
        end;

        TempOfficeContactDetails.SetRange("No.");
    end;

    local procedure FilterContactBusinessRelations(var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation")
    var
        ContactFilter: Text;
    begin
        // Filter contact business relations based on the specified list of contacts
        if Contact.FindSet() then
            repeat
                if StrPos(ContactFilter, Contact."No.") = 0 then
                    ContactFilter += Contact."No." + '|';
                if (StrPos(ContactFilter, Contact."Company No.") = 0) and (Contact."Company No." <> '') then
                    ContactFilter += Contact."Company No." + '|';
            until Contact.Next() = 0;

        ContactBusinessRelation.SetFilter("Contact No.", DelChr(ContactFilter, '>', '|'));
    end;

    local procedure FilterContacts(OfficeAddinContext: Record "Office Add-in Context"; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        case true of
            OfficeAddinContext.Command <> '':
                ContactBusinessRelation.SetRange("Link to Table", OfficeAddinContext.CommandType());
            OfficeAddinContext.IsAppointment():
                ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
            else
                exit;
        end;

        if ContactBusinessRelation.FindSet() then begin
            Contact.FilterGroup(-1);
            repeat
                Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.");
                Contact.SetRange("No.", ContactBusinessRelation."Contact No.");
                if Contact.FindSet() then
                    repeat
                        Contact.Mark(true);
                    until Contact.Next() = 0;
            until ContactBusinessRelation.Next() = 0;

            Contact.MarkedOnly(true);
        end;
    end;

    local procedure RedirectCustomer(Customer: Record Customer; var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeDocumentHandler: Codeunit "Office Document Handler";
    begin
        Page.Run(Page::"Customer Card", Customer);
        OfficeDocumentHandler.HandleSalesCommand(Customer, TempOfficeAddinContext);
    end;

    local procedure RedirectVendor(Vendor: Record Vendor; var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeDocumentHandler: Codeunit "Office Document Handler";
    begin
        Page.Run(Page::"Vendor Card", Vendor);
        OfficeDocumentHandler.HandlePurchaseCommand(Vendor, TempOfficeAddinContext);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Contact List", 'OnClosePageEvent', '', false, false)]
    local procedure OnContactSelected(var Rec: Record Contact)
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable() then begin
            OfficeMgt.GetContext(TempOfficeAddinContext);
            if TempOfficeAddinContext.Email = '' then begin
                TempOfficeAddinContext.Name := Rec.Name;
                TempOfficeAddinContext.Email := Rec."E-Mail";
                TempOfficeAddinContext."Contact No." := Rec."No.";
                TempOfficeAddinContext.Company := CompanyName();
                OfficeMgt.AddRecipient(Rec.Name, Rec."E-Mail");
                OfficeMgt.InitializeContext(TempOfficeAddinContext);
            end;
        end;
    end;
}

