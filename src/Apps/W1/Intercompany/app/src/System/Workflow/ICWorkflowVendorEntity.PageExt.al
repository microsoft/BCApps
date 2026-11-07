// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using Microsoft.Intercompany.Partner;

pageextension 8555 "IC Workflow Vendor Entity" extends "Workflow - Vendor Entity"
{
    layout
    {
        modify(icPartnerCode)
        {
            trigger OnAfterValidate()
            begin
                Rec.Validate("IC Partner Code", ICPartnerCode);
                ICPartnerCode := Rec."IC Partner Code";
            end;

            trigger OnLookup(var Text: Text): Boolean
            var
                ICPartner: Record "IC Partner";
            begin
                ICPartner.Code := ICPartnerCode;
                if Page.RunModal(0, ICPartner) <> Action::LookupOK then
                    exit(false);

                Text := ICPartner.Code;
                exit(true);
            end;
        }
    }

    trigger OnAfterGetRecord()
    begin
        ICPartnerCode := Rec."IC Partner Code";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ICPartnerCode := Rec."IC Partner Code";
    end;
}
