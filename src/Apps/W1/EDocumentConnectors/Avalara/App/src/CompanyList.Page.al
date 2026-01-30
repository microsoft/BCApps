#pragma warning disable AS0035
#pragma warning disable AS0026
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

page 6373 "Company List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Company List';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Avalara Company";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(CompanyList)
            {
                field(CompanyName; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Avalara company name';
                }
                field("Company Id"; Rec."Company Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Company Id field.', Comment = '%';
                }
            }
        }
    }

    procedure SetRecords(var AvalaraCompany: Record "Avalara Company" temporary)
    begin
        if AvalaraCompany.FindSet() then
            repeat
                Rec.TransferFields(AvalaraCompany);
                Rec.Insert();
            until AvalaraCompany.Next() = 0;
    end;
}
#pragma warning restore AS0026
#pragma warning restore AS0035