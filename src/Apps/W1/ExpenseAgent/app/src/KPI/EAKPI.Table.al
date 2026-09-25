// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6950 "EA KPI"
{
    Access = Internal;
    Caption = 'Expense Agent';
    DataClassification = CustomerContent;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(3; "File Received"; Integer)
        {
            Caption = 'Email attachments processed';
            ToolTip = 'Specifies the total number of email attachments processed by the Expense Agent.';
        }
        field(4; "Total Expenses Created"; Integer)
        {
            Caption = 'Expenses created';
            ToolTip = 'Specifies the total number of expenses created by the Expense Agent.';
        }
        field(5; "Total Expense Reports Created"; Integer)
        {
            Caption = 'Reports created';
            ToolTip = 'Specifies the total number of expense reports created by the Expense Agent.';
        }
        field(6; "Total Exp Report Lines Created"; Integer)
        {
            Caption = 'Report lines created';
            ToolTip = 'Specifies the total number of expense report lines created by the Expense Agent.';
        }
        field(7; "Total ERL Cr. with Itemization"; Integer)
        {
            Caption = 'Itemized report lines created';
            ToolTip = 'Specifies the number of expense report lines created by the Expense Agent that include itemization. This is a subset of the report lines created.';
        }
        field(20; "Last Updated DateTime"; DateTime)
        {
            Caption = 'Updated at';
            ToolTip = 'Specifies the date and time when the KPI was last updated.';
        }
        field(5000; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            ToolTip = 'Specifies the security identifier (SID) of the agent for whom the KPIs are tracked.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    internal procedure GetSafe()
    var
        UserSecurityIDFilter: Text;
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
        if not Rec.Get() then
            Rec.Insert();

        if IsNullGuid(Rec."User Security ID") then begin
            UserSecurityIDFilter := Rec.GetFilter("User Security ID");
            if Evaluate(Rec."User Security ID", UserSecurityIDFilter) then
                Rec.Modify(false);
        end;
    end;

    internal procedure UpdateEntryKPIs(var EAKPIEntry: Record "EA KPI Entry"; InsertedRecord: Boolean)
    begin
        Rec.GetSafe();
        case EAKPIEntry."Record Type" of
            EAKPIEntry."Record Type"::Expense:
                if InsertedRecord then begin
                    Rec."Total Expenses Created" += 1;
                    Rec."Last Updated DateTime" := CurrentDateTime();
                    Rec.Modify();
                end;
            EAKPIEntry."Record Type"::"Expense Report":
                if InsertedRecord then begin
                    Rec."Total Expense Reports Created" += 1;
                    Rec."Last Updated DateTime" := CurrentDateTime();
                    Rec.Modify();
                end;
            EAKPIEntry."Record Type"::"Expense Report Line":
                begin
                    if InsertedRecord then begin
                        Rec."Total Exp Report Lines Created" += 1;

                        if EAKPIEntry."Has Itemization" then
                            Rec."Total ERL Cr. with Itemization" += 1;
                    end;

                    Rec."Last Updated DateTime" := CurrentDateTime();
                    Rec.Modify();
                end;
        end;
    end;
}