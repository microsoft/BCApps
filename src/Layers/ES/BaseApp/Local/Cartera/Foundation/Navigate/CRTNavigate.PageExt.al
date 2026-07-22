// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

pageextension 7000116 "CRTNavigate" extends Navigate
{
    layout
    {
        addafter(DocNoFilter)
        {
            field(CarteraDocNoFilter; CarteraDocNoFilter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bill No.';
                ToolTip = 'Specifies the number of the bill.';

                trigger OnValidate()
                begin
                    SetPostingDate(PostingDateFilter);
                    ContactType := ContactType::" ";
                    ContactNo := '';
                    ExtDocNo := '';
                    CRTNavigateCartera.SetCarteraDocNoFilter(CarteraDocNoFilter);
                    ClearSourceInfo();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CRTNavigateCartera.SetCarteraDocNoFilter(CarteraDocNoFilter);
    end;

    trigger OnClosePage()
    begin
        CRTNavigateCartera.SetCarteraDocNoFilter('');
    end;

    var
        CRTNavigateCartera: Codeunit "CRTNavigateCartera";
        CarteraDocNoFilter: Text[250];
}
