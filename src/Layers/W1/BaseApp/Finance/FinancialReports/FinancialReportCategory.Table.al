// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 8391 "Financial Report Category"
{
    Caption = 'Financial Report Category';
    DataClassification = CustomerContent;
    DrillDownPageId = "Financial Report Category";
    LookupPageId = "Financial Report Categories";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unique code of the category.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the category name.';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the category description.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Code, Name) { }
    }

    procedure OpenWhereUsed()
    var
        FinancialReport: Record "Financial Report";
    begin
        FinancialReport.SetRange(CategoryCode, Code);
        Page.Run(0, FinancialReport);
    end;
}