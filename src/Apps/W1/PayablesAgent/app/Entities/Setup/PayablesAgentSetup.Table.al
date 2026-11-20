// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;
#if not CLEANSCHEMA33
using Microsoft.eServices.EDocument;
#endif
using System.Agents;

table 3303 "Payables Agent Setup"
{
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = rimdX;
    Permissions = tabledata "Payables Agent Setup" = ri;

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA33
#pragma warning disable AS0072
        field(2; "E-Document Service Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "E-Document Service".Code;
            ObsoleteReason = 'The Payables Agent E-Document Service code is fixed for the draft-based Payables Agent; it is no longer stored on the setup.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
        }
#pragma warning restore AS0072
#endif
        field(3; "Monitor Outlook"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA31
        field(4; "Agent User Security Id"; Guid)
        {
            DataClassification = SystemMetadata;
            ObsoleteReason = 'No longer used, replaced by "User Security Id" field';
#if not CLEAN28
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#endif
        }
#endif
#if not CLEANSCHEMA33
        field(5; "Review Incoming Invoice"; Boolean)
        {
            DataClassification = CustomerContent;
            InitValue = true;
            ObsoleteReason = 'Field replaced';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
        }
#endif
        field(7; Exists; Boolean)
        {
            Caption = 'Exists';
            FieldClass = FlowField;
            CalcFormula = exist(Agent where("User Security ID" = field("User Security Id")));
        }
        field(9; "Last Activated"; DateTime)
        {
            Caption = 'Last Activated';
            DataClassification = SystemMetadata;
        }
        field(10; "User Security Id"; Guid)
        {
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA32
#pragma warning disable AS0072
        field(11; "Use MLLM Processing"; Boolean)
        {
            Caption = 'Use MLLM Processing';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'The MLLM Payables Agent feature is fully rolled out; the toggle used to roll it out is no longer needed.';
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
        }
#pragma warning restore AS0072
#endif
        field(12; "Email Review Policy"; Enum "PA Email Review Policy")
        {
            Caption = 'Email review';
            DataClassification = CustomerContent;
        }
        field(13; "Applied Instr. Config Hash"; Text[64])
        {
            Caption = 'Applied Instructions Configuration Hash';
            DataClassification = SystemMetadata;
        }
        field(14; "Email Account Id"; Guid)
        {
            Caption = 'Email Account Id';
            DataClassification = SystemMetadata;
        }
        field(15; "Email Folder"; Text[2048])
        {
            Caption = 'Email Folder';
            DataClassification = CustomerContent;
        }
        field(16; "Email Folder Id"; Text[2048])
        {
            Caption = 'Email Folder Id';
            DataClassification = SystemMetadata;
        }
        field(17; "Last Sync At"; DateTime)
        {
            Caption = 'Last Sync At';
            DataClassification = SystemMetadata;
        }
        field(18; "Email Monitoring Consent"; Boolean)
        {
            Caption = 'Email Monitoring Consent';
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA33
        // Temporary production opt-in for the V2 preview
        field(19; "Preview Version"; Option)
        {
            Caption = 'Preview version';
            OptionMembers = " ","V2 Preview";
            OptionCaption = ' ,V2 Preview';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Temporary V2 preview selector, removed once version 2 no longer needs a preview opt-in.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';

            trigger OnValidate()
            var
                PAV1V2Flag: Codeunit "PA V1V2 Flag";
            begin
                if Rec."Preview Version" = Rec."Preview Version"::"V2 Preview" then
                    PAV1V2Flag.CheckV2PreviewSelectable();
            end;
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
        }
#endif
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    internal procedure GetOrCreateSetup()
    begin
        if TryGetSetup() then
            exit;
        Rec.Insert();
    end;

    internal procedure TryGetSetup(): Boolean
    begin
        if Rec.FindFirst() then
            exit(true);

        Clear(Rec);
        exit(false);
    end;
}
