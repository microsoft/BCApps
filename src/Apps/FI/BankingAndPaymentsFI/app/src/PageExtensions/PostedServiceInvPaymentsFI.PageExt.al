// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Bank.Payment;

pageextension 13586 "Posted Service Inv. Payments FI" extends "Posted Service Invoice"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Reference No.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addafter("Your Reference")
        {
            field("Payment Reference No."; Rec."Payment Reference No.")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
#if not CLEAN30
                Visible = FeatureEnabled;
#endif
            }
        }
    }

#if not CLEAN30
    trigger OnOpenPage()
    var
        Feature: Codeunit "Banking Payments Feature FI";
    begin
        FeatureEnabled := Feature.IsEnabled();
    end;

    var
        FeatureEnabled: Boolean;
#endif
}
