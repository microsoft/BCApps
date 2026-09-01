// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Sales.Customer;

report 10326 "Assign Tax Area to Customer"
{
    Caption = 'Assign Tax Area to Customer';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = County;

            trigger OnAfterGetRecord()
            begin
                "Tax Area Code" := TaxAreaCode;
                "Tax Liable" := TaxLiable;
                Modify();
            end;
        }
    }

    requestpage
    {
        ShowFilter = false;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Tax Liable"; TaxLiable)
                    {
                        ApplicationArea = SalesTax;
                        Caption = 'Tax Liable';
                        ToolTip = 'Specifies the tax area code that will be assigned.';
                    }
                    field("Tax Area Code Name"; TaxAreaCode)
                    {
                        ApplicationArea = SalesTax;
                        Caption = 'Tax Area Code';
                        TableRelation = "Tax Area";
                        ToolTip = 'Specifies the tax area code that will be assigned.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not Customer.Find() then
            CurrReport.Quit();
        Customer.Modify();
    end;

    var
        TaxLiable: Boolean;
        TaxAreaCode: Code[20];

    procedure InitializeRequest(NewTaxLiable: Boolean; NewTaxAreaCode: Code[20])
    begin
        TaxAreaCode := NewTaxAreaCode;
        TaxLiable := NewTaxLiable;
    end;

    procedure SetDefaultAreaCode(NewTaxAreaCode: Code[20])
    begin
        TaxAreaCode := NewTaxAreaCode;
        TaxLiable := true;
    end;
}

