// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Utilities;

#pragma implicitwith disable
page 31149 "EET Entry Status Log Prev. CZL"
{
    Caption = 'EET Entry Status Log Preview';
    DataCaptionFields = "EET Entry No.";
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "EET Entry Status Log CZL";
    SourceTableTemporary = true;
    SourceTableView = order(descending);
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Changed At"; Rec."Changed At")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("EET Entry No."; Rec."EET Entry No.")
                {
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(ErrorMessagesPart; "Error Messages Part")
            {
                Caption = 'Errors and Warnings';
                ShowFilter = false;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateErrorMessages();
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;

    procedure Set(var NewTempEETEntryStatusLogCZL: Record "EET Entry Status Log CZL" temporary; var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        Rec.Copy(NewTempEETEntryStatusLogCZL, true);
        TempErrorMessage.Copy(NewTempErrorMessage, true);
    end;

    local procedure UpdateErrorMessages()
    var
        TempLocalErrorMessage: Record "Error Message" temporary;
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", Rec.RecordId);
        TempErrorMessage.CopyToTemp(TempLocalErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempLocalErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.Update();
    end;
}
