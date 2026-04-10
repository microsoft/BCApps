// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.Environment;

/// <summary>
/// Company selection page for choosing companies in multi-company consolidation scenarios.
/// Provides read-only list of available companies for consolidation business unit assignment.
/// </summary>
/// <remarks>
/// List page for company selection during consolidation setup and business unit configuration.
/// Displays available companies in the database for association with consolidation business units.
/// Essential for multi-company consolidation scenarios enabling company-to-business-unit mapping.
/// </remarks>
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
