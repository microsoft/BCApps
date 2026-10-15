// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// How a Payables Agent task was sourced. Used to pick the review page regardless of whether the task is
/// backed by an e-document (v1) or a Payables Agent task (v2).
/// </summary>
enum 3340 "PA Agent Source Type"
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
