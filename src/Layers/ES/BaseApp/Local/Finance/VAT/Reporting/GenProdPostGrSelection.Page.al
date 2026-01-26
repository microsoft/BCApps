// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;

page 10735 "Gen. Prod. Post. Gr. Selection"
{
    Caption = 'Gen. Prod. Post. Gr. Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Gen. Prod. Post. Group Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1100000)
            {
                ShowCaption = false;
                field("Exclude from 349"; Rec."Exclude from 349")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entries with this posting group are excluded from report 349.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting group code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the posting group.';
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure GetGPPGSelBuf(var TheGPPGSelectionBuf: Record "Gen. Prod. Post. Group Buffer")
    begin
        TheGPPGSelectionBuf.DeleteAll();
        if Rec.Find('-') then
            repeat
                TheGPPGSelectionBuf := Rec;
                TheGPPGSelectionBuf.Insert();
            until Rec.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertGPPGSelBuf(NewSelected: Boolean; NewCode: Code[20]; NewDescription: Text[100])
    var
        GenProdPostGroup: Record "Gen. Product Posting Group";
    begin
        if NewDescription = '' then
            if GenProdPostGroup.Get(NewCode) then
                NewDescription := GenProdPostGroup.Description;

        Rec.Init();
        Rec."Exclude from 349" := NewSelected;
        Rec.Code := NewCode;
        Rec.Description := NewDescription;
        Rec.Insert();
    end;
}

