// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Sales.Document;

pageextension 10809 "Sales Credit Memo" extends "Sales Credit Memo"
{
    layout
    {
        addafter("EU 3-Party Trade")
        {
            field("VAT Paid on Debits FR"; Rec."VAT Paid on Debits FR")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the VAT was paid on debits for this document.';
#if not CLEAN30
                Visible = SalesFRFeatureEnabled;
#endif
            }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("VAT Paid on Debits")
        {
            Visible = not SalesFRFeatureEnabled;
        }
#pragma warning restore AL0432
#endif
    }
#if not CLEAN30

    var
        SalesFRFeatureEnabled: Boolean;

#pragma warning disable AL0432
    trigger OnOpenPage()
    var
        SalesFR: Codeunit "Sales FR";
    begin
        SalesFRFeatureEnabled := SalesFR.IsEnabled();
    end;
#pragma warning restore AL0432
#endif
}
