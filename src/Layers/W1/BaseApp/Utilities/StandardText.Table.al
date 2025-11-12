// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.ExtendedText;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

table 7 "Standard Text"
{
    Caption = 'Standard Text';
    LookupPageID = "Standard Text Codes";
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
        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"Standard Text");
        ExtTextHeader.SetRange("No.", Code);
        ExtTextHeader.DeleteAll(true);
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::" ", xRec.Code, Code);
        PurchaseLine.RenameNo(PurchaseLine.Type::" ", xRec.Code, Code);
        JobPlanningLine.RenameNo(JobPlanningLine.Type::Text, xRec.Code, Code);
    end;

    var
        ExtTextHeader: Record "Extended Text Header";
}

