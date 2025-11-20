// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 5916 "Service Hours"
{
    Caption = 'Service Hours';
    DataCaptionFields = "Service Contract No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Service Hour";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Contract No."; Rec."Service Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract to which the service hours apply.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service hours become valid.';
                }
                field(Day; Rec.Day)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the day when the service hours are valid.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting time of the service hours.';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending time of the service hours.';
                }
                field("Valid on Holidays"; Rec."Valid on Holidays")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that service hours are valid on holidays.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Copy Default Service Hours")
                {
                    ApplicationArea = Service;
                    Caption = '&Copy Default Service Hours';
                    Image = CopyServiceHours;
                    ToolTip = 'Insert the service calendar entries that are set up in the Default Service Hours window.';

                    trigger OnAction()
                    begin
                        Rec.CopyDefaultServiceHours();
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := false;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Clear(Weekdays);
        EntryMissing := false;

        ServHour.Reset();
        case Rec."Service Contract Type" of
            "Service Contract Type"::Quote:
                ServHour.SetRange("Service Contract Type", "Service Contract Type"::Quote);
            "Service Contract Type"::Contract:
                ServHour.SetRange("Service Contract Type", "Service Contract Type"::Contract);
        end;
        ServHour.SetRange("Service Contract No.", Rec."Service Contract No.");
        if ServHour.Find('-') then begin
            repeat
                Weekdays[ServHour.Day + 1] := true;
            until ServHour.Next() = 0;

            for i := 1 to 5 do
                if not Weekdays[i] then
                    EntryMissing := true;

            if EntryMissing then
                if not Confirm(Text000)
                then
                    exit(false);
        end;
    end;

    var
        ServHour: Record "Service Hour";
        Weekdays: array[7] of Boolean;
        EntryMissing: Boolean;
        i: Integer;

#pragma warning disable AA0074
        Text000: Label 'You have not specified service hours for all working days.\\Do you want to close the window?';
#pragma warning restore AA0074
}

