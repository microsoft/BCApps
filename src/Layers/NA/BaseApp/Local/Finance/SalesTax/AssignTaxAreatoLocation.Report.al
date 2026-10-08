// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Inventory.Location;

report 10328 "Assign Tax Area to Location"
{
    Caption = 'Assign Tax Area to Location';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Location; Location)
        {
            RequestFilterFields = "Code", Name;

            trigger OnAfterGetRecord()
            begin
                "Tax Area Code" := TaxAreaCode;
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
                    field("Tax Area Code"; TaxAreaCode)
                    {
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
        if not Location.Find() then
            CurrReport.Quit();
        Location.Modify();
    end;

    var
        TaxAreaCode: Code[20];

    procedure InitializeRequest(NewTaxAreaCode: Code[20])
    begin
        TaxAreaCode := NewTaxAreaCode;
    end;

    procedure SetDefaultAreaCode(NewTaxAreaCode: Code[20])
    begin
        TaxAreaCode := NewTaxAreaCode;
    end;
}

