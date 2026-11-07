// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Address;

table 6925 "Expense Location"
{
    Access = Internal;
    Caption = 'Expense Location';
    DataClassification = CustomerContent;
    DrillDownPageId = "Expense Location Card";
    LookupPageId = "Expense Locations";
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(4; "City"; Text[30])
        {
            Caption = 'City';
            OptimizeForTextSearch = true;
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(5; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        CheckExpenseLocation();
    end;

    trigger OnModify()
    begin
        CheckExpenseLocation();
    end;

    var
        ConflictingExpenseLocationErr: Label 'Expense Location %1 conflicts with existing Expense Location %2 having the same Country/Region Code %3, County %4, and City %5.', Comment = '%1 - Location No., %2 - Existing Location No., %3 - Country/Region Code, %4 - County, %5 - City';

    local procedure CheckExpenseLocation()
    var
        ExpenseLocation: Record "Expense Location";
    begin
        ExpenseLocation.SetFilter("No.", '<>%1', Rec."No.");
        ExpenseLocation.SetRange("Country/Region Code", Rec."Country/Region Code");
        ExpenseLocation.SetRange(County, Rec.County);
        ExpenseLocation.SetRange(City, Rec.City);
        if ExpenseLocation.FindFirst() then
            Error(ConflictingExpenseLocationErr, Rec."No.", ExpenseLocation."No.", Rec."Country/Region Code", Rec.County, Rec.City);
    end;
}