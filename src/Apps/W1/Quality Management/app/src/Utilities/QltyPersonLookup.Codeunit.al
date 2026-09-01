// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Provides utilities for looking up person/contact details from various person-related tables.
/// Supports Contact, Employee, Resource, User, User Setup, and Salesperson/Purchaser records.
/// </summary>
codeunit 20429 "Qlty. Person Lookup"
{
    Access = Internal;

    /// <summary>
    /// Extracts person contact details from an inspection line if it references a person-related record.
    /// Validates that the inspection line is a table lookup type referencing a supported person table before retrieval.
    /// 
    /// Supported person tables (validated via Field configuration):
    /// - Contact, Employee, Resource, User, User Setup, Salesperson/Purchaser
    /// 
    /// Returns false early if:
    /// - Test Value is empty
    /// - Field Type is not "Value Type Table Lookup"
    /// - Test Code is invalid
    /// - Lookup Table is not a person-related table
    /// 
    /// Common usage: Displaying inspector/approver details in test forms and reports.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line containing the person reference</param>
    /// <param name="FullName">Output: The person's full name</param>
    /// <param name="JobTitle">Output: The person's job title</param>
    /// <param name="EmailAddress">Output: The person's email address</param>
    /// <param name="PhoneNo">Output: The person's phone number</param>
    /// <param name="SourceRecordId">Output: RecordId of the source person record</param>
    /// <returns>True if inspection line references a person and details were retrieved; False otherwise</returns>
    procedure GetBasicPersonDetailsFromInspectionLine(QltyInspectionLine: Record "Qlty. Inspection Line"; var FullName: Text; var JobTitle: Text; var EmailAddress: Text; var PhoneNo: Text; var SourceRecordId: RecordId): Boolean
    var
        QltyTest: Record "Qlty. Test";
    begin
        Clear(FullName);
        Clear(JobTitle);
        Clear(EmailAddress);
        Clear(PhoneNo);
        Clear(SourceRecordId);

        if QltyInspectionLine."Test Value" = '' then
            exit(false);

        if not (QltyInspectionLine."Test Value Type" in [QltyInspectionLine."Test Value Type"::"Value Type Table Lookup"]) then
            exit(false);

        if not QltyTest.Get(QltyInspectionLine."Test Code") then
            exit(false);

        if not (QltyTest."Lookup Table No." in [
            Database::Contact,
            Database::Employee,
            Database::Resource,
            Database::User,
            Database::"User Setup",
            Database::"Salesperson/Purchaser"])
        then
            exit(false);

        exit(GetBasicPersonDetails(
            QltyInspectionLine."Test Value",
            FullName,
            JobTitle,
            EmailAddress,
            PhoneNo,
            SourceRecordId));
    end;

    /// <summary>
    /// Retrieves basic contact information for a person from any supported person-related record type.
    /// Searches across multiple tables to find contact details by primary key.
    /// 
    /// Supported record types:
    /// - Contact
    /// - Employee
    /// - Resource
    /// - User
    /// - User Setup
    /// - Salesperson/Purchaser
    /// 
    /// Common usage: Displaying inspector/approver details in quality inspection reports and forms.
    /// </summary>
    /// <param name="Input">The primary key value to search for (e.g., User ID, Contact No., Employee No.)</param>
    /// <param name="FullName">Output: The person's full name</param>
    /// <param name="JobTitle">Output: The person's job title or position</param>
    /// <param name="EmailAddress">Output: The person's email address</param>
    /// <param name="PhoneNo">Output: The person's phone number</param>
    /// <param name="SourceRecordId">Output: RecordId of the source record where details were found</param>
    /// <returns>True if person details were found in any supported table; False otherwise</returns>
    procedure GetBasicPersonDetails(Input: Text; var FullName: Text; var JobTitle: Text; var EmailAddress: Text; var PhoneNo: Text; var SourceRecordId: RecordId) HasDetails: Boolean
    var
        Contact: Record Contact;
        Employee: Record Employee;
        User: Record User;
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        Clear(FullName);
        Clear(JobTitle);
        Clear(EmailAddress);
        Clear(PhoneNo);
        Clear(SourceRecordId);
        if Input = '' then
            exit(false);

        if Contact.ReadPermission() then
            if Contact.Get(CopyStr(Input, 1, MaxStrLen(Contact."No."))) then begin
                FullName := Contact.Name;
                JobTitle := Contact."Job Title";
                EmailAddress := Contact."E-Mail";
                PhoneNo := Contact."Phone No.";
                SourceRecordId := Contact.RecordId();
                exit(true);
            end;

        if Employee.ReadPermission() then
            if Employee.Get(CopyStr(Input, 1, MaxStrLen(Employee."No."))) then begin
                FullName := Employee.FullName();
                JobTitle := Employee."Job Title";
                EmailAddress := Employee."E-Mail";
                PhoneNo := Employee."Phone No.";
                SourceRecordId := Employee.RecordId();
                exit(true);
            end;

        if Resource.ReadPermission() then
            if Resource.Get(CopyStr(Input, 1, MaxStrLen(Resource."No."))) then
                if Resource.Type = Resource.Type::Person then begin
                    FullName := Resource.Name;
                    JobTitle := Resource."Job Title";
                    EmailAddress := '';
                    PhoneNo := '';
                    SourceRecordId := Resource.RecordId();
                    exit(true);
                end;

        if User.ReadPermission() then begin
            User.SetRange("User Name", CopyStr(Input, 1, MaxStrLen(User."User Name")));
            if User.FindFirst() then begin
                HasDetails := true;
                FullName := User."Full Name";
                JobTitle := '';
                EmailAddress := User."Contact Email";
                PhoneNo := '';
                SourceRecordId := User.RecordId();
                if UserSetup.ReadPermission() then begin
                    if UserSetup.Get(User."User Name") then begin
                        SourceRecordId := UserSetup.RecordId();
                        if UserSetup."E-Mail" <> '' then
                            EmailAddress := UserSetup."E-Mail";
                        if UserSetup."Phone No." <> '' then
                            PhoneNo := UserSetup."Phone No.";

                        if UserSetup."Salespers./Purch. Code" <> '' then
                            Input := UserSetup."Salespers./Purch. Code";
                    end else
                        exit(true);
                end else
                    exit(true);
            end;

            if SalespersonPurchaser.ReadPermission() then
                if SalespersonPurchaser.Get(CopyStr(Input, 1, MaxStrLen(SalespersonPurchaser.Code))) then begin
                    if SalespersonPurchaser.Name <> '' then
                        FullName := SalespersonPurchaser.Name;
                    if SalespersonPurchaser."Job Title" <> '' then
                        JobTitle := SalespersonPurchaser."Job Title";
                    if SalespersonPurchaser."E-Mail" <> '' then
                        EmailAddress := SalespersonPurchaser."E-Mail";

                    if SalespersonPurchaser."Phone No." <> '' then
                        PhoneNo := SalespersonPurchaser."Phone No.";
                    SourceRecordId := SalespersonPurchaser.RecordId();
                    exit(true);
                end;
        end;
    end;
}
