#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Text;


/// <summary>
/// Contains settings for Azure OpenAI.
/// </summary>
table 2010 "Azure OpenAi Settings"
{
    ObsoleteReason = 'Moved to AI SDK';
    ObsoleteTag = '27.0';
    ObsoleteState = Removed;
    Caption = 'Azure OpenAI Settings';
    DataPerCompany = false;
    ReplicateData = false;
    Extensible = false;
    Access = Internal;

    fields
    {
        field(1; Id; Code[10])
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }

        field(2; Endpoint; Text[250])
        {
            Caption = 'Endpoint';
            DataClassification = CustomerContent;
        }

        field(3; Model; Text[250])
        {
            Caption = 'Model';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Id)
        {
        }
    }


}
#endif