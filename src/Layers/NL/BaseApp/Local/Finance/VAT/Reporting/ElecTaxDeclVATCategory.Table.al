// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 11411 "Elec. Tax Decl. VAT Category"
{
    Caption = 'Elec. Tax Decl. VAT Category';
    DrillDownPageID = "Elec. Tax Decl. VAT Categ.";
    LookupPageID = "Elec. Tax Decl. VAT Categ.";
    DataClassification = CustomerContent;

    fields
    {
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; Category; Option)
        {
            Caption = 'Category';
            OptionCaption = ' ,,,1. By Us (Domestic),,,2. To Us (Domestic),,,3. By Us (Foreign),,,4. To Us (Foreign),,,,,,5. Calculation';
            OptionMembers = " ",,,"1. By Us (Domestic)",,,"2. To Us (Domestic)",,,"3. By Us (Foreign)",,,"4. To Us (Foreign)",,,,,,"5. Calculation";

            trigger OnValidate()
            begin
                if Category <> Category::"1. By Us (Domestic)" then
                    "By Us (Domestic)" := "By Us (Domestic)"::" ";
                if Category <> Category::"2. To Us (Domestic)" then
                    "To Us (Domestic)" := "To Us (Domestic)"::" ";
                if Category <> Category::"3. By Us (Foreign)" then
                    "By Us (Foreign)" := "By Us (Foreign)"::" ";
                if Category <> Category::"4. To Us (Foreign)" then
                    "To Us (Foreign)" := "To Us (Foreign)"::" ";
                if Category <> Category::"5. Calculation" then
                    Calculation := Calculation::" ";
            end;
        }
        field(20; "By Us (Domestic)"; Option)
        {
            Caption = 'By Us (Domestic)';
            OptionCaption = ' ,,,1a. Sales Amount (High Rate),,,1a. Tax Amount (High Rate),,,1b. Sales Amount (Low Rate),,,1b. Tax Amount (Low Rate),,,1c. Sales Amount (Other Non-Zero Rates),,,1c. Tax Amount (Other Non-Zero Rates),,,1d. Sales Amount (Private Use),,,1d. Tax Amount (Private Use),,,1e. Sales Amount (Non-Taxed)';
            OptionMembers = " ",,,"1a. Sales Amount (High Rate)",,,"1a. Tax Amount (High Rate)",,,"1b. Sales Amount (Low Rate)",,,"1b. Tax Amount (Low Rate)",,,"1c. Sales Amount (Other Non-Zero Rates)",,,"1c. Tax Amount (Other Non-Zero Rates)",,,"1d. Sales Amount (Private Use)",,,"1d. Tax Amount (Private Use)",,,"1e. Sales Amount (Non-Taxed)";

            trigger OnValidate()
            begin
                if "By Us (Domestic)" <> "By Us (Domestic)"::" " then
                    TestField(Category, Category::"1. By Us (Domestic)");

                CheckDuplicates();
            end;
        }
        field(30; "To Us (Domestic)"; Option)
        {
            Caption = 'To Us (Domestic)';
            OptionCaption = ' ,,,2a. Sales Amount (Tax Withheld),,,2a. Tax Amount (Tax Withheld)';
            OptionMembers = " ",,,"2a. Sales Amount (Tax Withheld)",,,"2a. Tax Amount (Tax Withheld)";

            trigger OnValidate()
            begin
                if "To Us (Domestic)" <> "To Us (Domestic)"::" " then
                    TestField(Category, Category::"2. To Us (Domestic)");

                CheckDuplicates();
            end;
        }
        field(40; "By Us (Foreign)"; Option)
        {
            Caption = 'By Us (Foreign)';
            OptionCaption = ' ,,,3a. Sales Amount (Non-EU),,,3b. Sales Amount (EU),,,3c. Sales Amount (Installation)';
            OptionMembers = " ",,,"3a. Sales Amount (Non-EU)",,,"3b. Sales Amount (EU)",,,"3c. Sales Amount (Installation)";

            trigger OnValidate()
            begin
                if "By Us (Foreign)" <> "By Us (Foreign)"::" " then
                    TestField(Category, Category::"3. By Us (Foreign)");

                CheckDuplicates();
            end;
        }
        field(50; "To Us (Foreign)"; Option)
        {
            Caption = 'To Us (Foreign)';
            OptionCaption = ' ,,,4a. Purchase Amount (Non-EU),,,4a. Tax Amount (Non-EU),,,4b. Purchase Amount (EU),,,4b. Tax Amount (EU)';
            OptionMembers = " ",,,"4a. Purchase Amount (Non-EU)",,,"4a. Tax Amount (Non-EU)",,,"4b. Purchase Amount (EU)",,,"4b. Tax Amount (EU)";

            trigger OnValidate()
            begin
                if "To Us (Foreign)" <> "To Us (Foreign)"::" " then
                    TestField(Category, Category::"4. To Us (Foreign)");

                CheckDuplicates();
            end;
        }
        field(100; Calculation; Option)
        {
            Caption = 'Calculation';
            OptionCaption = ' ,,,5a. Tax Amount Due (Subtotal),,,5b. Tax Amount (Paid in Advance),,,5d. Small Entrepeneurs,,,5e. Estimate (Previous Declaration),,,5f. Estimate (This Declaration),,,5g. Tax Amount To Pay/Claim';
            OptionMembers = " ",,,"5a. Tax Amount Due (Subtotal)",,,"5b. Tax Amount (Paid in Advance)",,,"5d. Small Entrepeneurs",,,"5e. Estimate (Previous Declaration)",,,"5f. Estimate (This Declaration)",,,"5g. Tax Amount To Pay/Claim";

            trigger OnValidate()
            begin
                if Calculation <> Calculation::" " then
                    TestField(Category, Category::"5. Calculation");

                CheckDuplicates();
            end;
        }
        field(110; Optional; Boolean)
        {
            Caption = 'Optional';
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
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Reset();
        VATStatementLine.SetCurrentKey("Elec. Tax Decl. Category Code");
        VATStatementLine.SetRange("Elec. Tax Decl. Category Code", Code);
        if VATStatementLine.FindFirst() then
            Error(Text002, TableCaption(), Code);
    end;

    var
        Text000: Label 'An %1 with category %3 and subcategory %5 could not be found.';
        Text001: Label 'Invalid category.';
        Text002: Label '%1 %2 cannot be deleted; one or more VAT statement lines refer to it.';
        Text003: Label '%1 %2 already uses this category and subcategory.';

    procedure GetCategoryCode(Category: Integer; Subcategory: Integer): Code[10]
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        ElecTaxDeclVATCategory.Reset();
        ElecTaxDeclVATCategory.SetRange(Category);

        case Category of
            ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)":
                ElecTaxDeclVATCategory.SetRange("By Us (Domestic)", Subcategory);
            ElecTaxDeclVATCategory.Category::"2. To Us (Domestic)":
                ElecTaxDeclVATCategory.SetRange("To Us (Domestic)", Subcategory);
            ElecTaxDeclVATCategory.Category::"3. By Us (Foreign)":
                ElecTaxDeclVATCategory.SetRange("By Us (Foreign)", Subcategory);
            ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)":
                ElecTaxDeclVATCategory.SetRange("To Us (Foreign)", Subcategory);
            ElecTaxDeclVATCategory.Category::"5. Calculation":
                ElecTaxDeclVATCategory.SetRange(Calculation, Subcategory);
            else
                Error(Text001);
        end;

        if ElecTaxDeclVATCategory.FindFirst() then
            exit(ElecTaxDeclVATCategory.Code);

        ElecTaxDeclVATCategory.Category := Category;
        ElecTaxDeclVATCategory."By Us (Domestic)" := Subcategory;
        ElecTaxDeclVATCategory."To Us (Domestic)" := Subcategory;
        ElecTaxDeclVATCategory."By Us (Foreign)" := Subcategory;
        ElecTaxDeclVATCategory."To Us (Foreign)" := Subcategory;
        ElecTaxDeclVATCategory.Calculation := Subcategory;

        case Category of
            ElecTaxDeclVATCategory.Category::"1. By Us (Domestic)":
                Error(
                  Text000,
                  ElecTaxDeclVATCategory.TableCaption(),
                  ElecTaxDeclVATCategory.FieldCaption(Category),
                  ElecTaxDeclVATCategory.Category,
                  ElecTaxDeclVATCategory.FieldCaption("By Us (Domestic)"),
                  ElecTaxDeclVATCategory."By Us (Domestic)");
            ElecTaxDeclVATCategory.Category::"2. To Us (Domestic)":
                Error(
                  Text000,
                  ElecTaxDeclVATCategory.TableCaption(),
                  ElecTaxDeclVATCategory.FieldCaption(Category),
                  ElecTaxDeclVATCategory.Category,
                  ElecTaxDeclVATCategory.FieldCaption("To Us (Domestic)"),
                  ElecTaxDeclVATCategory."To Us (Domestic)");
            ElecTaxDeclVATCategory.Category::"3. By Us (Foreign)":
                Error(
                  Text000,
                  ElecTaxDeclVATCategory.TableCaption(),
                  ElecTaxDeclVATCategory.FieldCaption(Category),
                  ElecTaxDeclVATCategory.Category,
                  ElecTaxDeclVATCategory.FieldCaption("By Us (Foreign)"),
                  ElecTaxDeclVATCategory."By Us (Foreign)");
            ElecTaxDeclVATCategory.Category::"4. To Us (Foreign)":
                Error(
                  Text000,
                  ElecTaxDeclVATCategory.TableCaption(),
                  ElecTaxDeclVATCategory.FieldCaption(Category),
                  ElecTaxDeclVATCategory.Category,
                  ElecTaxDeclVATCategory.FieldCaption("To Us (Foreign)"),
                  ElecTaxDeclVATCategory."To Us (Foreign)");
            ElecTaxDeclVATCategory.Category::"5. Calculation":
                Error(
                  Text000,
                  ElecTaxDeclVATCategory.TableCaption(),
                  ElecTaxDeclVATCategory.FieldCaption(Category),
                  ElecTaxDeclVATCategory.Category,
                  ElecTaxDeclVATCategory.FieldCaption(Calculation),
                  ElecTaxDeclVATCategory.Calculation);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckDuplicates()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        ElecTaxDeclVATCategory.Reset();
        ElecTaxDeclVATCategory.SetFilter(Code, '<>%1', Code);
        ElecTaxDeclVATCategory.SetRange(Category, Category);
        ElecTaxDeclVATCategory.SetRange("By Us (Domestic)", "By Us (Domestic)");
        ElecTaxDeclVATCategory.SetRange("To Us (Domestic)", "To Us (Domestic)");
        ElecTaxDeclVATCategory.SetRange("By Us (Foreign)", "By Us (Foreign)");
        ElecTaxDeclVATCategory.SetRange("To Us (Foreign)", "To Us (Foreign)");
        ElecTaxDeclVATCategory.SetRange(Calculation, Calculation);

        if ElecTaxDeclVATCategory.FindFirst() then
            Error(Text003, ElecTaxDeclVATCategory.TableCaption(), ElecTaxDeclVATCategory.Code);
    end;
}

