// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.Environment;

page 244 "Company Selector"
{
    Caption = 'Companies';
    PageType = List;
    SourceTable = Company;
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Companies)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Company name';
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Company display name';
                }
            }
        }
    }

    internal procedure GetSelectedCompany(var SelectedCompany: Record Company temporary)
    begin
        CurrPage.SetSelectionFilter(SelectedCompany);
    end;

    internal procedure SetCompanies(var Company: Record Company temporary)
    begin
        if not Company.FindSet() then
            exit;
        repeat
            Rec.TransferFields(Company);
            Rec.Insert();
        until Company.Next() = 0;
    end;
}
