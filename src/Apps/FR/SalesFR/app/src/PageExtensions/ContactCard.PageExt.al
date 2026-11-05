// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.Contact;

pageextension 10812 "Contact Card" extends "Contact Card"
{
    layout
    {
        addafter("APE Code")
        {

            field("SIREN No. FR"; Rec."SIREN No. FR")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the SIREN No. for the contact.';
#if not CLEAN30
                Visible = SalesFRFeatureEnabled;
#endif
            }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("SIREN No.")
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
