// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

using Microsoft.Service.Document;

table 5927 "Repair Status"
{
    Caption = 'Repair Status';
    DrillDownPageID = "Repair Status";
    LookupPageID = "Repair Status";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Service Order Status"; Enum "Service Document Status")
        {
            Caption = 'Service Order Status';

            trigger OnValidate()
            begin
                if not ServStatusPrioritySetup.Get("Service Order Status") then
                    Error(
                      Text000,
                      FieldCaption("Service Order Status"), "Service Order Status", ServStatusPrioritySetup.TableCaption());

                Priority := ServStatusPrioritySetup.Priority;
            end;
        }
        field(4; Priority; Option)
        {
            Caption = 'Priority';
            Editable = false;
            OptionCaption = 'High,Medium High,Medium Low,Low';
            OptionMembers = High,"Medium High","Medium Low",Low;
        }
        field(5; Initial; Boolean)
        {
            Caption = 'Initial';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if Initial then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange(Initial, true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption(Initial));
                end;
            end;
        }
        field(6; "Partly Serviced"; Boolean)
        {
            Caption = 'Partly Serviced';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if "Partly Serviced" then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange("Partly Serviced", true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption("Partly Serviced"));
                end;
            end;
        }
        field(7; "In Process"; Boolean)
        {
            Caption = 'In Process';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if "In Process" then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange("In Process", true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption("In Process"));
                end;
            end;
        }
        field(8; Finished; Boolean)
        {
            Caption = 'Finished';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if Finished then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange(Finished, true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption(Finished));
                end;
            end;
        }
        field(9; Referred; Boolean)
        {
            Caption = 'Referred';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if Referred then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange(Referred, true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption(Referred));
                end;
            end;
        }
        field(10; "Spare Part Ordered"; Boolean)
        {
            Caption = 'Spare Part Ordered';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if "Spare Part Ordered" then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange("Spare Part Ordered", true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption("Spare Part Ordered"));
                end;
            end;
        }
        field(11; "Spare Part Received"; Boolean)
        {
            Caption = 'Spare Part Received';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if "Spare Part Received" then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange("Spare Part Received", true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption("Spare Part Received"));
                end;
            end;
        }
        field(12; "Waiting for Customer"; Boolean)
        {
            Caption = 'Waiting for Customer';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if "Waiting for Customer" then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange("Waiting for Customer", true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption("Waiting for Customer"));
                end;
            end;
        }
        field(13; "Quote Finished"; Boolean)
        {
            Caption = 'Quote Finished';

            trigger OnValidate()
            var
                RepairStatus: Record "Repair Status";
            begin
                if "Quote Finished" then begin
                    RepairStatus.SetFilter(Code, '<>%1', Code);
                    RepairStatus.SetRange("Quote Finished", true);
                    if not RepairStatus.IsEmpty() then
                        Error(Text001, TableCaption(), FieldCaption("Quote Finished"));
                end;
            end;
        }
        field(20; "Posting Allowed"; Boolean)
        {
            Caption = 'Posting Allowed';
        }
        field(21; "Pending Status Allowed"; Boolean)
        {
            Caption = 'Pending Status Allowed';
        }
        field(22; "In Process Status Allowed"; Boolean)
        {
            Caption = 'In Process Status Allowed';
        }
        field(23; "Finished Status Allowed"; Boolean)
        {
            Caption = 'Finished Status Allowed';
        }
        field(24; "On Hold Status Allowed"; Boolean)
        {
            Caption = 'On Hold Status Allowed';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Priority)
        {
        }
        key(Key3; Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Service Order Status")
        {
        }
    }

    trigger OnDelete()
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Repair Status Code", Code);
        if not ServiceItemLine.IsEmpty() then
            Error(Text002, TableCaption(), Code, ServiceItemLine.TableCaption());
    end;

    trigger OnInsert()
    begin
        Validate("Service Order Status");
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The program cannot find the %1 %2 in the %3 table.';
        Text001: Label 'Only one %1 can be marked as %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ServStatusPrioritySetup: Record "Service Status Priority Setup";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'You cannot delete the %1 %2 because there is at least one %3 that has this %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure ReturnStatusCode(RepairStatus2: Record "Repair Status"): Code[10]
    var
        RepairStatus: Record "Repair Status";
        IsHandled: Boolean;
    begin
        case true of
            RepairStatus2.Initial:
                RepairStatus.SetRange(Initial, true);
            RepairStatus2."Partly Serviced":
                RepairStatus.SetRange("Partly Serviced", true);
            RepairStatus2."In Process":
                RepairStatus.SetRange("In Process", true);
            RepairStatus2.Finished:
                RepairStatus.SetRange(Finished, true);
            RepairStatus2.Referred:
                RepairStatus.SetRange(Referred, true);
            RepairStatus2."Spare Part Ordered":
                RepairStatus.SetRange("Spare Part Ordered", true);
            RepairStatus2."Spare Part Received":
                RepairStatus.SetRange("Spare Part Received", true);
            RepairStatus2."Waiting for Customer":
                RepairStatus.SetRange("Waiting for Customer", true);
            RepairStatus2."Quote Finished":
                RepairStatus.SetRange("Quote Finished", true);
            else begin
                IsHandled := false;
                OnReturnStatusCodeElseCase(RepairStatus2, RepairStatus, IsHandled);
                if not IsHandled then
                    exit('');
            end;
        end;
        if RepairStatus.FindFirst() then
            exit(RepairStatus.Code);

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReturnStatusCodeElseCase(RepairStatus2: Record "Repair Status"; var RepairStatus: Record "Repair Status"; var IsHandled: Boolean)
    begin
    end;
}

