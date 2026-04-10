// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

table 730 "Standard Address"
{
    Caption = 'Standard Address';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Related RecordID"; RecordID)
        {
            Caption = 'Related RecordID';
            DataClassification = CustomerContent;
        }
        field(2; "Address Type"; Option)
        {
            Caption = 'Address Type';
            OptionCaption = ' ,Sell-to,Bill-to';
            OptionMembers = " ","Sell-to","Bill-to";
        }
        field(3; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(4; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(5; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()

            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(6; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
    }

    keys
    {
        key(Key1; "Related RecordID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if not IsTemporary then
            Error(DevMsgNotTemporaryErr);
    end;

    var
        PostCode: Record "Post Code";
        FormatAddress: Codeunit "Format Address";

        DevMsgNotTemporaryErr: Label 'This function can only be used when the record is temporary.';

    procedure ToString() FullAddress: Text
    var
        AddressArray: array[8] of Text[100];
        AddressPosition: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeToString(Rec, FullAddress, IsHandled);
        if IsHandled then
            exit(FullAddress);

        FormatAddress.FormatAddr(AddressArray, '', '', '', Address, "Address 2", City, "Post Code", County, "Country/Region Code");
        for AddressPosition := 1 to 8 do begin
            AddressArray[AddressPosition] := DelChr(AddressArray[AddressPosition], '<', ', ');
            if AddressArray[AddressPosition] <> '' then
                if FullAddress = '' then
                    FullAddress := AddressArray[AddressPosition]
                else
                    FullAddress += ', ' + AddressArray[AddressPosition];
        end;
    end;

    procedure CopyFromCustomer(Customer: Record Customer)
    begin
        Init();
        "Related RecordID" := Customer.RecordId;
        Address := Customer.Address;
        "Address 2" := Customer."Address 2";
        City := Customer.City;
        "Country/Region Code" := Customer."Country/Region Code";
        "Post Code" := Customer."Post Code";
        County := Customer.County;
        OnCopyFromCustomerOnBeforeInsert(Rec, Customer);
        Insert(true);
    end;

    procedure CopyFromCompanyInformation(CompanyInformation: Record "Company Information")
    begin
        Init();
        "Related RecordID" := CompanyInformation.RecordId;
        Address := CompanyInformation.Address;
        "Address 2" := CompanyInformation."Address 2";
        City := CompanyInformation.City;
        "Country/Region Code" := CompanyInformation."Country/Region Code";
        "Post Code" := CompanyInformation."Post Code";
        County := CompanyInformation.County;
        Insert(true);
    end;

    procedure CopyFromSalesHeaderSellTo(SalesHeader: Record "Sales Header")
    begin
        Init();
        "Address Type" := "Address Type"::"Sell-to";
        "Related RecordID" := SalesHeader.RecordId;
        Address := SalesHeader."Sell-to Address";
        "Address 2" := SalesHeader."Sell-to Address 2";
        City := SalesHeader."Sell-to City";
        "Country/Region Code" := SalesHeader."Sell-to Country/Region Code";
        "Post Code" := SalesHeader."Sell-to Post Code";
        County := SalesHeader."Sell-to County";
        Insert(true);
    end;

    procedure CopyFromSalesInvoiceHeaderSellTo(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        Init();
        "Address Type" := "Address Type"::"Sell-to";
        "Related RecordID" := SalesInvoiceHeader.RecordId;
        Address := SalesInvoiceHeader."Sell-to Address";
        "Address 2" := SalesInvoiceHeader."Sell-to Address 2";
        City := SalesInvoiceHeader."Sell-to City";
        "Country/Region Code" := SalesInvoiceHeader."Sell-to Country/Region Code";
        "Post Code" := SalesInvoiceHeader."Sell-to Post Code";
        County := SalesInvoiceHeader."Sell-to County";
        Insert(true);
    end;

    procedure SaveToRecord()
    var
        RecID: RecordID;
    begin
        RecID := "Related RecordID";
        case RecID.TableNo of
            DATABASE::Customer:
                SaveToCustomer();
            DATABASE::"Company Information":
                SaveToCompanyInformation();
            DATABASE::"Sales Header":
                case "Address Type" of
                    "Address Type"::"Sell-to":
                        SaveToSalesHeaderSellTo();
                end;
        end;
    end;

    local procedure SaveToCustomer()
    var
        Customer: Record Customer;
    begin
        Customer.LockTable();
        Customer.Get("Related RecordID");
        Customer.Validate(Address, Address);
        Customer.Validate("Address 2", "Address 2");
        Customer.Validate(City, City);
        Customer.Validate("Country/Region Code", "Country/Region Code");
        Customer.Validate("Post Code", "Post Code");
        Customer.Validate(County, County);
        OnSaveToCustomerOnBeforeModify(Rec, Customer);
        Customer.Modify(true);
    end;

    local procedure SaveToCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.LockTable();
        CompanyInformation.Get("Related RecordID");
        CompanyInformation.Validate(Address, Address);
        CompanyInformation.Validate("Address 2", "Address 2");
        CompanyInformation.Validate(City, City);
        CompanyInformation.Validate("Country/Region Code", "Country/Region Code");
        CompanyInformation.Validate("Post Code", "Post Code");
        CompanyInformation.Validate(County, County);
        CompanyInformation.Modify(true);
    end;

    local procedure SaveToSalesHeaderSellTo()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.LockTable();
        SalesHeader.Get("Related RecordID");
        SalesHeader.Validate("Sell-to Address", Address);
        SalesHeader.Validate("Sell-to Address 2", "Address 2");
        SalesHeader.Validate("Sell-to City", City);
        SalesHeader.Validate("Sell-to Country/Region Code", "Country/Region Code");
        SalesHeader.Validate("Sell-to Post Code", "Post Code");
        SalesHeader.Validate("Sell-to County", County);
        SalesHeader.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToString(var StandardAddress: Record "Standard Address"; var FullAddress: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveToCustomerOnBeforeModify(StandardAddress: Record "Standard Address"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromCustomerOnBeforeInsert(var StandardAddress: Record "Standard Address"; var Customer: Record Customer)
    begin
    end;
}

