// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;

#pragma warning disable AA0217
codeunit 11401 "Post Code Management"
{

    trigger OnRun()
    begin
    end;

    var
        PostCodeLookupTable: Codeunit "Post Code Lookup - Table";

    procedure FindStreetName(var Address: Text[100]; var Address2: Text[50]; var PostCode: Code[20]; var City: Text[30]; var CountryCode: Code[10]; var PhoneNo: Text[30]; var FaxNo: Text[30])
    var
        NewAddress: Text[100];
        NewStreetname: Text[50];
        NewHouseNo: Text[50];
        NewPostCode: Code[20];
        NewCity: Text[50];
        NewPhoneNo: Text[30];
        NewFaxNo: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindStreetNameFromAddress(IsHandled);
        if IsHandled then
            exit;

        NewAddress := DelChr(Address, '<');

        case true of
            NewAddress = '':
                exit;
            not ParseAddress(NewAddress, NewHouseNo, NewPostCode):
                exit;
        end;

        if not PostCodeLookupTable.FindStreetNameFromAddress(
             NewStreetname, NewHouseNo, NewPostCode, NewCity, NewPhoneNo, NewFaxNo)
        then
            exit;

        if StrLen(NewHouseNo) = 0 then begin
            Address :=
                CopyStr(
                    DelChr(CopyStr(StrSubstNo('%1 %2', NewStreetname, NewAddress), 1, MaxStrLen(Address)), '<>'),
                    1, MaxStrLen(Address));
            Address2 :=
                CopyStr(
                    DelChr(CopyStr(StrSubstNo('%1 %2', NewStreetname, NewAddress), MaxStrLen(Address) + 1, MaxStrLen(Address2)), '<>'),
                    1, MaxStrLen(Address2));
        end else begin
            Address :=
                CopyStr(
                    DelChr(CopyStr(StrSubstNo('%1 %2%3', NewStreetname, NewHouseNo, NewAddress), 1, MaxStrLen(Address)), '<>'),
                    1, MaxStrLen(Address));
            Address2 :=
                CopyStr(
                    DelChr(CopyStr(StrSubstNo('%1 %2%3', NewStreetname, NewHouseNo, NewAddress), MaxStrLen(Address) + 1, MaxStrLen(Address2)), '<>'),
                    1, MaxStrLen(Address2));
        end;

        PostCode := NewPostCode;
        City := CopyStr(NewCity, 1, MaxStrLen(City));

        case true of
            NewPhoneNo = '':
                ;
            PhoneNo = '',
            PhoneNo[StrLen(PhoneNo)] = '-':
                PhoneNo := CopyStr(StrSubstNo('%1-', NewPhoneNo), 1, MaxStrLen(PhoneNo));
        end;

        case true of
            NewFaxNo = '':
                ;
            FaxNo = '',
            FaxNo[StrLen(FaxNo)] = '-':
                FaxNo := CopyStr(StrSubstNo('%1-', NewFaxNo), 1, MaxStrLen(FaxNo));
        end;

        OnAfterFindStreetNameFromAddress(Address, Address2, PostCode, City, CountryCode, PhoneNo, FaxNo);
    end;

    local procedure ParseAddress(var NewAddress: Text[100]; var NewHouseNo: Text[50]; var NewPostCode: Code[20]): Boolean
    var
        Done: Boolean;
    begin
        while (StrLen(NewAddress) > 0) and (not Done) do
            case StrLen(NewPostCode) of
                0 .. 3: // Find numbers
                    if NewAddress[1] in ['0' .. '9'] then begin
                        NewPostCode := NewPostCode + Format(NewAddress[1]);
                        NewAddress := DelChr(DelStr(NewAddress, 1, 1), '<');
                    end else
                        exit(false);
                4 .. 5: // Find letters
                    if UpperCase(Format(NewAddress[1])) in ['A' .. 'Z'] then begin
                        NewPostCode := NewPostCode + Format(NewAddress[1]);
                        NewAddress := DelChr(DelStr(NewAddress, 1, 1), '<');
                    end else
                        exit(false);
                else // Find house no.
                    if NewAddress[1] in ['0' .. '9'] then begin
                        NewHouseNo := NewHouseNo + Format(NewAddress[1]);
                        NewAddress := DelStr(NewAddress, 1, 1);
                    end else
                        exit(true);
            end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ParseAddressAdditionHouseNo(var StreetName: Text[100]; var HouseNo: Text[50]; var AdditionHouseNo: Text[50]; Address: Text[100])
    var
        HouseString: Text[50];
    begin
        StreetName := '';
        HouseNo := '';
        AdditionHouseNo := '';
        if Address = '' then
            exit;

        // Suppose that house string is a last word in the Address
        HouseString := GetHouseString(Address);

        if HouseString = '' then begin
            StreetName := Address;
            exit;
        end;

        // The last word is a House string with possible AdditionHouseNo information. All before last word is a StreetName.
        StreetName := CopyStr(Address, 1, StrLen(Address) - StrLen(HouseString) - 1);
        HouseNo := GetHouseNoFromHouseString(HouseString);
        AdditionHouseNo := HouseString;
    end;

    local procedure GetHouseString(Address: Text[100]): Text[50]
    var
        i: Integer;
    begin
        // If there's only one word then return empty HouseString
        if StrPos(Address, ' ') = 0 then
            exit('');

        // Find the last word: revert address string, cut first word, revert result
        RevertString(Address);

        // delete space symbols from the begining
        i := 1;
        while Address[i] = ' ' do
            i += 1;
        Address := CopyStr(Address, i);

        // cut the first word
        i := StrPos(Address, ' ');
        Address := CopyStr(Address, 1, i - 1);

        RevertString(Address);
        // If result word starts with digit then return it as HouseString
        if Address[1] in ['0' .. '9'] then
            exit(Address);

        exit('');
    end;

    local procedure GetHouseNoFromHouseString(var HouseString: Text[50]) HouseNo: Text[50]
    var
        Pos: Integer;
    begin
        Pos := 1;
        while HouseString[Pos] in ['0' .. '9'] do
            Pos += 1;
        HouseNo := CopyStr(HouseString, 1, Pos - 1);

        // remove HouseNo from the HouseString including special separating char if such exist
        if HouseString[Pos] in ['/', '\', '-'] then
            Pos += 1;
        HouseString := CopyStr(HouseString, Pos);
    end;

    local procedure RevertString(var String: Text[100])
    var
        StringCopy: Text[100];
        i: Integer;
        Length: Integer;
    begin
        StringCopy := String;
        Length := StrLen(String);
        for i := 1 to Length do
            String[i] := StringCopy[Length - i + 1];
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindStreetNameFromAddress(var Address: Text[100]; var Address2: Text[50]; var PostCode: Code[20]; var City: Text[50]; var CountryCode: Code[10]; var PhoneNo: Text[30]; var FaxNo: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindStreetNameFromAddress(var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Alternative Address", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure AlternativeAddressOnBeforeValidateAddress(var Rec: Record "Alternative Address")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure BankAccountOnBeforeValidateAddress(var Rec: Record "Bank Account")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeValidateEvent', 'Account Holder Address', false, false)]
    local procedure BankAccountOnBeforeValidateAccHolderAddress(var Rec: Record "Bank Account")
    var
        AcctHolderAddress2: Text[50];
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Account Holder Address", AcctHolderAddress2, Rec."Account Holder Post Code", Rec."Account Holder City",
            Rec."Acc. Hold. Country/Region Code", PhoneNo, FaxNo);
    end;


    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure CompanyInformationOnBeforeValidateAddress(var Rec: Record "Company Information")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateEvent', 'Ship-To Address', false, false)]
    local procedure CompanyInformationOnBeforeValidateShipToAddress(var Rec: Record "Company Information")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to Post Code", Rec."Ship-to City",
            Rec."Ship-to Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ContactOnBeforeValidateAddress(var Rec: Record "Contact")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Alt. Address", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ContactAltAddressOnBeforeValidateAddress(var Rec: Record "Contact Alt. Address")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure CustomerOnBeforeValidateAddress(var Rec: Record Customer)
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure CustomerBankAccountOnBeforeValidateAddress(var Rec: Record "Customer Bank Account")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnBeforeValidateEvent', 'Account Holder Address', false, false)]
    local procedure CustomerBankAccountOnBeforeValidateAccHolderAddress(var Rec: Record "Customer Bank Account")
    var
        AcctHolderAddress2: Text[50];
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Account Holder Address", AcctHolderAddress2, Rec."Account Holder Post Code", Rec."Account Holder City",
            Rec."Acc. Hold. Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure EmployeeOnBeforeValidateAddress(var Rec: Record Employee)
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure FinanceChargeMemoHeaderOnBeforeValidateAddress(var Rec: Record "Finance Charge Memo Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure LocationOnBeforeValidateAddress(var Rec: Record Location)
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure MachineCenterOnBeforeValidateAddress(var Rec: Record "Machine Center")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Address", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure OrderAddressOnBeforeValidateAddress(var Rec: Record "Order Address")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Pay-To Address', false, false)]
    local procedure PurchaseHeaderOnAfterValidatePayToAddress(var Rec: Record "Purchase Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Pay-to Address", Rec."Pay-to Address 2", Rec."Pay-to Post Code", Rec."Pay-to City",
            Rec."Pay-to Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateEvent', 'Ship-To Address', false, false)]
    local procedure PurchaseHeaderOnBeforeValidateShipToAddress(var Rec: Record "Purchase Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to Post Code", Rec."Ship-to City",
            Rec."Ship-to Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateEvent', 'Buy-From Address', false, false)]
    local procedure PurchaseHeaderOnBeforeValidateBuyFromAddress(var Rec: Record "Purchase Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Buy-from Address", Rec."Buy-from Address 2", Rec."Buy-from Post Code", Rec."Buy-from City",
            Rec."Buy-from Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ReminderHeaderOnBeforeValidateAddress(var Rec: Record "Reminder Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Resource", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ResourceOnBeforeValidateAddress(var Rec: Record "Resource")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Responsibility Center", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ResponsibilityCenterOnBeforeValidateAddress(var Rec: Record "Responsibility Center")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Bill-to Address', false, false)]
    local procedure SalesHeaderOnAfterValidateBillToAddress(var Rec: Record "Sales Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Bill-to Address", Rec."Bill-to Address 2", Rec."Bill-to Post Code", Rec."Bill-to City",
            Rec."Bill-to Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Ship-to Address', false, false)]
    local procedure SalesHeaderOnAfterValidateShipToAddress(var Rec: Record "Sales Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to Post Code", Rec."Ship-to City",
            Rec."Ship-to Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Sell-to Address', false, false)]
    local procedure SalesHeaderOnAfterValidateSellToAddress(var Rec: Record "Sales Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Sell-to Address", Rec."Sell-to Address 2", Rec."Sell-to Post Code", Rec."Sell-to City",
            Rec."Sell-to Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ShipToAddressOnBeforeValidateAddress(var Rec: Record "Ship-to Address")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateEvent', 'Transfer-from Address', false, false)]
    local procedure TransferHeaderOnBeforeValidateTransferFromAddress(var Rec: Record "Transfer Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Transfer-from Address", Rec."Transfer-from Address 2", Rec."Transfer-from Post Code",
            Rec."Transfer-from City", Rec."Trsf.-from Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateEvent', 'Transfer-to Address', false, false)]
    local procedure TransferHeaderOnBeforeValidateTransferToAddress(var Rec: Record "Transfer Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Transfer-to Address", Rec."Transfer-to Address 2", Rec."Transfer-to Post Code", Rec."Transfer-to City",
            Rec."Trsf.-to Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::Union, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure UnionOnBeforeValidateAddress(var Rec: Record Union)
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure VendorOnBeforeValidateAddress(var Rec: Record Vendor)
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure VendorBankAccountOnBeforeValidateAddress(var Rec: Record "Vendor Bank Account")
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnBeforeValidateEvent', 'Account Holder Address', false, false)]
    local procedure VendorBankAccountOnBeforeValidateAccHolderAddress(var Rec: Record "Vendor Bank Account")
    var
        AcctHolderAddress2: Text[50];
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec."Account Holder Address", AcctHolderAddress2, Rec."Account Holder Post Code", Rec."Account Holder City",
            Rec."Acc. Hold. Country/Region Code", PhoneNo, FaxNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure WorkCenterOnBeforeValidateAddress(var Rec: Record "Work Center")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", PhoneNo, FaxNo);
    end;
}
#pragma warning restore AA0217

