// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Globalization;

table 318 "Tax Area"
{
    Caption = 'Tax Area';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Tax Area List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if IsTaxAreaInUse() then
            Error(TaxAreaInUseErr);
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime();
    end;

    var
        TaxAreaInUseErr: Label 'You cannot delete this tax rate because it is used on one or more existing documents.';

    procedure CreateTaxArea(NewTaxAreaCode: Code[20]; City: Text[50]; State: Text[50])
    begin
        Init();
        Code := NewTaxAreaCode;
        Description := NewTaxAreaCode;
        if Insert() then;

        if City <> '' then
            CreateTaxAreaLine(Code, CopyStr(City, 1, 10));
        if State <> '' then
            CreateTaxAreaLine(Code, CopyStr(State, 1, 10));
        if (City = '') and (State = '') then
            CreateTaxAreaLine(Code, CopyStr(NewTaxAreaCode, 1, 10));
    end;

    local procedure CreateTaxAreaLine(NewTaxArea: Code[20]; NewJurisdictionCode: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if TaxAreaLine.Get(NewTaxArea, NewJurisdictionCode) then
            exit;
        TaxAreaLine.Init();
        TaxAreaLine."Tax Area" := NewTaxArea;
        TaxAreaLine."Tax Jurisdiction Code" := NewJurisdictionCode;
        TaxAreaLine.Insert();
        TaxJurisdiction.CreateTaxJurisdiction(NewJurisdictionCode);
    end;

    procedure GetDescriptionInCurrentLanguageFullLength(): Text[100]
    var
        TaxAreaTranslation: Record "Tax Area Translation";
        Language: Codeunit Language;
    begin
        if TaxAreaTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(TaxAreaTranslation.Description);

        exit(Description);
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    local procedure IsTaxAreaInUse(): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
    begin
        Customer.SetRange("Tax Area Code", Code);
        if not Customer.IsEmpty() then
            exit(true);

        SalesHeader.SetRange("Tax Area Code", Code);
        if not SalesHeader.IsEmpty() then
            exit(true);

        SalesInvoiceHeader.SetRange("Tax Area Code", Code);
        if not SalesInvoiceHeader.IsEmpty() then
            exit(true);

        exit(false);
    end;
}
