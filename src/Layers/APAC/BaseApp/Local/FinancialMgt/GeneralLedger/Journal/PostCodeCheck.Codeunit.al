// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
#if not CLEAN28
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
#endif
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Reminder;

codeunit 28000 "Post Code Check"
{
    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Country: Record "Country/Region";
        HadGLSetup: Boolean;
        ContactName: Text[100];
        AddressValidationErr: Label '%1 must be Post Code & City in %2.', Comment = '%1 - Address Validation caption, %2 - table caption';
        ExternalComponentMsg: Label 'The external component is not installed.';

    procedure VerifyCity(CurrFieldNumber: Integer; TableNo: Integer; TableKey: Text; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[50]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var PostCode: Code[20]; var County: Text[30]; var CountryCode: Code[10])
    var
        PostCodeRec: Record "Post Code";
        RecCount: Integer;
    begin
        if (City = '') or (CurrFieldNumber = 0) or (not GuiAllowed) then
            exit;

        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Post Code & City":
                begin
                    PostCodeRec.Reset();
                    PostCodeRec.SetCurrentKey("Search City");
                    PostCodeRec.SetFilter("Search City", UpperCase(City));
                    PostCodeRec.FindFirst();
                    RecCount := PostCodeRec.Count();
                    case true of
                        RecCount = 1:
                            begin
                                PostCode := PostCodeRec.Code;
                                City := PostCodeRec.City;
                                County := PostCodeRec.County;
                                CountryCode := PostCodeRec."Country/Region Code";
                            end;
                        RecCount > 1:
                            if PAGE.RunModal(
                                    PAGE::"Post Codes", PostCodeRec, PostCodeRec.Code) = ACTION::LookupOK
                            then begin
                                PostCode := PostCodeRec.Code;
                                City := PostCodeRec.City;
                                County := PostCodeRec.County;
                                CountryCode := PostCodeRec."Country/Region Code";
                            end else
                                Error('');
                    end;
                end;
            Country."Address Validation"::"Entire Address",
            Country."Address Validation"::"Address ID":
                RunAddressValidation(
                    TableNo, TableKey, AddressType, 2,
                    Name, Name2, Contact, Address, Address2, City, PostCode, County, CountryCode);
        end;

        OnAfterVerifyCity(PostCodeRec, City, PostCode, County, CountryCode);
    end;

    procedure VerifyPostCode(CurrentFieldNo: Integer; TableNo: Integer; TableKey: Text; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[50]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var PostCode: Code[20]; var County: Text[30]; var CountryCode: Code[10])
    var
        PostCodeRec: Record "Post Code";
        RecCount: Integer;
    begin
        if (PostCode = '') or (CurrentFieldNo = 0) or (not GuiAllowed) then
            exit;

        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Post Code & City":
                begin
                    PostCodeRec.Reset();
                    PostCodeRec.SetFilter(Code, PostCode);
                    OnVerifyPostCodeOnAfterFilterPostCode(PostCodeRec, CountryCode);
                    PostCodeRec.FindFirst();
                    RecCount := PostCodeRec.Count();
                    case true of
                        RecCount = 1:
                            begin
                                PostCode := PostCodeRec.Code;
                                City := PostCodeRec.City;
                                County := PostCodeRec.County;
                                CountryCode := PostCodeRec."Country/Region Code";
                            end;
                        RecCount > 1:
                            if PAGE.RunModal(
                                    PAGE::"Post Codes", PostCodeRec, PostCodeRec.City) = ACTION::LookupOK
                            then begin
                                PostCode := PostCodeRec.Code;
                                City := PostCodeRec.City;
                                County := PostCodeRec.County;
                                CountryCode := PostCodeRec."Country/Region Code";
                            end else
                                Error('');
                    end;
                end;
            Country."Address Validation"::"Entire Address",
            Country."Address Validation"::"Address ID":
                RunAddressValidation(
                  TableNo, TableKey, AddressType, 2,
                  Name, Name2, Contact, Address, Address2, City, PostCode, County, CountryCode);
        end;

        OnAfterVerifyPostCode(PostCodeRec, City, PostCode, County, CountryCode);
    end;

    procedure LookUpCity(CurrFieldNumber: Integer; TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[90]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; ReturnValues: Boolean)
    var
        PostCodeRec: Record "Post Code";
        TempName2: Text[50];
        TempCity, TempCounty : Text[30];
    begin
        if not GuiAllowed then
            exit;

        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Post Code & City":
                begin
                    PostCodeRec.Reset();
                    PostCodeRec.SetCurrentKey("Search City");
                    PostCodeRec."Search City" := UpperCase(TempCity);
                    if (PAGE.RunModal(
                          PAGE::"Post Codes", PostCodeRec, PostCodeRec.City) = ACTION::LookupOK) and ReturnValues
                    then begin
                        PostCode := PostCodeRec.Code;
                        City := PostCodeRec.City;
                        County := PostCodeRec.County;
                        CountryCode := PostCodeRec."Country/Region Code";
                    end;
                end;
            Country."Address Validation"::"Entire Address",
            Country."Address Validation"::"Address ID":
                begin
                    TempName2 := CopyStr(Name2, 1, 50);
                    TempCity := CopyStr(City, 1, 30);
                    TempCounty := CopyStr(County, 1, 30);
                    RunAddressValidation(
                        TableNo, TableKey, AddressType, 1,
                        Name, TempName2, Contact, Address, Address2, TempCity, PostCode, TempCounty, CountryCode);
                    City := CopyStr(TempCity, 1, 30);
                    County := CopyStr(TempCounty, 1, 30);
                    Name2 := CopyStr(TempName2, 1, 50);
                end;
        end;
    end;

    procedure LookUpPostCode(CurrFieldNumber: Integer; TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[90]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; ReturnValues: Boolean)
    var
        PostCodeRec: Record "Post Code";
        TempName2: Text[50];
        TempCity, TempCounty : Text[30];
    begin
        if not GuiAllowed then
            exit;

        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Post Code & City":
                begin
                    PostCodeRec.Reset();
                    PostCodeRec.Code := PostCode;
                    if (PAGE.RunModal(
                          PAGE::"Post Codes", PostCodeRec, PostCodeRec.Code) = ACTION::LookupOK) and ReturnValues
                    then begin
                        PostCode := PostCodeRec.Code;
                        City := PostCodeRec.City;
                        County := PostCodeRec.County;
                        CountryCode := PostCodeRec."Country/Region Code";
                    end;
                end;
            Country."Address Validation"::"Entire Address",
            Country."Address Validation"::"Address ID":
                begin
                    TempName2 := CopyStr(Name2, 1, 50);
                    TempCity := CopyStr(City, 1, 30);
                    TempCounty := CopyStr(County, 1, 30);
                    RunAddressValidation(
                        TableNo, TableKey, AddressType, 1,
                        Name, TempName2, Contact, Address, Address2, TempCity, PostCode, TempCounty, CountryCode);
                    City := CopyStr(TempCity, 1, 30);
                    County := CopyStr(TempCounty, 1, 30);
                    Name2 := CopyStr(TempName2, 1, 50);
                end;
        end;
    end;

    procedure VerifyAddress(CurrentFieldNo: Integer; TableNo: Integer; TableKey: Text; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[50]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var PostCode: Code[20]; var County: Text[30]; var CountryCode: Code[10])
    begin
        if (PostCode = '') or (City = '') or (CurrentFieldNo = 0) or (not GuiAllowed) then
            exit;

        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Entire Address",
            Country."Address Validation"::"Address ID":
                RunAddressValidation(
                  TableNo, TableKey, AddressType, 3,
                  Name, Name2, Contact, Address, Address2, City, PostCode, County, CountryCode);
        end;
    end;

    local procedure RunAddressValidation(TableNo: Integer; TableKey: Text; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; ValidationType: Option " ","GUI Only","GUI Optional","No GUI"; var Name: Text[100]; var Name2: Text[50]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var PostCode: Code[20]; var County: Text[30]; var CountryCode: Code[10])
    var
        AddressID: Record "Address ID";
        TempAddressBuffer: Record "Address Buffer" temporary;
        TableKey2: Text[200];
    begin
        TableKey2 := CopyStr(TableKey, 1, 200);

        Country.TestField("AMAS Software");
        TempAddressBuffer.Init();
        TempAddressBuffer.Name := Name;
        TempAddressBuffer."Name 2" := Name2;
        TempAddressBuffer.Contact := Contact;
        TempAddressBuffer.Address := Address;
        TempAddressBuffer."Address 2" := Address2;
        TempAddressBuffer.City := City;
        TempAddressBuffer."Post Code" := PostCode;
        TempAddressBuffer.County := County;
        TempAddressBuffer."Country/Region Code" := CountryCode;
        TempAddressBuffer."Validation Type" := ValidationType;
        TempAddressBuffer.Insert();
        CODEUNIT.Run(Country."AMAS Software", TempAddressBuffer);
        if (TempAddressBuffer."Address ID" <> '') or
           (TempAddressBuffer."Bar Code" <> '') or
           (TempAddressBuffer."Error Flag No." <> '')
        then
            if not AddressID.Get(TableNo, TableKey2, AddressType) then begin
                AddressID.Init();
                AddressID."Table No." := TableNo;
                AddressID."Table Key" := TableKey2;
                AddressID."Address Type" := AddressType;
                AddressID.Validate("Address ID", TempAddressBuffer."Address ID");
                AddressID."Address Sort Plan" := TempAddressBuffer."Address Sort Plan";
                AddressID."Error Flag No." := TempAddressBuffer."Error Flag No.";
                AddressID."Bar Code System" := TempAddressBuffer."Bar Code System";
                AddressID.Insert();
            end else begin
                AddressID.Validate("Address ID", TempAddressBuffer."Address ID");
                AddressID."Address Sort Plan" := TempAddressBuffer."Address Sort Plan";
                AddressID."Error Flag No." := TempAddressBuffer."Error Flag No.";
                AddressID."Bar Code System" := TempAddressBuffer."Bar Code System";
                AddressID.Modify();
            end;

        if Country."Address Validation" =
           Country."Address Validation"::"Entire Address"
        then begin
            Name := TempAddressBuffer.Name;
            Name2 := CopyStr(TempAddressBuffer."Name 2", 1, 50);
            Contact := TempAddressBuffer.Contact;
            Address := TempAddressBuffer.Address;
            Address2 := CopyStr(TempAddressBuffer."Address 2", 1, 50);
            City := CopyStr(TempAddressBuffer.City, 1, 30);
            PostCode := CopyStr(TempAddressBuffer."Post Code", 1, 20);
            County := CopyStr(TempAddressBuffer.County, 1, 30);
            CountryCode := CopyStr(TempAddressBuffer."Country/Region Code", 1, 10);
        end;
    end;

    procedure DeleteAddressIDRecords(TableNo: Integer; TableKey: Text; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to")
    var
        AddressID: Record "Address ID";
    begin
        AddressID.SetRange("Table No.", TableNo);
        AddressID.SetRange("Table Key", TableKey);
        AddressID.SetRange("Address Type", AddressType);
        AddressID.DeleteAll();
    end;

    local procedure DeleteAllAddressIDRecords(TableNo: Integer; TableKey: Text)
    var
        AddressID: Record "Address ID";
    begin
        AddressID.SetRange("Table No.", TableNo);
        AddressID.SetRange("Table Key", TableKey);
        AddressID.DeleteAll();
    end;

    procedure CopyAddressIDRecord(FromTableNo: Integer; FromTableKey: Text; FromAddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; ToTableNo: Integer; ToTableKey: Text; ToAddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to")
    var
        FromAddressID: Record "Address ID";
        ToAddressID: Record "Address ID";
        FromTableKey2: Text[200];
        ToTableKey2: Text[200];
    begin
        FromTableKey2 := CopyStr(FromTableKey, 1, 200);
        ToTableKey2 := CopyStr(ToTableKey, 1, 200);
        if FromAddressID.Get(FromTableNo, FromTableKey2, FromAddressType) then begin
            if not ToAddressID.Get(ToTableNo, ToTableKey2, ToAddressType) then begin
                ToAddressID.Init();
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := ToTableKey2;
                ToAddressID."Address Type" := ToAddressType;
                ToAddressID.Insert();
            end else begin
                ToAddressID."Address ID" := FromAddressID."Address ID";
                ToAddressID."Address Sort Plan" := FromAddressID."Address Sort Plan";
                ToAddressID."Bar Code" := FromAddressID."Bar Code";
                ToAddressID."Bar Code System" := FromAddressID."Bar Code System";
                ToAddressID."Error Flag No." := FromAddressID."Error Flag No.";
                ToAddressID."Address ID Check Date" := FromAddressID."Address ID Check Date";
                ToAddressID.Modify();
            end;
        end else
            if ToAddressID.Get(ToTableNo, ToTableKey2, ToAddressType) then
                ToAddressID.Delete();
    end;

    local procedure CopyAddressIDRecords(FromTableNo: Integer; FromTableKey: Text; ToTableNo: Integer; ToTableKey: Text)
    var
        FromAddressID: Record "Address ID";
        ToAddressID: Record "Address ID";
    begin
        FromAddressID.SetRange("Table No.", FromTableNo);
        FromAddressID.SetRange("Table Key", FromTableKey);
        ToAddressID.SetRange("Table No.", ToTableNo);
        ToAddressID.SetRange("Table Key", ToTableKey);
        ToAddressID.DeleteAll();
        if FromAddressID.Find('-') then
            repeat
                ToAddressID.Init();
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := CopyStr(ToTableKey, 1, 200);
                ToAddressID.Insert();
            until FromAddressID.Next() = 0;
    end;

    local procedure MoveAddressIDRecord(FromTableNo: Integer; FromTableKey: Text; FromAddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; ToTableNo: Integer; ToTableKey: Text; ToAddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to")
    var
        FromAddressID: Record "Address ID";
        ToAddressID: Record "Address ID";
        FromTableKey2: Text[200];
        ToTableKey2: Text[200];
    begin
        FromTableKey2 := CopyStr(FromTableKey, 1, 200);
        ToTableKey2 := CopyStr(ToTableKey, 1, 200);
        if FromAddressID.Get(FromTableNo, FromTableKey2, FromAddressType) then begin
            if not ToAddressID.Get(ToTableNo, ToTableKey2, ToAddressType) then begin
                ToAddressID.Init();
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := ToTableKey2;
                ToAddressID."Address Type" := ToAddressType;
                ToAddressID.Insert();
            end else begin
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := ToTableKey2;
                ToAddressID."Address Type" := ToAddressType;
                ToAddressID.Modify();
            end;
            FromAddressID.Delete();
        end else
            if ToAddressID.Get(ToTableNo, ToTableKey2, ToAddressType) then
                ToAddressID.Delete();
    end;

    local procedure MoveAddressIDRecords(FromTableNo: Integer; FromTableKey: Text; ToTableNo: Integer; ToTableKey: Text)
    var
        FromAddressID: Record "Address ID";
        ToAddressID: Record "Address ID";
    begin
        FromAddressID.SetRange("Table No.", FromTableNo);
        FromAddressID.SetRange("Table Key", FromTableKey);
        ToAddressID.SetRange("Table No.", ToTableNo);
        ToAddressID.SetRange("Table Key", ToTableKey);
        ToAddressID.DeleteAll();
        if FromAddressID.Find('-') then
            repeat
                ToAddressID.Init();
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := CopyStr(ToTableKey, 1, 200);
                ToAddressID.Insert();
            until FromAddressID.Next() = 0;

        FromAddressID.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure TextToArray(OutputText: Text[1024]; var ArrayOutputText: array[100] of Text[1024]) ReturnInformation: Text[1024]
    var
        i: Integer;
        j: Integer;
    begin
        i := 1;
        j := 1;
        while (OutputText[i] <> 0) and (j < 100) do begin
            if Format(OutputText[i]) <> ',' then
                ArrayOutputText[j] := ArrayOutputText[j] + Format(OutputText[i])
            else
                j := j + 1;
            i := i + 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplicationNotInstalled()
    begin
        Message(ExternalComponentMsg);
    end;

    local procedure GetAddressValidationSetup(CountryCode: Code[10])
    begin
        if CountryCode = '' then begin
            GetGLSetup();
            Clear(Country);
            Country."Address Validation" := GLSetup."Address Validation";
            Country."AMAS Software" := GLSetup."AMAS Software";
        end else
            Country.Get(CountryCode);
    end;

    local procedure GetGLSetup()
    begin
        if not HadGLSetup then begin
            GLSetup.Get();
            HadGLSetup := true;
        end;
    end;

    local procedure CheckAddressValidation()
    begin
        GetGLSetup();
        if GLSetup."Address Validation" <> GLSetup."Address Validation"::"Post Code & City" then
            Error(AddressValidationErr, GLSetup.FieldCaption("Address Validation"), GLSetup.TableCaption());
    end;

    // Table "Post Code"
    [EventSubscriber(ObjectType::Table, Database::"Post Code", 'OnBeforeValidateCityProcedure', '', false, false)]
    local procedure PostCodeOnBeforeValidateCity()
    begin
        CheckAddressValidation();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Post Code", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure PostCodeOnBeforeValidatePostCode()
    begin
        CheckAddressValidation();
    end;

    // Table Alternative Address
    [EventSubscriber(ObjectType::Table, Database::"Alternative Address", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure AlternativeAddressAddress(var Rec: Record "Alternative Address"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Alternative Address", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Alternative Address", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure AlternativeAddressAddress2(var Rec: Record "Alternative Address"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Alternative Address", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Alternative Address", 'OnBeforeValidateCity', '', false, false)]
    local procedure AlternativeAddressOnBeforeValidateCity(var AlternativeAddress: Record "Alternative Address"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Alternative Address", AlternativeAddress.GetPosition(), 0,
            AlternativeAddress.Name, AlternativeAddress."Name 2", ContactName, AlternativeAddress.Address,
            AlternativeAddress."Address 2", AlternativeAddress.City, AlternativeAddress."Post Code",
            AlternativeAddress.County, AlternativeAddress."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Alternative Address", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure AlternativeAddressOnBeforeValidatePostCode(var AlternativeAddress: Record "Alternative Address"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Alternative Address", AlternativeAddress.GetPosition(), 0,
            AlternativeAddress.Name, AlternativeAddress."Name 2", ContactName, AlternativeAddress.Address,
            AlternativeAddress."Address 2", AlternativeAddress.City, AlternativeAddress."Post Code",
            AlternativeAddress.County, AlternativeAddress."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Alternative Address", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AlternativeAddressOnAfterDeleteEvent(var Rec: Record "Alternative Address")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Alternative Address", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Alternative Address", 'OnAfterRenameEvent', '', false, false)]
    local procedure AlternativeAddressOnAfterRenameEvent(var Rec: Record "Alternative Address"; var xRec: Record "Alternative Address")
    begin
        MoveAddressIDRecord(
          DATABASE::"Alternative Address", xRec.GetPosition(), 0, DATABASE::"Alternative Address", Rec.GetPosition(), 0);
    end;

    // Table Bank Account
    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure BankAccountAddress(var Rec: Record "Bank Account"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Bank Account", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure BankAccountAddress2(var Rec: Record "Bank Account"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Bank Account", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeValidateCity', '', false, false)]
    local procedure BankAccountOnBeforeValidateCity(var BankAccount: Record "Bank Account"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Bank Account", BankAccount.GetPosition(), 0,
            BankAccount.Name, BankAccount."Name 2", BankAccount.Contact, BankAccount.Address,
            BankAccount."Address 2", BankAccount.City, BankAccount."Post Code", BankAccount.County,
            BankAccount."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure BankAccountOnBeforeValidatePostCode(var BankAccount: Record "Bank Account"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Bank Account", BankAccount.GetPosition(), 0,
            BankAccount.Name, BankAccount."Name 2", BankAccount.Contact, BankAccount.Address,
            BankAccount."Address 2", BankAccount.City, BankAccount."Post Code", BankAccount.County,
            BankAccount."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnAfterDeleteEvent', '', false, false)]
    local procedure BankAccountOnAfterDeleteEvent(var Rec: Record "Bank Account")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Bank Account", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnAfterRenameEvent', '', false, false)]
    local procedure BankAccountOnAfterRenameEvent(var Rec: Record "Bank Account"; var xRec: Record "Bank Account")
    begin
        MoveAddressIDRecord(
          DATABASE::"Bank Account", xRec.GetPosition(), 0, DATABASE::"Bank Account", Rec.GetPosition(), 0);
    end;

    // Codeunit "Blanket Purch. Order to Order"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Purch. Order to Order", 'OnCreatePurchHeaderOnAfterPurchOrderHeaderInsert', '', false, false)]
    local procedure OnCreatePurchHeaderOnAfterPurchOrderHeaderInsert(PurchHeader: Record "Purchase Header"; var PurchOrderHeader: Record "Purchase Header")
    begin
        MoveAddressIDRecords(
            DATABASE::"Purchase Header", PurchHeader.GetPosition(),
            DATABASE::"Purchase Header", PurchOrderHeader.GetPosition());
    end;

    // Codeunit "Blanket Purch. Order to Order"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Sales Order to Order", 'OnCreateSalesHeaderOnAfterSalesOrderHeaderInsert', '', false, false)]
    local procedure OnCreateSalesHeaderOnAfterSalesOrderHeaderInsert(SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    begin
        MoveAddressIDRecords(
            DATABASE::"Purchase Header", SalesHeader.GetPosition(),
            DATABASE::"Purchase Header", SalesOrderHeader.GetPosition());
    end;

    // Table "Company Information"
    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure CompanyInformationAddress(var Rec: Record "Company Information"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Company Information", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure CompanyInformationAddress2(var Rec: Record "Company Information"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Company Information", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateEvent', 'Ship-to Address', false, false)]
    local procedure CompanyInformationShipToAddress(var Rec: Record "Company Information"; CurrFieldNo: Integer)
    var
        ShipToAddress: Text[100];
    begin
        ShipToAddress := Rec."Ship-to Address";
        VerifyAddress(
            CurrFieldNo, DATABASE::"Company Information", Rec.GetPosition(), 2,
            Rec."Ship-to Name", Rec."Ship-to Name 2", Rec."Ship-to Contact",
            ShipToAddress, Rec."Ship-to Address 2", Rec."Ship-to City", Rec."Ship-to Post Code",
            Rec."Ship-to County", Rec."Ship-to Country/Region Code");
        Rec."Ship-to Address" := CopyStr(ShipToAddress, 1, MaxStrLen(Rec."Ship-to Address"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateEvent', 'Ship-to Address 2', false, false)]
    local procedure CompanyInformationShipToAddress2(var Rec: Record "Company Information"; CurrFieldNo: Integer)
    var
        ShipToAddress: Text[100];
    begin
        ShipToAddress := Rec."Ship-to Address";
        VerifyAddress(
            CurrFieldNo, DATABASE::"Company Information", Rec.GetPosition(), 2,
            Rec."Ship-to Name", Rec."Ship-to Name 2", Rec."Ship-to Contact",
            ShipToAddress, Rec."Ship-to Address 2", Rec."Ship-to City", Rec."Ship-to Post Code",
            Rec."Ship-to County", Rec."Ship-to Country/Region Code");
        Rec."Ship-to Address" := CopyStr(ShipToAddress, 1, MaxStrLen(Rec."Ship-to Address"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateCity', '', false, false)]
    local procedure CompanyInformationOnBeforeValidateCity(var CompanyInformation: Record "Company Information"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Company Information", CompanyInformation.GetPosition(), 0,
            CompanyInformation.Name, CompanyInformation."Name 2", ContactName, CompanyInformation.Address,
            CompanyInformation."Address 2", CompanyInformation.City, CompanyInformation."Post Code",
            CompanyInformation.County, CompanyInformation."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateShipToCity', '', false, false)]
    local procedure CompanyInformationOnBeforeValidateShipToCity(var CompanyInformation: Record "Company Information"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    var
        ShipToAddress: Text[100];
    begin
        ShipToAddress := CompanyInformation."Ship-to Address";
        VerifyCity(
            CurrentFieldNo, DATABASE::"Company Information", CompanyInformation.GetPosition(), 2,
            CompanyInformation."Ship-to Name", CompanyInformation."Ship-to Name 2", CompanyInformation."Ship-to Contact",
            ShipToAddress, CompanyInformation."Ship-to Address 2", CompanyInformation."Ship-to City",
            CompanyInformation."Ship-to Post Code", CompanyInformation."Ship-to County", CompanyInformation."Ship-to Country/Region Code");
        CompanyInformation."Ship-to Address" := CopyStr(ShipToAddress, 1, MaxStrLen(CompanyInformation."Ship-to Address"));
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure CompanyInformationOnBeforeVerifyPostCode(var CompanyInformation: Record "Company Information"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Company Information", CompanyInformation.GetPosition(), 0,
            CompanyInformation.Name, CompanyInformation."Name 2", ContactName, CompanyInformation.Address,
            CompanyInformation."Address 2", CompanyInformation.City, CompanyInformation."Post Code",
            CompanyInformation.County, CompanyInformation."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnBeforeValidateShipToPostCode', '', false, false)]
    local procedure CompanyInformationOnBeforeValidateShipToPostCode(var CompanyInformation: Record "Company Information"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    var
        ShipToAddress: Text[100];
    begin
        ShipToAddress := CompanyInformation."Ship-to Address";
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Company Information", CompanyInformation.GetPosition(), 2,
            CompanyInformation."Ship-to Name", CompanyInformation."Ship-to Name 2", CompanyInformation."Ship-to Contact",
            ShipToAddress, CompanyInformation."Ship-to Address 2",
            CompanyInformation."Ship-to City", CompanyInformation."Ship-to Post Code",
            CompanyInformation."Ship-to County", CompanyInformation."Ship-to Country/Region Code");
        CompanyInformation."Ship-to Address" := CopyStr(ShipToAddress, 1, MaxStrLen(CompanyInformation."Ship-to Address"));
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnAfterDeleteEvent', '', false, false)]
    local procedure CompanyInformationOnAfterDeleteEvent(var Rec: Record "Company Information")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Company Information", Rec.GetPosition(), 0);
    end;

    // Table "Contact"
    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ContactAddress(var Rec: Record Contact; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Contact, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure ContactAddress2(var Rec: Record Contact; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Contact, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeValidateCity', '', false, false)]
    local procedure ContactOnBeforeValidateCity(var Contact: Record Contact; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::Contact, Contact.GetPosition(), 0,
            Contact.Name, Contact."Name 2", ContactName, Contact.Address,
            Contact."Address 2", Contact.City, Contact."Post Code", Contact.County,
            Contact."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeValidatePostCode', '', false, false)]
    local procedure ContactOnBeforeValidatePostCode(var Contact: Record Contact; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::Contact, Contact.GetPosition(), 0,
            Contact.Name, Contact."Name 2", ContactName, Contact.Address,
            Contact."Address 2", Contact.City, Contact."Post Code", Contact.County,
            Contact."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnAfterDeleteEvent', '', false, false)]
    local procedure ContactOnAfterDeleteEvent(var Rec: Record Contact)
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::Contact, Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnAfterRenameEvent', '', false, false)]
    local procedure ContactOnAfterRenameEvent(var Rec: Record Contact; var xRec: Record Contact)
    begin
        MoveAddressIDRecord(
          DATABASE::Contact, xRec.GetPosition(), 0, DATABASE::Contact, Rec.GetPosition(), 0);
    end;

    // Table "Contact Alt. Address"
    [EventSubscriber(ObjectType::Table, Database::"Contact Alt. Address", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ContactAltAddressAddress(var Rec: Record "Contact Alt. Address"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Contact Alt. Address", Rec.GetPosition(), 0,
            Rec."COmpany Name", Rec."Company Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Alt. Address", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure ContactAltAddressAddress2(var Rec: Record "Contact Alt. Address"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Contact Alt. Address", Rec.GetPosition(), 0,
            Rec."Company Name", Rec."Company Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Alt. Address", 'OnBeforeValidateCity', '', false, false)]
    local procedure ContactAltAddressOnBeforeValidateCity(var ContactAltAddress: Record "Contact Alt. Address"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Contact Alt. Address", ContactAltAddress.GetPosition(), 0,
            ContactAltAddress."Company Name", ContactAltAddress."COmpany Name 2", ContactName, ContactAltAddress.Address,
            ContactAltAddress."Address 2", ContactAltAddress.City, ContactAltAddress."Post Code",
            ContactAltAddress.County, ContactAltAddress."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Alt. Address", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure ContactAltAddressOnBeforeValidatePostCode(var ContactAltAddress: Record "Contact Alt. Address"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Contact Alt. Address", ContactAltAddress.GetPosition(), 0,
            ContactAltAddress."Company Name", ContactAltAddress."Company Name 2", ContactName, ContactAltAddress.Address,
            ContactAltAddress."Address 2", ContactAltAddress.City, ContactAltAddress."Post Code",
            ContactAltAddress.County, ContactAltAddress."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Alt. Address", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ContactAltAddressOnAfterDeleteEvent(var Rec: Record "Contact Alt. Address")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Contact Alt. Address", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Alt. Address", 'OnAfterRenameEvent', '', false, false)]
    local procedure ContactAltAddressOnAfterRenameEvent(var Rec: Record "Contact Alt. Address"; var xRec: Record "Contact Alt. Address")
    begin
        MoveAddressIDRecord(
          DATABASE::"Contact Alt. Address", xRec.GetPosition(), 0,
          DATABASE::"Contact Alt. Address", Rec.GetPosition(), 0);
    end;

    // Report "Copy Purchase Document"
    [EventSubscriber(ObjectType::Report, Report::"Copy Purchase Document", 'OnValidateDocNoOnAfterTransferFieldsFromPurchRcptHeader', '', false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromPurchRcptHeader(FromPurchHeader: Record "Purchase Header"; FromPurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Purch. Rcpt. Header", FromPurchRcptHeader.GetPosition(),
            DATABASE::"Purchase Header", FromPurchHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Purchase Document", 'OnValidateDocNoOnAfterTransferFieldsFromPurchInvHeader', '', false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromPurchInvHeader(FromPurchHeader: Record "Purchase Header"; FromPurchInvHeader: Record "Purch. Inv. Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Purch. Inv. Header", FromPurchInvHeader.GetPosition(),
            DATABASE::"Purchase Header", FromPurchHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Purchase Document", 'OnValidateDocNoOnAfterTransferFieldsFromPurchCrMemoHeader', '', false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromPurchCrMemoHeader(FromPurchHeader: Record "Purchase Header"; FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        CopyAddressIDRecords(
            DATABASE::"Purch. Cr. Memo Hdr.", FromPurchCrMemoHdr.GetPosition(),
            DATABASE::"Purchase Header", FromPurchHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Purchase Document", 'OnValidateDocNoOnAfterTransferFieldsFromReturnShipmentHeader', '', false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromReturnShipmentHeader(FromPurchHeader: Record "Purchase Header"; FromReturnShipmentHeader: Record "Return Shipment Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Return Shipment Header", FromReturnShipmentHeader.GetPosition(),
            DATABASE::"Purchase Header", FromPurchHeader.GetPosition());
    end;

    // Report "Copy Sales Document"
    [EventSubscriber(ObjectType::Report, Report::"Copy Sales Document", 'OnValidateDocNoOnAfterTransferFieldsFromSalesInvHeader', '', false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromSalesInvHeader(FromSalesHeader: Record "Sales Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Sales Invoice Header", FromSalesInvoiceHeader.GetPosition(),
            DATABASE::"Sales Header", FromSalesHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Sales Document", 'OnValidateDocNoOnAfterTransferFieldsFromSalesCrMemoHeader', '', false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromSalesCrMemoHeader(FromSalesHeader: Record "Sales Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Sales Cr.Memo Header", FromSalesCrMemoHeader.GetPosition(),
            DATABASE::"Sales Header", FromSalesHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Sales Document", 'OnValidateDocNoOnAfterTransferFieldsFromReturnReceiptHeader', '', false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromSalesReturnRcptHeader(FromSAlesHeader: Record "Sales Header"; FromReturnReceiptHeader: Record "Return Receipt Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Return Receipt Header", FromReturnReceiptHeader.GetPosition(),
            DATABASE::"Sales Header", FromSalesHeader.GetPosition());
    end;

    // Table Customer
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure CustomerAddress(var Rec: Record Customer; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Customer, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure CustomerAddress2(var Rec: Record Customer; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Customer, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeValidateCity', '', false, false)]
    local procedure CustomerOnBeforeValidateCity(var Customer: Record Customer; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::Customer, Customer.GetPosition(), 0,
            Customer.Name, Customer."Name 2", Customer.Contact, Customer.Address,
            Customer."Address 2", Customer.City, Customer."Post Code", Customer.County,
            Customer."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeValidatePostCode', '', false, false)]
    local procedure CustomerOnBeforeValidatePostCode(var Customer: Record Customer; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::Customer, Customer.GetPosition(), 0,
            Customer.Name, Customer."Name 2", Customer.Contact, Customer.Address,
            Customer."Address 2", Customer.City, Customer."Post Code", Customer.County,
            Customer."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterDeleteEvent', '', false, false)]
    local procedure CustomerOnAfterDeleteEvent(var Rec: Record Customer)
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::Customer, Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterRenameEvent', '', false, false)]
    local procedure CustomerOnAfterRenameEvent(var Rec: Record Customer; var xRec: Record Customer)
    begin
        MoveAddressIDRecord(
          DATABASE::Customer, xRec.GetPosition(), 0, DATABASE::Customer, Rec.GetPosition(), 0);
    end;

    // Table Customer Bank Account
    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure CustomerBankAccountAddress(var Rec: Record "Customer Bank Account"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Customer Bank Account", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure CustomerBankAccountAddress2(var Rec: Record "Customer Bank Account"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Customer Bank Account", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnBeforeValidateCity', '', false, false)]
    local procedure CustomerBankAccountOnBeforeValidateCity(var CustomerBankAccount: Record "Customer Bank Account"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Customer Bank Account", CustomerBankAccount.GetPosition(), 0,
            CustomerBankAccount.Name, CustomerBankAccount."Name 2", CustomerBankAccount.Contact,
            CustomerBankAccount.Address, CustomerBankAccount."Address 2", CustomerBankAccount.City,
            CustomerBankAccount."Post Code", CustomerBankAccount.County, CustomerBankAccount."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure CustomerBankAccountOnBeforeValidatePostCode(var CustomerBankAccount: Record "Customer Bank Account"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Customer Bank Account", CustomerBankAccount.GetPosition(), 0,
            CustomerBankAccount.Name, CustomerBankAccount."Name 2", CustomerBankAccount.Contact,
            CustomerBankAccount.Address, CustomerBankAccount."Address 2", CustomerBankAccount.City,
            CustomerBankAccount."Post Code", CustomerBankAccount.County, CustomerBankAccount."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnAfterDeleteEvent', '', false, false)]
    local procedure CustomerBankAccountOnAfterDeleteEvent(var Rec: Record "Customer Bank Account")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Customer Bank Account", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnAfterRenameEvent', '', false, false)]
    local procedure CustomerBankAccountOnAfterRenameEvent(var Rec: Record "Customer Bank Account"; var xRec: Record "Customer Bank Account")
    begin
        MoveAddressIDRecord(
            DATABASE::"Customer Bank Account", xRec.GetPosition(), 0,
            DATABASE::"Customer Bank Account", Rec.GetPosition(), 0);
    end;

    // Table Employee
    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure EmployeeAddress(var Rec: Record Employee; CurrFieldNo: Integer)
    var
        FirstName: Text[100];
        LastName: Text[50];
    begin
        FirstName := Rec."First Name";
        LastName := Rec."Last Name";
        VerifyAddress(
            CurrFieldNo, DATABASE::Employee, Rec.GetPosition(), 0, FirstName, LastName, ContactName,
            Rec.Address, Rec."Address 2", Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
        FirstName := CopyStr(Rec."First Name", 1, MaxStrLen(Rec."First Name"));
        LastName := CopyStr(Rec."Last Name", 1, MaxStrLen(Rec."Last Name"));
    end;

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure EmployeeAddress2(var Rec: Record Employee; CurrFieldNo: Integer)
    var
        FirstName: Text[100];
        LastName: Text[50];
    begin
        FirstName := Rec."First Name";
        LastName := Rec."Last Name";
        VerifyAddress(
            CurrFieldNo, DATABASE::Employee, Rec.GetPosition(), 0,
            FirstName, LastName, ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
        FirstName := CopyStr(Rec."First Name", 1, MaxStrLen(Rec."First Name"));
        LastName := CopyStr(Rec."Last Name", 1, MaxStrLen(Rec."Last Name"));
    end;

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnBeforeValidateCity', '', false, false)]
    local procedure EmployeeOnBeforeValidateCity(var Employee: Record Employee; CurrentFieldNo: Integer; var IsHandled: Boolean)
    var
        FirstName: Text[100];
        LastName: Text[50];
    begin
        FirstName := Employee."First Name";
        LastName := Employee."Last Name";
        VerifyCity(
            CurrentFieldNo, DATABASE::Employee, Employee.GetPosition(), 0,
            FirstName, LastName, ContactName, Employee.Address,
            Employee."Address 2", Employee.City, Employee."Post Code", Employee.County,
            Employee."Country/Region Code");
        FirstName := CopyStr(Employee."First Name", 1, MaxStrLen(Employee."First Name"));
        LastName := CopyStr(Employee."Last Name", 1, MaxStrLen(Employee."Last Name"));
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnBeforeValidatePostCode', '', false, false)]
    local procedure EmployeeOnBeforeValidatePostCode(var Employee: Record Employee; CurrentFieldNo: Integer; var IsHandled: Boolean)
    var
        FirstName: Text[100];
        LastName: Text[50];
    begin
        FirstName := Employee."First Name";
        LastName := Employee."Last Name";
        VerifyPostCode(
            CurrentFieldNo, DATABASE::Employee, Employee.GetPosition(), 0,
            FirstName, LastName, ContactName, Employee.Address,
            Employee."Address 2", Employee.City, Employee."Post Code", Employee.County,
            Employee."Country/Region Code");
        FirstName := CopyStr(Employee."First Name", 1, MaxStrLen(Employee."First Name"));
        LastName := CopyStr(Employee."Last Name", 1, MaxStrLen(Employee."Last Name"));
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnAfterDeleteEvent', '', false, false)]
    local procedure EmployeeOnAfterDeleteEvent(var Rec: Record Employee)
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::Employee, Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnAfterRenameEvent', '', false, false)]
    local procedure EmployeeOnAfterRenameEvent(var Rec: Record Employee; var xRec: Record Employee)
    begin
        MoveAddressIDRecord(
            DATABASE::Employee, xRec.GetPosition(), 0, DATABASE::Employee, Rec.GetPosition(), 0);
    end;

    // Table "Finance Charge Memo Header" 
    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure FinanceChargeMemoHeaderAddress(var Rec: Record "Finance Charge Memo Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Finance Charge Memo Header", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure FinanceChargeMemoHeaderAddress2(var Rec: Record "Finance Charge Memo Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Finance Charge Memo Header", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnBeforeValidateCity', '', false, false)]
    local procedure FinanceChargeMemoHeaderOnBeforeValidateCity(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Finance Charge Memo Header", FinanceChargeMemoHeader.GetPosition(), 0,
            FinanceChargeMemoHeader.Name, FinanceChargeMemoHeader."Name 2", FinanceChargeMemoHeader.Contact,
            FinanceChargeMemoHeader.Address, FinanceChargeMemoHeader."Address 2",
            FinanceChargeMemoHeader.City, FinanceChargeMemoHeader."Post Code",
            FinanceChargeMemoHeader.County, FinanceChargeMemoHeader."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure FinanceChargeMemoHeaderOnBeforeValidatePostCode(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Finance Charge Memo Header", FinanceChargeMemoHeader.GetPosition(), 0,
            FinanceChargeMemoHeader.Name, FinanceChargeMemoHeader."Name 2", FinanceChargeMemoHeader.Contact,
            FinanceChargeMemoHeader.Address, FinanceChargeMemoHeader."Address 2",
            FinanceChargeMemoHeader.City, FinanceChargeMemoHeader."Post Code",
            FinanceChargeMemoHeader.County, FinanceChargeMemoHeader."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnValidateCustomerNoOnAfterAssignCustomerValues', '', false, false)]
    local procedure FinanceChargeMemoHeaderOnValidateCustomerNoOnAfterAssignCustomerValues(Customer: Record Customer; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
        CopyAddressIDRecord(
            DATABASE::Customer, Customer.GetPosition(), 0,
            DATABASE::"Finance Charge Memo Header", FinanceChargeMemoHeader.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure FinanceChargeMemoHeaderOnAfterDeleteEvent(var Rec: Record "Finance Charge Memo Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Finance Charge Memo Header", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnAfterRenameEvent', '', false, false)]
    local procedure FinanceChargeMemoHeaderOnAfterRenameEvent(var Rec: Record "Finance Charge Memo Header"; var xRec: Record "Finance Charge Memo Header")
    begin
        MoveAddressIDRecord(
          DATABASE::"Finance Charge Memo Header", xRec.GetPosition(), 0, DATABASE::"Finance Charge Memo Header", Rec.GetPosition(), 0);
    end;

    // Table "Issued Fin. Charge Memo Header"
    [EventSubscriber(ObjectType::Table, Database::"Issued Fin. Charge Memo Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure IssuedFinChargeMemoHeaderOnAfterDeleteEvent(var Rec: Record "Issued Fin. Charge Memo Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Issued Fin. Charge Memo Header", Rec.GetPosition(), 0);
    end;

    // Table "Issued Reminder Header"
    [EventSubscriber(ObjectType::Table, Database::"Issued Reminder Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure IssuedReminderHeaderOnAfterDeleteEvent(var Rec: Record "Issued Reminder Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Issued Reminder Header", Rec.GetPosition(), 0);
    end;

    // Table "Job"
    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeValidateBillToCity', '', false, false)]
    local procedure JobOnBeforeValidateBillToCity(var Job: Record Job; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::Job, Job.GetPosition(), 1,
            Job."Bill-to Name", Job."Bill-to Name 2", Job."Bill-to Contact",
            Job."Bill-to Address", Job."Bill-to Address 2", Job."Bill-to City",
            Job."Bill-to Post Code", Job."Bill-to County", Job."Bill-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeValidateBillToPostCode', '', false, false)]
    local procedure JobOnBeforeValidateBillToPostCode(var Job: Record Job; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::Job, Job.GetPosition(), 1,
            Job."Bill-to Name", Job."Bill-to Name 2", Job."Bill-to Contact",
            Job."Bill-to Address", Job."Bill-to Address 2", Job."Bill-to City",
            Job."Bill-to Post Code", Job."Bill-to County", Job."Bill-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeValidateSellToCity', '', false, false)]
    local procedure JobOnBeforeValidateSellToCity(var Job: Record Job; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::Job, Job.GetPosition(), 3,
            Job."Sell-to Customer Name", Job."Sell-to Customer Name 2", Job."Sell-to Contact",
            Job."Sell-to Address", Job."Sell-to Address 2", Job."Sell-to City",
            Job."Sell-to Post Code", Job."Sell-to County", Job."Sell-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeValidateShipToCity', '', false, false)]
    local procedure JobOnBeforeValidateShipToCity(var Job: Record Job; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::Job, Job.GetPosition(), 2,
            Job."Ship-to Name", Job."Ship-to Name 2", Job."Ship-to Contact",
            Job."Ship-to Address", Job."Ship-to Address 2", Job."Ship-to City",
            Job."Ship-to Post Code", Job."Ship-to County", Job."Ship-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnAfterDeleteEvent', '', false, false)]
    local procedure JobOnAfterDeleteEvent(var Rec: Record Job)
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::Job, Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnAfterRenameEvent', '', false, false)]
    local procedure JobOnAfterRenameEvent(var Rec: Record Job; var xRec: Record Job)
    begin
        MoveAddressIDRecord(
          DATABASE::Job, xRec.GetPosition(), 0, DATABASE::Job, Rec.GetPosition(), 0);
    end;

    // Codeunit "FinChrgMemo-Issue"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FinChrgMemo-Issue", 'OnBeforeIssuedFinChrgMemoHeaderInsert', '', false, false)]
    local procedure OnBeforeIssuedFinChrgMemoHeaderInsert(FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        MoveAddressIDRecords(
            DATABASE::"Finance Charge Memo Header", FinanceChargeMemoHeader.GetPosition(),
            DATABASE::"Issued Fin. Charge Memo Header", IssuedFinChargeMemoHeader.GetPosition());
    end;

    // Table "Location"
    [EventSubscriber(ObjectType::Table, Database::"Location", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure LocationAddress(var Rec: Record "Location"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Location, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Location", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure LocationAddress2(var Rec: Record "Location"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Location, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Location", 'OnBeforeValidateCity', '', false, false)]
    local procedure LocationOnBeforeValidateCity(var Location: Record "Location"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::Location, Location.GetPosition(), 0,
            Location.Name, Location."Name 2", Location.Contact, Location.Address, Location."Address 2",
            Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Location", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure LocationOnBeforeValidatePostCode(var Location: Record "Location"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::Location, Location.GetPosition(), 0,
            Location.Name, Location."Name 2", Location.Contact, Location.Address, Location."Address 2",
            Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Location", 'OnAfterDeleteEvent', '', false, false)]
    local procedure LocationOnAfterDeleteEvent(var Rec: Record "Location")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Location", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Location", 'OnAfterRenameEvent', '', false, false)]
    local procedure LocationOnAfterRenameEvent(var Rec: Record "Location"; var xRec: Record "Location")
    begin
        MoveAddressIDRecord(
          DATABASE::Location, xRec.GetPosition(), 0, DATABASE::Location, Rec.GetPosition(), 0);
    end;

#if not CLEAN28
    // Table "Machine Center"
    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure MachineCenterAddress(var Rec: Record "Machine Center"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Machine Center", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure MachineCenterAddress2(var Rec: Record "Machine Center"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Machine Center", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnBeforeValidateCity', '', false, false)]
    local procedure MachineCenterOnBeforeValidateCity(var MachineCenter: Record "Machine Center"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Machine Center", MachineCenter.GetPosition(), 0,
            MachineCenter.Name, MachineCenter."Name 2", ContactName,
            MachineCenter.Address, MachineCenter."Address 2", MachineCenter.City,
            MachineCenter."Post Code", MachineCenter.County, MachineCenter."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure MachineCenterOnBeforeValidatePostCode(var MachineCenter: Record "Machine Center"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Machine Center", MachineCenter.GetPosition(), 0,
            MachineCenter.Name, MachineCenter."Name 2", ContactName,
            MachineCenter.Address, MachineCenter."Address 2", MachineCenter.City,
            MachineCenter."Post Code", MachineCenter.County, MachineCenter."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnAfterDeleteEvent', '', false, false)]
    local procedure MachineCenterOnAfterDeleteEvent(var Rec: Record "Machine Center")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Machine Center", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnAfterRenameEvent', '', false, false)]
    local procedure MachineCenterOnAfterRenameEvent(var Rec: Record "Machine Center"; var xRec: Record "Machine Center")
    begin
        MoveAddressIDRecord(
          DATABASE::"Machine Center", xRec.GetPosition(), 0, DATABASE::"Machine Center", Rec.GetPosition(), 0);
    end;
#endif

    // Table "Order Address"
    [EventSubscriber(ObjectType::Table, Database::"Order Address", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure OrderAddressAddress(var Rec: Record "Order Address"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Order Address", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Address", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure OrderAddressAddress2(var Rec: Record "Order Address"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Order Address", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Address", 'OnBeforeValidateCity', '', false, false)]
    local procedure OrderAddressOnBeforeValidateCity(var OrderAddress: Record "Order Address"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Order Address", OrderAddress.GetPosition(), 0,
            OrderAddress.Name, OrderAddress."Name 2", ContactName, OrderAddress.Address,
            OrderAddress."Address 2", OrderAddress.City, OrderAddress."Post Code",
            OrderAddress.County, OrderAddress."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Address", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure OrderAddressOnBeforeValidatePostCode(var OrderAddress: Record "Order Address"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Order Address", OrderAddress.GetPosition(), 0,
            OrderAddress.Name, OrderAddress."Name 2", ContactName, OrderAddress.Address,
            OrderAddress."Address 2", OrderAddress.City, OrderAddress."Post Code",
            OrderAddress.County, OrderAddress."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Address", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OrderAddressOnAfterDeleteEvent(var Rec: Record "Order Address")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Order Address", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Address", 'OnAfterRenameEvent', '', false, false)]
    local procedure OrderAddressOnAfterRenameEvent(var Rec: Record "Order Address"; var xRec: Record "Order Address")
    begin
        MoveAddressIDRecord(
          DATABASE::"Order Address", xRec.GetPosition(), 0, DATABASE::"Order Address", Rec.GetPosition(), 0);
    end;

    // Table "Purchase Header"
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterCopyBuyFromVendorFieldsFromVendor', '', false, false)]
    local procedure PurchaseHeaderOnAfterCopyBuyFromVendorFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        CopyAddressIDRecord(
           DATABASE::Vendor, Vendor.GetPosition(), 0, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 5);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterCopyBuyFromVendorFieldsFromVendor', '', false, false)]
    local procedure PurchaseHeaderOnAfterCopyPayToVendorFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        CopyAddressIDRecord(
            DATABASE::Vendor, Vendor.GetPosition(), 0, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 4);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidateShipToCodeOnAfterCopyFromShipToAddr', '', false, false)]
    local procedure PurchaseHeaderOnValidateShipToCodeOnAfterCopyFromShipToAddr(var PurchaseHeader: Record "Purchase Header"; ShipToAddress: Record "Ship-to Address")
    begin
        CopyAddressIDRecord(
            DATABASE::"Ship-to Address", ShipToAddress.GetPosition(), 0, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidateShipToCodeOnAfterCopyFromSellToCust', '', false, false)]
    local procedure PurchaseHeaderOnValidateShipToCodeOnAfterCopyFromSellToCust(var PurchaseHeader: Record "Purchase Header"; Customer: Record Customer)
    begin
        CopyAddressIDRecord(
            DATABASE::Customer, Customer.GetPosition(), 0, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnUpdateShipToAddressOnAfterCopyFromLocation', '', false, false)]
    local procedure PurchaseHeaderOnUpdateShipToAddressOnAfterCopyFromLocation(var PurchaseHeader: Record "Purchase Header"; Location: Record Location)
    begin
        CopyAddressIDRecord(
            DATABASE::Location, Location.GetPosition(), 0, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnUpdateShipToAddressOnAfterCopyFromCompany', '', false, false)]
    local procedure PurchaseHeaderOnUpdateShipToAddressOnAfterCopyFromCompany(var PurchaseHeader: Record "Purchase Header"; CompanyInformation: Record "Company Information")
    begin
        CopyAddressIDRecord(
            DATABASE::"Company Information", CompanyInformation.GetPosition(), 0,
            DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterCopyAddressInfoFromOrderAddress', '', false, false)]
    local procedure PurchaseHeaderOnAfterCopyAddressInfoFromOrderAddress(var PurchHeader: Record "Purchase Header"; var OrderAddress: Record "Order Address")
    begin
        CopyAddressIDRecord(
            DATABASE::"Order Address", OrderAddress.GetPosition(), 0, DATABASE::"Purchase Header", PurchHeader.GetPosition(), 5);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateEvent', 'Pay-to Address', false, false)]
    local procedure PurchaseHeaderPayToAddress(var Rec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Purchase Header", Rec.GetPosition(), 4,
            Rec."Pay-to Name", Rec."Pay-to Name 2", Rec."Pay-to Contact",
            Rec."Pay-to Address", Rec."Pay-to Address 2", Rec."Pay-to City",
            Rec."Pay-to Post Code", Rec."Pay-to County", Rec."Pay-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateEvent', 'Pay-to Address 2', false, false)]
    local procedure PurchaseHeaderPayToAddress2(var Rec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Purchase Header", Rec.GetPosition(), 4,
            Rec."Pay-to Name", Rec."Pay-to Name 2", Rec."Pay-to Contact",
            Rec."Pay-to Address", Rec."Pay-to Address 2", Rec."Pay-to City",
            Rec."Pay-to Post Code", Rec."Pay-to County", Rec."Pay-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateEvent', 'Ship-to Address', false, false)]
    local procedure PurchaseHeaderShipToAddress(var Rec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Purchase Header", Rec.GetPosition(), 2,
            Rec."Ship-to Name", Rec."Ship-to Name 2", Rec."Ship-to Contact",
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to City",
            Rec."Ship-to Post Code", Rec."Ship-to County", Rec."Ship-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateEvent', 'Ship-to Address 2', false, false)]
    local procedure PurchaseHeaderShipToAddress2(var Rec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Purchase Header", Rec.GetPosition(), 2,
            Rec."Ship-to Name", Rec."Ship-to Name 2", Rec."Ship-to Contact",
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to City",
            Rec."Ship-to Post Code", Rec."Ship-to County", Rec."Ship-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidatePayToCity', '', false, false)]
    local procedure PurchaseHeaderOnBeforeValidatePayToCity(var PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 4,
            PurchaseHeader."Pay-to Name", PurchaseHeader."Pay-to Name 2", PurchaseHeader."Pay-to Contact",
            PurchaseHeader."Pay-to Address", PurchaseHeader."Pay-to Address 2", PurchaseHeader."Pay-to City",
            PurchaseHeader."Pay-to Post Code", PurchaseHeader."Pay-to County", PurchaseHeader."Pay-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateEvent', 'Buy-from Address', false, false)]
    local procedure PurchaseHeaderBuyFromAddress(var Rec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Purchase Header", Rec.GetPosition(), 5,
            Rec."Buy-from Vendor Name", Rec."Buy-from Vendor Name 2", Rec."Buy-from Contact",
            Rec."Buy-from Address", Rec."Buy-from Address 2", Rec."Buy-from City",
            Rec."Buy-from Post Code", Rec."Buy-from County", Rec."Buy-from Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateEvent', 'Buy-from Address 2', false, false)]
    local procedure PurchaseHeaderBuyFromAddress2(var Rec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Purchase Header", Rec.GetPosition(), 5,
            Rec."Buy-from Vendor Name", Rec."Buy-from Vendor Name 2", Rec."Buy-from Contact",
            Rec."Buy-from Address", Rec."Buy-from Address 2", Rec."Buy-from City",
            Rec."Buy-from Post Code", Rec."Buy-from County", Rec."Buy-from Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidatePayToPostCode', '', false, false)]
    local procedure PurchaseHeaderOnBeforeValidatePayToPostCode(var PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 4,
            PurchaseHeader."Pay-to Name", PurchaseHeader."Pay-to Name 2", PurchaseHeader."Pay-to Contact",
            PurchaseHeader."Pay-to Address", PurchaseHeader."Pay-to Address 2", PurchaseHeader."Pay-to City",
            PurchaseHeader."Pay-to Post Code", PurchaseHeader."Pay-to County", PurchaseHeader."Pay-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateShipToCity', '', false, false)]
    local procedure PurchaseHeaderOnBeforeValidateShipToCity(var PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 2,
            PurchaseHeader."Ship-to Name", PurchaseHeader."Ship-to Name 2", PurchaseHeader."Ship-to Contact",
            PurchaseHeader."Ship-to Address", PurchaseHeader."Ship-to Address 2", PurchaseHeader."Ship-to City",
            PurchaseHeader."Ship-to Post Code", PurchaseHeader."Ship-to County", PurchaseHeader."Ship-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateShipToPostCode', '', false, false)]
    local procedure PurchaseHeaderOnBeforeValidateShipToPostCode(var PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 2,
            PurchaseHeader."Ship-to Name", PurchaseHeader."Ship-to Name 2", PurchaseHeader."Ship-to Contact",
            PurchaseHeader."Ship-to Address", PurchaseHeader."Ship-to Address 2", PurchaseHeader."Ship-to City",
            PurchaseHeader."Ship-to Post Code", PurchaseHeader."Ship-to County", PurchaseHeader."Ship-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateBuyFromCity', '', false, false)]
    local procedure PurchaseHeaderOnBeforeValidateBuyFromCity(var PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 5,
            PurchaseHeader."Buy-from Vendor Name", PurchaseHeader."Buy-from Vendor Name 2", PurchaseHeader."Buy-from Contact",
            PurchaseHeader."Buy-from Address", PurchaseHeader."Buy-from Address 2", PurchaseHeader."Buy-from City",
            PurchaseHeader."Buy-from Post Code", PurchaseHeader."Buy-from County", PurchaseHeader."Buy-from Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidateBuyFromPostCode', '', false, false)]
    local procedure PurchaseHeaderOnBeforeValidateBuyFromPostCode(var PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 5,
            PurchaseHeader."Buy-from Vendor Name", PurchaseHeader."Buy-from Vendor Name 2", PurchaseHeader."Buy-from Contact",
            PurchaseHeader."Buy-from Address", PurchaseHeader."Buy-from Address 2", PurchaseHeader."Buy-from City",
            PurchaseHeader."Buy-from Post Code", PurchaseHeader."Buy-from County", PurchaseHeader."Buy-from Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidateOrderAddressCodeOnAfterCopyBuyFromVendorAddressFieldsFromVendor', '', false, false)]
    local procedure PurchaseHeaderOnValidateOrderAddressCodeOnAfterCopyBuyFromVendorAddressFieldsFromVendor(Vend: Record Vendor; var PurchaseHeader: Record "Purchase Header")
    begin
        CopyAddressIDRecord(
            DATABASE::Vendor, Vend.GetPosition(), 0, DATABASE::"Purchase Header", PurchaseHeader.GetPosition(), 5);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure PurchaseHeaderOnAfterDeleteEvent(var Rec: Record "Purchase Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Purchase Header", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterRenameEvent', '', false, false)]
    local procedure PurchaseHeaderOnAfterRenameEvent(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header")
    begin
        MoveAddressIDRecord(
          DATABASE::"Purchase Header", xRec.GetPosition(), 0, DATABASE::"Purchase Header", Rec.GetPosition(), 0);
    end;

    // Table "Purch. Cr. Memo Hdr."
    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Hdr.", 'OnAfterDeleteEvent', '', false, false)]
    local procedure PurchCrMemoHdrOnAfterDeleteEvent(var Rec: Record "Purch. Cr. Memo Hdr.")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Purch. Cr. Memo Hdr.", Rec.GetPosition(), 0);
    end;

    // Table "Purch. Inv. Header"
    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure PurchInvHeaderOnAfterDeleteEvent(var Rec: Record "Purch. Inv. Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Purch. Inv. Header", Rec.GetPosition(), 0);
    end;

    // Table "Purch. Rcpt. Header"
    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure PurchRcptHeaderOnAfterDeleteEvent(var Rec: Record "Purch. Rcpt. Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Purch. Rcpt. Header", Rec.GetPosition(), 0);
    end;

    // Codeunit "Purch.-Quote to Order"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Quote to Order", 'OnCreatePurchHeaderOnAfterPurchOrderHeaderInsert', '', false, false)]
    local procedure PurchQuoteToOrderOnCreatePurchHeaderOnAfterPurchOrderHeaderInsert(var PurchOrderHeader: Record "Purchase Header"; BlanketOrderPurchHeader: Record "Purchase Header")
    begin
        MoveAddressIDRecords(
            DATABASE::"Purchase Header", BlanketOrderPurchHeader.GetPosition(),
            DATABASE::"Purchase Header", PurchOrderHeader.GetPosition());
    end;

    // Codeunit "Purch.-Post"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterInsertPostedHeaders', '', false, false)]
    local procedure PurchPostOnAfterInsertPostedHeaders(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        if not PurchaseHeader.Invoice then
            exit;

        if PurchaseHeader.IsCreditDocType() then
            CopyAddressIDRecords(
                DATABASE::"Purchase Header", PurchaseHeader.GetPosition(),
                DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHdr.GetPosition())
        else
            CopyAddressIDRecords(
                DATABASE::"Purchase Header", PurchaseHeader.GetPosition(),
                DATABASE::"Purch. Inv. Header", PurchInvHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterInsertReceiptHeader', '', false, false)]
    local procedure PurchPostOnAfterInsertReceiptHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Purchase Header", PurchHeader.GetPosition(),
            DATABASE::"Purch. Rcpt. Header", PurchRcptHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterSalesShptHeaderInsert', '', false, false)]
    local procedure PurchPostOnAfterSalesShptHeaderInsert(SalesOrderHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Sales Header", SalesOrderHeader.GetPosition(),
            DATABASE::"Sales Shipment Header", SalesShipmentHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterInsertReturnShipmentHeader', '', false, false)]
    local procedure PurchPostOnAfterInsertReturnShipmentHeader(var PurchHeader: Record "Purchase Header"; var ReturnShptHeader: Record "Return Shipment Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Purchase Header", PurchHeader.GetPosition(),
            DATABASE::"Return Shipment Header", ReturnShptHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterDeleteAfterPosting', '', false, false)]
    local procedure PurchPostOnAfterDeleteAfterPosting(PurchHeader: Record "Purchase Header")
    begin
        DeleteAllAddressIDRecords(DATABASE::"Purchase Header", PurchHeader.GetPosition());
    end;

    // Table "Reminder Header" 
    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ReminderHeaderAddress(var Rec: Record "Reminder Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Reminder Header", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure ReminderHeaderAddress2(var Rec: Record "Reminder Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Reminder Header", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnBeforeValidateCity', '', false, false)]
    local procedure ReminderHeaderOnBeforeValidateCity(var ReminderHeader: Record "Reminder Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Reminder Header", ReminderHeader.GetPosition(), 0,
            ReminderHeader.Name, ReminderHeader."Name 2", ReminderHeader.Contact,
            ReminderHeader.Address, ReminderHeader."Address 2", ReminderHeader.City,
            ReminderHeader."Post Code", ReminderHeader.County, ReminderHeader."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure ReminderHeaderOnBeforeValidatePostCode(var ReminderHeader: Record "Reminder Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Reminder Header", ReminderHeader.GetPosition(), 0,
            ReminderHeader.Name, ReminderHeader."Name 2", ReminderHeader.Contact,
            ReminderHeader.Address, ReminderHeader."Address 2", ReminderHeader.City,
            ReminderHeader."Post Code", ReminderHeader.County, ReminderHeader."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnValidateCustomerNoOnAfterAssignCustomerValues', '', false, false)]
    local procedure ReminderHeaderOnValidateCustomerNoOnAfterAssignCustomerValues(Customer: Record Customer; var ReminderHeader: Record "Reminder Header")
    begin
        CopyAddressIDRecord(
            DATABASE::Customer, Customer.GetPosition(), 0,
            DATABASE::"Reminder Header", ReminderHeader.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ReminderHeaderOnAfterDeleteEvent(var Rec: Record "Reminder Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Reminder Header", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnAfterRenameEvent', '', false, false)]
    local procedure ReminderHeaderOnAfterRenameEvent(var Rec: Record "Reminder Header"; var xRec: Record "Reminder Header")
    begin
        MoveAddressIDRecord(
          DATABASE::"Reminder Header", xRec.GetPosition(), 0, DATABASE::"Reminder Header", Rec.GetPosition(), 0);
    end;

    // Codeunit "Reminder-Issue"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reminder-Issue", 'OnBeforeIssuedReminderHeaderInsert', '', false, false)]
    local procedure OnBeforeIssuedReminderHeaderInsert(ReminderHeader: Record "Reminder Header"; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        MoveAddressIDRecords(
            DATABASE::"Finance Charge Memo Header", ReminderHeader.GetPosition(),
            DATABASE::"Issued Fin. Charge Memo Header", IssuedReminderHeader.GetPosition());
    end;

    // Table "Resource"
    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ResourceAddress(var Rec: Record Resource; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Resource, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure ResourceAddress2(var Rec: Record Resource; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Resource, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnBeforeValidateCity', '', false, false)]
    local procedure ResourceOnBeforeValidateCity(var Resource: Record Resource; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::Resource, Resource.GetPosition(), 0,
            Resource.Name, Resource."Name 2", ContactName, Resource.Address,
            Resource."Address 2", Resource.City, Resource."Post Code",
            Resource.County, Resource."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnBeforeValidatePostCode', '', false, false)]
    local procedure ResourceOnBeforeValidatePostCode(var Resource: Record Resource; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::Resource, Resource.GetPosition(), 0,
            Resource.Name, Resource."Name 2", ContactName, Resource.Address,
            Resource."Address 2", Resource.City, Resource."Post Code",
            Resource.County, Resource."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnAfterDeleteEvent', '', false, false)]
    local procedure ResourceOnAfterDeleteEvent(var Rec: Record Resource)
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::Resource, Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnAfterRenameEvent', '', false, false)]
    local procedure ResourceOnAfterRenameEvent(var Rec: Record Resource; var xRec: Record Resource)
    begin
        MoveAddressIDRecord(
          DATABASE::Resource, xRec.GetPosition(), 0, DATABASE::Resource, Rec.GetPosition(), 0);
    end;

    // Table "Responsibility Center"
    [EventSubscriber(ObjectType::Table, Database::"Responsibility Center", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ResponsibilityCenterAddress(var Rec: Record "Responsibility Center"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Responsibility Center", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Responsibility Center", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure ResponsibilityCenterAddress2(var Rec: Record "Responsibility Center"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Responsibility Center", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Responsibility Center", 'OnBeforeValidateCity', '', false, false)]
    local procedure ResponsibilityCenterOnBeforeValidateCity(var ResponsibilityCenter: Record "Responsibility Center"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Responsibility Center", ResponsibilityCenter.GetPosition(), 0,
            ResponsibilityCenter.Name, ResponsibilityCenter."Name 2", ResponsibilityCenter.Contact,
            ResponsibilityCenter.Address, ResponsibilityCenter."Address 2", ResponsibilityCenter.City,
            ResponsibilityCenter."Post Code", ResponsibilityCenter.County, ResponsibilityCenter."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Responsibility Center", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure ResponsibilityCenterOnBeforeValidatePostCode(var ResponsibilityCenter: Record "Responsibility Center"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Responsibility Center", ResponsibilityCenter.GetPosition(), 0,
            ResponsibilityCenter.Name, ResponsibilityCenter."Name 2", ResponsibilityCenter.Contact,
            ResponsibilityCenter.Address, ResponsibilityCenter."Address 2", ResponsibilityCenter.City,
            ResponsibilityCenter."Post Code", ResponsibilityCenter.County, ResponsibilityCenter."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Responsibility Center", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ResponsibilityCenterOnAfterDeleteEvent(var Rec: Record "Responsibility Center")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Responsibility Center", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Responsibility Center", 'OnAfterRenameEvent', '', false, false)]
    local procedure ResponsibilityCenterOnAfterRenameEvent(var Rec: Record "Responsibility Center"; var xRec: Record "Responsibility Center")
    begin
        MoveAddressIDRecord(
          DATABASE::"Responsibility Center", xRec.GetPosition(), 0, DATABASE::"Responsibility Center", Rec.GetPosition(), 0);
    end;

    // Table "Return Receipt Header"
    [EventSubscriber(ObjectType::Table, Database::"Return Receipt Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ReturnReceiptHeaderOnAfterDeleteEvent(var Rec: Record "Return Receipt Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Return Receipt Header", Rec.GetPosition(), 0);
    end;

    // Table "Return Shipment Header"
    [EventSubscriber(ObjectType::Table, Database::"Return Shipment Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ReturnShipmentHeaderOnAfterDeleteEvent(var Rec: Record "Return Shipment Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Return Shipment Header", Rec.GetPosition(), 0);
    end;

    // Table "Sales Header"
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Bill-to Address', false, false)]
    local procedure SalesHeaderBillToAddress(var Rec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Sales Header", Rec.GetPosition(), 1,
            Rec."Bill-to Name", Rec."Bill-to Name 2", Rec."Bill-to Contact",
            Rec."Bill-to Address", Rec."Bill-to Address 2", Rec."Bill-to City",
            Rec."Bill-to Post Code", Rec."Bill-to County", Rec."Bill-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Bill-to Address 2', false, false)]
    local procedure SalesHeaderBillToAddress2(var Rec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Sales Header", Rec.GetPosition(), 1,
            Rec."Bill-to Name", Rec."Bill-to Name 2", Rec."Bill-to Contact",
            Rec."Bill-to Address", Rec."Bill-to Address 2", Rec."Bill-to City",
            Rec."Bill-to Post Code", Rec."Bill-to County", Rec."Bill-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Ship-to Address', false, false)]
    local procedure SalesHeaderShipToAddress(var Rec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Sales Header", Rec.GetPosition(), 2,
            Rec."Ship-to Name", Rec."Ship-to Name 2", Rec."Ship-to Contact",
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to City",
            Rec."Ship-to Post Code", Rec."Ship-to County", Rec."Ship-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Ship-to Address 2', false, false)]
    local procedure SalesHeaderShipToAddress2(var Rec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Sales Header", Rec.GetPosition(), 2,
            Rec."Ship-to Name", Rec."Ship-to Name 2", Rec."Ship-to Contact",
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to City",
            Rec."Ship-to Post Code", Rec."Ship-to County", Rec."Ship-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Sell-to Address', false, false)]
    local procedure SalesHeaderSellToAddress(var Rec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Sales Header", Rec.GetPosition(), 3,
            Rec."Sell-to Customer Name", Rec."Sell-to Customer Name 2", Rec."Sell-to Contact",
            Rec."Sell-to Address", Rec."Sell-to Address 2", Rec."Sell-to City",
            Rec."Sell-to Post Code", Rec."Sell-to County", Rec."Sell-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Sell-to Address 2', false, false)]
    local procedure SalesHeaderSellToAddress2(var Rec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Sales Header", Rec.GetPosition(), 3,
            Rec."Sell-to Customer Name", Rec."Sell-to Customer Name 2", Rec."Sell-to Contact",
            Rec."Sell-to Address", Rec."Sell-to Address 2", Rec."Sell-to City",
            Rec."Sell-to Post Code", Rec."Sell-to County", Rec."Sell-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateBillToCity', '', false, false)]
    local procedure SalesHeaderOnBeforeValidateBillToCity(var SalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Sales Header", SalesHeader.GetPosition(), 1,
            SalesHeader."Bill-to Name", SalesHeader."Bill-to Name 2", SalesHeader."Bill-to Contact",
            SalesHeader."Bill-to Address", SalesHeader."Bill-to Address 2", SalesHeader."Bill-to City",
            SalesHeader."Bill-to Post Code", SalesHeader."Bill-to County", SalesHeader."Bill-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateBillToPostCode', '', false, false)]
    local procedure SalesHeaderOnBeforeValidateBillToPostCode(var SalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Sales Header", SalesHeader.GetPosition(), 1,
            SalesHeader."Bill-to Name", SalesHeader."Bill-to Name 2", SalesHeader."Bill-to Contact",
            SalesHeader."Bill-to Address", SalesHeader."Bill-to Address 2", SalesHeader."Bill-to City",
            SalesHeader."Bill-to Post Code", SalesHeader."Bill-to County", SalesHeader."Bill-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateShipToCity', '', false, false)]
    local procedure SalesHeaderOnBeforeValidateShipToCity(var SalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Sales Header", SalesHeader.GetPosition(), 2,
            SalesHeader."Ship-to Name", SalesHeader."Ship-to Name 2", SalesHeader."Ship-to Contact",
            SalesHeader."Ship-to Address", SalesHeader."Ship-to Address 2", SalesHeader."Ship-to City",
            SalesHeader."Ship-to Post Code", SalesHeader."Ship-to County", SalesHeader."Ship-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateShipToPostCode', '', false, false)]
    local procedure SalesHeaderOnBeforeValidateShipToPostCode(var SalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Sales Header", SalesHeader.GetPosition(), 2,
            SalesHeader."Ship-to Name", SalesHeader."Ship-to Name 2", SalesHeader."Ship-to Contact",
            SalesHeader."Ship-to Address", SalesHeader."Ship-to Address 2", SalesHeader."Ship-to City",
            SalesHeader."Ship-to Post Code", SalesHeader."Ship-to County", SalesHeader."Ship-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopySellToCustomerAddressFieldsFromCustomer', '', false, false)]
    local procedure SalesHeaderOnAfterCopySellToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer)
    begin
        CopyAddressIDRecord(
            DATABASE::Customer, SellToCustomer.GetPosition(), 0, DATABASE::"Sales Header", SalesHeader.GetPosition(), 3);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterSetFieldsBilltoCustomer', '', false, false)]
    local procedure SalesHeaderOnAfterSetFieldsBilltoCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        CopyAddressIDRecord(
            DATABASE::Customer, Customer.GetPosition(), 0, DATABASE::"Sales Header", SalesHeader.GetPosition(), 1);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnUpdateBillToCustOnAfterSalesQuote', '', false, false)]
    local procedure SalesHeaderOnUpdateBillToCustOnAfterSalesQuote(var SalesHeader: Record "Sales Header"; Contact: Record Contact)
    begin
        CopyAddressIDRecord(
          DATABASE::Contact, Contact.GetPosition(), 0, DATABASE::"Sales Header", SalesHeader.GetPosition(), 1);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr', '', false, false)]
    local procedure SalesHeaderOnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(var SalesHeader: Record "Sales Header"; ShipToAddress: Record "Ship-to Address")
    begin
        CopyAddressIDRecord(
            DATABASE::"Ship-to Address", ShipToAddress.GetPosition(), 0, DATABASE::"Sales Header", SalesHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopyShipToCustomerAddressFieldsFromCustomer', '', false, false)]
    local procedure SalesHeaderOnAfterCopyShipToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer)
    begin
        CopyAddressIDRecord(
            DATABASE::Customer, SellToCustomer.GetPosition(), 0, DATABASE::"Sales Header", SalesHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnUpdateSellToCustOnAfterSetFromSearchContact', '', false, false)]
    local procedure SalesHeaderOnUpdateSellToCustOnAfterSetFromSearchContact(var SalesHeader: Record "Sales Header"; var SearchContact: Record Contact)
    begin
        CopyAddressIDRecord(
            DATABASE::Contact, SearchContact.GetPosition(), 0, DATABASE::"Sales Header", SalesHeader.GetPosition(), 3);
        CopyAddressIDRecord(
            DATABASE::Contact, SearchContact.GetPosition(), 0, DATABASE::"Sales Header", SalesHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SalesHeaderOnAfterDeleteEvent(var Rec: Record "Sales Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Sales Header", Rec.GetPosition(), 0);
    end;

    // Table "Sales Cr.Memo Header"
    [EventSubscriber(ObjectType::Table, Database::"Sales Cr.Memo Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SalesCrMemoHeaderOnAfterDeleteEvent(var Rec: Record "Sales Cr.Memo Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Sales Cr.Memo Header", Rec.GetPosition(), 0);
    end;

    // Table "Sales Invoice Header"
    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SalesInvoiceHeaderOnAfterDeleteEvent(var Rec: Record "Sales Invoice Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Sales Invoice Header", Rec.GetPosition(), 0);
    end;

    // Table "Sales Shipment Header"
    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SalesShipmentHeaderOnAfterDeleteEvent(var Rec: Record "Sales Shipment Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Sales Shipment Header", Rec.GetPosition(), 0);
    end;

    // Codeunit "Sales-Quote to Order"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Order", 'OnAfterInsertSalesOrderHeader', '', false, false)]
    local procedure SalesQuoteToOrderOnAfterInsertSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    begin
        MoveAddressIDRecords(
            DATABASE::"Sales Header", SalesQuoteHeader.GetPosition(),
            DATABASE::"Sales Header", SalesOrderHeader.GetPosition());
    end;

    // Codeunit "Sales-Post"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertPostedHeaders', '', false, false)]
    local procedure SalesPostOnAfterInsertPostedHeaders(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHdr: Record "Sales Cr.Memo Header")
    begin
        if not SalesHeader.Invoice then
            exit;

        if SalesHeader.IsCreditDocType() then
            CopyAddressIDRecords(
                DATABASE::"Sales Header", SalesHeader.GetPosition(),
                DATABASE::"Sales Cr.Memo Header", SalesCrMemoHdr.GetPosition())
        else
            CopyAddressIDRecords(
                DATABASE::"Sales Header", SalesHeader.GetPosition(),
                DATABASE::"Sales Invoice Header", SalesInvoiceHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertShipmentHeader', '', false, false)]
    local procedure SalesPostOnAfterInsertShipmentHeader(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Sales Header", SalesHeader.GetPosition(),
            DATABASE::"Sales Shipment Header", SalesShipmentHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPurchRcptHeaderInsert', '', false, false)]
    local procedure SalesPostOnAfterSalesShptHeaderInsert(PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Purchase Header", PurchaseHeader.GetPosition(),
            DATABASE::"Purch. Rcpt. Header", PurchRcptHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertReturnReceiptHeader', '', false, false)]
    local procedure SalesPostOnAfterInsertReturnReceiptHeader(var SalesHeader: Record "Sales Header"; var ReturnReceiptHeader: Record "Return Receipt Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Sales Header", SalesHeader.GetPosition(),
            DATABASE::"Return Shipment Header", ReturnReceiptHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterDeleteAfterPosting', '', false, false)]
    local procedure PostOnAfterDeleteAfterPosting(SalesHeader: Record "Sales Header")
    begin
        DeleteAllAddressIDRecords(DATABASE::"Sales Header", SalesHeader.GetPosition());
    end;

    // Table "Ship-to Address"
    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ShipToAddressAddress(var Rec: Record "Ship-to Address"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Ship-to Address", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure ShipToAddressAddress2(var Rec: Record "Ship-to Address"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Ship-to Address", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnBeforeValidateCity', '', false, false)]
    local procedure ShipToAddressOnBeforeValidateCity(var ShipToAddress: Record "Ship-to Address"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Ship-to Address", ShipToAddress.GetPosition(), 0,
            ShipToAddress.Name, ShipToAddress."Name 2", ShipToAddress.Contact, ShipToAddress.Address,
            ShipToAddress."Address 2", ShipToAddress.City, ShipToAddress."Post Code",
            ShipToAddress.County, ShipToAddress."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure ShipToAddressOnBeforeValidatePostCode(var ShipToAddress: Record "Ship-to Address"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Ship-to Address", ShipToAddress.GetPosition(), 0,
            ShipToAddress.Name, ShipToAddress."Name 2", ShipToAddress.Contact, ShipToAddress.Address,
            ShipToAddress."Address 2", ShipToAddress.City, ShipToAddress."Post Code",
            ShipToAddress.County, ShipToAddress."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ShipToAddressOnAfterDeleteEvent(var Rec: Record "Ship-to Address")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Ship-to Address", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnAfterRenameEvent', '', false, false)]
    local procedure ShipToAddressOnAfterRenameEvent(var Rec: Record "Ship-to Address"; var xRec: Record "Ship-to Address")
    begin
        MoveAddressIDRecord(
          DATABASE::"Ship-to Address", xRec.GetPosition(), 0, DATABASE::"Ship-to Address", Rec.GetPosition(), 0);
    end;

    // Table "Transfer Header" 
    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateEvent', 'Transfer-from Address', false, false)]
    local procedure TransferHeaderTransferFromAddress(var Rec: Record "Transfer Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Transfer Header", Rec.GetPosition(), 6,
            Rec."Transfer-from Name", Rec."Transfer-from Name 2", Rec."Transfer-from Contact",
            Rec."Transfer-from Address", Rec."Transfer-from Address 2", Rec."Transfer-from City",
            Rec."Transfer-from Post Code", Rec."Transfer-from County", Rec."Trsf.-from Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateEvent', 'Transfer-from Address 2', false, false)]
    local procedure TransferHeaderTransferFromAddress2(var Rec: Record "Transfer Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Transfer Header", Rec.GetPosition(), 6,
            Rec."Transfer-from Name", Rec."Transfer-from Name 2", Rec."Transfer-from Contact",
            Rec."Transfer-from Address", Rec."Transfer-from Address 2", Rec."Transfer-from City",
            Rec."Transfer-from Post Code", Rec."Transfer-from County", Rec."Trsf.-from Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateEvent', 'Transfer-to Address', false, false)]
    local procedure TransferHeaderTransferToAddress(var Rec: Record "Transfer Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Transfer Header", Rec.GetPosition(), 7,
            Rec."Transfer-to Name", Rec."Transfer-to Name 2", Rec."Transfer-to Contact",
            Rec."Transfer-to Address", Rec."Transfer-to Address 2", Rec."Transfer-to City",
            Rec."Transfer-to Post Code", Rec."Transfer-to County", Rec."Trsf.-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateEvent', 'Transfer-to Address 2', false, false)]
    local procedure TransferHeaderTransferToAddress2(var Rec: Record "Transfer Header"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Transfer Header", Rec.GetPosition(), 7,
            Rec."Transfer-to Name", Rec."Transfer-to Name 2", Rec."Transfer-to Contact",
            Rec."Transfer-to Address", Rec."Transfer-to Address 2", Rec."Transfer-to City",
            Rec."Transfer-to Post Code", Rec."Transfer-to County", Rec."Trsf.-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateTransferFromCity', '', false, false)]
    local procedure TransferHeaderOnBeforeValidateTransferFromCity(var TransferHeader: Record "Transfer Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Transfer Header", TransferHeader.GetPosition(), 6,
            TransferHeader."Transfer-from Name", TransferHeader."Transfer-from Name 2", TransferHeader."Transfer-from Contact",
            TransferHeader."Transfer-from Address", TransferHeader."Transfer-from Address 2", TransferHeader."Transfer-from City",
            TransferHeader."Transfer-from Post Code", TransferHeader."Transfer-from County", TransferHeader."Trsf.-from Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateTransferFromPostCode', '', false, false)]
    local procedure TransferHeaderOnBeforeValidateTransferFromPostCode(var TransferHeader: Record "Transfer Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Transfer Header", TransferHeader.GetPosition(), 6,
            TransferHeader."Transfer-from Name", TransferHeader."Transfer-from Name 2", TransferHeader."Transfer-from Contact",
            TransferHeader."Transfer-from Address", TransferHeader."Transfer-from Address 2", TransferHeader."Transfer-from City",
            TransferHeader."Transfer-from Post Code", TransferHeader."Transfer-from County", TransferHeader."Trsf.-from Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateTransferToCity', '', false, false)]
    local procedure TransferHeaderOnBeforeValidateTransferToCity(var TransferHeader: Record "Transfer Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Transfer Header", TransferHeader.GetPosition(), 7,
            TransferHeader."Transfer-to Name", TransferHeader."Transfer-to Name 2", TransferHeader."Transfer-to Contact",
            TransferHeader."Transfer-to Address", TransferHeader."Transfer-to Address 2", TransferHeader."Transfer-to City",
            TransferHeader."Transfer-to Post Code", TransferHeader."Transfer-to County", TransferHeader."Trsf.-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeValidateTransferToPostCode', '', false, false)]
    local procedure TransferHeaderOnBeforeValidateTransferToPostCode(var TransferHeader: Record "Transfer Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Transfer Header", TransferHeader.GetPosition(), 7,
            TransferHeader."Transfer-to Name", TransferHeader."Transfer-to Name 2", TransferHeader."Transfer-to Contact",
            TransferHeader."Transfer-to Address", TransferHeader."Transfer-to Address 2", TransferHeader."Transfer-to City",
            TransferHeader."Transfer-to Post Code", TransferHeader."Transfer-to County", TransferHeader."Trsf.-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterInitFromTransferFromLocation', '', false, false)]
    local procedure TransferHeaderOnAfterInitFromTransferFromLocation(var TransferHeader: Record "Transfer Header"; Location: Record Location)
    begin
        CopyAddressIDRecord(
            DATABASE::Location, Location.GetPosition(), 0,
            DATABASE::"Transfer Header", TransferHeader.GetPosition(), 6);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterInitFromTransferToLocation', '', false, false)]
    local procedure TransferHeaderOnAfterInitFromTransferToLocation(var TransferHeader: Record "Transfer Header"; Location: Record Location)
    begin
        CopyAddressIDRecord(
            DATABASE::Location, Location.GetPosition(), 0,
            DATABASE::"Transfer Header", TransferHeader.GetPosition(), 7);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure TransferHeaderOnAfterDeleteEvent(var Rec: Record "Transfer Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Transfer Header", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterRenameEvent', '', false, false)]
    local procedure TransferHeaderOnAfterRenameEvent(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header")
    begin
        MoveAddressIDRecord(
          DATABASE::"Transfer Header", xRec.GetPosition(), 0, DATABASE::"Transfer Header", Rec.GetPosition(), 0);
    end;

    // Table "Transfer Receipt Header"
    [EventSubscriber(ObjectType::Table, Database::"Transfer Receipt Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure TransferReceiptHeaderOnAfterDeleteEvent(var Rec: Record "Transfer Receipt Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Transfer Receipt Header", Rec.GetPosition(), 0);
    end;

    // Table "Transfer Shipment Header"
    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure TransferShipmentHeaderOnAfterDeleteEvent(var Rec: Record "Transfer Shipment Header")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Transfer Shipment Header", Rec.GetPosition(), 0);
    end;

    // Codeunit "TransferOrder-Post Receipt"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptHeader', '', false, false)]
    local procedure TransferOrderPostReceipt(var TransHeader: Record "Transfer Header"; var TransRcptHeader: Record "Transfer Receipt Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Transfer Header", TransHeader.GetPosition(),
            DATABASE::"Transfer Receipt Header", TransRcptHeader.GetPosition());
    end;

    // Codeunit "TransferOrder-Post Shipment"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptHeader', '', false, false)]
    local procedure TransferOrderPostShipment(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        CopyAddressIDRecords(
            DATABASE::"Transfer Header", TransferHeader.GetPosition(),
            DATABASE::"Transfer Shipment Header", TransferShipmentHeader.GetPosition());
    end;

    // Table Vendor
    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure VendorAddress(var Rec: Record Vendor; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Vendor, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure VendorAddress2(var Rec: Record Vendor; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Vendor, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnBeforeValidateCity', '', false, false)]
    local procedure VendorOnBeforeValidateCity(var Vendor: Record Vendor; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::Vendor, Vendor.GetPosition(), 0,
            Vendor.Name, Vendor."Name 2", Vendor.Contact, Vendor.Address,
            Vendor."Address 2", Vendor.City, Vendor."Post Code", Vendor.County,
            Vendor."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnBeforeValidatePostCode', '', false, false)]
    local procedure VendorOnBeforeValidatePostCode(var Vendor: Record Vendor; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::Vendor, Vendor.GetPosition(), 0,
            Vendor.Name, Vendor."Name 2", Vendor.Contact, Vendor.Address,
            Vendor."Address 2", Vendor.City, Vendor."Post Code", Vendor.County,
            Vendor."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterDeleteEvent', '', false, false)]
    local procedure VendorOnAfterDeleteEvent(var Rec: Record Vendor)
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::Vendor, Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterRenameEvent', '', false, false)]
    local procedure VendorOnAfterRenameEvent(var Rec: Record Vendor; var xRec: Record Vendor)
    begin
        MoveAddressIDRecord(
          DATABASE::Vendor, xRec.GetPosition(), 0, DATABASE::Vendor, Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Delete Invd Blnkt Purch Orders", 'OnBeforeDeletePurchaseHeader', '', false, false)]
    local procedure DeleteInvdBlnktPurchOrders(var PurchaseHeader: Record "Purchase Header")
    begin
        DeleteAllAddressIDRecords(DATABASE::"Purchase Header", PurchaseHeader.GetPosition());
    end;

    // Table Vendor Bank Account

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure VendorBankAccountAddress(var Rec: Record "Vendor Bank Account"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::Customer, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure VendorBankAccountAddress2(var Rec: Record "Vendor Bank Account"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Vendor Bank Account", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec.Contact, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnBeforeValidateCity', '', false, false)]
    local procedure VendorBankAccountOnBeforeValidateCity(var VendorBankAccount: Record "Vendor Bank Account"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Vendor Bank Account", VendorBankAccount.GetPosition(), 0,
            VendorBankAccount.Name, VendorBankAccount."Name 2", VendorBankAccount.Contact,
            VendorBankAccount.Address, VendorBankAccount."Address 2", VendorBankAccount.City,
            VendorBankAccount."Post Code", VendorBankAccount.County, VendorBankAccount."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure VendorBankAccountOnBeforeValidatePostCode(var VendorBankAccount: Record "Vendor Bank Account"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Vendor Bank Account", VendorBankAccount.GetPosition(), 0,
            VendorBankAccount.Name, VendorBankAccount."Name 2", VendorBankAccount.Contact,
            VendorBankAccount.Address, VendorBankAccount."Address 2", VendorBankAccount.City,
            VendorBankAccount."Post Code", VendorBankAccount.County, VendorBankAccount."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnAfterDeleteEvent', '', false, false)]
    local procedure VendorBankAccountOnAfterDeleteEvent(var Rec: Record "Vendor Bank Account")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Vendor Bank Account", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnAfterRenameEvent', '', false, false)]
    local procedure VendorBankAccountOnAfterRenameEvent(var Rec: Record "Vendor Bank Account"; var xRec: Record "Vendor Bank Account")
    begin
        MoveAddressIDRecord(
            DATABASE::"Vendor Bank Account", xRec.GetPosition(), 0,
            DATABASE::"Vendor Bank Account", Rec.GetPosition(), 0);
    end;

    // Reports

    [EventSubscriber(ObjectType::Report, Report::"Delete Invd Blnkt Sales Orders", 'OnBeforeDeleteSalesHeader', '', false, false)]
    local procedure DeleteInvdBlnktSalesOrders(var SalesHeader: Record "Sales Header")
    begin
        DeleteAllAddressIDRecords(DATABASE::"Sales Header", SalesHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Delete Invd Purch. Ret. Orders", 'OnBeforeDeletePurchaseHeader', '', false, false)]
    local procedure DeleteInvdPurchRetOrders(var PurchaseHeader: Record "Purchase Header")
    begin
        DeleteAllAddressIDRecords(DATABASE::"Purchase Header", PurchaseHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Delete Invd Sales Ret. Orders", 'OnBeforeDeleteSalesOrderHeader', '', false, false)]
    local procedure DeleteInvdSalesRetOrders(var SalesHeader: Record "Sales Header")
    begin
        DeleteAllAddressIDRecords(DATABASE::"Sales Header", SalesHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Delete Invoiced Purch. Orders", 'OnBeforeDeletePurchaseHeader', '', false, false)]
    local procedure DeleteInvoicedPurchOrders(var PurchaseHeader: Record "Purchase Header")
    begin
        DeleteAllAddressIDRecords(DATABASE::"Purchase Header", PurchaseHeader.GetPosition());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Delete Invoiced Sales Orders", 'OnBeforeDeleteSalesHeader', '', false, false)]
    local procedure DeleteInvoicedSalesOrders(var SalesHeader: Record "Sales Header")
    begin
        DeleteAllAddressIDRecords(DATABASE::"Sales Header", SalesHeader.GetPosition());
    end;

    // Table "Union"
    [EventSubscriber(ObjectType::Table, Database::Union, 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure UnionAddress(var Rec: Record Union; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, Database::Union, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Union, 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure UnionAddress2(var Rec: Record Union; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, Database::Union, Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::Union, 'OnBeforeValidateCity', '', false, false)]
    local procedure UnionOnBeforeValidateCity(var Union: Record Union; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, Database::Union, Union.GetPosition(), 0,
            Union.Name, Union."Name 2", ContactName,
            Union.Address, Union."Address 2", Union.City,
            Union."Post Code", Union.County, Union."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Union, 'OnBeforeValidatePostCode', '', false, false)]
    local procedure UnionOnBeforeValidatePostCode(var Union: Record Union; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, Database::Union, Union.GetPosition(), 0,
            Union.Name, Union."Name 2", ContactName,
            Union.Address, Union."Address 2", Union.City,
            Union."Post Code", Union.County, Union."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Union, 'OnAfterDeleteEvent', '', false, false)]
    local procedure UnionOnAfterDeleteEvent(var Rec: Record Union)
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(Database::Union, Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Union, 'OnAfterRenameEvent', '', false, false)]
    local procedure UnionOnAfterRenameEvent(var Rec: Record Union; var xRec: Record Union)
    begin
        MoveAddressIDRecord(
          Database::Union, xRec.GetPosition(), 0, Database::Union, Rec.GetPosition(), 0);
    end;

#if not CLEAN28
    // Table "Work Center"
    [EventSubscriber(ObjectType::Table, Database::"Work Center", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure WorkCenterAddress(var Rec: Record "Work Center"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Work Center", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure WorkCenterAddress2(var Rec: Record "Work Center"; CurrFieldNo: Integer)
    begin
        VerifyAddress(
            CurrFieldNo, DATABASE::"Work Center", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", ContactName, Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", 'OnBeforeValidateCity', '', false, false)]
    local procedure WorkCenterOnBeforeValidateCity(var WorkCenter: Record "Work Center"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyCity(
            CurrentFieldNo, DATABASE::"Work Center", WorkCenter.GetPosition(), 0,
            WorkCenter.Name, WorkCenter."Name 2", ContactName,
            WorkCenter.Address, WorkCenter."Address 2", WorkCenter.City,
            WorkCenter."Post Code", WorkCenter.County, WorkCenter."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure WorkCenterOnBeforeValidatePostCode(var WorkCenter: Record "Work Center"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        VerifyPostCode(
            CurrentFieldNo, DATABASE::"Work Center", WorkCenter.GetPosition(), 0,
            WorkCenter.Name, WorkCenter."Name 2", ContactName,
            WorkCenter.Address, WorkCenter."Address 2", WorkCenter.City,
            WorkCenter."Post Code", WorkCenter.County, WorkCenter."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", 'OnAfterDeleteEvent', '', false, false)]
    local procedure WorkCenterOnAfterDeleteEvent(var Rec: Record "Work Center")
    begin
        if Rec.IsTemporary() then
            exit;

        DeleteAddressIDRecords(DATABASE::"Work Center", Rec.GetPosition(), 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", 'OnAfterRenameEvent', '', false, false)]
    local procedure WorkCenterOnAfterRenameEvent(var Rec: Record "Work Center"; var xRec: Record "Work Center")
    begin
        MoveAddressIDRecord(
          DATABASE::"Work Center", xRec.GetPosition(), 0, DATABASE::"Work Center", Rec.GetPosition(), 0);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterVerifyCity(var PostCodeRec: Record "Post Code"; var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVerifyPostCode(var PostCodeRec: Record "Post Code"; var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyPostCodeOnAfterFilterPostCode(var PostCodeRec: Record "Post Code"; CountryCode: Code[10])
    begin
    end;
}
