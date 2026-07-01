// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;

pageextension 60 ShowCurrencyGenLedgSetup extends "General Ledger Setup"
{
    layout
    {
        addafter("Local Currency Description")
        {
            field(ShowCurrencySymbol; Rec."Show Currency")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Currency';
                importance = Additional;

                trigger OnValidate()
                begin
                    RestartSession := true;
                end;
            }
            field(CurrencySymbolPosition; Rec."Currency Symbol Position")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Currency Symbol Position';
                importance = Additional;

                trigger OnValidate()
                begin
                    RestartSession := true;
                end;
            }
        }
    }

    var
        RestartSession: Boolean;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        SessionSetting: SessionSettings;
    begin
        if CloseAction = CloseAction::OK then
            if RestartSession then begin
                SessionSetting.Init();
                SessionSetting.RequestSessionUpdate(false);
            end;
    end;
}