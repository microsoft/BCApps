// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6951 "EA KPI Entry"
{
    Access = Internal;
    Caption = 'Expense Agent KPI Entry';
    DataClassification = CustomerContent;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Record Type"; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of the record that is being tracked.';
            OptionMembers = " ",Expense,"Expense Report","Expense Report Line";
            OptionCaption = ' ,Expense,Expense Report,Expense Report Line';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the record that is being tracked.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of the record that is being tracked.';
        }
        field(4; "Has Itemization"; Boolean)
        {
            Caption = 'Has Itemization';
            ToolTip = 'Specifies whether the tracked expense report line has itemization.';
        }
        field(5; "Created by User ID"; Guid)
        {
            Caption = 'Created by Agent User ID';
            ToolTip = 'Specifies the security ID of the agent user who created the record.';
        }
        field(6; "Created By Exp. User Id"; Guid)
        {
            Caption = 'Created By Expense User Id';
            DataClassification = EndUserPseudonymousIdentifiers;
            ToolTip = 'Specifies the SystemId of the Expense User on whose behalf the record was created by the Expense Agent.';
        }
        field(7; "Created By Entra App Id"; Guid)
        {
            Caption = 'Created By Entra App Id';
            ToolTip = 'Specifies the Business Central user security id that backs the Expense Agent Entra (AAD) application. Used to attribute KPI entries to the agent independently of the calling session.';
        }
        field(8; "Expense User Name"; Text[100])
        {
            Caption = 'Expense User Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup("Expense User".Name where(SystemId = field("Created By Exp. User Id")));
            ToolTip = 'Specifies the name of the Expense User on whose behalf the record was created by the Expense Agent.';
        }
    }

    keys
    {
        key(Key1; "Record Type", "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key3; "Created by User ID")
        {
        }
    }

    var
        ExpenseDoesNotExistMsg: Label 'The expense does not exist any more.';
        ExpenseReportDoesNotExistMsg: Label 'The expense report does not exist any more.';
        ExpenseReportLineDoesNotExistMsg: Label 'The expense report line does not exist any more.';
        NotPossibleToViewTheRecordMsg: Label 'It is not possible to view the record.';

    internal procedure OpenCard()
    var
        ExpenseHeader: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        case Rec."Record Type" of
            Rec."Record Type"::Expense:
                begin
                    if ExpenseHeader.Get(Rec."No.") then begin
                        Page.Run(Page::Expense, ExpenseHeader);
                        exit;
                    end;

                    Message(ExpenseDoesNotExistMsg);
                    exit;
                end;
            Rec."Record Type"::"Expense Report":
                begin
                    if ExpenseReportHeader.Get(Rec."No.") then begin
                        Page.Run(Page::"Expense Report", ExpenseReportHeader);
                        exit;
                    end;

                    Message(ExpenseReportDoesNotExistMsg);
                    exit;
                end;
            Rec."Record Type"::"Expense Report Line":
                begin
                    if ExpenseReportLine.Get(Rec."No.", Rec."Line No.") then begin
                        Page.Run(Page::"Expense Report Lines", ExpenseReportLine);
                        exit;
                    end;

                    Message(ExpenseReportLineDoesNotExistMsg);
                    exit;
                end;
        end;

        Message(NotPossibleToViewTheRecordMsg);
    end;
}