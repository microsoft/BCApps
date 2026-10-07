// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Utilities;

#pragma implicitwith disable
page 31148 "EET Entry Status Log CZL"
{
    Caption = 'EET Entry Status Log';
    DataCaptionFields = "EET Entry No.";
    Editable = false;
    PageType = List;
    SourceTable = "EET Entry Status Log CZL";
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

    local procedure UpdateErrorMessages()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Context Record ID", Rec.RecordId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.Update();
    end;
}
