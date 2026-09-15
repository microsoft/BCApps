// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Purchases.Vendor;

report 10327 "Assign Tax Area to Vendor"
{
    Caption = 'Assign Tax Area to Vendor';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Vendor; Vendor)
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
                    field("Tax Area Code"; TaxAreaCode)
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
        if not Vendor.Find() then
            CurrReport.Quit();
        Vendor.Modify();
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

