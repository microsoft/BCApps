// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.Email;

table 4325 "SOA Setup"
{
    Access = Internal;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; ID; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
#if not CLEANSCHEMA28
        field(2; "Agent User Security ID"; Guid)
        {
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by "User Security ID" field.';
#if not CLEAN28            
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#endif
#endif
        }
        field(3; "Email Account ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Email Connector"; Enum "Email Connector")
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Incoming Monitoring"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Email Monitoring"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(7; Exists; Boolean)
        {
            Caption = 'Exists';
            FieldClass = FlowField;
            CalcFormula = exist(Agent where("User Security ID" = field("User Security ID")));
        }
        field(8; State; Option)
        {
            InitValue = Disabled;
            Caption = 'State';
            OptionCaption = 'Enabled,Disabled';
            OptionMembers = Enabled,Disabled;
            FieldClass = FlowField;
            CalcFormula = lookup(Agent.State where("User Security ID" = field("User Security ID")));
        }
        field(9; "Agent Scheduled Task ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Recovery Scheduled Task ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Quote Review"; Boolean)
        {
            Caption = 'Request Quote Review When Created';
            DataClassification = SystemMetadata;
        }
        field(12; "Create Order from Quote"; Boolean)
        {
            Caption = 'Create Order from Quote';
            DataClassification = SystemMetadata;
            InitValue = true;

            trigger OnValidate()
            begin
                if not "Create Order from Quote" then
                    "Order Review" := false;
            end;
        }
        field(13; "Order Review"; Boolean)
        {
            Caption = 'Request Order Review When Created';
            DataClassification = SystemMetadata;
        }
        field(14; "Sales Doc. Configuration"; Boolean)
        {
            Caption = 'Sales Document Configuration';
            DataClassification = SystemMetadata;
        }
        field(15; "Search Only Available Items"; Boolean)
        {
            Caption = 'Search Only Available Items';
            DataClassification = SystemMetadata;
        }
        field(16; "Activated At"; DateTime)
        {
            Caption = 'Activated At';
            ToolTip = 'Specifies the date and time the agent was activated or deactivated.';
            DataClassification = SystemMetadata;
        }
        field(17; "Earliest Sync At"; DateTime)
        {
            Caption = 'Earliest Sync At';
            ToolTip = 'Specifies the earliest date and time that the agent will process emails.';
            DataClassification = SystemMetadata;
        }
        field(18; "Last Sync At"; DateTime)
        {
            Caption = 'Last Sync At';
            ToolTip = 'Specifies the date and time the agent last processed emails.';
            DataClassification = SystemMetadata;
        }
        field(19; "Email Address"; Text[250])
        {
            Caption = 'Email Address';
            ToolTip = 'Specifies the email address of the agent.';
        }
        field(20; "Known Sender In. Msg. Review"; Enum "SOA Input Message Review")
        {
            Caption = 'Registered Sender Input Message Review';
            ToolTip = 'Specifies the type of input message review for messages from registered senders.';
            DataClassification = SystemMetadata;
            InitValue = "First Message";
        }
        field(21; "Unknown Sender In. Msg. Review"; Enum "SOA Input Message Review")
        {
            Caption = 'Unregistered Sender Input Message Review';
            ToolTip = 'Specifies the type of input message review for messages from unregistered senders.';
            DataClassification = SystemMetadata;
            InitValue = "All Messages";
        }
        field(22; "Incl. Capable to Promise"; Boolean)
        {
            Caption = 'Include Capable to Promise';
            DataClassification = SystemMetadata;
        }
        field(23; "Instructions Last Sync At"; DateTime)
        {
            Caption = 'Instructions Last Sync At';
            ToolTip = 'Specifies the date and time the agent last synchronized instructions.';
            DataClassification = SystemMetadata;
        }
        field(24; "Message Limit"; Integer)
        {
            Caption = 'Message Limit';
            ToolTip = 'Specifies the maximum number of messages the agent can process in a single day.';
            DataClassification = SystemMetadata;
            InitValue = 100;
        }
        field(25; "Analyze Attachments"; Boolean)
        {
            Caption = 'Analyze attachments';
            ToolTip = 'Specifies whether the agent analyzes attachments when determining intent.';
            DataClassification = SystemMetadata;
        }
        field(26; "Send Sales Quote"; Boolean)
        {
            Caption = 'Send Sales Quote';
            ToolTip = 'Specifies if the agent sends sales quotes for confirmation.';
            DataClassification = SystemMetadata;
        }
        field(27; "Email Template"; Blob)
        {
            Caption = 'Email Signature';
            ToolTip = 'Specifies the email signature for the sales order agent.';
        }
        field(28; "Configure Email Template"; Boolean)
        {
            Caption = 'Configure Email Signature';
            ToolTip = 'Specifies whether the email signature is configured for the sales order agent.';
        }

        field(29; "Email Folder"; Text[2048])
        {
            Caption = 'Email Folder';
            ToolTip = 'Specifies the email folder that the agent monitors.';
            DataClassification = SystemMetadata;
        }
        field(30; "Email Folder Id"; Text[2048])
        {
            Caption = 'Email Folder Id';
            ToolTip = 'Specifies the unique identifier of the email folder that the agent monitors.';
        }
        field(31; "Mark Email As Read"; Boolean)
        {
            Caption = 'Mark email as read';
            ToolTip = 'Specifies whether the agent marks emails as read after processing them.';
            DataClassification = SystemMetadata;
        }
        field(33; "Owner User Security ID"; Guid)
        {
            Caption = 'Owner User Security ID';
            ToolTip = 'Specifies the BC user who owns this agent instance.';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(34; "Agent Name"; Text[50])
        {
            Caption = 'Display name';
            ToolTip = 'Specifies the unique display name of the sales order agent instance.';
            DataClassification = SystemMetadata;
        }
        field(35; "Agent Initials"; Text[4])
        {
            Caption = 'Initials';
            ToolTip = 'Specifies the initials for the sales order agent instance.';
            DataClassification = SystemMetadata;
        }
        field(50; "User Security ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(51; "Plain Date"; Date)
        {
            Caption = 'Plain Date';
        }
        field(52; "Assist Date"; Date)
        {
            Caption = 'Assist Date';
        }
        field(53; "DrillDown Date"; Date)
        {
            Caption = 'DrillDown Date';
        }
        field(54; "Assist And DrillDown Date"; Date)
        {
            Caption = 'Assist and DrillDown Date';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
#if not CLEAN28
#pragma warning disable AL0432
        key(Key2; "Agent User Security ID")
#pragma warning restore AL0432
        {
        }
#endif
        key(Key3; "User Security ID")
        {
        }
    }

    internal procedure GetBasedOnAgentUserSecurityID(var AgentUserSecurityID: Guid; ErrorIfNotFound: Boolean): Boolean
    var
        NotFoundErr: Label 'Sales Order Agent Setup not found.';
    begin
        Rec.Reset();
        Rec.SetRange("User Security ID", AgentUserSecurityID);
        if Rec.FindFirst() then
            exit(true);

        Clear(Rec);
        if ErrorIfNotFound then
            Error(NotFoundErr);
        exit(false);
    end;

    internal procedure GetDefaultMessageLimit(): Integer
    begin
        exit(100);
    end;

    internal procedure SetEmailSignature(EmailSignatureAsTxt: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Rec."Email Template");
        Rec."Email Template".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(EmailSignatureAsTxt);
    end;

    internal procedure GetEmailSignatureAsTxt(): Text
    var
        InStream: InStream;
    begin
        Rec.CalcFields("Email Template");
        if not Rec."Email Template".HasValue() then
            exit('');

        Rec."Email Template".CreateInStream(InStream, TextEncoding::UTF8);
        exit(ReadAsTextWithSeparator(InStream, ' '));
    end;

    local procedure ReadAsTextWithSeparator(InStream: InStream; LineSeparator: Text): Text
    var
        Tb: TextBuilder;
        ContentLine: Text;
    begin
        InStream.ReadText(ContentLine);
        Tb.Append(ContentLine);
        while not InStream.EOS do begin
            InStream.ReadText(ContentLine);
            Tb.Append(LineSeparator);
            Tb.Append(ContentLine);
        end;

        exit(Tb.ToText());
    end;
}