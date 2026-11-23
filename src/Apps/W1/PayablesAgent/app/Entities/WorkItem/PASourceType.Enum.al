// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

enum 3340 "PA Source Type"
{
    Access = Internal;
    Extensible = false;

    value(0; Email)
    {
        Caption = 'Email';
    }
    value(1; Upload)
    {
        Caption = 'Upload';
    }
}
