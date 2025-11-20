// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6079 "Contract Amount Distribution"
{
    Caption = 'Contract Amount Distribution';
    PageType = ConfirmationDialog;

    layout
    {
        area(content)
        {
            field(Result; Result)
            {
                ApplicationArea = Service;
                Caption = 'Do you want the differences to be distributed to the contract lines by';
                OptionCaption = 'Even Distribution?,Distribution Based on Profit?,Distribution Based on Line Amount?';
            }
            group(Details)
            {
                Caption = 'Details';
                InstructionalText = 'The Annual Amount and the Calcd. Annual Amount must be the same.';
                field(AnnualAmount; AnnualAmount)
                {
                    ApplicationArea = Service;
                    Caption = 'Annual Amount';
                    Editable = false;
                }
                field(CalcdAnnualAmount; CalcdAnnualAmount)
                {
                    ApplicationArea = Service;
                    Caption = 'Calcd. Annual Amount';
                    Editable = false;
                }
                field(Difference; Difference)
                {
                    ApplicationArea = Service;
                    Caption = 'Difference';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    var
        Result: Option "0","1","2";
        AnnualAmount: Decimal;
        CalcdAnnualAmount: Decimal;
        Difference: Decimal;

    procedure GetResult(): Integer
    begin
        exit(Result);
    end;

    procedure SetValues(AnnualAmount2: Decimal; CalcdAnnualAmount2: Decimal)
    begin
        AnnualAmount := AnnualAmount2;
        CalcdAnnualAmount := CalcdAnnualAmount2;
        Difference := AnnualAmount2 - CalcdAnnualAmount2;
    end;

    procedure SetResult(Option: Option)
    begin
        Result := Option;
    end;
}

