// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

table 613 "IC Incoming Notification"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Operation ID"; Guid)
        {
            Caption = 'Operation ID';
        }
        field(2; "Source IC Partner Code"; Code[20])
        {
            Caption = 'Source Intercompany Partner Code';
        }
        field(3; "Target IC Partner Code"; Code[20])
        {
            Caption = 'Target Intercompany Partner Code';
        }
        field(10; "Notified DateTime"; DateTime)
        {
            Caption = 'Notified DateTime';
        }
        field(20; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Created,Failed,Processed,Scheduled for deletion failed';
            OptionMembers = Created,Failed,Processed,"Scheduled for deletion failed";
        }
        field(21; "Error Message"; Blob)
        {
            Caption = 'Error Message';
        }
    }

    keys
    {
        key(Key1; "Operation ID")
        {
            Clustered = true;
        }
    }

    procedure SetErrorMessage(value: Text)
    var
        outStr: OutStream;
    begin
        Rec."Error Message".CreateOutStream(outStr);
        outStr.WriteText(value);
    end;

    procedure GetErrorMessage(value: Text)
    var
        inStr: InStream;
    begin
        CalcFields(Rec."Error Message");
        if Rec."Error Message".HasValue() then begin
            Rec."Error Message".CreateInStream(inStr);
            inStr.ReadText(value);
        end
        else
            value := '';
    end;
}
