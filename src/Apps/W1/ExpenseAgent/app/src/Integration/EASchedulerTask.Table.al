// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

table 6935 "EA Scheduler Task"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "ID"; BigInteger)
        {
            AutoIncrement = true;
            Caption = 'ID';
            ToolTip = 'Specifies the unique identifier (BigInteger) of the EA Scheduler Task. This value is assigned automatically and should not be changed.';
        }
        field(2; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = "In Progress",Succeeded,Failed;
            OptionCaption = 'In Progress,Succeeded,Failed', Comment = 'In Progress = task is running, Succeeded = task completed successfully, Failed = something went wrong. See error message';
            ToolTip = 'Specifies whether the task executed successfully or not.';
        }
        field(3; "Access Token Retrieved"; Boolean)
        {
            Caption = 'Access Token Retrieved';
            ToolTip = 'Specifies whether the process was able to obtain an acess token.';
        }
        field(4; "Send Replies Successful"; Boolean)
        {
            Caption = 'Send Replies Successful';
            ToolTip = 'Specifies that send email replies executed successfully.';
        }
        field(11; "Error Message"; Text[1000])
        {
            Caption = 'Error Message';
            ToolTip = 'Specifies what error occurred if Status=Failed.';
            DataClassification = CustomerContent;
        }
        field(12; "Error Call Stack"; Blob)
        {
            Caption = 'Error Call Stack';
            ToolTip = 'Specifies the full error call stack captured if Status=Failed.';
            DataClassification = CustomerContent;
        }
        field(20; "Run by user"; Text[50])
        {
            Caption = 'Run by user';
            ToolTip = 'Specifies the user name of the user who ran this process.';
            FieldClass = FlowField;
            CalcFormula = lookup(System.Security.AccessControl.User."User Name" where("User Security ID" = field(SystemCreatedBy)));
        }
    }

    keys
    {
        key(Key1; "ID")
        {
            Clustered = true;
        }
    }

    internal procedure SetErrorCallStack(CallStack: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Rec."Error Call Stack");
        Rec."Error Call Stack".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(CallStack);
    end;

    internal procedure GetErrorCallStack() CallStack: Text
    var
        InStream: InStream;
    begin
        Rec.CalcFields("Error Call Stack");
        if not Rec."Error Call Stack".HasValue() then
            exit('');
        Rec."Error Call Stack".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(CallStack);
    end;
}