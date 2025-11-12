// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.DateTime;

table 225 "Post Code"
{
    Caption = 'Post Code';
    LookupPageID = "Post Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            OptimizeForTextSearch = true;
            NotBlank = true;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                PostCode.SetRange("Search City", "Search City");
                PostCode.SetRange(Code, Code);
                if not PostCode.IsEmpty() then
                    Error(CodeCityAlreadyExistsErr, FieldCaption(Code), Code);
            end;
        }
        field(2; City; Text[30])
        {
            Caption = 'City';
            OptimizeForTextSearch = true;
            NotBlank = true;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCityField(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;
                TestField(Code);
                "Search City" := City;
                if xRec."Search City" <> "Search City" then begin
                    PostCode.SetRange("Search City", "Search City");
                    PostCode.SetRange(Code, Code);
                    if not PostCode.IsEmpty() then
                        Error(CodeCityAlreadyExistsErr, FieldCaption(City), City);
                end;
            end;
        }
        field(3; "Search City"; Code[30])
        {
            Caption = 'Search City';
        }
        field(4; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(5; County; Text[30])
        {
            Caption = 'County';
            OptimizeForTextSearch = true;
        }
        field(30; "Time Zone"; Text[180])
        {

            trigger OnLookup()
            var
                TimeZoneID: Text[180];
            begin
                if TimeZoneSelection.LookupTimeZone(TimeZoneID) then
                    "Time Zone" := TimeZoneID;
            end;

            trigger OnValidate()
            begin
                TimeZoneSelection.ValidateTimeZone("Time Zone");
            end;
        }
    }

    keys
    {
        key(Key1; "Code", City)
        {
            Clustered = true;
        }
        key(Key2; City, "Code")
        {
        }
        key(Key3; "Search City")
        {
        }
        key(Key4; "Country/Region Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", City, "Country/Region Code", County)
        {
        }
        fieldgroup(Brick; "Code", City, County, "Country/Region Code")
        {
        }
    }

    var
        TimeZoneSelection: Codeunit "Time Zone Selection";
        CodeCityAlreadyExistsErr: Label '%1 %2 already exists.', Comment = '%1 = Post code ; %2 = City name';

    procedure ValidateCity(var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; UseDialog: Boolean)
    var
        PostCodeRec: Record "Post Code";
        PostCodeRec2: Record "Post Code";
        SearchCity: Code[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCityProcedure(CityTxt, PostCode, CountyTxt, CountryCode, UseDialog, IsHandled);
        if not IsHandled then begin
            if not GuiAllowed then
                exit;

            if CityTxt <> '' then begin
                SearchCity := CityTxt;
                PostCodeRec.SetCurrentKey("Search City");
                if StrPos(SearchCity, '*') = StrLen(SearchCity) then
                    PostCodeRec.SetFilter("Search City", SearchCity)
                else
                    PostCodeRec.SetRange("Search City", SearchCity);
                if not PostCodeRec.FindFirst() then
                    exit;

                if CountryCode <> '' then begin
                    PostCodeRec.SetRange("Country/Region Code", CountryCode);
                    if not PostCodeRec.FindFirst() then
                        PostCodeRec.SetRange("Country/Region Code");
                end;

                PostCodeRec2.Copy(PostCodeRec);
                if UseDialog and (PostCodeRec2.Next() = 1) then
                    if PAGE.RunModal(PAGE::"Post Codes", PostCodeRec, PostCodeRec.Code) <> ACTION::LookupOK then
                        Error('');

                if UseDialog or (PostCode = '') then
                    PostCode := PostCodeRec.Code;

                CityTxt := PostCodeRec.City;
                CountryCode := PostCodeRec."Country/Region Code";
                CountyTxt := PostCodeRec.County;

                OnValidateCityOnAfterSelectPostCode(PostCodeRec, CityTxt, PostCode, CountyTxt, CountryCode, UseDialog);
            end;
        end;
        OnAfterValidateCity(Rec, CityTxt, PostCode, CountyTxt, CountryCode, UseDialog);
    end;

    procedure ValidatePostCode(var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; UseDialog: Boolean)
    var
        PostCodeRec: Record "Post Code";
        PostCodeRec2: Record "Post Code";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidatePostCode(CityTxt, PostCode, CountyTxt, CountryCode, UseDialog, IsHandled);
        if IsHandled then
            exit;

        if PostCode <> '' then begin
            if IsFilter(PostCode) then
                PostCodeRec.SetFilter(Code, PostCode)
            else
                PostCodeRec.SetRange(Code, PostCode);
            OnValidatePostCodeOnAfterSetFilters(PostCodeRec);
            if not PostCodeRec.FindFirst() then
                exit;

            if CountryCode <> '' then begin
                PostCodeRec.SetRange("Country/Region Code", CountryCode);
                if not PostCodeRec.FindFirst() then
                    PostCodeRec.SetRange("Country/Region Code");
            end;

            if not (UseDialog and IsFilter(PostCode)) then
                if CityTxt <> '' then begin
                    PostCodeRec.SetRange("Search City", CityTxt);
                    if not PostCodeRec.FindFirst() then
                        PostCodeRec.SetRange("Search City");
                end;

            PostCodeRec2.Copy(PostCodeRec);
            if UseDialog and (PostCodeRec2.Next() = 1) and GuiAllowed then
                if PAGE.RunModal(PAGE::"Post Codes", PostCodeRec, PostCodeRec.Code) <> ACTION::LookupOK then
                    exit;
            PostCode := PostCodeRec.Code;
            CityTxt := PostCodeRec.City;
            CountryCode := PostCodeRec."Country/Region Code";
            CountyTxt := PostCodeRec.County;

            OnValidatePostCodeOnAfterSelectPostCode(PostCodeRec, CityTxt, PostCode, CountyTxt, CountryCode, UseDialog);
        end;

        OnAfterValidatePostCode(Rec, CityTxt, PostCode, CountyTxt, CountryCode, UseDialog);
    end;

    procedure UpdateFromSalesHeader(SalesHeader: Record "Sales Header"; PostCodeChanged: Boolean)
    begin
        CreatePostCode(SalesHeader."Sell-to Post Code", SalesHeader."Sell-to City",
          SalesHeader."Sell-to Country/Region Code", SalesHeader."Sell-to County", PostCodeChanged);
    end;

    procedure UpdateFromCustomer(Customer: Record Customer; PostCodeChanged: Boolean)
    begin
        CreatePostCode(Customer."Post Code", Customer.City,
          Customer."Country/Region Code", Customer.County, PostCodeChanged);
    end;

    procedure UpdateFromCompanyInformation(CompanyInformation: Record "Company Information"; PostCodeChanged: Boolean)
    begin
        CreatePostCode(CompanyInformation."Post Code", CompanyInformation.City,
          CompanyInformation."Country/Region Code", CompanyInformation.County, PostCodeChanged);
    end;

    procedure UpdateFromStandardAddress(StandardAddress: Record "Standard Address"; PostCodeChanged: Boolean)
    begin
        CreatePostCode(StandardAddress."Post Code", StandardAddress.City,
          StandardAddress."Country/Region Code", StandardAddress.County, PostCodeChanged);
    end;

    local procedure CreatePostCode(NewPostCode: Code[20]; NewCity: Text[30]; NewCountryRegion: Code[10]; NewCounty: Text[30]; PostCodeChanged: Boolean)
    begin
        if NewPostCode = '' then
            exit;

        SetRange(Code, NewPostCode);
        if FindFirst() then begin
            if PostCodeChanged then
                exit; // If the post code was updated, then don't insert the city for the old post code into the new post code
            if (NewCity <> '') and (City <> NewCity) then
                Rename(NewPostCode, NewCity);
            if NewCountryRegion <> '' then
                "Country/Region Code" := NewCountryRegion;
            if NewCounty <> '' then
                County := NewCounty;
            Modify();
        end else begin
            Init();

            Code := NewPostCode;
            City := NewCity;
            "Country/Region Code" := NewCountryRegion;
            County := NewCounty;
            Insert();
        end;
    end;

    local procedure IsFilter(PostCode: Code[20]): Boolean
    var
        Result: Boolean;
    begin
        Result := StrPos(PostCode, '*') = StrLen(PostCode);
        exit(Result);
    end;

    procedure ValidateCountryCode(var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10])
    var
        PostCodeRec: Record "Post Code";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCountryCode(CityTxt, PostCode, CountyTxt, CountryCode, IsHandled);
        if IsHandled then
            exit;
        if xRec."Country/Region Code" = CountryCode then
            exit;
        if (CountryCode = '') or (PostCode = '') then
            exit;

        PostCodeRec.SetRange("Country/Region Code", CountryCode);
        PostCodeRec.SetRange(Code, PostCode);
        if PostCodeRec.FindFirst() then begin
            PostCode := PostCodeRec.Code;
            CityTxt := PostCodeRec.City;
            CountryCode := PostCodeRec."Country/Region Code";
            CountyTxt := PostCodeRec.County;
        end;
    end;

    procedure CheckClearPostCodeCityCounty(var CityTxt: Text; var PostCode: Code[20]; var CountyTxt: Text; var CountryCode: Code[10]; xCountryCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckClearPostCodeCityCounty(CityTxt, PostCode, CountyTxt, CountryCode, xCountryCode, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        if GLSetup."Req.Country/Reg. Code in Addr." then
            exit;

        if (xCountryCode = CountryCode) or (xCountryCode = '') then
            exit;

        PostCode := '';
        CityTxt := '';
        CountyTxt := '';
    end;

    procedure LookupPostCode(var CityTxt: Text; var PostCode: Code[20]; var CountyTxt: Text; var CountryCode: Code[10])
    var
        PostCodeRec: Record "Post Code";
        PostCodes: Page "Post Codes";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupPostCode(CityTxt, PostCode, CountyTxt, CountryCode, IsHandled);
        if IsHandled then
            exit;

        if CountryCode <> '' then begin
            PostCodeRec.SetRange("Country/Region Code", CountryCode);
            PostCodes.SetTableView(PostCodeRec);
        end;

        if PostCodeRec.Get(PostCode, CityTxt) then
            PostCodes.SetRecord(PostCodeRec);

        PostCodes.LookupMode := true;
        if PostCodes.RunModal() = ACTION::LookupOK then begin
            PostCodes.GetRecord(PostCodeRec);
            PostCode := PostCodeRec.Code;
            CityTxt := PostCodeRec.City;
            CountryCode := PostCodeRec."Country/Region Code";
            CountyTxt := PostCodeRec.County;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCity(var PostCodeRec: Record "Post Code"; var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; UseDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostCode(var PostCodeRec: Record "Post Code"; var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; UseDialog: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckClearPostCodeCityCounty(var CityTxt: Text; var PostCode: Code[20]; var CountyTxt: Text; var CountryCode: Code[10]; xCountryCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupPostCode(var CityTxt: Text; var PostCode: Code[20]; var CountyTxt: Text; var CountryCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateCityProcedure(var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; UseDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCityField(var PostCode: Record "Post Code"; xPostCode: Record "Post Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCode(var PostCode: Record "Post Code"; xPostCode: Record "Post Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateCountryCode(var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidatePostCode(var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; var UseDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostCodeOnAfterSetFilters(var PostCodeRec: Record "Post Code");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCityOnAfterSelectPostCode(var PostCodeRec: Record "Post Code"; var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; UseDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostCodeOnAfterSelectPostCode(var PostCodeRec: Record "Post Code"; var CityTxt: Text[30]; var PostCode: Code[20]; var CountyTxt: Text[30]; var CountryCode: Code[10]; UseDialog: Boolean)
    begin
    end;
}
