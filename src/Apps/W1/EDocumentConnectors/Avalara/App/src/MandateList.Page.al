// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

page 6370 "Mandate List"
{
    ApplicationArea = All;
    Caption = 'Avalara Mandate List';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = Mandate;
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Country Mandate"; Rec."Country Mandate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the mandate for the country.';
                }
                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the country.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the mandate.';
                }
                field("Invoice Format"; Rec."Invoice Format")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Invoice Format field.', Comment = '%';
                }
            }
        }
    }

    procedure SetTempRecords(var Mandate: Record Mandate temporary)
    begin
        if Mandate.FindSet() then
            repeat
                Rec := Mandate;
                Rec.Insert();
            until Mandate.Next() = 0;
    end;
}