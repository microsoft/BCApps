// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 1320 ExcelTemplateCompanyInfo
{
    Caption = 'ExcelTemplateCompanyInfo';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Company Information";

    layout
    {
        area(content)
        {
            group(CompanyDisplayName)
            {
                Caption = 'CompanyDisplayName';
                field(DisplayName; DisplayName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'DisplayName';
                    ToolTip = 'Specifies the display name of the company.';
                }
            }
            group(CurrencyCode)
            {
                Caption = 'CurrencyCode';
                field(Currency; CurrencyCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency', Locked = true;
                    ToolTip = 'Specifies the currency code of the company.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetCompanyInformation();
    end;

    var
        DisplayName: Text[250];
        CurrencyCode: Text[10];

    local procedure GetCompanyInformation()
    var
        Company: Record Company;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if Company.Get(CompanyName) then
            DisplayName := Company."Display Name";

        if GeneralLedgerSetup.Get() then
            CurrencyCode := GeneralLedgerSetup."LCY Code";
    end;
}

