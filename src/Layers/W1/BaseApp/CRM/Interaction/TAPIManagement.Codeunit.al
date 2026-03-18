// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 5053 TAPIManagement
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text001: Label 'No Contact found.';
#pragma warning disable AA0470
        Text002: Label 'No registered phone numbers have been found for this %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure Dial(PhoneNumber: Text[80]): Boolean
    begin
        HyperLink(StrSubstNo('tel:%1', PhoneNumber));
        exit(true);
    end;

    procedure DialContCustVendBank(TableNo: Integer; No: Code[20]; PhoneNo: Text[30]; ContAltAddrCode: Code[10])
    var
        ContBusRel: Record "Contact Business Relation";
        Contact: Record Contact;
        Task: Record "To-do";
        TempSegmentLine: Record "Segment Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDialContCustVendBank(TableNo, No, PhoneNo, ContAltAddrCode, IsHandled);
        if IsHandled then
            exit;

        case TableNo of
            Database::Contact:
                Contact.Get(No);
            Database::"To-do":
                begin
                    Task.Get(No);
                    Task.TestField("Contact No.");
                    Contact.Get(Task."Contact No.");
                end;
            else begin
                ContBusRel.Reset();
                ContBusRel.SetCurrentKey("Link to Table", "No.");
                case TableNo of
                    Database::Customer:
                        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    Database::Vendor:
                        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
                    Database::"Bank Account":
                        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::"Bank Account");
                    else
                        OnDialContCustVendBankCaseElse(ContBusRel, TableNo);
                end;
                ContBusRel.SetRange("No.", No);
                if ContBusRel.FindFirst() then
                    Contact.Get(ContBusRel."Contact No.")
                else
                    Error(Text001);
            end;
        end;

        OnDialContCustVendBankOnBeforemakePhoneCall(Contact);

        // Call Make Phone Call Wizard
        TempSegmentLine.MakePhoneCallFromContact(Contact, Task, TableNo, PhoneNo, ContAltAddrCode);
    end;

    procedure ShowNumbers(ContactNo: Code[20]; ContAltAddrCode: Code[10]): Text[260]
    var
        TempCommunicationMethod: Record "Communication Method" temporary;
        Contact: Record Contact;
        Contact2: Record Contact;
        ContAltAddrCode2: Code[10];
    begin
        if not Contact.Get(ContactNo) then
            exit;

        if ContAltAddrCode = '' then
            ContAltAddrCode2 := Contact.ActiveAltAddress(Today)
        else
            ContAltAddrCode2 := ContAltAddrCode;

        CreateCommMethod(Contact, TempCommunicationMethod, ContactNo, ContAltAddrCode);

        // Get linked company phonenumbers
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then begin
            Contact2.Get(Contact."Company No.");

            if ContAltAddrCode = '' then
                ContAltAddrCode2 := Contact2.ActiveAltAddress(Today)
            else
                ContAltAddrCode2 := ContAltAddrCode;

            CreateCommMethod(Contact2, TempCommunicationMethod, ContactNo, ContAltAddrCode2);
        end;
        if TempCommunicationMethod.FindFirst() then begin
            if PAGE.RunModal(PAGE::"Contact Through", TempCommunicationMethod) = ACTION::LookupOK then
                exit(TempCommunicationMethod.Number);
        end else
            Error(Text002, Contact.TableCaption());
    end;

    local procedure TrimCode("Code": Code[20]) TrimString: Text[20]
    begin
        TrimString := CopyStr(Code, 1, 1) + LowerCase(CopyStr(Code, 2, StrLen(Code) - 1))
    end;

    local procedure CreateCommMethod(Contact: Record Contact; var TempCommunicationMethod: Record "Communication Method" temporary; ContactNo: Code[20]; ContAltAddrCode: Code[10])
    var
        ContAltAddr: Record "Contact Alt. Address";
    begin
        TempCommunicationMethod.Init();
        TempCommunicationMethod."Contact No." := ContactNo;
        TempCommunicationMethod.Name := Contact.Name;
        if Contact."Phone No." <> '' then begin
            TempCommunicationMethod."Key" += 1;
            TempCommunicationMethod.Description := CopyStr(Contact.FieldCaption("Phone No."), 1, MaxStrLen(TempCommunicationMethod.Description));
            TempCommunicationMethod.Number := Contact."Phone No.";
            TempCommunicationMethod.Type := Contact.Type;
            TempCommunicationMethod.Insert();
        end;
        if Contact."Mobile Phone No." <> '' then begin
            TempCommunicationMethod."Key" += 1;
            TempCommunicationMethod.Description := CopyStr(Contact.FieldCaption("Mobile Phone No."), 1, MaxStrLen(TempCommunicationMethod.Description));
            TempCommunicationMethod.Number := Contact."Mobile Phone No.";
            TempCommunicationMethod.Type := Contact.Type;
            TempCommunicationMethod.Insert();
        end;
        // Alternative address
        if ContAltAddr.Get(Contact."No.", ContAltAddrCode) then begin
            if ContAltAddr."Phone No." <> '' then begin
                TempCommunicationMethod."Key" += 1;
                TempCommunicationMethod.Description :=
                  CopyStr(TrimCode(ContAltAddr.Code) + ' - ' + ContAltAddr.FieldCaption("Phone No."), 1, MaxStrLen(TempCommunicationMethod.Description));
                TempCommunicationMethod.Number := ContAltAddr."Phone No.";
                TempCommunicationMethod.Type := Contact.Type;
                TempCommunicationMethod.Insert();
            end;
            if ContAltAddr."Mobile Phone No." <> '' then begin
                TempCommunicationMethod."Key" += 1;
                TempCommunicationMethod.Description :=
                  CopyStr(TrimCode(ContAltAddr.Code) + ' - ' + ContAltAddr.FieldCaption("Mobile Phone No."), 1, MaxStrLen(TempCommunicationMethod.Description));
                TempCommunicationMethod.Number := ContAltAddr."Mobile Phone No.";
                TempCommunicationMethod.Type := Contact.Type;
                TempCommunicationMethod.Insert();
            end;
        end;
        OnAfterCreateCommMethod(Contact, TempCommunicationMethod, ContactNo, ContAltAddrCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDialContCustVendBank(TableNo: Integer; No: Code[20]; PhoneNo: Text[30]; ContAltAddrCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDialContCustVendBankOnBeforemakePhoneCall(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDialContCustVendBankCaseElse(var ContactBusinessRelation: Record "Contact Business Relation"; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCommMethod(Contact: Record Contact; var TempCommunicationMethod: Record "Communication Method" temporary; ContactNo: Code[20]; ContAltAddrCode: Code[10])
    begin
    end;
}

