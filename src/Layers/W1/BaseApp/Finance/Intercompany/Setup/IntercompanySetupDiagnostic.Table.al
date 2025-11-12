// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

table 33 "Intercompany Setup Diagnostic"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Code[20])
        {

        }
        field(2; Description; Text[250])
        {

        }
        field(3; Status; Option)
        {
            OptionMembers = Ok,Warning,Error;
        }
    }
    keys
    {
        key(Key1; Id, Description)
        {
        }
    }
}
