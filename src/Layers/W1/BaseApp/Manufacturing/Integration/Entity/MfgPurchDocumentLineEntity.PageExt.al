// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

pageextension 99000831 "Mfg. PurchDocumentLineEntity" extends "Purchase Document Line Entity"
{
    layout
    {
        addafter(returnsDeferralStartDate)
        {
            field(prodOrderNumber; Rec."Prod. Order No.")
            {
                ApplicationArea = All;
                Caption = 'Prod. Order No.', Locked = true;
            }
        }
        addafter(subtype)
        {
            field(routingNumber; Rec."Routing No.")
            {
                ApplicationArea = All;
                Caption = 'Routing No.', Locked = true;
            }
            field(operationNumber; Rec."Operation No.")
            {
                ApplicationArea = All;
                Caption = 'Operation No.', Locked = true;
            }
            field(workCenterNumber; Rec."Work Center No.")
            {
                ApplicationArea = All;
                Caption = 'Work Center No.', Locked = true;
            }
            field(finished; Rec.Finished)
            {
                ApplicationArea = All;
                Caption = 'Finished', Locked = true;
            }
            field(prodOrderLineNumber; Rec."Prod. Order Line No.")
            {
                ApplicationArea = All;
                Caption = 'Prod. Order Line No.', Locked = true;
            }
        }
        addafter(safetyLeadTime)
        {
            field(routingReferenceNumber; Rec."Routing Reference No.")
            {
                ApplicationArea = All;
                Caption = 'Routing Reference No.', Locked = true;
            }
        }
    }
}