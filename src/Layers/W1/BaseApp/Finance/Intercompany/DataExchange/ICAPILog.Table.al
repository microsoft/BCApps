// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.DataExchange;

table 444 "IC API Log"
{
    Access = Internal;
    Caption = 'IC API Log';
    DataClassification = CustomerContent;
    ReplicateData = false;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
        }
        field(3; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Outgoing,Incoming';
            OptionMembers = Outgoing,Incoming;
            DataClassification = SystemMetadata;
        }
        field(4; Method; Text[10])
        {
            Caption = 'Method';
            DataClassification = SystemMetadata;
        }
        field(5; "Request URI"; Blob)
        {
            DataClassification = CustomerContent;
        }
        field(6; "Request URI Preview"; Text[250])
        {
            Caption = 'Request URI';
            DataClassification = CustomerContent;
        }
        field(7; "Request Body"; Blob)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Response Body"; Blob)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Status Code"; Integer)
        {
            Caption = 'Status Code';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}
#endif
