namespace System.Email;

using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using Microsoft.CRM.Contact;
using Microsoft.HumanResources.Employee;
using System.Security.AccessControl;
using System.Security.User;

codeunit 8899 "Email Address Lookup Subs"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Address Lookup", 'OnGetSuggestedAddresses', '', false, false)]
    local procedure SuggestedAddressesFromContacts(TableId: Integer; SystemId: Guid; var Address: Record "Email Address Lookup")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Employee: Record Employee;
        User: Record User;
        CompanyNo: Code[20];
    begin
        case TableId of
            Database::Customer:
                begin
                    if not Customer.GetBySystemId(SystemId) then
                        exit;
                    InsertAddressFromCustomer(Customer, Address);
                    if Contact.Get(Customer."Primary Contact No.") then
                        CompanyNo := Contact."Company No.";
                end;
            Database::Vendor:
                begin
                    if not Vendor.GetBySystemId(SystemId) then
                        exit;
                    InsertAddressFromVendor(Vendor, Address);
                    if Contact.Get(Vendor."Primary Contact No.") then
                        CompanyNo := Contact."Company No.";
                end;
            Database::Contact:
                begin
                    if Contact.GetBySystemId(SystemId) then
                        CompanyNo := Contact."Company No.";
                    if CompanyNo = '' then begin
                        InsertContactEmailAddress(Contact, Address);
                        exit;
                    end;
                end;
            Database::Employee:
                begin
                    if not Employee.GetBySystemId(SystemId) then
                        exit;
                    InsertAddressFromEmployee(Employee, Address);
                end;
            Database::User:
                begin
                    if not User.GetBySystemId(SystemId) then
                        exit;
                    InsertAddressFromUser(User, Address);
                end;
            else
                exit;

        end;
        InsertAddressFromContacts(CompanyNo, Address);
    end;

    local procedure InsertAddressFromCustomer(var Customer: Record Customer; var Address: Record "Email Address Lookup")
    begin
        if ((Customer."E-Mail" <> '') and not Address.Get(Customer."E-Mail", Customer.Name, Enum::"Email Address Entity"::Customer)) then begin
            Address.Name := Customer.Name;
            Address."E-Mail Address" := Customer."E-Mail";
            Address."Source Table Number" := Database::Customer;
            Address."Source System Id" := Customer.SystemId;
            Address."Entity type" := Enum::"Email Address Entity"::Customer;
            Address.Insert();
        end;
    end;

    local procedure InsertAddressFromVendor(var Vendor: Record Vendor; var Address: Record "Email Address Lookup")
    begin
        if ((Vendor."E-Mail" <> '') and not Address.Get(Vendor."E-Mail", Vendor.Name, Enum::"Email Address Entity"::Vendor)) then begin
            Address.Name := Vendor.Name;
            Address."E-Mail Address" := Vendor."E-Mail";
            Address."Source Table Number" := Database::Vendor;
            Address."Source System Id" := Vendor.SystemId;
            Address."Entity type" := Enum::"Email Address Entity"::Vendor;
            Address.Insert();
        end;
    end;

    local procedure InsertAddressFromEmployee(var Employee: Record Employee; var Address: Record "Email Address Lookup")
    begin
        if ((Employee."E-Mail" <> '') and not Address.Get(Employee."E-Mail", Employee.FullName(), Enum::"Email Address Entity"::Employee)) then begin
            Address.Name := Employee.FullName();
            Address."E-Mail Address" := Employee."E-Mail";
            Address."Source Table Number" := Database::Employee;
            Address."Source System Id" := Employee.SystemId;
            Address."Entity type" := Enum::"Email Address Entity"::Employee;
            Address.Insert();
        end;
    end;

    local procedure InsertAddressFromUser(var User: Record User; var Address: Record "Email Address Lookup")
    begin
        if ((User."Contact Email" <> '') and not Address.Get(User."Contact Email", User."Full Name", Enum::"Email Address Entity"::User)) then begin
            Address.Name := User."Full Name";
            Address."E-Mail Address" := User."Contact Email";
            Address."Source Table Number" := Database::User;
            Address."Source System Id" := User.SystemId;
            Address."Entity type" := Enum::"Email Address Entity"::User;
            Address.Insert();
        end;
    end;

    local procedure InsertAddressFromContacts(CompanyNo: Code[20]; var Address: Record "Email Address Lookup")
    var
        Contact: Record Contact;
    begin
        if CompanyNo = '' then
            exit;
        Contact.SetRange("Company No.", CompanyNo);
        if Contact.FindSet() then
            repeat
                InsertContactEmailAddress(Contact, Address);
            until Contact.Next() = 0;
    end;

    local procedure InsertContactEmailAddress(var Contact: Record Contact; var Address: Record "Email Address Lookup")
    begin
        if ((Contact."E-Mail" <> '') and not Address.Get(Contact."E-Mail", Contact.Name, Enum::"Email Address Entity"::Contact)) then begin
            Address.Name := Contact.Name;
            Address."E-Mail Address" := Contact."E-Mail";
            Address.Company := Contact."Company Name";
            Address."Source Table Number" := Database::Contact;
            Address."Source System Id" := Contact.SystemId;
            Address."Entity type" := Enum::"Email Address Entity"::Contact;

            // Contact No. is added on the table extension
            Address."Contact No." := Contact."No.";

            Address.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Address Lookup", 'OnLookupAddressFromEntity', '', false, false)]
    local procedure OnGetEmailFromContact(Entity: Enum "Email Address Entity"; var Address: Record "Email Address Lookup"; var IsHandled: Boolean)
    var
        Contact: Record Contact;
        ContactList: Page "Contact List";
    begin
        if not Contact.ReadPermission() or IsHandled or (Entity <> Entity::Contact) then
            exit;

        Contact.SetFilter("E-Mail", '<>%1', '');
        if not Contact.FindSet() then begin
            Message(StrSubstNo(NoRecordsFoundMsg, Contact.TableCaption()));
            exit;
        end;

        ContactList.SetTableView(Contact);
        ContactList.LookupMode := true;

        if ContactList.RunModal() <> ACTION::LookupOK then begin
            IsHandled := false;
            exit;
        end;

        ContactList.SetSelectionFilter(Contact);
        if Contact.FindSet() then
            repeat
                if StrLen(Contact."E-Mail") > 0 then begin
                    Address.Name := Contact.Name;
                    Address."E-Mail Address" := Contact."E-Mail";
                    Address.Company := Contact."Company Name";
                    Address."Source Table Number" := Database::Contact;
                    Address."Source System Id" := Contact.SystemId;
                    Address."Entity type" := Enum::"Email Address Entity"::Contact;

                    // Added contact number in table extension of email suggestions
                    Address."Contact No." := Contact."No.";

                    Address.Insert();
                    IsHandled := true;
                end;
            until Contact.Next() = 0;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Address Lookup", 'OnLookupAddressFromEntity', '', false, false)]
    local procedure OnGetEmailFromEmployee(Entity: Enum "Email Address Entity"; var Address: Record "Email Address Lookup"; var IsHandled: Boolean)
    var
        Employee: Record Employee;
        EmployeeList: Page "Employee List";
    begin
        if not Employee.ReadPermission() or IsHandled or (Entity <> Entity::Employee) then
            exit;

        Employee.SetFilter("E-Mail", '<>%1', '');
        if not Employee.FindSet() then begin
            Message(StrSubstNo(NoRecordsFoundMsg, Employee.TableCaption()));
            exit;
        end;

        EmployeeList.SetTableView(Employee);
        EmployeeList.LookupMode := true;

        if EmployeeList.RunModal() <> ACTION::LookupOK then begin
            IsHandled := false;
            exit;
        end;

        EmployeeList.SetSelectionFilter(Employee);
        if Employee.FindSet() then
            repeat
                if StrLen(Employee."E-Mail") > 0 then begin
                    Address.Name := Employee.FullName();
                    Address."E-Mail Address" := Employee."E-Mail";
                    Address.Company := CopyStr(Employee.CurrentCompany(), 1, 250);
                    Address."Source Table Number" := Database::Employee;
                    Address."Source System Id" := Employee.SystemId;
                    Address."Entity type" := Entity::Employee;
                    Address.Insert();
                end;
                IsHandled := true;
            until Employee.Next() = 0;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Address Lookup", 'OnLookupAddressFromEntity', '', false, false)]
    local procedure OnGetEmailFromCustomer(Entity: Enum "Email Address Entity"; var Address: Record "Email Address Lookup"; var IsHandled: Boolean)
    var
        Customer: Record Customer;
        CustomerList: Page "Customer List";
    begin
        if not Customer.ReadPermission() or IsHandled or (Entity <> Entity::Customer) then
            exit;

        Customer.SetFilter("E-Mail", '<>%1', '');
        if not Customer.FindSet() then begin
            Message(StrSubstNo(NoRecordsFoundMsg, Customer.TableCaption()));
            exit;
        end;
        CustomerList.SetTableView(Customer);
        CustomerList.LookupMode := true;

        if CustomerList.RunModal() <> ACTION::LookupOK then begin
            IsHandled := false;
            exit;
        end;

        CustomerList.SetSelectionFilter(Customer);
        if Customer.FindSet() then
            repeat
                if StrLen(Customer."E-Mail") > 0 then begin
                    Address.Name := Customer.Name;
                    Address."E-Mail Address" := Customer."E-Mail";
                    Address.Company := Customer.Name;
                    Address."Source Table Number" := Database::Customer;
                    Address."Source System Id" := Customer.SystemId;
                    Address."Entity type" := Entity::Customer;
                    Address.Insert();
                end;
                IsHandled := true;
            until Customer.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Address Lookup", 'OnLookupAddressFromEntity', '', false, false)]
    local procedure OnGetEmailFromVendor(Entity: Enum "Email Address Entity"; var Address: Record "Email Address Lookup"; var IsHandled: Boolean)
    var
        Vendor: Record Vendor;
        VendorList: Page "Vendor List";
    begin
        if not Vendor.ReadPermission() or IsHandled or (Entity <> Entity::Vendor) then
            exit;

        Vendor.SetFilter("E-Mail", '<>%1', '');
        if not Vendor.FindSet() then begin
            Message(StrSubstNo(NoRecordsFoundMsg, Vendor.TableCaption()));
            exit;
        end;
        VendorList.SetTableView(Vendor);
        VendorList.LookupMode := true;

        if VendorList.RunModal() <> ACTION::LookupOK then
            exit;

        VendorList.SetSelectionFilter(Vendor);
        if Vendor.FindSet() then
            repeat
                if StrLen(Vendor."E-Mail") > 0 then begin
                    Address.Name := Vendor.Name;
                    Address."E-Mail Address" := Vendor."E-Mail";
                    Address.Company := Vendor.Name;
                    Address."Source Table Number" := Database::Vendor;
                    Address."Source System Id" := Vendor.SystemId;
                    Address."Entity type" := Entity::Vendor;
                    Address.Insert();
                end;
                IsHandled := true;
            until Vendor.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Address Lookup", 'OnLookupAddressFromEntity', '', false, false)]
    local procedure OnGetEmailFromUser(Entity: Enum "Email Address Entity"; var Address: Record "Email Address Lookup"; var IsHandled: Boolean)
    var
        User: Record User;
        UserList: Page "Users";
    begin
        if not User.ReadPermission() or IsHandled or (Entity <> Entity::User) then
            exit;

        User.SetFilter("Contact Email", '<>%1', '');
        if not User.FindSet() then begin
            Message(StrSubstNo(NoRecordsFoundMsg, User.TableCaption()));
            exit;
        end;
        UserList.SetTableView(User);
        UserList.LookupMode := true;

        if UserList.RunModal() <> ACTION::LookupOK then
            exit;

        UserList.SetSelectionFilter(User);
        if User.FindSet() then
            repeat
                if StrLen(User."Contact Email") > 0 then begin
                    Address.Name := User."Full Name";
                    Address."E-Mail Address" := User."Contact Email";
                    Address.Company := '';
                    Address."Source Table Number" := Database::User;
                    Address."Source System Id" := User.SystemId;
                    Address."Entity type" := Entity::Vendor;
                    Address.Insert();
                end;
                IsHandled := true;
            until User.Next() = 0;
    end;

    var
        NoRecordsFoundMsg: Label 'No %1 found with an email address.', Comment = '%1 Entity type';
}
