// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 6702 "O365 Contact Sync. Helper"
{
    trigger OnRun()
    begin
    end;

    var
        O365SyncManagement: Codeunit "O365 Sync. Management";
        CountryRegionNotFoundErr: Label 'The Exchange Country/Region cannot be found in your company.';
        CreateExchangeContactTxt: Label 'Create exchange contact.';
        CreateExchangeContactFailedTxt: Label 'Failed to create the new exchange contact.';
        CreateNavContactTxt: Label 'Create contact. - %1', Comment = '%1 = The contact';
        FieldParseFailedTxt: Label 'Could not parse the field %1 for the Exchange contact', Locked = true;
        UniqueCompanyNameErr: Label 'The Exchange Company Name is not unique in your company.';
        LocalCountTelemetryTxt: Label 'Synchronizing %1 contacts to Exchange.', Locked = true;
        ExchangeCountTelemetryTxt: Label '%1 Exchange contacts remaining for synchronization.', Locked = true;
        FoundNavContactForExchangeContactTxt: Label 'Found a NAV contact for Exchange contact: %1', Locked = true;
        CouldNotCreateExchangeContactErr: Label 'Could not create an Exchange contact. The Activity Log table may contain more information.', Locked = true;
        ContactExistsWithDifferentEmailErr: Label 'Another contact exists in Exchange with the same email.', Locked = true;
        ModifiedExchangeContactTxt: Label 'Modified the Exchange contact', Locked = true;
        ModifiedExchangeContactFailedTxt: Label 'Failed to update the existing Exchange contact.', Locked = true;
        ExchangeContactNoMailTxt: Label 'The Exchange contact number %1 does not have any email address', Locked = true;
        ExchangeContactMalformedMailTxt: Label 'The Exchange contact number %1 may have a malformed email address', Locked = true;
        MultipleMatchTxt: Label 'There are duplicate Exchange contacts with the same email as a NAV contact', Locked = true;

    procedure GetO365Contacts(ExchangeSync: Record "Exchange Sync"; var TempContact: Record Contact temporary)
    var
        ExchangeContact: Record "Exchange Contact";
        Counter: Integer;
        RecordsFound: Boolean;
        Success: Boolean;
    begin
        TempContact.Reset();
        TempContact.DeleteAll();

        ExchangeContact.SetFilter(EMailAddress1, '<>%1', '');
        if TryFindContacts(ExchangeContact, RecordsFound, Success) and RecordsFound then
            repeat
                Counter := Counter + 1;
                Clear(TempContact);
                TempContact.Init();
                TempContact."No." := StrSubstNo('%1', Counter);
                TempContact.Type := TempContact.Type::Person;

                TransferExchangeContactToNavContactNoValidate(ExchangeSync, ExchangeContact, TempContact);
                TempContact.Insert(); // Do not run the trigger so we preserve the dates.

            until (ExchangeContact.Next() = 0)
        else
            if not Success then
                Error(GetLastErrorText);

        Clear(ExchangeContact);
    end;

    [TryFunction]
    local procedure TryFindContacts(var ExchangeContact: Record "Exchange Contact"; var RecordsFound: Boolean; var Success: Boolean)
    begin
        RecordsFound := ExchangeContact.FindSet();
        Success := true;
    end;

    procedure TransferExchangeContactToNavContact(var ExchangeContact: Record Contact; var NavContact: Record Contact; ExchangeSync: Record "Exchange Sync")
    begin
        NavContact.Type := NavContact.Type::Person;

        // Map the ExchangeContact.CompanyName to NavContact.CompanyNo if possible
        if ExchangeContact."Company Name" <> '' then
            if IsCompanyNameUnique(ExchangeContact."Company Name") then begin
                ValidateCompanyName(NavContact, ExchangeContact."Company Name");
                NavContact.Modify();
            end else
                LogFailure(ExchangeSync, NavContact.FieldCaption("Company Name"), ExchangeContact."E-Mail");

        TransferContactNameInfo(ExchangeContact, NavContact, ExchangeSync);

        TransferCommonContactInfo(ExchangeContact, NavContact, ExchangeSync);
    end;

    procedure TransferBookingContactToNavContact(var ExchangeContact: Record Contact; var NavContact: Record Contact)
    var
        ExchangeSync: Record "Exchange Sync";
    begin
        ExchangeSync.Get(UserId);

        TransferContactNameInfo(ExchangeContact, NavContact, ExchangeSync);
        TransferCommonContactInfo(ExchangeContact, NavContact, ExchangeSync);
    end;

    procedure ProcessNavContactRecordSet(var Contact: Record Contact; var TempContact: Record Contact temporary; var ExchangeSync: Record "Exchange Sync")
    var
        ExchangeContact: Record "Exchange Contact";
        LocalExchangeContact: Record "Exchange Contact";
        IsExchangeContact: Boolean;
    begin
        if Contact.FindSet() then begin
            Session.LogMessage('0000ACO', StrSubstNo(LocalCountTelemetryTxt, Contact.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

            repeat
                IsExchangeContact := false;
                TempContact.Reset();
                TempContact.SetRange("Search E-Mail", UpperCase(Contact."E-Mail"));
                if TempContact.FindSet() then begin
                    IsExchangeContact := true;
                    TempContact.Delete();
                    if TempContact.Next() > 0 then
                        Session.LogMessage('0000GOC', MultipleMatchTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                end;

                Session.LogMessage('0000GOD', StrSubstNo(FoundNavContactForExchangeContactTxt, IsExchangeContact), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

                Clear(ExchangeContact);
                ExchangeContact.Init();

                if not TransferNavContactToExchangeContact(Contact, ExchangeContact) then begin
                    Session.LogMessage('0000GOE', CouldNotCreateExchangeContactErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                    O365SyncManagement.LogActivityFailed(ExchangeSync.RecordId, ExchangeSync."User ID",
                      CreateExchangeContactTxt, ExchangeContact.EMailAddress1)
                end else
                    if IsExchangeContact then begin
                        if ExchangeContact.Modify() then // update the contact in Exchange
                            Session.LogMessage('0000GOF', ModifiedExchangeContactTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory())
                        else begin
                            Session.LogMessage('0000I2D', ModifiedExchangeContactFailedTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                            O365SyncManagement.LogActivityFailed(ExchangeSync.RecordId, ExchangeSync."User ID", ModifiedExchangeContactFailedTxt, ExchangeContact.EMailAddress1);
                        end;
                    end else begin
                        Clear(LocalExchangeContact);
                        LocalExchangeContact.Init();
                        LocalExchangeContact.SetFilter(EMailAddress1, '=%1', Contact."E-Mail");
                        if LocalExchangeContact.FindFirst() then begin
                            Session.LogMessage('0000GOG', ContactExistsWithDifferentEmailErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                            O365SyncManagement.LogActivityFailed(ExchangeSync.RecordId, ExchangeSync."User ID",
                              CreateExchangeContactTxt, ExchangeContact.EMailAddress1)
                        end else
                            if ExchangeContact.Insert() then // create the contact in Exchange
                                Session.LogMessage('0000GOH', CreateExchangeContactTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory())
                            else begin
                                Session.LogMessage('0000I2E', CreateExchangeContactFailedTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                                O365SyncManagement.LogActivityFailed(ExchangeSync.RecordId, ExchangeSync."User ID", CreateExchangeContactFailedTxt, ExchangeContact.EMailAddress1);
                            end;
                    end;

            until Contact.Next() = 0;

            Session.LogMessage('0000GOI', StrSubstNo(ExchangeCountTelemetryTxt, TempContact.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
        end;
    end;

    local procedure TransferExchangeContactToNavContactNoValidate(ExchangeSync: Record "Exchange Sync"; var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    var
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        MailManagement: Codeunit "Mail Management";
        ExchContDateTimeUtc: DateTime;
    begin
        if ExchangeContact.EMailAddress1 = '' then
            Session.LogMessage('0000GOJ', StrSubstNo(ExchangeContactNoMailTxt, NavContact."No."), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory())
        else
            if not MailManagement.CheckValidEmailAddress(ExchangeContact.EMailAddress1) then
                Session.LogMessage('0000GOK', StrSubstNo(ExchangeContactMalformedMailTxt, NavContact."No."), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

        if not SetFirstName(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("First Name"), ExchangeContact.EMailAddress1);

        if not SetMiddleName(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Middle Name"), ExchangeContact.EMailAddress1);

        if not SetSurName(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(Surname), ExchangeContact.EMailAddress1);

        if not SetInitials(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(Initials), ExchangeContact.EMailAddress1);

        if not SetPostCode(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Post Code"), ExchangeContact.EMailAddress1);

        if not SetEmail(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("E-Mail"), ExchangeContact.EMailAddress1);

        if not SetEmail2(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("E-Mail 2"), ExchangeContact.EMailAddress1);

        if not SetCompanyName(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Company Name"), ExchangeContact.EMailAddress1);

        if not SetHomePage(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Home Page"), ExchangeContact.EMailAddress1);

        if not SetPhoneNo(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Phone No."), ExchangeContact.EMailAddress1);

        if not SetMobilePhoneNo(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Mobile Phone No."), ExchangeContact.EMailAddress1);

        if not SetFaxNo(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Fax No."), ExchangeContact.EMailAddress1);

        if not SetCity(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(City), ExchangeContact.EMailAddress1);

        if not SetCounty(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(County), ExchangeContact.EMailAddress1);

        if not SetNavContactAddresses(NavContact, ExchangeContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(Address), ExchangeContact.EMailAddress1);

        ExchContDateTimeUtc := DotNet_DateTimeOffset.ConvertToUtcDateTime(ExchangeContact.LastModifiedTime);
        NavContact."Last Date Modified" := DT2Date(ExchContDateTimeUtc);
        NavContact."Last Time Modified" := DT2Time(ExchContDateTimeUtc);

        // NOTE, we are using "Name 2" as the datatype is large enough to accomodate Exchange data type.
        if not SetRegion(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Country/Region Code"), ExchangeContact.EMailAddress1);

        if not SetJobTitle(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Job Title"), ExchangeContact.EMailAddress1);
    end;

    [TryFunction]
    procedure TransferNavContactToExchangeContact(var NavContact: Record Contact; var ExchangeContact: Record "Exchange Contact")
    begin
        ExchangeContact.Validate(EMailAddress1, NavContact."E-Mail");
        if NavContact.Type = NavContact.Type::Person then
            ExchangeContact.Validate(GivenName, NavContact."First Name");
        if NavContact.Type = NavContact.Type::Company then
            ExchangeContact.Validate(GivenName, CopyStr(NavContact."Company Name", 1, 30));
        ExchangeContact.Validate(MiddleName, NavContact."Middle Name");
        ExchangeContact.Validate(Surname, NavContact.Surname);
        ExchangeContact.Validate(Initials, NavContact.Initials);
        ExchangeContact.Validate(PostalCode, NavContact."Post Code");
        ExchangeContact.Validate(EMailAddress2, NavContact."E-Mail 2");
        ExchangeContact.Validate(CompanyName, NavContact."Company Name");
        ExchangeContact.Validate(BusinessHomePage, NavContact."Home Page");
        ExchangeContact.Validate(BusinessPhone1, NavContact."Phone No.");
        ExchangeContact.Validate(MobilePhone, NavContact."Mobile Phone No.");
        ExchangeContact.Validate(BusinessFax, NavContact."Fax No.");
        ValidateExchangeContactAddress(ExchangeContact, NavContact);
        ExchangeContact.Validate(City, NavContact.City);
        ExchangeContact.Validate(State, NavContact.County);
        ExchangeContact.Validate(Region, NavContact."Country/Region Code");
        ExchangeContact.Validate(JobTitle, NavContact."Job Title");
    end;

    [TryFunction]
    local procedure SetNavContactAddresses(var NavContact: Record Contact; var ExchangeContact: Record "Exchange Contact")
    var
        LineFeed: Char;
        LocalStreet: Text;
        LineFeedPos: Integer;
        CarriageReturn: Char;
        CarriageReturnPos: Integer;
    begin
        // Split ExchangeContact.Street into NavContact.Address and Address2.
        LineFeed := 10;
        CarriageReturn := 13;
        LocalStreet := ExchangeContact.Street;
        LineFeedPos := StrPos(LocalStreet, Format(LineFeed));
        CarriageReturnPos := StrPos(LocalStreet, Format(CarriageReturn));
        if LineFeedPos > 0 then begin
            if CarriageReturnPos = 0 then
                // Exchange has a bug when editing from OWA where the Carriage Return is ommitted.
                NavContact.Address := CopyStr(LocalStreet, 1, LineFeedPos - 1)
            else
                NavContact.Address := CopyStr(LocalStreet, 1, LineFeedPos - 2);
            LocalStreet := CopyStr(LocalStreet, LineFeedPos + 1);
            LineFeedPos := StrPos(LocalStreet, Format(LineFeed));
            CarriageReturnPos := StrPos(LocalStreet, Format(CarriageReturn));
            if LineFeedPos > 0 then begin
                if CarriageReturnPos = 0 then
                    LocalStreet := CopyStr(LocalStreet, 1, LineFeedPos - 1)
                else
                    LocalStreet := CopyStr(LocalStreet, 1, LineFeedPos - 2);
                NavContact."Address 2" := CopyStr(LocalStreet, 1, StrLen(LocalStreet));
            end else
                NavContact."Address 2" := CopyStr(LocalStreet, 1, StrLen(LocalStreet));
        end else
            NavContact.Address := CopyStr(LocalStreet, 1, 50);
    end;

    [TryFunction]
    local procedure SetFirstName(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."First Name" := ExchangeContact.GivenName;
    end;

    [TryFunction]
    local procedure SetMiddleName(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Middle Name" := ExchangeContact.MiddleName;
    end;

    [TryFunction]
    local procedure SetSurName(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact.Surname := ExchangeContact.Surname;
    end;

    [TryFunction]
    local procedure SetInitials(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact.Initials := ExchangeContact.Initials;
    end;

    [TryFunction]
    local procedure SetPostCode(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Post Code" := ExchangeContact.PostalCode;
    end;

    [TryFunction]
    local procedure SetEmail(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."E-Mail" := ExchangeContact.EMailAddress1;
    end;

    [TryFunction]
    local procedure SetEmail2(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."E-Mail 2" := ExchangeContact.EMailAddress2;
    end;

    [TryFunction]
    local procedure SetCompanyName(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Company Name" := ExchangeContact.CompanyName;
    end;

    [TryFunction]
    local procedure SetHomePage(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Home Page" := ExchangeContact.BusinessHomePage;
    end;

    [TryFunction]
    local procedure SetPhoneNo(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Phone No." := ExchangeContact.BusinessPhone1;
    end;

    [TryFunction]
    local procedure SetMobilePhoneNo(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Mobile Phone No." := ExchangeContact.MobilePhone;
    end;

    [TryFunction]
    local procedure SetFaxNo(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Fax No." := ExchangeContact.BusinessFax;
    end;

    [TryFunction]
    local procedure SetCity(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact.City := ExchangeContact.City;
    end;

    [TryFunction]
    local procedure SetCounty(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact.County := ExchangeContact.State;
    end;

    [TryFunction]
    local procedure SetRegion(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Name 2" := ExchangeContact.Region;
    end;

    [TryFunction]
    local procedure SetJobTitle(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    begin
        NavContact."Job Title" := ExchangeContact.JobTitle;
    end;

    [TryFunction]
    local procedure IsCompanyNameUnique(ExchangeContactCompanyName: Text[100])
    var
        LocalContact: Record Contact;
    begin
        LocalContact.SetRange("Company Name", ExchangeContactCompanyName);
        LocalContact.SetRange(Type, LocalContact.Type::Company);
        if LocalContact.Count <> 1 then
            Error(UniqueCompanyNameErr);
    end;

    local procedure ValidateCompanyName(var NavContact: Record Contact; ExchangeContactCompanyName: Text[100])
    var
        LocalContact: Record Contact;
    begin
        LocalContact.SetRange("Company Name", ExchangeContactCompanyName);
        LocalContact.SetRange(Type, LocalContact.Type::Company);
        if LocalContact.FindFirst() then
            if LocalContact."Company Name" <> NavContact."Company Name" then
                NavContact.Validate("Company No.", LocalContact."No.");
    end;

    [TryFunction]
    local procedure ValidateCountryRegion(ExchangeContact: Record Contact; var NavContact: Record Contact)
    var
        LocalCountryRegion: Record "Country/Region";
    begin
        // Map Exchange.Region to NavContact."Country/Region Code"
        // NOTE, we are using "Name 2" as the datatype is large enough to accomodate Exchange data type.
        if ExchangeContact."Name 2" <> '' then
            if StrLen(ExchangeContact."Name 2") <= 10 then
                if LocalCountryRegion.Get(ExchangeContact."Name 2") then
                    NavContact.Validate("Country/Region Code", CopyStr(ExchangeContact."Name 2", 1, 10))
                else
                    ValidateCountryRegionByName(ExchangeContact."Name 2", NavContact)
            else
                ValidateCountryRegionByName(ExchangeContact."Name 2", NavContact);
    end;

    local procedure ValidateCountryRegionByName(Country: Text[50]; var NavContact: Record Contact)
    var
        LocalCountryRegion: Record "Country/Region";
    begin
        LocalCountryRegion.SetRange(Name, Country);
        if LocalCountryRegion.FindFirst() then
            NavContact.Validate("Country/Region Code", LocalCountryRegion.Code)
        else
            Error(CountryRegionNotFoundErr);
    end;

    local procedure ValidateExchangeContactAddress(var ExchangeContact: Record "Exchange Contact"; var NavContact: Record Contact)
    var
        TypeHelper: Codeunit "Type Helper";
        LocalStreet: Text;
    begin
        // Concatenate NavContact.Address & Address2 into ExchangeContact.Street
        LocalStreet := NavContact.Address + TypeHelper.CRLFSeparator() + NavContact."Address 2" + TypeHelper.CRLFSeparator();
        ExchangeContact.Validate(Street, CopyStr(LocalStreet, 1, 104));
    end;

    local procedure ValidateFirstName(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("First Name"), ExchangeContact."First Name") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateMiddleName(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("Middle Name"), ExchangeContact."Middle Name") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateSurname(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo(Surname), ExchangeContact.Surname) then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateInitials(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo(Initials), ExchangeContact.Initials) then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateEmail(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("E-Mail"), ExchangeContact."E-Mail") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateEmail2(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("E-Mail 2"), ExchangeContact."E-Mail 2") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateHomePage(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("Home Page"), ExchangeContact."Home Page") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidatePhoneNo(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("Phone No."), ExchangeContact."Phone No.") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateMobilePhoneNo(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("Mobile Phone No."), ExchangeContact."Mobile Phone No.") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateFaxNo(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("Fax No."), ExchangeContact."Fax No.") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateAddress(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo(Address), ExchangeContact.Address) then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateAddress2(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("Address 2"), ExchangeContact."Address 2") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateCity(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo(City), ExchangeContact.City) then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidatePostCode(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("Post Code"), ExchangeContact."Post Code") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateCounty(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo(County), ExchangeContact.County) then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure ValidateJobTitle(ExchangeContact: Record Contact; var NavContact: Record Contact): Boolean
    var
        RecRef: RecordRef;
    begin
        NavContact.Get(NavContact."No.");
        RecRef.GetTable(NavContact);
        if TryValidateField(RecRef, NavContact.FieldNo("Job Title"), ExchangeContact."Job Title") then
            exit(RecRef.Modify());
        exit(false);
    end;

    local procedure TransferContactNameInfo(var ExchangeContact: Record Contact; var NavContact: Record Contact; ExchangeSync: Record "Exchange Sync")
    begin
        if not ValidateFirstName(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("First Name"), ExchangeContact."E-Mail");

        if not ValidateMiddleName(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Middle Name"), ExchangeContact."E-Mail");

        if not ValidateSurname(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(Surname), ExchangeContact."E-Mail");

        if not ValidateInitials(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(Initials), ExchangeContact."E-Mail");
    end;

    local procedure TransferCommonContactInfo(var ExchangeContact: Record Contact; var NavContact: Record Contact; ExchangeSync: Record "Exchange Sync")
    begin
        if not ValidateEmail(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("E-Mail"), ExchangeContact."E-Mail");

        if not ValidateEmail2(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("E-Mail 2"), ExchangeContact."E-Mail");

        if not ValidateHomePage(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Home Page"), ExchangeContact."E-Mail");

        if not ValidatePhoneNo(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Phone No."), ExchangeContact."E-Mail");

        if not ValidateMobilePhoneNo(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Mobile Phone No."), ExchangeContact."E-Mail");

        if not ValidateFaxNo(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Fax No."), ExchangeContact."E-Mail");

        if not ValidateAddress(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(Address), ExchangeContact."E-Mail");

        if not ValidateAddress2(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Address 2"), ExchangeContact."E-Mail");

        if not ValidateCity(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(City), ExchangeContact."E-Mail");

        if not ValidatePostCode(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Post Code"), ExchangeContact."E-Mail");

        if not ValidateCounty(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption(County), ExchangeContact."E-Mail");

        NavContact.Validate("Last Date Modified", ExchangeContact."Last Date Modified");
        NavContact.Validate("Last Time Modified", ExchangeContact."Last Time Modified");

        if not ValidateCountryRegion(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Country/Region Code"), ExchangeContact."E-Mail");

        if not ValidateJobTitle(ExchangeContact, NavContact) then
            LogFailure(ExchangeSync, NavContact.FieldCaption("Job Title"), ExchangeContact."E-Mail");
    end;

    local procedure LogFailure(ExchangeSync: Record "Exchange Sync"; FieldCaption: Text; Identifier: Text)
    var
        Message: Text;
    begin
        Message := StrSubstNo(CreateNavContactTxt, FieldCaption);
        O365SyncManagement.LogActivityFailed(ExchangeSync.RecordId, ExchangeSync."User ID", Message, Identifier);
        Session.LogMessage('0000GOL', StrSubstNo(FieldParseFailedTxt, FieldCaption), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
    end;

    local procedure TryValidateField(var RecRef: RecordRef; FieldNo: Integer; Value: Variant): Boolean
    var
        ConfigTryValidate: Codeunit "Config. Try Validate";
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        ConfigTryValidate.SetValidateParameters(FieldRef, Value);
        Commit();
        exit(ConfigTryValidate.Run());
    end;
}

