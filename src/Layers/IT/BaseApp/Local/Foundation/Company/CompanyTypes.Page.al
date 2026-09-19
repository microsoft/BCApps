// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

page 12169 "Company Types"
{
    Caption = 'FatturaPA Fiscal Regimes';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Company Types";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the two-digit FatturaPA fiscal regime code. The code is exported with the RF prefix, for example 19 as RF19.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the FatturaPA fiscal regime.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        FatturaDocHelper.EnsureStandardFatturaPAFiscalRegimes();
        Rec.SetFilter(Code, '01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19');
    end;
}

