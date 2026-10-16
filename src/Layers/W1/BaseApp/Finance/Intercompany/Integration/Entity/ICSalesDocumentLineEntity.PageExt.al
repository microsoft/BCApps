// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

pageextension 8553 "IC Sales Document Line Entity" extends "Sales Document Line Entity"
{
    layout
    {
        addafter(vatIdentifier)
        {
            field(icPartnerRefType; Rec."IC Partner Ref. Type")
            {
                ApplicationArea = All;
                Caption = 'IC Partner Ref. Type', Locked = true;
            }
            field(icPartnerReference; Rec."IC Partner Reference")
            {
                ApplicationArea = All;
                Caption = 'IC Partner Reference', Locked = true;
            }
        }
        addafter(prepmtAmountInvLcy)
        {
            field(icPartnerCode; Rec."IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'IC Partner Code', Locked = true;
            }
        }
    }
}